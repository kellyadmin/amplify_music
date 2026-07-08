import 'package:flutter/material.dart';
import '../constants.dart';

/// Renders [text] with a brand gradient fill (light gold -> deep bronze by
/// default). Use this for hero headings / section titles to give the app a
/// polished, premium look instead of flat single-color text.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [primaryColor, primaryGradientEnd],
    ),
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  /// Gold -> ruby variant, handy for section titles / badges.
  const GradientText.magenta(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : gradient = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [primaryColor, accentColor],
        );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      ),
    );
  }
}

/// A soft, blurred glow orb used to add atmospheric depth to dark
/// backgrounds. Purely decorative - wrap screens' Stack with a couple
/// of these (top-right / bottom-left) behind scrollable content.
class GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const GlowOrb({
    super.key,
    this.size = 260,
    this.color = primaryColor,
    this.opacity = 0.22,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ambient dual-glow backdrop for screens: a purple glow top-right and a
/// magenta/cyan glow bottom-left, sitting behind [child] on the app's
/// dark background. Keeps screens feeling vibrant without hurting
/// legibility (glows are low-opacity and ignore pointer events).
class AmbientBackground extends StatelessWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: backgroundColor),
        Positioned(
          top: -80,
          right: -60,
          child: GlowOrb(size: 300, color: primaryColor, opacity: 0.20),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: GlowOrb(size: 320, color: accentColor, opacity: 0.14),
        ),
        child,
      ],
    );
  }
}
