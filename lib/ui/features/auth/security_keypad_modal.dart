import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veilchat/data/services/chat_security_service.dart';
import 'package:veilchat/ui/core/theme.dart';
import 'package:veilchat/ui/features/conversation/conversation_screen.dart';

class SecurityKeypadModal extends StatefulWidget {
  final String chatId;
  final String contactName;
  final String avatarInitials;
  final String? avatarAssetPath;

  const SecurityKeypadModal({
    super.key,
    required this.chatId,
    required this.contactName,
    required this.avatarInitials,
    this.avatarAssetPath,
  });

  static Future<void> show(
    BuildContext context, {
    required String chatId,
    required String contactName,
    required String avatarInitials,
    String? avatarAssetPath,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => SecurityKeypadModal(
        chatId: chatId,
        contactName: contactName,
        avatarInitials: avatarInitials,
        avatarAssetPath: avatarAssetPath,
      ),
    );
  }

  @override
  State<SecurityKeypadModal> createState() => _SecurityKeypadModalState();
}

class _SecurityKeypadModalState extends State<SecurityKeypadModal>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  bool _isError = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _isError = false;
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _isError = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() {
    final secService = context.read<ChatSecurityService>();
    final outcome = secService.authenticatePin(widget.chatId, _enteredPin);

    if (outcome == AuthOutcome.successReal) {
      _handleUnlockSuccess(isDecoy: false);
    } else if (outcome == AuthOutcome.successDecoy) {
      _handleUnlockSuccess(isDecoy: true);
    } else {
      // Trigger error shake
      setState(() {
        _isError = true;
      });
      _shakeController.forward(from: 0.0).then((_) {
        setState(() {
          _enteredPin = '';
        });
      });
    }
  }

  void _handleUnlockSuccess({required bool isDecoy}) {
    Navigator.of(context).pop(); // dismiss modal
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => ConversationScreen(
          chatId: widget.chatId,
          isDecoy: isDecoy,
        ),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _onBiometricTap() {
    final secService = context.read<ChatSecurityService>();
    secService.authenticateBiometrics(widget.chatId);
    _handleUnlockSuccess(isDecoy: false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.92,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: VeilTheme.surfaceDark.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: VeilTheme.surfaceBorderBright,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: VeilTheme.surfaceBorderBright,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),

            // Contact Avatar with Specular Aura Ring & Padlock Badge
            Stack(
              alignment: Alignment.center,
              children: [
                // Ambient Breathing Aura
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: VeilTheme.primaryViolet.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Liquid Specular Ring
                Container(
                  width: 54,
                  height: 54,
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [VeilTheme.cyberCyan, VeilTheme.primaryViolet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF1E2438),
                    backgroundImage: widget.avatarAssetPath != null
                        ? AssetImage(widget.avatarAssetPath!)
                        : null,
                    child: widget.avatarAssetPath == null
                        ? Text(
                            widget.avatarInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                ),
                // Verified Padlock Badge Overlaid
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: VeilTheme.surfaceCard,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: VeilTheme.surfaceDark,
                        width: 1.5,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        gradient: VeilTheme.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Header Text
            Text(
              'Unlock ${widget.contactName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: VeilTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Authenticate with Face ID, Fingerprint, or PIN',
              style: TextStyle(
                fontSize: 11.5,
                color: VeilTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            // Biometric Dynamic Sensor Pod
            InkWell(
              onTap: _onBiometricTap,
              borderRadius: BorderRadius.circular(25),
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VeilTheme.surfaceCard.withValues(alpha: 0.8),
                      border: Border.all(
                        color: VeilTheme.cyberCyan.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: VeilTheme.cyberCyan.withValues(alpha: 0.2),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      color: VeilTheme.cyberCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: VeilTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: VeilTheme.surfaceBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: VeilTheme.emeraldNeon,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Touch sensor or scan Face ID',
                          style: TextStyle(
                            color: VeilTheme.emeraldNeon,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // PIN Progress Beads with Error Shake
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final double offset = math.sin(_shakeController.value * math.pi * 4) * 8;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final bool isFilled = index < _enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 7),
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isError
                              ? VeilTheme.errorRed
                              : isFilled
                                  ? VeilTheme.primaryViolet
                                  : VeilTheme.surfaceCard,
                          border: Border.all(
                            color: _isError
                                ? VeilTheme.errorRed
                                : isFilled
                                    ? VeilTheme.primaryViolet
                                    : VeilTheme.surfaceBorderBright,
                            width: 1.5,
                          ),
                          boxShadow: isFilled && !_isError
                              ? [
                                  BoxShadow(
                                    color: VeilTheme.primaryViolet.withValues(alpha: 0.7),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Surgical Minimalist Numeric Pad (3x4 Layout)
            _buildKeypad(),
            const SizedBox(height: 10),

            // Discreet High-Security Footer Hint
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  Icons.shield_rounded,
                  size: 12,
                  color: VeilTheme.textDim.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Enclave Protected • Non-System Keystrokes',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: VeilTheme.textDim.withValues(alpha: 0.7),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('1', ''),
            _buildKey('2', 'ABC'),
            _buildKey('3', 'DEF'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('4', 'GHI'),
            _buildKey('5', 'JKL'),
            _buildKey('6', 'MNO'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('7', 'PQRS'),
            _buildKey('8', 'TUV'),
            _buildKey('9', 'WXYZ'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFaceIdKey(),
            _buildKey('0', '+'),
            _buildBackspaceKey(),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String digit, String letters) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(28),
        splashColor: VeilTheme.primaryViolet.withValues(alpha: 0.3),
        highlightColor: VeilTheme.cyberCyan.withValues(alpha: 0.15),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: VeilTheme.surfaceCard.withValues(alpha: 0.7),
            border: Border.all(
              color: VeilTheme.surfaceBorder,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: VeilTheme.textPrimary,
                  height: 1.1,
                ),
              ),
              if (letters.isNotEmpty)
                Text(
                  letters,
                  style: const TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w600,
                    color: VeilTheme.textDim,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaceIdKey() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onBiometricTap,
        borderRadius: BorderRadius.circular(28),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            Icons.face_rounded,
            color: VeilTheme.cyberCyan,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onBackspace,
        borderRadius: BorderRadius.circular(28),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            Icons.backspace_outlined,
            color: VeilTheme.textSecondary,
            size: 19,
          ),
        ),
      ),
    );
  }
}

