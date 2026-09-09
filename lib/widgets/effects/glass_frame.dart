import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A luxury frosted glassmorphism outer bezel/frame matching the Apple/macOS
/// liquid glass aesthetic shown in the design reference.
///
/// Features:
/// 1. Frosted background blur ([BackdropFilter] with [ui.ImageFilter.blur]) showing
///    the underlying animated cloud sky softly diffused.
/// 2. Translucent milky white specular glass fill gradient.
/// 3. Luminous 1.5px white specular rim border with corner light refraction.
/// 4. Soft ambient drop shadows and glass bloom.
class GlassFrame extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final double innerRadius;
  final double blurSigma;
  final Color? tintColor;
  final Color? glowColor;
  final double glassOpacity;
  final double borderOpacity;

  const GlassFrame({
    super.key,
    required this.child,
    this.borderWidth = 14.0,
    this.innerRadius = 24.0,
    this.blurSigma = 24.0,
    this.tintColor,
    this.glowColor,
    this.glassOpacity = 0.42,
    this.borderOpacity = 0.80,
  });

  @override
  Widget build(BuildContext context) {
    final outerRadius = innerRadius + borderWidth;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(outerRadius),
        boxShadow: [
          // 1. Soft diffused ambient drop shadow onto sky/clouds
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 44,
            spreadRadius: 0,
            offset: const Offset(0, 18),
          ),
          // 2. Subtle atmospheric sky glow tint
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.14),
            blurRadius: 28,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
          // 3. Specular top rim outer bloom
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.40),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(outerRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: CustomPaint(
            foregroundPainter: _GlassBorderPainter(
              outerRadius: outerRadius,
              strokeWidth: 1.5,
              borderOpacity: borderOpacity,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(outerRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: (glassOpacity + 0.18).clamp(0.0, 1.0)),
                    Colors.white.withValues(alpha: glassOpacity),
                    Colors.white.withValues(alpha: (glassOpacity - 0.16).clamp(0.0, 1.0)),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
              padding: EdgeInsets.all(borderWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassBorderPainter extends CustomPainter {
  final double outerRadius;
  final double strokeWidth;
  final double borderOpacity;

  _GlassBorderPainter({
    required this.outerRadius,
    required this.strokeWidth,
    required this.borderOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(outerRadius));
    final borderRRect = rrect.deflate(strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [
          Colors.white.withValues(alpha: (borderOpacity + 0.15).clamp(0.0, 1.0)),
          Colors.white.withValues(alpha: borderOpacity),
          Colors.white.withValues(alpha: (borderOpacity * 0.40)),
          Colors.white.withValues(alpha: (borderOpacity * 0.65)),
        ],
        const [0.0, 0.35, 0.75, 1.0],
      );

    canvas.drawRRect(borderRRect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassBorderPainter oldDelegate) {
    return oldDelegate.outerRadius != outerRadius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderOpacity != borderOpacity;
  }
}
