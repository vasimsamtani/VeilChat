import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:veilchat/data/services/chat_security_service.dart';
import 'package:veilchat/main.dart';
import 'package:veilchat/ui/core/theme.dart';
import 'package:veilchat/ui/features/auth/security_keypad_modal.dart';
import 'package:veilchat/ui/features/chat_list/chat_list_screen.dart';

void main() {
  testWidgets('VeilChatApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VeilChatApp());
    expect(find.byType(VeilChatApp), findsOneWidget);
  });

  testWidgets('ChatListScreen renders ambient security strip, contacts, and enclave card', (WidgetTester tester) async {
    final securityService = ChatSecurityService();

    await tester.pumpWidget(
      ChangeNotifierProvider<ChatSecurityService>.value(
        value: securityService,
        child: MaterialApp(
          theme: VeilTheme.darkTheme,
          home: const ChatListScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Verify ambient strip
    expect(find.text('SECURE CHANNEL • SHIELD ACTIVE'), findsOneWidget);
    expect(find.text('AES-GCM-256'), findsOneWidget);

    // Verify contacts
    expect(find.text('Sarah Miller'), findsOneWidget);
    expect(find.text('David Clark'), findsOneWidget);
    expect(find.text('Vault'), findsOneWidget);

    // Verify Zero-Knowledge Enclave status footer card
    expect(find.text('Zero-Knowledge Enclave'), findsOneWidget);
    expect(find.text('Audit'), findsOneWidget);
  });

  testWidgets('Tapping locked chat opens SecurityKeypadModal', (WidgetTester tester) async {
    final securityService = ChatSecurityService();

    await tester.pumpWidget(
      ChangeNotifierProvider<ChatSecurityService>.value(
        value: securityService,
        child: MaterialApp(
          theme: VeilTheme.darkTheme,
          home: const ChatListScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Tap on the hero locked chat row for Sarah Miller
    await tester.tap(find.text('Sarah Miller'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify modal appeared
    expect(find.byType(SecurityKeypadModal), findsOneWidget);
    expect(find.text("Unlock Sarah Miller"), findsOneWidget);
    expect(find.text('Touch sensor or scan Face ID'), findsOneWidget);
  });

  testWidgets('Entering decoy PIN 9999 seamlessly unlocks Decoy conversation with typing indicator', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    final securityService = ChatSecurityService();

    addTearDown(() {
      securityService.lockCurrentChat();
      securityService.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<ChatSecurityService>.value(
        value: securityService,
        child: MaterialApp(
          theme: VeilTheme.darkTheme,
          home: const ChatListScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Tap on Sarah Miller to open modal
    await tester.tap(find.text('Sarah Miller'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Find the '9' keypad button
    final key9 = find.widgetWithText(InkWell, '9');
    expect(key9, findsOneWidget);

    // Enter 9999
    await tester.tap(key9);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(key9);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(key9);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(key9);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Decoy conversation is open
    expect(find.text('Today, October 24'), findsOneWidget);
    expect(find.text('Sarah is typing...'), findsOneWidget);
    expect(find.text('Active now'), findsOneWidget);

    // Cancel active countdown timer before test verification
    securityService.lockCurrentChat();
  });
}
