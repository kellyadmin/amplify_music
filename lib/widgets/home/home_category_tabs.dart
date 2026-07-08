import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants.dart';

class HomeCategoryTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const HomeCategoryTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.person_outline;
      case 1:
        return Icons.trending_up;
      case 2:
        return Icons.whatshot_outlined;
      case 3:
        return Icons.new_releases_outlined;
      default:
        return Icons.music_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF191919).withOpacity(0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(tabs.length, (index) {
              final selected = selectedIndex == index;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: selected ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTabSelected(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      margin: const EdgeInsets.only(right: 6),
                      transform: Matrix4.identity()
                        ..scale(1.0 + (value * 0.02)),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? LinearGradient(
                                colors: [
                                  primaryColor,
                                  const Color(0xFFB8860B),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.04),
                                  Colors.white.withOpacity(0.02),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          if (selected) ...[
                            BoxShadow(
                              color: primaryColor.withOpacity(0.18),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                              spreadRadius: -6,
                            ),
                          ] else ...[
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.only(right: selected ? 10 : 0),
                            width: selected ? 24 : 0,
                            child: selected
                                ? Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: secondaryColor.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: secondaryColor.withOpacity(0.12),
                                      ),
                                    ),
                                    child: Icon(
                                      _getTabIcon(index),
                                      size: 14,
                                      color: secondaryColor,
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontSize: selected ? 15 : 14,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w600,
                              color: selected ? secondaryColor : textColor,
                              letterSpacing: selected ? 0.2 : 0.3,
                            ),
                            child: Text(tabs[index]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}
