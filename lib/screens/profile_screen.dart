import 'package:flutter/material.dart';
import 'playlists_screen.dart';
import 'liked_songs_screen.dart';
import 'downloads_screen.dart';
import 'recently_played_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color goldColor = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            // Profile Picture and Info
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage('assets/images/fameica.jpg'),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black87,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit, color: goldColor, size: 16),
                    onPressed: () {
                      // Add edit profile image logic here
                    },
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Kelly Trendz',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Yo favorite vocal artist',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Followers', '2.5K'),
                _buildStatItem('Following', '180'),
                _buildStatItem('Downloads', '1.2K'),
              ],
            ),
            const SizedBox(height: 30),

            // Section Header
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "My Music",
                style: TextStyle(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            // Profile menu items
            _buildProfileMenuItem(Icons.playlist_play, 'Playlists', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistsScreen()));
            }),
            _buildProfileMenuItem(Icons.favorite, 'Liked Songs', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LikedSongsScreen()));
            }),
            _buildProfileMenuItem(Icons.download_for_offline, 'Downloads', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()));
            }),
            _buildProfileMenuItem(Icons.history, 'Recently Played', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RecentlyPlayedScreen()));
            }),

            const SizedBox(height: 30),

            // Logout button
            ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.black),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                _confirmLogout(context);
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: goldColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildProfileMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: goldColor),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to logout?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: goldColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Add actual logout logic here
            },
            child: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
