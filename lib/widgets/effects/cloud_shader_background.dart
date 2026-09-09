import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Animated Cloud Shader Background replicating Aceternity UI's cloud-shader.
/// Runs the GLSL billow noise cloud shader on GPU via [ui.FragmentProgram] when available,
/// with a graceful animated atmospheric fallback if shaders are loading or unsupported.
class CloudShaderBackground extends StatefulWidget {
  final Widget? child;
  final double speed;
  final double count;
  final Color cloudColor;
  final Color skyTopColor;
  final Color skyBottomColor;

  const CloudShaderBackground({
    super.key,
    this.child,
    this.speed = 1.0,
    this.count = 6.0,
    this.cloudColor = const Color(0xFFFBF8F2),
    this.skyTopColor = const Color(0xFF3876BA),
    this.skyBottomColor = const Color(0xFF8CBFE8),
  });

  @override
  State<CloudShaderBackground> createState() => _CloudShaderBackgroundState();
}

class _CloudShaderBackgroundState extends State<CloudShaderBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  bool _shaderLoadFailed = false;

  late final Ticker _ticker;
  double _elapsedTime = 0.0;

  @override
  void initState() {
    super.initState();
    _loadShader();

    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() {
          _elapsedTime = (elapsed.inMicroseconds / 1000000.0) * widget.speed;
        });
      }
    });
    _ticker.start();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/cloud.frag');
      if (mounted) {
        setState(() {
          _program = program;
        });
      }
    } catch (e) {
      debugPrint('CloudShader: Fallback to animated atmospheric painter ($e)');
      if (mounted) {
        setState(() {
          _shaderLoadFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget background;

    if (_program != null && !_shaderLoadFailed) {
      background = CustomPaint(
        painter: _CloudFragmentShaderPainter(
          program: _program!,
          time: _elapsedTime,
          count: widget.count,
          cloudColor: widget.cloudColor,
          skyTopColor: widget.skyTopColor,
          skyBottomColor: widget.skyBottomColor,
        ),
        size: Size.infinite,
      );
    } else {
      background = CustomPaint(
        painter: _AtmosphericFallbackPainter(
          time: _elapsedTime,
          cloudColor: widget.cloudColor,
          skyTopColor: widget.skyTopColor,
          skyBottomColor: widget.skyBottomColor,
        ),
        size: Size.infinite,
      );
    }

    if (widget.child == null) {
      return background;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: background),
        widget.child!,
      ],
    );
  }
}

class _CloudFragmentShaderPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final double count;
  final Color cloudColor;
  final Color skyTopColor;
  final Color skyBottomColor;

  _CloudFragmentShaderPainter({
    required this.program,
    required this.time,
    required this.count,
    required this.cloudColor,
    required this.skyTopColor,
    required this.skyBottomColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final shader = program.fragmentShader();

    // 0, 1: u_res (vec2)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // 2: u_time (float)
    shader.setFloat(2, time);

    // 3: u_count (float)
    shader.setFloat(3, count);

    // 4, 5, 6: u_cloud (vec3)
    shader.setFloat(4, cloudColor.r);
    shader.setFloat(5, cloudColor.g);
    shader.setFloat(6, cloudColor.b);

    // 7, 8, 9: u_skyTop (vec3)
    shader.setFloat(7, skyTopColor.r);
    shader.setFloat(8, skyTopColor.g);
    shader.setFloat(9, skyTopColor.b);

    // 10, 11, 12: u_skyBottom (vec3)
    shader.setFloat(10, skyBottomColor.r);
    shader.setFloat(11, skyBottomColor.g);
    shader.setFloat(12, skyBottomColor.b);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _CloudFragmentShaderPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.count != count ||
        oldDelegate.cloudColor != cloudColor ||
        oldDelegate.skyTopColor != skyTopColor ||
        oldDelegate.skyBottomColor != skyBottomColor;
  }
}

/// Graceful atmospheric sky and animated drifting cloud puff fallback
class _AtmosphericFallbackPainter extends CustomPainter {
  final double time;
  final Color cloudColor;
  final Color skyTopColor;
  final Color skyBottomColor;

  _AtmosphericFallbackPainter({
    required this.time,
    required this.cloudColor,
    required this.skyTopColor,
    required this.skyBottomColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Sky gradient
    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height),
        [skyTopColor, skyBottomColor],
      );
    canvas.drawRect(rect, skyPaint);

    // Soft sun glow (top right area)
    final sunCenter = Offset(size.width * 0.78, size.height * 0.15);
    final sunPaint = Paint()
      ..shader = ui.Gradient.radial(
        sunCenter,
        size.width * 0.35,
        [
          const Color(0x66FFF2D1),
          const Color(0x22FFF2D1),
          Colors.transparent,
        ],
      );
    canvas.drawCircle(sunCenter, size.width * 0.35, sunPaint);

    // Multi-layered drifting cloud puffs
    _drawCloudLayer(canvas, size, time * 0.03, 0.25, 0.45, 0.20, cloudColor.withValues(alpha: 0.30));
    _drawCloudLayer(canvas, size, time * 0.05 + 100, 0.45, 0.35, 0.32, cloudColor.withValues(alpha: 0.45));
    _drawCloudLayer(canvas, size, time * 0.08 + 250, 0.70, 0.25, 0.42, cloudColor.withValues(alpha: 0.65));
  }

  void _drawCloudLayer(
    Canvas canvas,
    Size size,
    double progress,
    double yRatio,
    double cloudScale,
    double speed,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);

    final totalWidth = size.width * 1.5;
    final baseX = ((progress * totalWidth) % totalWidth) - (size.width * 0.25);
    final baseY = size.height * yRatio;

    final path = Path();
    // 3 joined puffy circles for each cloud formation
    final r = size.height * 0.12 * cloudScale;
    path.addOval(Rect.fromCircle(center: Offset(baseX, baseY), radius: r * 1.3));
    path.addOval(Rect.fromCircle(center: Offset(baseX + r * 0.9, baseY - r * 0.3), radius: r * 1.0));
    path.addOval(Rect.fromCircle(center: Offset(baseX - r * 0.9, baseY - r * 0.2), radius: r * 1.1));
    path.addOval(Rect.fromCircle(center: Offset(baseX + r * 1.6, baseY + r * 0.2), radius: r * 0.8));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AtmosphericFallbackPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
