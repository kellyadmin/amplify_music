import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const Color backgroundColor = Color(0xFF121212);
  static const Color tileColor = Color(0xFF1E1E1E);
  static const Color goldColor = Color(0xFFFFD700);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true; // Default to dark mode

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsScreen.backgroundColor,
      appBar: AppBar(
        backgroundColor: SettingsScreen.backgroundColor,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'General',
            style: TextStyle(
                color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.person,
            title: 'Account',
            onTap: () {
              // Navigate to account settings
            },
          ),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              // Navigate to notifications settings
            },
          ),

          // Appearance tile with Switch
          Card(
            color: SettingsScreen.tileColor,
            child: ListTile(
              leading: Icon(Icons.palette, color: SettingsScreen.goldColor),
              title: const Text('Appearance', style: TextStyle(color: Colors.white)),
              trailing: Switch(
                value: _isDarkMode,
                activeColor: SettingsScreen.goldColor,
                onChanged: (val) {
                  setState(() {
                    _isDarkMode = val;
                    // Optionally notify app theme change here
                    // e.g. via Provider, Bloc, or setState in parent widget
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Support',
            style: TextStyle(
                color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              _showAboutDialog(context);
            },
          ),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout, color: Colors.black),
            label: const Text('Logout',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: SettingsScreen.goldColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: SettingsScreen.tileColor,
      child: ListTile(
        leading: Icon(icon, color: SettingsScreen.goldColor),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Amplify Music',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.music_note, color: SettingsScreen.goldColor),
      applicationLegalese: '© 2025 Kelly Trendz',
      children: const [
        SizedBox(height: 10),
        Text(
          'Amplify Music is your favorite music streaming app built with ❤️ in Uganda.',
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SettingsScreen.tileColor,
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to logout?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",
                style: TextStyle(color: SettingsScreen.goldColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Add actual logout logic here
            },
            child:
            const Text("Logout", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
