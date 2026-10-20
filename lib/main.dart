import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veilchat/data/services/chat_security_service.dart';
import 'package:veilchat/data/services/whatsapp_bridge_service.dart';
import 'package:veilchat/ui/core/theme.dart';
import 'package:veilchat/ui/features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VeilChatApp());
}

class VeilChatApp extends StatefulWidget {
  const VeilChatApp({super.key});

  @override
  State<VeilChatApp> createState() => _VeilChatAppState();
}

class _VeilChatAppState extends State<VeilChatApp> with WidgetsBindingObserver {
  late final ChatSecurityService _securityService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _securityService = ChatSecurityService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _securityService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _securityService.lockCurrentChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatSecurityService>.value(
          value: _securityService,
        ),
        ChangeNotifierProvider<WhatsAppBridgeService>(
          create: (_) => WhatsAppBridgeService(securityService: _securityService),
        ),
      ],
      child: MaterialApp(
        title: 'VeilChat',
        debugShowCheckedModeBanner: false,
        theme: VeilTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
