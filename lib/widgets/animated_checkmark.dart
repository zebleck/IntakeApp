import 'package:flutter/material.dart';

class AnimatedCheckmark extends StatefulWidget {
  final bool isChecked;
  final double size;

  const AnimatedCheckmark({
    super.key,
    required this.isChecked,
    this.size = 16,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.isChecked ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(AnimatedCheckmark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChecked != oldWidget.isChecked) {
      if (widget.isChecked) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.value == 0.0) {
          return SizedBox(width: widget.size, height: widget.size);
        }
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: widget.isChecked ? 1.0 : 0.9),
          duration: const Duration(milliseconds: 200),
          builder: (context, scale, _) {
            return Transform.scale(
              scale: scale,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CheckPainter(progress: _controller.value),
              ),
            );
          },
        );
      },
    );
  }
}

// Flutter's AnimatedBuilder is the same as the old AnimatedBuilder widget
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: animation,
      builder: (context, child) => builder(context, child),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;

  _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.42, size.height * 0.72);
    path.lineTo(size.width * 0.8, size.height * 0.28);

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final extractPath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
