import 'package:flutter/material.dart';
import 'glass_frame.dart';

export 'glass_frame.dart';
export 'noise_background.dart';

/// A luxury frosted glass outer bezel/frame matching the Apple liquid glass aesthetic.
class NoiseFrame extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final double innerRadius;
  final Color baseColor;
  final Color glowColor;
  final List<Color>? gradientColors;

  const NoiseFrame({
    super.key,
    required this.child,
    this.borderWidth = 14.0,
    this.innerRadius = 24.0,
    this.baseColor = const Color(0xFF0F172A),
    this.glowColor = const Color(0xFF38BDF8),
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return GlassFrame(
      borderWidth: borderWidth,
      innerRadius: innerRadius,
      blurSigma: 24.0,
      glassOpacity: 0.42,
      borderOpacity: 0.80,
      glowColor: glowColor,
      child: child,
    );
  }
}
