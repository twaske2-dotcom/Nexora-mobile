import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Nexora ka reusable "aurora" background.
/// Dark base + dheere-dheere ghoomte purple/pink glow blobs.
/// Koi video/asset nahi - pure Flutter, smooth aur halka.
class AppBackground extends StatefulWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark gradient
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D0D14),
                Color(0xFF15102A),
                Color(0xFF0D0D14),
              ],
            ),
          ),
          child: SizedBox.expand(),
        ),

        // Moving glow blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * math.pi;
            return Stack(
              children: [
                _glow(
                  color: const Color(0xFF7B5CF0),
                  size: 360,
                  ax: -0.7 + 0.25 * math.sin(t),
                  ay: -0.8 + 0.15 * math.cos(t),
                  opacity: 0.40,
                ),
                _glow(
                  color: const Color(0xFFB06AB3),
                  size: 320,
                  ax: 0.8 + 0.18 * math.cos(t * 0.8),
                  ay: -0.3 + 0.20 * math.sin(t * 0.8),
                  opacity: 0.32,
                ),
                _glow(
                  color: const Color(0xFF5B3FD0),
                  size: 420,
                  ax: 0.1 + 0.20 * math.sin(t * 0.6 + 1),
                  ay: 0.9 + 0.12 * math.cos(t * 0.6 + 1),
                  opacity: 0.30,
                ),
              ],
            );
          },
        ),

        // Actual screen content
        widget.child,
      ],
    );
  }

  // Ek soft glowing circle jo alignment (ax, ay) pe rehta hai (-1..1)
  Widget _glow({
    required Color color,
    required double size,
    required double ax,
    required double ay,
    required double opacity,
  }) {
    return Align(
      alignment: Alignment(ax, ay),
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
