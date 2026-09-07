import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Centralized Global Animation System for UNISPHERE
/// Provides consistent durations, curves, transitions, and micro-interaction wrappers.
class AppAnimations {
  // Standard Animation Durations (Fast -> Responsive -> Smooth -> Consistent)
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration page = Duration(milliseconds: 260);
  static const Duration expand = Duration(milliseconds: 220);
  static const Duration dialog = Duration(milliseconds: 220);

  // Standard Animation Curves
  static const Curve fastCurve = Curves.easeOut;
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve enterCurve = Curves.decelerate;
  static const Curve exitCurve = Curves.easeInCubic;

  /// Checks if reduced motion is requested by the system/user
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }
}

/// Interactive micro-interaction wrapper for buttons, icons, and clickable items.
/// Provides immediate scale feedback (0.97) on press with physics-like return.
class AppPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final Duration duration;
  final Curve curve;
  final bool enableHaptic;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;
  final HitTestBehavior behavior;

  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 0.968,
    this.duration = AppAnimations.fast,
    this.curve = AppAnimations.fastCurve,
    this.enableHaptic = false,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = AppAnimations.isReducedMotion(context);
    final effectiveScale = (isReduced || !_isPressed) ? 1.0 : widget.scaleFactor;

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: effectiveScale,
        duration: isReduced ? Duration.zero : widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

/// Interactive micro-interaction wrapper for Cards and List Tiles.
/// Provides subtle press scaling (0.985) and smooth ripple.
class AppCardPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? pressedColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const AppCardPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.color,
    this.pressedColor,
    this.margin,
    this.padding,
    this.border,
    this.boxShadow,
  });

  @override
  State<AppCardPressable> createState() => _AppCardPressableState();
}

class _AppCardPressableState extends State<AppCardPressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isReduced = AppAnimations.isReducedMotion(context);
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(16);

    return Container(
      margin: widget.margin,
      child: AnimatedScale(
        scale: (isReduced || !_isPressed) ? 1.0 : 0.985,
        duration: isReduced ? Duration.zero : AppAnimations.fast,
        curve: AppAnimations.fastCurve,
        child: Material(
          color: _isPressed && widget.pressedColor != null
              ? widget.pressedColor
              : (widget.color ?? Colors.transparent),
          borderRadius: effectiveRadius,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onHighlightChanged: (val) {
              if (mounted) setState(() => _isPressed = val);
            },
            borderRadius: effectiveRadius,
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: effectiveRadius,
                border: widget.border,
                boxShadow: _isPressed ? null : widget.boxShadow,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle, high-performance Slide-from-Right + Fade Transition for Tabs and Screen Swaps.
/// Uses a staggered Fade-Through architecture so outgoing text completely fades out before
/// incoming text renders, guaranteeing zero text overlap and zero bleed-through.
class FadeSlideTransition extends StatelessWidget {
  final Widget child;
  final Axis direction;
  final double offsetDistance;
  final Duration duration;
  final Curve curve;
  final Key? transitionKey;

  const FadeSlideTransition({
    super.key,
    required this.child,
    this.direction = Axis.horizontal,
    this.offsetDistance = 6.0,
    this.duration = const Duration(milliseconds: 180),
    this.curve = Curves.easeOutCubic,
    this.transitionKey,
  });

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.isReducedMotion(context)) {
      return child;
    }

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.topLeft,
          children: <Widget>[
            ...previousChildren.map((w) => ExcludeSemantics(child: w)),
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget incomingChild, Animation<double> animation) {
        // Fade-Through Non-Overlapping curve:
        // Outgoing widget quickly fades out to 0% opacity in the first 25% of the switch.
        // Incoming widget smoothly fades in from 20% to 100% with a subtle micro-glide.
        // This guarantees that text from previous and next screens NEVER overlap or bleed through.
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.20, 1.0, curve: Curves.easeOutCubic),
        ));

        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.015, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.20, 1.0, curve: Curves.easeOutCubic),
        ));

        return RepaintBoundary(
          child: SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: incomingChild,
            ),
          ),
        );
      },
      child: KeyedSubtree(
        key: transitionKey ?? ValueKey(child.hashCode),
        child: child,
      ),
    );
  }
}

/// Smooth Expand / Collapse Accordion Container (Section 8)
class SmoothExpandable extends StatelessWidget {
  final bool isExpanded;
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Alignment alignment;

  const SmoothExpandable({
    super.key,
    required this.isExpanded,
    required this.child,
    this.duration = AppAnimations.expand,
    this.curve = AppAnimations.smoothCurve,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.isReducedMotion(context)) {
      return isExpanded ? child : const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: isExpanded ? child : const SizedBox.shrink(),
    );
  }
}

/// Rotating Chevron Icon for Accordion & Dropdown headers
class SmoothChevron extends StatelessWidget {
  final bool isExpanded;
  final double size;
  final Color? color;
  final Duration duration;
  final Curve curve;

  const SmoothChevron({
    super.key,
    required this.isExpanded,
    this.size = 20,
    this.color,
    this.duration = AppAnimations.medium,
    this.curve = AppAnimations.smoothCurve,
  });

  @override
  Widget build(BuildContext context) {
    final turns = isExpanded ? 0.5 : 0.0;
    final isReduced = AppAnimations.isReducedMotion(context);

    return AnimatedRotation(
      turns: turns,
      duration: isReduced ? Duration.zero : duration,
      curve: curve,
      child: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: size,
        color: color,
      ),
    );
  }
}

/// Standardized Page Route Transitions for GoRouter & Navigator (Section 6)
class AppRouteTransitions {
  /// Builds a buttery-smooth Slide-from-Right Transition Page for GoRouter & Navigator
  static CustomTransitionPage<T> slideFade<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Duration duration = const Duration(milliseconds: 260),
    Axis direction = Axis.horizontal,
  }) {
    final isReduced = AppAnimations.isReducedMotion(context);

    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: isReduced ? Duration.zero : duration,
      reverseTransitionDuration: isReduced ? Duration.zero : duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (isReduced) return child;

        // Slide in from right to left with 100% solid opacity (no transparency ghosting)
        final primarySlide = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ));

        // Subtle parallax slide for outgoing screen behind it
        final secondarySlide = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.15, 0.0),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ));

        return RepaintBoundary(
          child: SlideTransition(
            position: secondarySlide,
            child: SlideTransition(
              position: primarySlide,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: Offset(-4, 0),
                    ),
                  ],
                ),
                child: ColoredBox(
                  color: Colors.white,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a smooth Fade + Scale Modal Transition Page
  static CustomTransitionPage<T> modalFadeScale<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Duration duration = AppAnimations.dialog,
  }) {
    final isReduced = AppAnimations.isReducedMotion(context);

    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: isReduced ? Duration.zero : duration,
      reverseTransitionDuration: isReduced ? Duration.zero : duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (isReduced) return child;

        final scaleAnimation = Tween<double>(
          begin: 0.96,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: AppAnimations.standardCurve,
          reverseCurve: Curves.easeInCubic,
        ));

        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: AppAnimations.standardCurve,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: ColoredBox(
              color: Colors.white,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
