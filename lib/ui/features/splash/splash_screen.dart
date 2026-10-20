import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:veilchat/ui/core/theme.dart';
import 'package:veilchat/ui/features/chat_list/chat_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late Animation<double> _vTraceAnim;
  late Animation<double> _shackleSnapAnim;
  late Animation<double> _rippleAnim;
  late Animation<double> _textBlurAnim;
  late Animation<double> _taglineFadeAnim;
  late Animation<double> _unlockGlowAnim;

  @override
  void initState() {
    super.initState();
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // Phase 1: 0.0s - 0.6s
    _vTraceAnim = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic),
    );

    // Phase 2: 0.6s - 1.0s
    _shackleSnapAnim = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.25, 0.42, curve: Curves.elasticOut),
    );

    _rippleAnim = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
    );

    // Phase 3: 1.0s - 1.6s
    _textBlurAnim = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.40, 0.65, curve: Curves.easeOutCubic),
    );

    // Phase 4: 1.6s - 2.0s
    _taglineFadeAnim = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.65, 0.82, curve: Curves.easeIn),
    );

    // Phase 5: 2.0s - 2.5s
    _unlockGlowAnim = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.82, 1.0, curve: Curves.easeInOut),
    );

    _masterController.forward();

    _masterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secondaryAnim) => const ChatListScreen(),
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeilTheme.backgroundDeep,
      body: GestureDetector(
        onTap: _navigateToHome,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Radial Gradient behind logo
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.15),
                    radius: 0.85,
                    colors: [
                      Color(0x287C3AED),
                      Color(0x0008090D),
                    ],
                  ),
                ),
              ),
            ),

            // Animated Biometric Ripple Rings
            AnimatedBuilder(
              animation: _rippleAnim,
              builder: (context, _) {
                if (_rippleAnim.value <= 0) return const SizedBox.shrink();
                final radius = 60.0 + (_rippleAnim.value * 160.0);
                final opacity = (1.0 - _rippleAnim.value).clamp(0.0, 1.0);
                return Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VeilTheme.cyberCyan.withValues(alpha: opacity * 0.45),
                      width: 2.0,
                    ),
                  ),
                );
              },
            ),

            // Center Content: Monogram + Typography
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Padlock Monogram
                AnimatedBuilder(
                  animation: _masterController,
                  builder: (context, child) {
                    final vProgress = _vTraceAnim.value;
                    final snapVal = _shackleSnapAnim.value;
                    final isUnlockedFlash = _unlockGlowAnim.value > 0.5;

                    return SizedBox(
                      width: 130,
                      height: 130,
                      child: CustomPaint(
                        painter: _VeilMonogramPainter(
                          traceProgress: vProgress,
                          shackleDrop: snapVal,
                          isUnlocked: isUnlockedFlash,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),

                // App Name: "VeilChat"
                AnimatedBuilder(
                  animation: _textBlurAnim,
                  builder: (context, child) {
                    final val = _textBlurAnim.value;
                    return Opacity(
                      opacity: val.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, (1 - val) * 12),
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              colors: [
                                Colors.white,
                                Color(0xFFE2E8F0),
                                VeilTheme.cyberCyan,
                              ],
                              stops: [0.0, 0.7, 1.0],
                            ).createShader(bounds);
                          },
                          child: const Text(
                            'VeilChat',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Tagline: "Visible to you. Hidden from prying eyes."
                AnimatedBuilder(
                  animation: _taglineFadeAnim,
                  builder: (context, child) {
                    final val = _taglineFadeAnim.value;
                    return Opacity(
                      opacity: val.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, (1 - val) * 8),
                        child: const Text(
                          'Visible to you. Hidden from prying eyes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            color: VeilTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Bottom Vault Status Badge & Skip Hint
            Positioned(
              bottom: 40,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: VeilTheme.surfaceDark.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: VeilTheme.surfaceBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: VeilTheme.emeraldNeon,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Zero-Knowledge Local Vault',
                          style: TextStyle(
                            color: VeilTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap anywhere to skip',
                    style: TextStyle(
                      color: VeilTheme.textDim,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VeilMonogramPainter extends CustomPainter {
  final double traceProgress;
  final double shackleDrop;
  final bool isUnlocked;

  _VeilMonogramPainter({
    required this.traceProgress,
    required this.shackleDrop,
    required this.isUnlocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Gradient Shader for strokes
    final strokeColor = isUnlocked ? VeilTheme.emeraldNeon : VeilTheme.cyberCyan;
    final Paint glowPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.35)
      ..strokeWidth = 9.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final Paint vPaint = Paint()
      ..shader = const LinearGradient(
        colors: [VeilTheme.primaryViolet, VeilTheme.cyberCyan],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw Shackle (Padlock Arch)
    if (shackleDrop > 0.05) {
      final shacklePaint = Paint()
        ..color = isUnlocked ? VeilTheme.emeraldNeon : VeilTheme.lockedAmber
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final shackleRect = Rect.fromCenter(
        center: Offset(cx, cy - 24 + ((1.0 - shackleDrop) * -20.0)),
        width: 38,
        height: 44,
      );

      final shacklePath = Path()
        ..addArc(shackleRect, math.pi, math.pi);

      canvas.drawPath(shacklePath, shacklePaint);
    }

    // Draw Geometric "V" base
    if (traceProgress > 0.02) {
      final vPath = Path();
      final leftStart = Offset(cx - 36, cy - 14);
      final bottomApex = Offset(cx, cy + 38);
      final rightEnd = Offset(cx + 36, cy - 14);

      if (traceProgress < 0.5) {
        final t = traceProgress / 0.5;
        vPath.moveTo(leftStart.dx, leftStart.dy);
        vPath.lineTo(
          leftStart.dx + (bottomApex.dx - leftStart.dx) * t,
          leftStart.dy + (bottomApex.dy - leftStart.dy) * t,
        );
      } else {
        final t = (traceProgress - 0.5) / 0.5;
        vPath.moveTo(leftStart.dx, leftStart.dy);
        vPath.lineTo(bottomApex.dx, bottomApex.dy);
        vPath.lineTo(
          bottomApex.dx + (rightEnd.dx - bottomApex.dx) * t,
          bottomApex.dy + (rightEnd.dy - bottomApex.dy) * t,
        );
      }

      canvas.drawPath(vPath, glowPaint);
      canvas.drawPath(vPath, vPaint);

      // Center keyhole dot
      final keyholePaint = Paint()
        ..color = isUnlocked ? VeilTheme.emeraldNeon : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy + 12), 4.0, keyholePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VeilMonogramPainter oldDelegate) {
    return oldDelegate.traceProgress != traceProgress ||
        oldDelegate.shackleDrop != shackleDrop ||
        oldDelegate.isUnlocked != isUnlocked;
  }
}
