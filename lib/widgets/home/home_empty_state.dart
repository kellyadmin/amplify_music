import 'package:flutter/material.dart';
import '../../constants.dart';

class HomeEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HomeEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(spacingLg),
              decoration: BoxDecoration(
                color: surfaceGlass.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, size: 40, color: subtitleColor.withOpacity(0.6)),
            ),
            const SizedBox(height: spacingMd),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacingXxl),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: homeFont(
                    size: bodyMd,
                    color: subtitleColor.withOpacity(0.7),
                    weight: FontWeight.w500),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: spacingMd),
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
                style: TextButton.styleFrom(foregroundColor: primaryColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HomeSectionError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const HomeSectionError(
      {super.key, this.message = 'Something went wrong', this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(spacingMd),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: const Color(0xFFE63950), size: 32),
            ),
            const SizedBox(height: spacingSm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacingXxl),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: homeFont(size: bodySm, color: subtitleColor),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: spacingSm),
              TextButton(
                onPressed: onRetry,
                child:
                    const Text('Retry', style: TextStyle(color: primaryColor)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
