import 'package:flutter/material.dart';
import '../../constants.dart';

class HomeHeader extends StatelessWidget {
  final String username;
  final String greeting;
  final String onlineUsersText;
  final Animation<double> shimmerAnimation;
  final Animation<double> liveActivityAnimation;
  final Animation<double> pulseAnimation;
  final VoidCallback onPremiumTap;
  final bool isLoggedIn;

  const HomeHeader({
    super.key,
    required this.username,
    required this.greeting,
    required this.onlineUsersText,
    required this.shimmerAnimation,
    required this.liveActivityAnimation,
    required this.pulseAnimation,
    required this.onPremiumTap,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(spacingXl, spacingLg, spacingXl, spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: shimmerAnimation,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment(-1.0 + shimmerAnimation.value, 0.0),
                          end: Alignment(-0.5 + shimmerAnimation.value, 0.0),
                          colors: [
                            Colors.white.withOpacity(0.8),
                            primaryColor,
                            Colors.white.withOpacity(0.8),
                          ],
                        ).createShader(bounds);
                      },
                      child: Text(
                        greeting,
                        style: TextStyle(
                          fontSize: bodySm,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: spacingXs),
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: headingXl,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: spacingXs),
                AnimatedBuilder(
                  animation: liveActivityAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, liveActivityAnimation.value * 2),
                      child: Text(
                        onlineUsersText,
                        style: TextStyle(
                          fontSize: bodySm,
                          fontWeight: FontWeight.w400,
                          color: subtitleColor.withOpacity(0.85),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: spacingMd),
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.98 + (pulseAnimation.value * 0.03),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: onPremiumTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1D1B17),
                            const Color(0xFF0A0A0B),
                            primaryColor.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        border:
                            Border.all(color: primaryColor.withOpacity(0.45)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: primaryColor.withOpacity(0.10),
                            blurRadius: 20,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor.withOpacity(0.14),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.22),
                              ),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: primaryColor,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Premium',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: primaryColor,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Text(
                                isLoggedIn ? 'Ad-free' : 'Sign in',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: subtitleColor.withOpacity(0.78),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
