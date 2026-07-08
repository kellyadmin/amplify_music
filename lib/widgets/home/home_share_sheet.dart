import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models.dart';

void showHomeShareSheet(BuildContext context, Song song) {
  String toSlug(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[\s\W_]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  final String slug = toSlug('${song.artist} ${song.title}');
  final String shareUrl = 'https://amplifymusic.site/song/${song.id}/$slug';
  final String shareText = 'Now listening to "${song.title}" by ${song.artist} on Amplify Music. Check it out!\n\n$shareUrl';

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF171514),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            _ShareOption(
              icon: Icons.message,
              iconColor: const Color(0xFF25D366),
              label: 'WhatsApp',
              onTap: () async {
                final whatsappUrl = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(shareText)}');
                if (await canLaunchUrl(whatsappUrl)) {
                  await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
            _ShareOption(
              icon: Icons.facebook_rounded,
              iconColor: const Color(0xFF1877F2),
              label: 'Facebook',
              onTap: () async {
                final facebookUrl = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}');
                if (await canLaunchUrl(facebookUrl)) {
                  await launchUrl(facebookUrl, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
            _ShareOption(
              icon: Icons.copy_all_rounded,
              iconColor: Colors.white,
              label: 'Copy Link',
              onTap: () {
                Clipboard.setData(ClipboardData(text: shareUrl));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: subtitleColor, fontSize: 12)),
        ],
      ),
    );
  }
}
