import 'package:flutter/material.dart';
import '../constants.dart';

/// Vibrant Card with animated gradient border and glow effect
class VibrantCard extends StatefulWidget {
  final Widget child;
  final LinearGradient? gradient;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool enableGlow;
  final bool enableAnimation;
  final BorderRadius? borderRadius;

  const VibrantCard({
    Key? key,
    required this.child,
    this.gradient,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.onTap,
    this.enableGlow = true,
    this.enableAnimation = true,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<VibrantCard> createState() => _VibrantCardState();
}

class _VibrantCardState extends State<VibrantCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.enableAnimation) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final gradient = widget.gradient ?? brandGradient;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap?.call();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: Container(
            width: widget.width,
            height: widget.height,
            margin: widget.margin,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: widget.enableGlow
                  ? [
                      BoxShadow(
                        color: gradient.colors.first
                            .withOpacity(_glowAnimation.value * 0.5),
                        blurRadius: _isPressed ? 12 : 20,
                        spreadRadius: _isPressed ? 1 : 3,
                      ),
                      BoxShadow(
                        color: gradient.colors.last
                            .withOpacity(_glowAnimation.value * 0.3),
                        blurRadius: _isPressed ? 18 : 30,
                        spreadRadius: _isPressed ? 2 : 5,
                      ),
                    ]
                  : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: borderRadius,
              ),
              child: Container(
                padding: widget.padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14.5),
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Vibrant Gradient Button with glow effect
class VibrantButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final double? width;
  final double height;
  final IconData? icon;
  final bool isLoading;

  const VibrantButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.width,
    this.height = 50,
    this.icon,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<VibrantButton> createState() => _VibrantButtonState();
}

class _VibrantButtonState extends State<VibrantButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? brandGradient;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) {
        _controller.forward();
        setState(() => _isPressed = true);
      } : null,
      onTapUp: isEnabled ? (_) {
        _controller.reverse();
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      } : null,
      onTapCancel: isEnabled ? () {
        _controller.reverse();
        setState(() => _isPressed = false);
      } : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: isEnabled ? gradient : null,
                color: !isEnabled ? surfaceElevated : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: gradient.colors.first.withOpacity(0.5),
                          blurRadius: _isPressed ? 8 : 16,
                          spreadRadius: _isPressed ? 1 : 2,
                        ),
                        BoxShadow(
                          color: gradient.colors.last.withOpacity(0.3),
                          blurRadius: _isPressed ? 12 : 24,
                          spreadRadius: _isPressed ? 2 : 4,
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(textColor),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: textColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.text,
                              style: homeFont(
                                size: 16,
                                weight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Glassmorphic Card with vibrant border
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassmorphicCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceGlass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor ?? cardBorderColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
