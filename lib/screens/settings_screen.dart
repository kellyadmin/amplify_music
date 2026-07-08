import 'package:flutter/material.dart';

// Using the same theme colors from ProfileScreen
class AppTheme {
  static const Color darkBg = Color(0xFF0A0A0B);
  static const Color gold = Color(0xFFF2B84B);
  static const Color premiumGold = Color(0xFFB8860B);
  static const Color cardBg = Color(0xFF171514);
  static const Color cardBorder = Color(0xFF2A2A2A);
  static const Color textDisabled = Colors.white54;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dataSaver = false;
  bool _pushNotifications = true;
  String _audioQuality = 'Normal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        title: const Text(
          'Settings & Privacy',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          _buildSettingsSection(
            title: 'Account',
            children: [
              _buildNavigationTile(
                context,
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Change your username, avatar, etc.',
                onTap: () {
                  // This assumes the Edit Profile dialog is in ProfileScreen
                  // and that you're navigating back to it.
                  // If Settings is pushed on top, this just pops.
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                    // You might need a more robust way to trigger this
                    // e.g., pass a callback to ProfileScreen to open the dialog
                  }
                },
              ),
              _buildNavigationTile(
                context,
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your account security',
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                    // Same as above, you need a way to tell ProfileScreen
                    // to open the password dialog.
                  }
                },
              ),
              _buildNavigationTile(
                context,
                icon: Icons.star_border,
                title: 'Manage Subscription',
                subtitle: 'View your plan and billing details',
                onTap: () {
                  // TODO: Navigate to subscription page
                },
              ),
            ],
          ),
          _buildSettingsSection(
            title: 'App',
            children: [
              _buildSwitchTile(
                icon: Icons.data_usage,
                title: 'Data Saver',
                subtitle: 'Reduces data usage by lowering audio quality',
                value: _dataSaver,
                onChanged: (val) {
                  setState(() {
                    _dataSaver = val;
                    if (val) {
                      _audioQuality = 'Low';
                    } else {
                      _audioQuality = 'Normal';
                    }
                  });
                },
              ),
              _buildDropdownTile(
                icon: Icons.music_note_outlined,
                title: 'Audio Quality',
                subtitle: 'Set your streaming and download quality',
                value: _audioQuality,
                items: ['Low', 'Normal', 'High', 'Lossless'],
                onChanged: _dataSaver ? null : (val) {
                  if (val != null) {
                    setState(() {
                      _audioQuality = val;
                    });
                  }
                },
              ),
              _buildSwitchTile(
                icon: Icons.notifications_none,
                title: 'Push Notifications',
                subtitle: 'New releases, playlist updates, and more',
                value: _pushNotifications,
                onChanged: (val) {
                  setState(() {
                    _pushNotifications = val;
                  });
                },
              ),
            ],
          ),
          _buildSettingsSection(
            title: 'Legal',
            children: [
              _buildNavigationTile(
                context,
                icon: Icons.shield_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  // TODO: Open Privacy Policy URL
                },
              ),
              _buildNavigationTile(
                context,
                icon: Icons.article_outlined,
                title: 'Terms of Service',
                onTap: () {
                  // TODO: Open Terms of Service URL
                },
              ),
              _buildNavigationTile(
                context,
                icon: Icons.info_outline,
                title: 'About Amplify',
                subtitle: 'Version 1.0.0',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textDisabled,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder, width: 1),
          ),
          // Use ListView.separated to automatically add dividers
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
            separatorBuilder: (context, index) => const Divider(
              color: AppTheme.cardBorder,
              height: 1,
              indent: 68, // Aligns divider with title
            ),
          ),
        ),
      ],
    );
  }

  /// A reusable tile for navigation
  Widget _buildNavigationTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle,
        required VoidCallback onTap,
      }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.cardBorder.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textDisabled, fontSize: 13),
      )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textDisabled,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  /// A reusable tile for boolean settings
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.cardBorder.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textDisabled, fontSize: 13),
      )
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.premiumGold,
      inactiveTrackColor: AppTheme.cardBorder,
    );
  }

  /// A reusable tile for dropdown settings
  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.cardBorder.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textDisabled, fontSize: 13),
      )
          : null,
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: AppTheme.cardBg,
        style: TextStyle(color: onChanged == null ? AppTheme.textDisabled : AppTheme.textSecondary),
        underline: Container(), // Hides the default underline
        icon: Icon(
          Icons.arrow_drop_down,
          color: onChanged == null ? AppTheme.textDisabled : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
