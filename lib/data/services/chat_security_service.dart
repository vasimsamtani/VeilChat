import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';

enum AuthOutcome { successReal, successDecoy, failed }

class ChatSecurityService extends ChangeNotifier {
  String _primaryPin = '1234';
  String _decoyPin = '9999';
  int _autoLockSeconds = 60;
  String _notificationDisguise = 'Google Calendar: Team Sync in 15m';

  String? _unlockedChatId;
  bool _isDecoyActive = false;
  int _remainingLockSeconds = 0;
  Timer? _countdownTimer;

  bool _globalGhostMode = false;
  final List<String> _vaultSavedMedia = [];

  // Initial Sample Conversations
  late List<ChatConversation> _conversations;

  ChatSecurityService() {
    _initSampleData();
  }

  // Getters
  String get primaryPin => _primaryPin;
  String get decoyPin => _decoyPin;
  int get autoLockSeconds => _autoLockSeconds;
  String get notificationDisguise => _notificationDisguise;
  String? get unlockedChatId => _unlockedChatId;
  bool get isDecoyActive => _isDecoyActive;
  int get remainingLockSeconds => _remainingLockSeconds;
  bool get globalGhostMode => _globalGhostMode;
  List<ChatConversation> get conversations => List.unmodifiable(_conversations);
  List<String> get vaultSavedMedia => List.unmodifiable(_vaultSavedMedia);

  void _initSampleData() {
    _conversations = [];
  }

  // Authentication logic
  AuthOutcome authenticatePin(String chatId, String pin) {
    if (pin == _primaryPin) {
      _unlockedChatId = chatId;
      _isDecoyActive = false;
      _startCountdown();
      notifyListeners();
      return AuthOutcome.successReal;
    } else if (pin == _decoyPin) {
      _unlockedChatId = chatId;
      _isDecoyActive = true;
      _startCountdown();
      notifyListeners();
      return AuthOutcome.successDecoy;
    } else {
      return AuthOutcome.failed;
    }
  }

