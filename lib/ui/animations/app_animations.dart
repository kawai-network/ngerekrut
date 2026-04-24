import 'package:flutter/material.dart';

/// Reusable animation constants for micro-interactions
class AppAnimations {
  AppAnimations._();

  // Duration constants
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 800);

  // Curve constants
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeInCubic = Curves.easeInCubic;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;

  // Common animation combinations
  static const FadeIn fadeIn = FadeIn(
    curve: AppAnimations.easeOut,
    duration: AppAnimations.normal,
  );

  static const SlideInRight slideInRight = SlideInRight(
    begin: Offset(0.3, 0),
    curve: AppAnimations.easeOutCubic,
    duration: AppAnimations.normal,
  );

  static const ScaleIn scaleIn = ScaleIn(
    curve: AppAnimations.easeOutCubic,
    duration: AppAnimations.fast,
  );

  /// Success checkmark animation duration
  static const Duration successAnimationDuration = Duration(milliseconds: 600);

  /// Heart animation duration for save action
  static const Duration heartAnimationDuration = Duration(milliseconds: 400);
}

/// Fade in animation for widgets
class FadeIn extends StatelessWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.curve = AppAnimations.easeOut,
    this.duration = AppAnimations.normal,
    this.delay = Duration.zero,
    this.onEnd,
  });

  final Widget child;
  final Curve curve;
  final Duration duration;
  final Duration delay;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      curve: curve,
      duration: duration,
      onEnd: onEnd,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Slide in from right animation
class SlideInRight extends StatelessWidget {
  const SlideInRight({
    super.key,
    required this.child,
    this.begin = const Offset(0.3, 0),
    this.curve = AppAnimations.easeOutCubic,
    this.duration = AppAnimations.normal,
    this.onEnd,
  });

  final Widget child;
  final Offset begin;
  final Curve curve;
  final Duration duration;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: Offset.zero),
      curve: curve,
      duration: duration,
      onEnd: onEnd,
      builder: (context, value, child) {
        return FractionalTranslation(
          translation: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Scale in animation
class ScaleIn extends StatelessWidget {
  const ScaleIn({
    super.key,
    required this.child,
    this.curve = AppAnimations.easeOutCubic,
    this.duration = AppAnimations.fast,
    this.onEnd,
  });

  final Widget child;
  final Curve curve;
  final Duration duration;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      curve: curve,
      duration: duration,
      onEnd: onEnd,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Success checkmark animation widget
class SuccessCheckmark extends StatefulWidget {
  const SuccessCheckmark({
    super.key,
    this.size = 48.0,
    this.color = Colors.green,
    this.onComplete,
  });

  final double size;
  final Color color;
  final VoidCallback? onComplete;

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.successAnimationDuration,
      vsync: this,
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) {
          return CustomPaint(
            painter: _CheckmarkPainter(
              progress: _progress.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width / 10;

    // Draw circle
    final circlePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final circleProgress = (progress * 1.5).clamp(0.0, 1.0);
    if (circleProgress > 0) {
      final sweepAngle = 2 * 3.14159 * circleProgress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: size.width / 2 - strokeWidth / 2),
        -3.14159 / 2,
        sweepAngle,
        false,
        circlePaint,
      );
    }

    // Draw checkmark
    if (progress > 0.5) {
      final checkmarkProgress = ((progress - 0.5) * 2).clamp(0.0, 1.0);
      final checkmarkPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      final checkmarkSize = size.width * 0.3;

      // Start point (top of checkmark)
      final startPoint = Offset(
        center.dx - checkmarkSize * 0.4,
        center.dy,
      );

      // Middle point
      final middlePoint = Offset(
        center.dx - checkmarkSize * 0.1,
        center.dy + checkmarkSize * 0.3,
      );

      // End point
      final endPoint = Offset(
        center.dx + checkmarkSize * 0.5,
        center.dy - checkmarkSize * 0.3,
      );

      if (checkmarkProgress < 0.5) {
        // First segment (top to middle)
        final segmentProgress = checkmarkProgress * 2;
        final currentPoint = Offset.lerp(startPoint, middlePoint, segmentProgress)!;
        path.moveTo(startPoint.dx, startPoint.dy);
        path.lineTo(currentPoint.dx, currentPoint.dy);
      } else {
        // Both segments
        path.moveTo(startPoint.dx, startPoint.dy);
        path.lineTo(middlePoint.dx, middlePoint.dy);

        final segmentProgress = (checkmarkProgress - 0.5) * 2;
        final currentPoint = Offset.lerp(middlePoint, endPoint, segmentProgress)!;
        path.lineTo(currentPoint.dx, currentPoint.dy);
      }

      canvas.drawPath(path, checkmarkPaint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Heart animation for save button
class HeartAnimation extends StatefulWidget {
  const HeartAnimation({
    super.key,
    required this.child,
    required this.isAnimating,
    this.onEnd,
  });

  final Widget child;
  final bool isAnimating;
  final VoidCallback? onEnd;

  @override
  State<HeartAnimation> createState() => _HeartAnimationState();
}

class _HeartAnimationState extends State<HeartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.heartAnimationDuration,
      vsync: this,
    );

    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse().then((_) {
          widget.onEnd?.call();
        });
      }
    });
  }

  @override
  void didUpdateWidget(HeartAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}
