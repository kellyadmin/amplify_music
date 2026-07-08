import 'package:flutter/material.dart';
import '../../constants.dart';

class HomeLiveActivityBar extends StatelessWidget {
  final String nowPlayingCount;
  final String recentActivity;
  final Animation<double> pulseAnimation;
  final bool isVisible;
  final VoidCallback onDismiss;

  const HomeLiveActivityBar({
    super.key,
    required this.nowPlayingCount,
    required this.recentActivity,
    required this.pulseAnimation,
    required this.isVisible,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: isVisible ? 62 : 0,
      margin: const EdgeInsets.symmetric(
          horizontal: spacingLg, vertical: spacingXs),
      child: isVisible
          ? Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: spacingMd, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.1),
                    primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE63950),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE63950)
                                  .withOpacity(pulseAnimation.value * 0.5),
                              blurRadius: pulseAnimation.value * 4,
                              spreadRadius: pulseAnimation.value * 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE MIX',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFE63950),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$nowPlayingCount listening now',
                          key: ValueKey(nowPlayingCount),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (recentActivity.isNotEmpty)
                          Text(
                            recentActivity,
                            key: ValueKey(recentActivity),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: subtitleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onDismiss,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
