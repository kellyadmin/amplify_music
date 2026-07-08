import 'package:flutter/material.dart';

class AnimatedAmplifyLogo extends StatefulWidget {
  const AnimatedAmplifyLogo({super.key});

  @override
  State<AnimatedAmplifyLogo> createState() => _AnimatedAmplifyLogoState();
}

class _AnimatedAmplifyLogoState extends State<AnimatedAmplifyLogo> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _mainBarAnim;
  late Animation<double> _sideBarsAnim;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _mainBarAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.6, curve: Curves.easeOut)),
    );

    _sideBarsAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.9, curve: Curves.easeOut)),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.8, 1.0, curve: Curves.easeIn)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildBar({required double height, required double delay}) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(delay, delay + 0.3, curve: Curves.easeOutBack),
        ),
      ),
      child: Container(
        width: 10,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Orange Circle with animated bars
        Container(
          width: 180,
          height: 180,
          decoration: const BoxDecoration(
            color: Color(0xFFF2B84B),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildBar(height: 30, delay: 0.4),
                buildBar(height: 50, delay: 0.3),
                buildBar(height: 90, delay: 0.1), // main bar
                buildBar(height: 50, delay: 0.3),
                buildBar(height: 20, delay: 0.4),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FadeTransition(
          opacity: _textOpacity,
              child: Column(
              children: const [
                Text(
                  'Amplify',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF2B84B),
                  ),
                ),
                Text(
                  'MUSIC',
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
        )
      ],
    );
  }
}
