import 'package:flutter_test/flutter_test.dart';
import 'package:veilchat/data/services/chat_security_service.dart';

void main() {
  group('ChatSecurityService Security & Duress Tests', () {
    late ChatSecurityService service;

    setUp(() {
      service = ChatSecurityService();
    });

    tearDown(() {
      service.dispose();
    });

    test('Primary PIN unlocks real chat mode', () {
      final result = service.authenticatePin('sarah_m', '1234');
      expect(result, AuthOutcome.successReal);
      expect(service.isChatUnlocked('sarah_m'), isTrue);
      expect(service.isDecoyActive, isFalse);
      expect(service.remainingLockSeconds, 60);
    });

    test('Decoy PIN triggers duress Decoy Mode seamlessly', () {
      final result = service.authenticatePin('sarah_m', '9999');
      expect(result, AuthOutcome.successDecoy);
      expect(service.isChatUnlocked('sarah_m'), isTrue);
      expect(service.isDecoyActive, isTrue);
      expect(service.remainingLockSeconds, 60);
    });

    test('Invalid PIN fails verification and does not unlock', () {
      final result = service.authenticatePin('sarah_m', '0000');
      expect(result, AuthOutcome.failed);
      expect(service.isChatUnlocked('sarah_m'), isFalse);
    });

    test('Manual instant lock immediately resets session', () {
      service.authenticatePin('sarah_m', '1234');
      expect(service.isChatUnlocked('sarah_m'), isTrue);

      service.lockCurrentChat();
      expect(service.isChatUnlocked('sarah_m'), isFalse);
      expect(service.unlockedChatId, isNull);
    });

    test('Biometric authentication unlocks real chat', () {
      final success = service.authenticateBiometrics('sarah_m');
      expect(success, isTrue);
      expect(service.isChatUnlocked('sarah_m'), isTrue);
      expect(service.isDecoyActive, isFalse);
    });

    test('Toggle individual chat lock updates conversation state', () {
      final conv = service.conversations.firstWhere((c) => c.id == 'david_c');
      expect(conv.isLocked, isFalse);

      service.toggleChatLock('david_c');
      final updated = service.conversations.firstWhere((c) => c.id == 'david_c');
      expect(updated.isLocked, isTrue);
    });

    test('Save view-once media adds to encrypted local vault', () {
      expect(service.vaultSavedMedia, isEmpty);
      service.saveViewOnceToVault('m4');
      expect(service.vaultSavedMedia.contains('m4'), isTrue);
    });

    test('Ghost Mode toggle works as expected', () {
      expect(service.globalGhostMode, isFalse);
      service.toggleGhostMode();
      expect(service.globalGhostMode, isTrue);
    });
  });
}
