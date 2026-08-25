import 'package:flutter/material.dart';

/// Artful custom vector illustration widget for the onboarding top hero visual.
/// Renders scenic mountain silhouettes, glowing sky gradient, futuristic college architecture,
/// and smooth bottom gradient mask fading into white.
class CampusHeroArt extends StatelessWidget {
  final double height;

  const CampusHeroArt({
    super.key,
    this.height = 360,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Onboarding Top Hero Art Image
          Image.asset(
            'assets/onboarding.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stackTrace) => CustomPaint(
              painter: _HeroLandscapePainter(),
              size: Size.infinite,
            ),
          ),

          // Smooth Gradient Mask: Fades the bottom cleanly into pure white
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00FFFFFF),
                    Color(0x33FFFFFF),
                    Color(0x99FFFFFF),
                    Color(0xFFFFFFFF),
                  ],
                  stops: [0.0, 0.40, 0.75, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroLandscapePainter extends CustomPainter {
  _HeroLandscapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sky Gradient (Alpine Dawn / Scenic Horizon)
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF4A6F9E),
          Color(0xFF7AA0C8),
          Color(0xFFD8C1AF),
          Color(0xFFF8FAFC),
        ],
        stops: [0.0, 0.4, 0.78, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 2. Soft Ambient Sun Glow
    final sunCenter = Offset(w * 0.70, h * 0.28);
    final sunGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF59E0B).withValues(alpha: 0.35),
          const Color(0xFFF59E0B).withValues(alpha: 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: w * 0.42));
    canvas.drawCircle(sunCenter, w * 0.42, sunGlowPaint);

    final sunCorePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(sunCenter, 28, sunCorePaint);

    // 3. Far Mountain Peaks (Layer 1 - Warm Ochre & Alpine Ridges)
    final farMountainPath = Path();
    farMountainPath.moveTo(0, h * 0.52);
    farMountainPath.lineTo(w * 0.16, h * 0.28);
    farMountainPath.lineTo(w * 0.32, h * 0.40);
    farMountainPath.lineTo(w * 0.52, h * 0.20);
    farMountainPath.lineTo(w * 0.74, h * 0.34);
    farMountainPath.lineTo(w * 0.90, h * 0.24);
    farMountainPath.lineTo(w, h * 0.32);
    farMountainPath.lineTo(w, h);
    farMountainPath.lineTo(0, h);
    farMountainPath.close();

    final farMountainPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFC0835E).withValues(alpha: 0.65),
          const Color(0xFF889BB2).withValues(alpha: 0.75),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.18, w, h * 0.82));
    canvas.drawPath(farMountainPath, farMountainPaint);

    // Snow caps on far peaks
    _drawSnowCap(canvas, Offset(w * 0.16, h * 0.28), 34, 46);
    _drawSnowCap(canvas, Offset(w * 0.52, h * 0.20), 44, 62);
    _drawSnowCap(canvas, Offset(w * 0.90, h * 0.24), 30, 42);

    // 4. Mid Mountain Silhouettes (Layer 2 - Deep Slate Blue / Charcoal)
    final midMountainPath = Path();
    midMountainPath.moveTo(0, h * 0.60);
    midMountainPath.lineTo(w * 0.26, h * 0.38);
    midMountainPath.lineTo(w * 0.46, h * 0.50);
    midMountainPath.lineTo(w * 0.68, h * 0.33);
    midMountainPath.lineTo(w * 0.86, h * 0.45);
    midMountainPath.lineTo(w, h * 0.39);
    midMountainPath.lineTo(w, h);
    midMountainPath.lineTo(0, h);
    midMountainPath.close();

    final midMountainPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF334155).withValues(alpha: 0.80),
          const Color(0xFF0F172A).withValues(alpha: 0.90),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.32, w, h * 0.68));
    canvas.drawPath(midMountainPath, midMountainPaint);

    // Snow highlights on mid peaks
    _drawSnowCap(canvas, Offset(w * 0.26, h * 0.38), 28, 40);
    _drawSnowCap(canvas, Offset(w * 0.68, h * 0.33), 36, 50);

    // 5. Contemporary Campus Architecture & Glass Tower
    _drawModernCampusArchitecture(canvas, size);

    // 6. Curving Terracotta Pathway / Roadway
    _drawRoadwayAndPathway(canvas, size);

    // 7. Ambient Sparkles
    _drawAmbientSparkles(canvas, size);
  }

  void _drawSnowCap(Canvas canvas, Offset peak, double width, double height) {
    final snowPath = Path();
    snowPath.moveTo(peak.dx, peak.dy);
    snowPath.lineTo(peak.dx - width * 0.5, peak.dy + height);
    snowPath.quadraticBezierTo(
      peak.dx - width * 0.2,
      peak.dy + height * 0.7,
      peak.dx,
      peak.dy + height * 0.9,
    );
    snowPath.quadraticBezierTo(
      peak.dx + width * 0.2,
      peak.dy + height * 0.65,
      peak.dx + width * 0.5,
      peak.dy + height,
    );
    snowPath.close();

    final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.94);
    canvas.drawPath(snowPath, snowPaint);
  }

  void _drawModernCampusArchitecture(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Modern Academic Glass Tower (Left)
    final towerRect = Rect.fromLTWH(w * 0.08, h * 0.44, w * 0.24, h * 0.38);
    final towerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF2563EB).withValues(alpha: 0.85),
          const Color(0xFF1E3A8A).withValues(alpha: 0.95),
        ],
      ).createShader(towerRect);
    canvas.drawRRect(RRect.fromRectAndRadius(towerRect, const Radius.circular(8)), towerPaint);

    // Glass Window Grids
    final glassPaint = Paint()..color = const Color(0xFF93C5FD).withValues(alpha: 0.40);
    for (double y = h * 0.46; y < h * 0.76; y += 14) {
      for (double x = w * 0.10; x < w * 0.29; x += 16) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 10, 8), const Radius.circular(2)),
          glassPaint,
        );
      }
    }

    // Modern College Dome / Innovation Pavilion (Right)
    final domeCenter = Offset(w * 0.76, h * 0.60);
    final domePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF4F46E5).withValues(alpha: 0.80),
          const Color(0xFF312E81).withValues(alpha: 0.90),
        ],
      ).createShader(Rect.fromCircle(center: domeCenter, radius: w * 0.22));
    canvas.drawCircle(domeCenter, w * 0.18, domePaint);

    // Glass Arch Facade
    final archRect = Rect.fromLTWH(w * 0.64, h * 0.52, w * 0.24, h * 0.24);
    final archPaint = Paint()
      ..color = const Color(0xFFC7D2FE).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(RRect.fromRectAndRadius(archRect, const Radius.circular(18)), archPaint);

    // Campus Central Pillar Beacon
    final pillarRect = Rect.fromLTWH(w * 0.46, h * 0.40, w * 0.08, h * 0.40);
    final pillarPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFFFFF),
          const Color(0xFFCBD5E1),
        ],
      ).createShader(pillarRect);
    canvas.drawRRect(RRect.fromRectAndRadius(pillarRect, const Radius.circular(4)), pillarPaint);

    // Beacon Light
    final beaconPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(w * 0.50, h * 0.40), 6, beaconPaint);
  }

  void _drawRoadwayAndPathway(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Curving Terracotta Pathway / Campus Boulevard
    final roadPath = Path();
    roadPath.moveTo(0, h * 0.74);
    roadPath.cubicTo(
      w * 0.35,
      h * 0.68,
      w * 0.65,
      h * 0.78,
      w,
      h * 0.66,
    );
    roadPath.lineTo(w, h * 0.84);
    roadPath.cubicTo(
      w * 0.65,
      h * 0.94,
      w * 0.35,
      h * 0.82,
      0,
      h * 0.88,
    );
    roadPath.close();

    final roadPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFFD97706).withValues(alpha: 0.70),
          const Color(0xFFC2410C).withValues(alpha: 0.65),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.66, w, h * 0.28));
    canvas.drawPath(roadPath, roadPaint);

    // Subtle Road Center Dash Line
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final dashPath = Path();
    dashPath.moveTo(w * 0.08, h * 0.79);
    dashPath.cubicTo(w * 0.35, h * 0.74, w * 0.65, h * 0.84, w * 0.92, h * 0.73);
    canvas.drawPath(dashPath, dashPaint);
  }

  void _drawAmbientSparkles(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawSparkle(canvas, Offset(w * 0.20, h * 0.12), 4.5);
    _drawSparkle(canvas, Offset(w * 0.44, h * 0.08), 3.5);
    _drawSparkle(canvas, Offset(w * 0.86, h * 0.10), 5.0);
  }

  void _drawSparkle(Canvas canvas, Offset center, double size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.80);
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeroLandscapePainter oldDelegate) => false;
}
