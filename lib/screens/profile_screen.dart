import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'playlists_screen.dart';
import 'liked_songs_screen.dart';
import 'downloads_screen.dart';
import 'recently_played_screen.dart';
import 'settings_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const Color gold = Color(0xFFFFD700);
  static const Color darkBg = Color(0xFF121212);
  static const Color cardBg = Color(0xFF1E1E1E);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  User? user;
  String? username, avatarUrl;
  int followers = 0, following = 0, downloads = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    user = supabase.auth.currentUser;
    if (user != null) {
      final profile = await supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user!.id)
          .maybeSingle();

      final counts = await supabase.rpc('profile_counts', params: {'uid': user!.id});

      setState(() {
        username = profile['username'] as String? ?? user!.email;
        avatarUrl = profile['avatar_url'] as String?;
        followers = counts['followers_count'] as int? ?? 0;
        following = counts['following_count'] as int? ?? 0;
        downloads = counts['downloads_count'] as int? ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = user != null;
    return Scaffold(
      backgroundColor: ProfileScreen.darkBg,
      appBar: AppBar(
        backgroundColor: ProfileScreen.darkBg,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (isLogin)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
        ],
      ),
      body: isLogin ? _buildLogged(context) : _buildGuest(context),
    );
  }

  Widget _buildGuest(BuildContext c) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 100, color: Colors.white24),
          const SizedBox(height: 20),
          const Text('Sign in to explore your music space', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfileScreen.gold,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const AuthScreen())),
            child: const Text('Sign In / Sign Up', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );

  Widget _buildLogged(BuildContext c) => RefreshIndicator(
    onRefresh: _loadUser,
    color: ProfileScreen.gold,
    displacement: 40,
    backgroundColor: ProfileScreen.darkBg,
    child: ListView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: avatarUrl != null
              ? NetworkImage(avatarUrl!)
              : const AssetImage('assets/images/fameica.jpg') as ImageProvider,
        ),
        const SizedBox(height: 12),
        Text(username ?? user!.email!, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(user!.email!, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('Followers', followers),
            _statItem('Following', following),
            _statItem('Downloads', downloads),
          ],
        ),
        const SizedBox(height: 30),
        Text("My Music", style: TextStyle(color: ProfileScreen.gold, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _menuItem(Icons.playlist_play, 'Playlists', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistsScreen()))),
        _menuItem(Icons.favorite, 'Liked Songs', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LikedSongsScreen()))),
        _menuItem(Icons.download_for_offline, 'Downloads', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()))),
        _menuItem(Icons.history, 'Recently Played', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecentlyPlayedScreen()))),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: ProfileScreen.gold,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          icon: const Icon(Icons.logout, color: Colors.black),
          label: const Text('Logout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          onPressed: () => _showLogout(context),
        ),
      ],
    ),
  );

  Widget _statItem(String title, int count) => Column(
    children: [
      Text(count.toString(), style: const TextStyle(color: ProfileScreen.gold, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(title, style: const TextStyle(color: Colors.white70)),
    ],
  );

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) => Card(
    color: ProfileScreen.cardBg,
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: ListTile(
      leading: Icon(icon, color: ProfileScreen.gold),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    ),
  );

  void _showLogout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: ProfileScreen.cardBg,
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Logout from your account?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: ProfileScreen.gold))),
          TextButton(
            onPressed: () async {
              await supabase.auth.signOut();
              Navigator.pushAndRemoveUntil(ctx, MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