  bool authenticateBiometrics(String chatId) {
    _unlockedChatId = chatId;
    _isDecoyActive = false;
    _startCountdown();
    notifyListeners();
    return true;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _remainingLockSeconds = _autoLockSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingLockSeconds > 1) {
        _remainingLockSeconds--;
        notifyListeners();
      } else {
        lockCurrentChat();
      }
    });
  }

  void lockCurrentChat() {
    _countdownTimer?.cancel();
    _unlockedChatId = null;
    _isDecoyActive = false;
    _remainingLockSeconds = 0;
    notifyListeners();
  }

  bool isChatUnlocked(String chatId) {
    return _unlockedChatId == chatId;
  }

  void toggleChatLock(String chatId) {
    final index = _conversations.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final current = _conversations[index];
      _conversations[index] = current.copyWith(isLocked: !current.isLocked);
      if (current.id == _unlockedChatId) {
        lockCurrentChat();
      }
      notifyListeners();
    }
  }

  bool _ghostReadReceipts = true;
  bool _ghostStatusView = true;
  bool _ghostTyping = true;
  bool _autoSaveViewOnce = true;
  bool _antiRevokeMessages = true;

  bool get ghostReadReceipts => _ghostReadReceipts;
  bool get ghostStatusView => _ghostStatusView;
  bool get ghostTyping => _ghostTyping;
  bool get autoSaveViewOnce => _autoSaveViewOnce;
  bool get antiRevokeMessages => _antiRevokeMessages;

  void toggleGhostMode() {
    _globalGhostMode = !_globalGhostMode;
    notifyListeners();
  }

  void toggleGhostReadReceipts() {
    _ghostReadReceipts = !_ghostReadReceipts;
    notifyListeners();
  }

  void toggleGhostStatusView() {
    _ghostStatusView = !_ghostStatusView;
    notifyListeners();
  }

  void toggleGhostTyping() {
    _ghostTyping = !_ghostTyping;
    notifyListeners();
  }

  void toggleAutoSaveViewOnce() {
    _autoSaveViewOnce = !_autoSaveViewOnce;
    notifyListeners();
  }

  void toggleAntiRevokeMessages() {
    _antiRevokeMessages = !_antiRevokeMessages;
    notifyListeners();
  }

  final Map<String, bool> _grantedPermissions = {
    'camera': false,
    'gallery': false,
    'contacts': false,
    'files': false,
    'location': false,
    'microphone': false,
  };

  Map<String, bool> get grantedPermissions => Map.unmodifiable(_grantedPermissions);

  void togglePermission(String key) {
    _grantedPermissions[key] = !(_grantedPermissions[key] ?? false);
    notifyListeners();
  }

  bool verifyPin(String pin, {required bool isDecoy}) {
    return isDecoy ? pin == _decoyPin : pin == _primaryPin;
  }

  bool changePin({
    required bool isDecoy,
    required String oldPin,
    required String newPin,
  }) {
    if (newPin.length != 4) return false;
    final isOldValid = isDecoy ? oldPin == _decoyPin : oldPin == _primaryPin;
    if (!isOldValid) return false;

    if (isDecoy) {
      _decoyPin = newPin;
    } else {
      _primaryPin = newPin;
    }
    notifyListeners();
    return true;
  }

  void setPrimaryPin(String newPin) {
    if (newPin.length == 4) {
      _primaryPin = newPin;
      notifyListeners();
    }
  }

  void setDecoyPin(String newPin) {
    if (newPin.length == 4) {
      _decoyPin = newPin;
      notifyListeners();
    }
  }

  void setAutoLockSeconds(int seconds) {
    _autoLockSeconds = seconds;
    notifyListeners();
  }

  void setNotificationDisguise(String disguise) {
    _notificationDisguise = disguise;
    notifyListeners();
  }

  void saveViewOnceToVault(String messageId) {
    if (!_vaultSavedMedia.contains(messageId)) {
      _vaultSavedMedia.add(messageId);
      // Update message in conversation
      for (int i = 0; i < _conversations.length; i++) {
        final conv = _conversations[i];
        final updatedReal = conv.realMessages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(isSavedToVault: true);
          }
          return m;
        }).toList();
        _conversations[i] = conv.copyWith(realMessages: updatedReal);
      }
      notifyListeners();
    }
  }

  void sendMessage(String chatId, String text) {
    if (text.trim().isEmpty) return;
    final nowTime = 'Just now';
    final newMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      text: text.trim(),
      timestamp: nowTime,
      isMe: true,
      isRead: false,
    );

    final index = _conversations.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final conv = _conversations[index];
      if (_isDecoyActive) {
        final updatedDecoy = List<ChatMessage>.from(conv.decoyMessages)..add(newMessage);
        _conversations[index] = conv.copyWith(
          decoyMessages: updatedDecoy,
          lastMessageTime: nowTime,
          previewText: text.trim(),
        );
      } else {
        final updatedReal = List<ChatMessage>.from(conv.realMessages)..add(newMessage);
        _conversations[index] = conv.copyWith(
          realMessages: updatedReal,
          lastMessageTime: nowTime,
          previewText: text.trim(),
        );
      }
      notifyListeners();
    }
  }

  ChatConversation createOrGetConversation(String jid, String name) {
    // Purge dummy mock chats
    _conversations.removeWhere((c) =>
        c.id == 'sarah_m' ||
        c.id == 'david_c' ||
        c.id == 'alex_r' ||
        c.id == 'emily_c');

    final index = _conversations.indexWhere((c) => c.id == jid);
    if (index != -1) {
      return _conversations[index];
    }

    final displayName = name.isNotEmpty ? name : jid.split('@')[0];
    final initials = displayName.length >= 2
        ? displayName.substring(0, 2).toUpperCase()
        : displayName.toUpperCase();

    final newConv = ChatConversation(
      id: jid,
      contactName: displayName,
      avatarInitials: initials,
      isOnline: true,
      isLocked: false,
      isVerified: false,
      unreadCount: 0,
      lastMessageTime: 'Just now',
      previewText: 'Tap to chat',
      realMessages: [],
      decoyMessages: [],
    );

    _conversations.insert(0, newConv);
    notifyListeners();
    return newConv;
  }

  void clearMockDataIfAuthenticated() {
    final hadMock = _conversations.any((c) =>
        c.id == 'sarah_m' ||
        c.id == 'david_c' ||
        c.id == 'alex_r' ||
        c.id == 'emily_c');
    if (hadMock) {
      _conversations.removeWhere((c) =>
          c.id == 'sarah_m' ||
          c.id == 'david_c' ||
          c.id == 'alex_r' ||
          c.id == 'emily_c');
      notifyListeners();
    }
  }

  void syncWhatsAppChats(List<Map<String, dynamic>> rawChats) {
    if (rawChats.isEmpty) return;

    // Filter out status broadcasts or empty IDs
    final validChats = rawChats.where((r) {
      final jid = r['id']?.toString() ?? '';
      return jid.isNotEmpty && !jid.contains('status@broadcast');
    }).toList();

    if (validChats.isEmpty) return;

    // Remove dummy sample conversations so user's real WhatsApp chats take over
    _conversations.removeWhere((c) =>
        c.id == 'sarah_m' ||
        c.id == 'david_c' ||
        c.id == 'alex_r' ||
        c.id == 'emily_c');

    bool hasChanges = false;
    for (final raw in validChats) {
      final jid = raw['id']?.toString() ?? '';
      final name = raw['name']?.toString() ?? jid.split('@')[0];
      final unreadCount = (raw['unreadCount'] as num?)?.toInt() ?? 0;
      final lastText = raw['lastMessageText']?.toString() ?? '';
      final lastTime = raw['lastMessageTime']?.toString() ?? '';

      final existingIndex = _conversations.indexWhere((c) => c.id == jid);
      if (existingIndex != -1) {
        final existing = _conversations[existingIndex];
        _conversations[existingIndex] = existing.copyWith(
          contactName: name.isNotEmpty ? name : existing.contactName,
          unreadCount: unreadCount,
          lastMessageTime: lastTime.isNotEmpty ? lastTime : existing.lastMessageTime,
          previewText: lastText.isNotEmpty ? lastText : existing.previewText,
        );
        hasChanges = true;
      } else {
        // Add new live WhatsApp chat
        final initials = name.isNotEmpty
            ? (name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase())
            : 'WA';
        _conversations.add(
          ChatConversation(
            id: jid,
            contactName: name,
            avatarInitials: initials,
            isOnline: true,
            isLocked: false,
            isVerified: false,
            unreadCount: unreadCount,
            lastMessageTime: lastTime,
            previewText: lastText.isNotEmpty ? lastText : 'Tap to start conversation',
            realMessages: [],
            decoyMessages: [
              const ChatMessage(
                id: 'decoy_init',
                senderId: 'contact',
                text: 'Hey! Are we still meeting for lunch today?',
                timestamp: '11:00 AM',
                isMe: false,
              ),
            ],
          ),
        );
        hasChanges = true;
      }
    }
    if (hasChanges) {
      notifyListeners();
    }
  }

  void handleIncomingLiveMessage(Map<String, dynamic> msg) {
    final remoteJid = msg['remoteJid']?.toString() ?? '';
    final text = msg['text']?.toString() ?? '';
    final isFromMe = msg['isFromMe'] == true;
    final timeStr = msg['timeStr']?.toString() ?? 'Just now';
    final id = msg['id']?.toString() ?? 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final senderName = msg['senderName']?.toString() ?? remoteJid.split('@')[0];

    if (remoteJid.isEmpty || text.isEmpty) return;

    // Purge dummy mock chats
    _conversations.removeWhere((c) =>
        c.id == 'sarah_m' ||
        c.id == 'david_c' ||
        c.id == 'alex_r' ||
        c.id == 'emily_c');

    final newChatMessage = ChatMessage(
      id: id,
      senderId: isFromMe ? 'me' : remoteJid,
      text: text,
      timestamp: timeStr,
      isMe: isFromMe,
      isRead: false,
    );

    final index = _conversations.indexWhere((c) => c.id == remoteJid);
    if (index != -1) {
      final conv = _conversations[index];
      final updatedReal = List<ChatMessage>.from(conv.realMessages)..add(newChatMessage);
      _conversations[index] = conv.copyWith(
        realMessages: updatedReal,
        lastMessageTime: timeStr,
        previewText: text,
        unreadCount: isFromMe ? conv.unreadCount : conv.unreadCount + 1,
      );
    } else {
      // New conversation initiated by incoming message
      final initials = senderName.length >= 2
          ? senderName.substring(0, 2).toUpperCase()
          : senderName.toUpperCase();
      _conversations.insert(
        0,
        ChatConversation(
          id: remoteJid,
          contactName: senderName,
          avatarInitials: initials,
          isOnline: true,
          isLocked: false,
          isVerified: false,
          unreadCount: isFromMe ? 0 : 1,
          lastMessageTime: timeStr,
          previewText: text,
          realMessages: [newChatMessage],
          decoyMessages: [
            const ChatMessage(
              id: 'decoy_init',
              senderId: 'contact',
              text: 'Hey! Are we still meeting for lunch today?',
              timestamp: '11:00 AM',
              isMe: false,
            ),
          ],
        ),
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
