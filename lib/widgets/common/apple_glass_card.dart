import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A realistic Apple-style Glassmorphic container with frosted blur,
/// specular gradient border, inner gloss reflection, and depth shadow.
class AppleGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Gradient? glassGradient;
  final Color? baseColor;
  final double glassOpacity;
  final double borderWidth;
  final bool showSpecularGloss;
  final VoidCallback? onTap;

  const AppleGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
    this.borderRadius = 24.0,
    this.blur = 25.0,
    this.glassGradient,
    this.baseColor,
    this.glassOpacity = 0.25,
    this.borderWidth = 1.2,
    this.showSpecularGloss = true,
    this.onTap,
  });

  /// Factory constructor for the iconic Apple Blue Glass card (e.g., Greeting Banner)
  factory AppleGlassCard.blueBanner({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24.0),
    double borderRadius = 24.0,
    VoidCallback? onTap,
  }) {
    return AppleGlassCard(
      key: key,
      padding: padding,
      borderRadius: borderRadius,
      blur: 28.0,
      borderWidth: 1.5,
      glassGradient: LinearGradient(
        colors: [
          const Color(0xFF1E3A8A).withValues(alpha: 0.85), // Deep navy blue frosted
          const Color(0xFF2563EB).withValues(alpha: 0.75), // Vibrant electric blue
          const Color(0xFF3B82F6).withValues(alpha: 0.65), // Bright sky blue translucency
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: onTap,
      child: child,
    );
  }

  /// Factory constructor for Ultra-Light Frosted Glass (cards, stats, panels)
  factory AppleGlassCard.frosted({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20.0),
    double borderRadius = 20.0,
    VoidCallback? onTap,
  }) {
    return AppleGlassCard(
      key: key,
      padding: padding,
      borderRadius: borderRadius,
      blur: 20.0,
      borderWidth: 1.2,
      glassGradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.70),
          Colors.white.withValues(alpha: 0.40),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = glassGradient ??
        LinearGradient(
          colors: [
            (baseColor ?? Colors.white).withValues(alpha: glassOpacity * 1.5),
            (baseColor ?? Colors.white).withValues(alpha: glassOpacity * 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

    final cardContent = Container(
      constraints: const BoxConstraints(minWidth: 1.0, minHeight: 1.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Ambient soft depth shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 25,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          // Specular keylight shadow
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
            blurRadius: 35,
            spreadRadius: -5,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: kIsWeb ? (blur > 8 ? 8 : blur) : blur,
                sigmaY: kIsWeb ? (blur > 8 ? 8 : blur) : blur,
              ),
          child: CustomPaint(
            foregroundPainter: _AppleGlassSpecularBorderPainter(
              borderRadius: borderRadius,
              borderWidth: borderWidth,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: padding,
              decoration: BoxDecoration(
                gradient: effectiveGradient,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              foregroundDecoration: showSpecularGloss
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 0.65],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    )
                  : null,
              child: child,
            ),
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Custom painter to draw Apple's characteristic multi-angle specular border.
/// Light hits top-left (bright high-alpha white highlight) and fades towards bottom-right.
class _AppleGlassSpecularBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;

  _AppleGlassSpecularBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      borderWidth / 2,
      borderWidth / 2,
      size.width - borderWidth,
      size.height - borderWidth,
    );

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.70), // Top-Left Specular Light Peak
          Colors.white.withValues(alpha: 0.35), // Mid-Edge Transition
          Colors.white.withValues(alpha: 0.10), // Bottom-Right Soft Shadow Edge
          Colors.white.withValues(alpha: 0.30), // Corner Reflection Bounce
        ],
        stops: const [0.0, 0.4, 0.75, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _AppleGlassSpecularBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius || oldDelegate.borderWidth != borderWidth;
  }
}

/// Background Ambient Mesh Glow widget that provides rich colorful nodes
/// behind the glass elements for authentic glass refraction effects.
class AmbientGlassBackground extends StatelessWidget {
  final Widget child;

  const AmbientGlassBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base white background canvas tint with glowing ambient mesh orbs
        Positioned.fill(
          child: Container(
            color: Colors.white,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: -60,
                  left: -40,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.35),
                          const Color(0xFF60A5FA).withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 120,
                  right: -50,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF8B5CF6).withValues(alpha: 0.30),
                          const Color(0xFFC084FC).withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100,
                  left: 40,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF06B6D4).withValues(alpha: 0.25),
                          const Color(0xFF67E8F9).withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content on top of ambient glass background
        child,
      ],
    );
  }
}
