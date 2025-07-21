import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // for a bit of Boomplay flair
import '../models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = true;

  // Example data—you can replace these with your real playlists
  final List<Map<String, String>> _playlists = [
    {'title': 'Morning Vibes', 'image': 'assets/images/people.jpg'},
    {'title': 'Workout Hits', 'image': 'assets/images/rush.jpg'},
    {'title': 'Chill Evening', 'image': 'assets/images/default_cover.jpg'},
    {'title': 'Party Time', 'image': 'assets/images/people.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = _darkMode ? Theme.of(context) : ThemeData.light();
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: _darkMode ? const Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          backgroundColor: _darkMode ? const Color(0xFF121212) : Colors.white,
          elevation: 0,
          title: Text(
            'Profile',
            style: TextStyle(
              color: _darkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _darkMode ? Icons.dark_mode : Icons.light_mode,
                color: _darkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => setState(() => _darkMode = !_darkMode),
            ),
            IconButton(
              icon: Icon(Icons.settings, color: _darkMode ? Colors.white : Colors.black),
              onPressed: () {
                // settings navigation
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              // Avatar & Name
              CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/images/fameica.jpg'),
              ),
              const SizedBox(height: 12),
              Text(
                'Kelly Trendz',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your favorite vocal artist 🎤',
                style: TextStyle(
                  fontSize: 16,
                  color: _darkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Followers', '2.5K'),
                  _buildStat('Following', '180'),
                  _buildStat('Downloads', '1.2K'),
                ],
              ),
              const SizedBox(height: 30),

              // Action tiles
              _buildActionTile(Icons.playlist_play, 'Playlists', () {}),
              _buildActionTile(Icons.favorite, 'Liked Songs', () {}),
              _buildActionTile(Icons.download_for_offline, 'Downloads', () {}),
              _buildActionTile(Icons.history, 'Recently Played', () {}),
              const SizedBox(height: 30),

              // Your Playlists grid
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Playlists',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _darkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _playlists.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final pl = _playlists[index];
                  return GestureDetector(
                    onTap: () {
                      // open playlist
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(pl['image']!, fit: BoxFit.cover),
                          Container(
                            color: Colors.black38,
                            alignment: Alignment.bottomLeft,
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              pl['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),

              // Logout
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 80, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: const Color(0xFFFFD700),
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

  Widget _buildActionTile(
      IconData icon, String label, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFFD700)),
        title: Text(label,
            style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}
