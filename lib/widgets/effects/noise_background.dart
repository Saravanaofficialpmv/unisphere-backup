import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Flutter implementation of Aceternity UI's [NoiseBackground].
///
/// Features:
/// 1. Floating spring-physics radial gradient blobs moving in 360-degree organic drift.
/// 2. Luminous top gradient strip that smoothly shifts with position.
/// 3. Tactile photographic noise overlay using [BlendMode.overlay].
/// 4. Can be used either as a card bezel/frame (with [borderWidth] and [innerRadius]),
///    or as a full outer page/screen container ([borderWidth] = 0).
class NoiseBackground extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final double innerRadius;
  final double outerRadius;
  final List<Color> gradientColors;
  final double noiseIntensity;
  final double speed;
  final bool backdropBlur;
  final bool animating;
  final Color baseColor;

  const NoiseBackground({
    super.key,
    required this.child,
    this.borderWidth = 14.0,
    this.innerRadius = 24.0,
    this.outerRadius = 38.0,
    this.gradientColors = const [
      Color(0xFFFF6496), // rgb(255, 100, 150)
      Color(0xFF6496FF), // rgb(100, 150, 255)
      Color(0xFFFFC864), // rgb(255, 200, 100)
    ],
    this.noiseIntensity = 0.22,
    this.speed = 0.12,
    this.backdropBlur = false,
    this.animating = true,
    this.baseColor = const Color(0xFF0F172A), // Luxury dark slate
  });

  @override
  State<NoiseBackground> createState() => _NoiseBackgroundState();
}

class _NoiseBackgroundState extends State<NoiseBackground>
    with SingleTickerProviderStateMixin {
  static ui.Image? _cachedNoiseImage;
  static bool _isGeneratingNoise = false;

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Position and spring physics
  double _targetX = 200;
  double _targetY = 200;
  double _springX = 200;
  double _springY = 200;
  double _springVx = 0;
  double _springVy = 0;

  // Velocity for random drift
  double _vx = 0;
  double _vy = 0;
  double _timeSinceLastDirectionChange = 0;
  double _nextDirectionChangeInterval = 2.0;

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _ensureNoiseImage();
    _initRandomVelocity();

    _ticker = createTicker(_handleTick);
    if (widget.animating) {
      _ticker.start();
    }
  }

  void _initRandomVelocity() {
    final angle = _random.nextDouble() * math.pi * 2;
    final magnitude = widget.speed * (50.0 + _random.nextDouble() * 50.0);
    _vx = math.cos(angle) * magnitude;
    _vy = math.sin(angle) * magnitude;
    _nextDirectionChangeInterval = 1.5 + _random.nextDouble() * 1.5;
  }

  void _ensureNoiseImage() {
    if (_cachedNoiseImage != null || _isGeneratingNoise) return;
    _isGeneratingNoise = true;

    const size = 128;
    final rng = math.Random(1337);
    final pixels = Uint8List(size * size * 4);

    for (int i = 0; i < pixels.length; i += 4) {
      // Monochromatic zero-mean noise around 128 for perfect BlendMode.overlay
      final n = (rng.nextDouble() * 2.0 - 1.0);
      final val = (128 + n * 70).toInt().clamp(0, 255);
      pixels[i] = val;
      pixels[i + 1] = val;
      pixels[i + 2] = val;
      pixels[i + 3] = 255;
    }

    ui.decodeImageFromPixels(
      pixels,
      size,
      size,
      ui.PixelFormat.rgba8888,
      (image) {
        _cachedNoiseImage = image;
        _isGeneratingNoise = false;
        if (mounted) setState(() {});
      },
    );
  }

  void _handleTick(Duration elapsed) {
    if (!mounted || !widget.animating) return;

    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (dt <= 0 || dt > 0.1) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.hasSize == true ? renderBox!.size : const Size(500, 500);

    final maxX = size.width;
    final maxY = size.height;

    // Change direction periodically
    _timeSinceLastDirectionChange += dt;
    if (_timeSinceLastDirectionChange > _nextDirectionChangeInterval) {
      _initRandomVelocity();
      _timeSinceLastDirectionChange = 0;
    }

    // Move target position
    _targetX += _vx * dt;
    _targetY += _vy * dt;

    // Bounce off edges smoothly
    const padding = 20.0;
    if (_targetX < padding || _targetX > maxX - padding) {
      _vx = -_vx;
      _targetX = _targetX.clamp(padding, maxX - padding);
      _timeSinceLastDirectionChange = 0;
    }
    if (_targetY < padding || _targetY > maxY - padding) {
      _vy = -_vy;
      _targetY = _targetY.clamp(padding, maxY - padding);
      _timeSinceLastDirectionChange = 0;
    }

    // Spring physics: stiffness = 100, damping = 30
    const stiffness = 100.0;
    const damping = 30.0;
    final fx = -stiffness * (_springX - _targetX) - damping * _springVx;
    final fy = -stiffness * (_springY - _targetY) - damping * _springVy;

    _springVx += fx * dt;
    _springVy += fy * dt;
    _springX += _springVx * dt;
    _springY += _springVy * dt;

    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outerR = widget.borderWidth > 0
        ? (widget.innerRadius + widget.borderWidth)
        : widget.outerRadius;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(outerR),
        boxShadow: widget.borderWidth > 0
            ? [
                // Deep ambient shadow onto background
                BoxShadow(
                  color: const Color(0xFF020617).withValues(alpha: 0.45),
                  blurRadius: 36,
                  spreadRadius: 2,
                  offset: const Offset(0, 16),
                ),
                // Soft colored highlight aura from first gradient color
                BoxShadow(
                  color: widget.gradientColors.first.withValues(alpha: 0.16),
                  blurRadius: 24,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _NoiseBackgroundPainter(
          springX: _springX,
          springY: _springY,
          gradientColors: widget.gradientColors,
          noiseImage: _cachedNoiseImage,
          noiseIntensity: widget.noiseIntensity,
          borderWidth: widget.borderWidth,
          innerRadius: widget.innerRadius,
          outerRadius: outerR,
          baseColor: widget.baseColor,
        ),
        child: Padding(
          padding: EdgeInsets.all(widget.borderWidth),
          child: widget.child,
        ),
      ),
    );
  }
}

