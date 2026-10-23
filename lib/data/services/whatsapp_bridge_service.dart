import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'chat_security_service.dart';

enum BridgeSocketStatus {
  disconnected,
  connecting,
  connected,
}

enum WhatsAppAuthStatus {
  disconnected,
  connecting,
  qrReady,
  authenticated,
}

class WhatsAppBridgeService extends ChangeNotifier {
  static const String defaultBridgeUrl = 'ws://127.0.0.1:5055';

  String _bridgeUrl;
  ChatSecurityService? _securityService;

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _disposed = false;

  BridgeSocketStatus _socketStatus = BridgeSocketStatus.disconnected;
  WhatsAppAuthStatus _waStatus = WhatsAppAuthStatus.disconnected;
  String? _qrCode;
  String? _userJid;
  String? _userName;
  String? _lastError;

  WhatsAppBridgeService({
    this._bridgeUrl = defaultBridgeUrl,
    ChatSecurityService? securityService,
    bool autoConnect = true,
  }) {
    _securityService = securityService;
    if (autoConnect) {
      connect();
    }
  }

  String get bridgeUrl => _bridgeUrl;

  void updateBridgeUrl(String newUrl) {
    if (newUrl.trim().isEmpty) return;
    String formatted = newUrl.trim();
    if (!formatted.startsWith('ws://') && !formatted.startsWith('wss://')) {
      if (formatted.startsWith('https://')) {
        formatted = formatted.replaceFirst('https://', 'wss://');
      } else if (formatted.startsWith('http://')) {
        formatted = formatted.replaceFirst('http://', 'ws://');
      } else {
        formatted = 'wss://$formatted';
      }
    }
    _bridgeUrl = formatted;
    _channel?.sink.close();
    _socketStatus = BridgeSocketStatus.disconnected;
    notifyListeners();
    connect();
  }

  void updateSecurityService(ChatSecurityService securityService) {
    _securityService = securityService;
  }

  // Getters
  BridgeSocketStatus get socketStatus => _socketStatus;
  WhatsAppAuthStatus get waStatus => _waStatus;
  String? get qrCode => _qrCode;
  String? get userJid => _userJid;
  String? get userName => _userName;
  String? get lastError => _lastError;
  bool get isConnectedToBridge => _socketStatus == BridgeSocketStatus.connected;
  bool get isAuthenticated => _waStatus == WhatsAppAuthStatus.authenticated;

  void connect() {
    if (_disposed || _socketStatus == BridgeSocketStatus.connecting) return;

    _reconnectTimer?.cancel();
    _socketStatus = BridgeSocketStatus.connecting;
    notifyListeners();

    try {
      final uri = Uri.parse(bridgeUrl);
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _onMessageReceived,
        onDone: _onDisconnected,
        onError: (err) {
          _lastError = 'Bridge error: $err';
          _onDisconnected();
        },
      );

      _socketStatus = BridgeSocketStatus.connected;
      notifyListeners();

      // Request status from bridge
      sendAction({'action': 'get_status'});
    } catch (e) {
      _lastError = 'Failed to connect to local bridge: $e';
      _onDisconnected();
    }
  }

  void _onMessageReceived(dynamic event) {
    try {
      final data = jsonDecode(event.toString()) as Map<String, dynamic>;
      final type = data['type']?.toString();

      switch (type) {
        case 'status':
          _handleStatusUpdate(data);
          break;

        case 'qr':
          _qrCode = data['qr']?.toString();
          _waStatus = WhatsAppAuthStatus.qrReady;
          notifyListeners();
          break;

        case 'connected':
          _qrCode = null;
          _waStatus = WhatsAppAuthStatus.authenticated;
          final user = data['user'] as Map<String, dynamic>?;
          _userJid = user?['id']?.toString();
          _userName = user?['name']?.toString() ?? _userJid?.split('@')[0];
          if (data.containsKey('chats')) {
            final rawChats = (data['chats'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
            _securityService?.syncWhatsAppChats(rawChats);
          }
          notifyListeners();
          break;

        case 'chats_update':
          final rawChats = (data['chats'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          _securityService?.syncWhatsAppChats(rawChats);
          notifyListeners();
          break;

        case 'message_new':
          final message = data['message'] as Map<String, dynamic>?;
          if (message != null) {
            _securityService?.handleIncomingLiveMessage(message);
          }
          notifyListeners();
          break;

        case 'error':
          _lastError = data['message']?.toString();
          notifyListeners();
          break;
      }
    } catch (e) {
      debugPrint('[WhatsAppBridgeService] Error parsing event: $e');
    }
  }

  void _handleStatusUpdate(Map<String, dynamic> data) {
    final status = data['status']?.toString();
    _qrCode = data['qr']?.toString();

    if (status == 'connected') {
      _waStatus = WhatsAppAuthStatus.authenticated;
      final user = data['user'] as Map<String, dynamic>?;
      _userJid = user?['id']?.toString();
      _userName = user?['name']?.toString() ?? _userJid?.split('@')[0];
      _securityService?.clearMockDataIfAuthenticated();
    } else if (status == 'qr_ready' || _qrCode != null) {
      _waStatus = WhatsAppAuthStatus.qrReady;
    } else if (status == 'connecting') {
      _waStatus = WhatsAppAuthStatus.connecting;
    } else {
      _waStatus = WhatsAppAuthStatus.disconnected;
    }

    if (data.containsKey('chats')) {
      final rawChats = (data['chats'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      _securityService?.syncWhatsAppChats(rawChats);
    }

    notifyListeners();
  }

  void _onDisconnected() {
    _socketStatus = BridgeSocketStatus.disconnected;
    _waStatus = WhatsAppAuthStatus.disconnected;
    _channel = null;
    notifyListeners();

    if (!_disposed) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 4), () {
        connect();
      });
    }
  }

  void sendAction(Map<String, dynamic> actionMap) {
    if (_channel != null && _socketStatus == BridgeSocketStatus.connected) {
      try {
        _channel!.sink.add(jsonEncode(actionMap));
      } catch (e) {
        debugPrint('[WhatsAppBridgeService] Error sending action: $e');
      }
    }
  }

  void sendMessage(String jid, String text) {
    sendAction({
      'action': 'send_message',
      'jid': jid,
      'text': text,
    });
  }

  void startChat(String jid, String name) {
    sendAction({
      'action': 'start_chat',
      'jid': jid,
      'name': name,
    });
  }

  void logout() {
    sendAction({'action': 'logout'});
  }

  void refreshQr() {
    sendAction({'action': 'restart_bridge'});
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
