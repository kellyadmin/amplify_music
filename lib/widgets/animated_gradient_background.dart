import 'package:flutter/material.dart';
import '../constants.dart';

/// Animated gradient mesh background for hero sections
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;
  final double opacity;

  const AnimatedGradientBackground({
    Key? key,
    required this.child,
    this.colors = const [
      Color(0xFF9333EA),
      Color(0xFFFF1493),
      Color(0xFF00D9FF),
      Color(0xFF00E5B8),
    ],
    this.duration = const Duration(seconds: 8),
    this.opacity = 0.15,
  }) : super(key: key);

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated gradient orbs
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              children: [
                // Top-left orb
                Positioned(
                  top: -100 + (_animation.value * 50),
                  left: -100 + (_animation.value * 30),
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.colors[0].withOpacity(widget.opacity),
                          widget.colors[0].withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Top-right orb
                Positioned(
                  top: 50 + (_animation.value * -30),
                  right: -150 + (_animation.value * 40),
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.colors[1].withOpacity(widget.opacity),
                          widget.colors[1].withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom-left orb
                Positioned(
                  bottom: -100 + (_animation.value * -40),
                  left: 50 + (_animation.value * 20),
                  child: Container(
                    width: 450,
                    height: 450,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.colors[2].withOpacity(widget.opacity),
                          widget.colors[2].withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom-right orb
                Positioned(
                  bottom: 100 + (_animation.value * 30),
                  right: -100 + (_animation.value * -20),
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.colors[3].withOpacity(widget.opacity),
                          widget.colors[3].withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        // Content
        widget.child,
      ],
    );
  }
}

/// Pulsing glow container for active elements
class PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final double minOpacity;
  final double maxOpacity;
  final Duration duration;

  const PulsingGlow({
    Key? key,
    required this.child,
    required this.color,
    this.minOpacity = 0.3,
    this.maxOpacity = 0.7,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_animation.value),
                blurRadius: 20,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: widget.color.withOpacity(_animation.value * 0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer effect with multi-color gradient
class MultiColorShimmer extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;

  const MultiColorShimmer({
    Key? key,
    required this.child,
    this.colors = const [
      Color(0xFFFF1493),
      Color(0xFF9333EA),
      Color(0xFF00D9FF),
      Color(0xFF00E5B8),
    ],
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<MultiColorShimmer> createState() => _MultiColorShimmerState();
}

class _MultiColorShimmerState extends State<MultiColorShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
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
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: widget.colors,
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Gradient border container
class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final LinearGradient gradient;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const GradientBorderContainer({
    Key? key,
    required this.child,
    this.gradient = brandGradient,
    this.borderWidth = 2,
    this.borderRadius,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: radius,
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(
            radius.topLeft.x - borderWidth,
          ),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}
