import 'package:flutter/material.dart';
import 'package:veilchat/ui/core/theme.dart';

class ShimmerRedaction extends StatefulWidget {
  final String label;
  final bool isLocked;
  final bool showWaveform;
  final IconData icon;
  final String? trailingTag;
  final VoidCallback? onTap;

  const ShimmerRedaction({
    super.key,
    this.label = 'Tap to unlock conversation',
    this.isLocked = true,
    this.showWaveform = false,
    this.icon = Icons.fingerprint_rounded,
    this.trailingTag,
    this.onTap,
  });

  @override
  State<ShimmerRedaction> createState() => _ShimmerRedactionState();
}

class _ShimmerRedactionState extends State<ShimmerRedaction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF1E2232),
                  Color(0xFF2E3348),
                  Color(0xFF1E2232),
                ],
                stops: [
                  (progress - 0.3).clamp(0.0, 1.0),
                  progress.clamp(0.0, 1.0),
                  (progress + 0.3).clamp(0.0, 1.0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border.all(
                color: VeilTheme.cyberCyan.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 15,
                  color: VeilTheme.cyberCyan,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      color: Color(0xFFBAC4D6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.showWaveform) ...[
                  const SizedBox(width: 8),
                  _buildAnimatedWaveform(progress),
                ],
                if (widget.trailingTag != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: VeilTheme.primaryViolet.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.trailingTag!,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: VeilTheme.primaryViolet,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedWaveform(double progress) {
    // 5 bars with phase offsets
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBar(progress, 0.0, 8, VeilTheme.cyberCyan),
        const SizedBox(width: 2),
        _buildBar(progress, 0.2, 14, VeilTheme.primaryViolet),
        const SizedBox(width: 2),
        _buildBar(progress, 0.4, 6, VeilTheme.cyberCyan),
        const SizedBox(width: 2),
        _buildBar(progress, 0.6, 16, VeilTheme.primaryViolet),
        const SizedBox(width: 2),
        _buildBar(progress, 0.8, 9, VeilTheme.cyberCyan),
      ],
    );
  }

  Widget _buildBar(double progress, double offset, double maxHeight, Color color) {
    final effectiveProgress = (progress + offset) % 1.0;
    final scale = 0.3 + 0.7 * (1 - (effectiveProgress - 0.5).abs() * 2);
    return Container(
      width: 2,
      height: maxHeight * scale,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
