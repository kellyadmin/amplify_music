import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants.dart';
import '../gradient_text.dart';

class HomeSectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool showSeeAll;
  final bool isExpanded;
  final IconData? icon;
  final String? subtitle;
  final double titleSize;
  final FontWeight titleWeight;

  const HomeSectionTitle({
    super.key,
    required this.title,
    this.onTap,
    this.showSeeAll = false,
    this.isExpanded = false,
    this.icon,
    this.subtitle,
    this.titleSize = headingLg,
    this.titleWeight = FontWeight.w800,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: spacingXl, vertical: spacingXs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: titleSize * 1.1,
                margin: const EdgeInsets.only(right: spacingMd),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primaryColor, Color(0xFFE63950)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (icon != null) ...[
                Icon(icon, color: primaryColor, size: titleSize - 2),
                const SizedBox(width: spacingSm),
              ],
              Expanded(
                child: GradientText.magenta(
                  title,
                  style: _homeFont(size: titleSize, weight: titleWeight),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showSeeAll && onTap != null)
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: spacingSm),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isExpanded ? 'Show less' : 'See all',
                    style: _homeFont(
                      size: bodySm,
                      weight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: spacingXs),
            Padding(
              padding: const EdgeInsets.only(left: spacingLg),
              child: Text(
                subtitle!,
                style: _homeFont(
                  size: bodySm,
                  weight: FontWeight.w400,
                  color: subtitleColor.withOpacity(0.85),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class HomeSectionDivider extends StatelessWidget {
  final String title;
  final String? badge;
  final VoidCallback? onSeeAll;
  final bool showSeeAll;

  const HomeSectionDivider({
    super.key,
    required this.title,
    this.badge,
    this.onSeeAll,
    this.showSeeAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: spacingXl, vertical: spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GradientText.magenta(
                      title,
                      style: const TextStyle(
                        fontSize: headingLg,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: spacingSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: spacingSm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.035),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.58),
                            fontSize: captionSm,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showSeeAll && onSeeAll != null)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, value, child) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onSeeAll!();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: spacingLg,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [primaryGradientStart, primaryGradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.45),
                                blurRadius: 16,
                                offset: const Offset(0, 5),
                                spreadRadius: -3,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'See All',
                                style: TextStyle(
                                  color: backgroundColor,
                                  fontSize: bodySm,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: backgroundColor,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

TextStyle _homeFont({
  double size = bodyMd,
  FontWeight weight = FontWeight.w500,
  Color color = textColor,
  double? letterSpacing,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );
}
