import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
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
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.lerp(
                Alignment.topCenter,
                Alignment.topLeft,
                t,
              )!,
              end: Alignment.lerp(
                Alignment.bottomCenter,
                Alignment.bottomRight,
                t,
              )!,
              colors: [
                Color.lerp(
                  const Color(0xFF0A0E21),
                  const Color(0xFF0C1025),
                  t,
                )!,
                Color.lerp(
                  const Color(0xFF0F1328),
                  const Color(0xFF0D112A),
                  t,
                )!,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

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