class _NoiseBackgroundPainter extends CustomPainter {
  final double springX;
  final double springY;
  final List<Color> gradientColors;
  final ui.Image? noiseImage;
  final double noiseIntensity;
  final double borderWidth;
  final double innerRadius;
  final double outerRadius;
  final Color baseColor;

  _NoiseBackgroundPainter({
    required this.springX,
    required this.springY,
    required this.gradientColors,
    required this.noiseImage,
    required this.noiseIntensity,
    required this.borderWidth,
    required this.innerRadius,
    required this.outerRadius,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final outerRRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(outerRadius),
    );

    canvas.save();
    canvas.clipRRect(outerRRect);

    // 1. Base dark background matching Aceternity dark:bg-neutral-900 / slate-950
    final basePaint = Paint()..color = baseColor;
    canvas.drawRRect(outerRRect, basePaint);

    // 2. Dynamic Radial Gradient Layer 1 (multiplier 1.0, opacity 0.40)
    final color1 = gradientColors.isNotEmpty
        ? gradientColors[0]
        : const Color(0xFFFF6496);
    final radius1 = math.max(size.width, size.height) * 0.55;
    final paint1 = Paint()
      ..shader = ui.Gradient.radial(
        Offset(springX * 1.0, springY * 1.0),
        radius1,
        [
          color1.withValues(alpha: 0.45),
          color1.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        [0.0, 0.35, 1.0],
      );
    canvas.drawRRect(outerRRect, paint1);

    // 3. Dynamic Radial Gradient Layer 2 (multiplier 0.7, opacity 0.30)
    final color2 = gradientColors.length > 1
        ? gradientColors[1]
        : const Color(0xFF6496FF);
    final radius2 = math.max(size.width, size.height) * 0.48;
    final paint2 = Paint()
      ..shader = ui.Gradient.radial(
        Offset(springX * 0.7, springY * 0.7),
        radius2,
        [
          color2.withValues(alpha: 0.38),
          color2.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        [0.0, 0.40, 1.0],
      );
    canvas.drawRRect(outerRRect, paint2);

    // 4. Dynamic Radial Gradient Layer 3 (multiplier 1.2, opacity 0.25)
    final color3 = gradientColors.length > 2
        ? gradientColors[2]
        : color1;
    final radius3 = math.max(size.width, size.height) * 0.42;
    final paint3 = Paint()
      ..shader = ui.Gradient.radial(
        Offset(springX * 1.2, springY * 1.2),
        radius3,
        [
          color3.withValues(alpha: 0.32),
          color3.withValues(alpha: 0.10),
          Colors.transparent,
        ],
        [0.0, 0.45, 1.0],
      );
    canvas.drawRRect(outerRRect, paint3);

    // 5. Top luminous gradient strip (Aceternity top gradient line)
    final topShift = (springX * 0.15 - 40).clamp(-size.width * 0.2, size.width * 0.2);
    final topStripPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(topShift, 0),
        Offset(size.width + topShift, 0),
        [
          color1.withValues(alpha: 0.85),
          color2.withValues(alpha: 0.85),
          color3.withValues(alpha: 0.85),
        ],
      );
    final topStripRect = Rect.fromLTWH(0, 0, size.width, 3.5);
    canvas.drawRect(topStripRect, topStripPaint);

    // Soft glow blur for the top strip
    final glowPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(topShift, 0),
        Offset(size.width + topShift, 0),
        [
          color1.withValues(alpha: 0.4),
          color2.withValues(alpha: 0.4),
          color3.withValues(alpha: 0.4),
        ],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 6.0), glowPaint);

    // 6. Monochromatic Photographic Noise Overlay via BlendMode.overlay
    if (noiseImage != null) {
      final noisePaint = Paint()
        ..shader = ImageShader(
          noiseImage!,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.identity().storage,
        )
        ..blendMode = BlendMode.overlay
        ..color = Colors.white.withValues(alpha: noiseIntensity);
      canvas.drawRRect(outerRRect, noisePaint);
    }

    // 7. Bevels and borders
    if (borderWidth > 0) {
      // Inner crisp border where content container sits
      final innerRect = Rect.fromLTWH(
        borderWidth,
        borderWidth,
        size.width - borderWidth * 2,
        size.height - borderWidth * 2,
      );
      final innerRRect = RRect.fromRectAndRadius(
        innerRect,
        Radius.circular(innerRadius),
      );
      final innerBorderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.black.withValues(alpha: 0.35);
      canvas.drawRRect(innerRRect, innerBorderPaint);
    }

    // Outer refined border with subtle highlight
    final outerBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height),
        [
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.08),
          Colors.black.withValues(alpha: 0.40),
        ],
        [0.0, 0.4, 1.0],
      );
    canvas.drawRRect(outerRRect, outerBorderPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NoiseBackgroundPainter oldDelegate) {
    return oldDelegate.springX != springX ||
        oldDelegate.springY != springY ||
        oldDelegate.noiseImage != noiseImage ||
        oldDelegate.noiseIntensity != noiseIntensity ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.innerRadius != innerRadius ||
        oldDelegate.outerRadius != outerRadius ||
        oldDelegate.baseColor != baseColor;
  }
}
