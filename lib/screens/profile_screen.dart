import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'settings_screen.dart';
import 'playlists_screen.dart';
import 'liked_songs_screen.dart';
import 'downloads_screen.dart';
import 'recently_played_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const Color darkBg = Color(0xFF121212);
  static const Color gold = Color(0xFFFFD700);
  static const Color cardBg = Color(0xFF1F1F1F);

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  final supabase = Supabase.instance.client;

  User? user;
  String? avatarUrl;
  String? username;
  String role = 'user';
  bool isVerified = false;
  bool isPremium = false;

  int followers = 0;
  int following = 0;
  int downloads = 0;

  bool _isUploadingImage = false;
  bool _isEditingUsername = false;
  bool _isSavingUsername = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', user!.id)
        .single();

    setState(() {
      avatarUrl = response['avatar_url'];
      username = response['username'];
      role = response['role'] ?? 'user';
      isVerified = response['is_verified'] ?? false;
      isPremium = response['is_premium'] ?? false;
      followers = response['followers'] ?? 0;
      following = response['following'] ?? 0;
      downloads = response['downloads'] ?? 0;
      _usernameController.text = username ?? '';
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final bytes = await pickedFile.readAsBytes();
      final fileName = '${user!.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.png';

      await supabase.storage.from('avatars').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      await supabase.from('profiles').update({
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user!.id);

      setState(() {
        avatarUrl = publicUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully!')),
      );
    } catch (e) {
      debugPrint('Image upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _saveUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty || newUsername == username) {
      setState(() => _isEditingUsername = false);
      return;
    }

    setState(() {
      _isSavingUsername = true;
    });

    try {
      final response = await supabase.from('profiles').update({
        'username': newUsername,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user!.id);

      setState(() {
        username = newUsername;
        _isEditingUsername = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully!')),
      );
    } catch (e) {
      debugPrint('Error saving username: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving username: $e')),
      );
    } finally {
      setState(() {
        _isSavingUsername = false;
      });
    }
  }

  Widget _buildRoleBadge() {
    Color bgColor;
    IconData iconData;
    String label;

    switch (role.toLowerCase()) {
      case 'artist':
        bgColor = Colors.purple;
        iconData = Icons.music_note;
        label = 'Artist';
        break;
      case 'user':
        bgColor = Colors.blue;
        iconData = Icons.person;
        label = 'User';
        break;
      default:
        bgColor = Colors.grey;
        iconData = Icons.person_outline;
        label = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPremiumBadge() {
    if (!isPremium) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade700,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Premium',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = supabase.auth.currentUser != null;

    return Scaffold(
      backgroundColor: ProfileScreen.darkBg,
      appBar: AppBar(
        backgroundColor: ProfileScreen.darkBg,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
        ],
      ),
      body: isLoggedIn ? _buildProfileBody() : _buildGuestUI(context),
    );
  }

  Widget _buildGuestUI(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color: Colors.white24),
            const SizedBox(height: 20),
            const Text(
              'Sign in to explore your music space',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ProfileScreen.gold,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
              },
              child: const Text(
                'Sign In / Sign Up',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBody() {
    return RefreshIndicator(
      onRefresh: _loadUser,
      color: ProfileScreen.gold,
      backgroundColor: ProfileScreen.darkBg,
      displacement: 40,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl!)
                      : const AssetImage('assets/images/fameica.jpg') as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: _isUploadingImage ? null : _pickImage,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: ProfileScreen.gold,
                      child: _isUploadingImage
                          ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                          : const Icon(Icons.camera_alt, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isEditingUsername
                  ? SizedBox(
                width: 180,
                child: TextField(
                  controller: _usernameController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: ProfileScreen.gold, width: 2),
                    ),
                    fillColor: ProfileScreen.cardBg,
                    filled: true,
                  ),
                  enabled: !_isSavingUsername,
                  onSubmitted: (_) => _saveUsername(),
                ),
              )
                  : Text(
                username ?? 'No Username',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (!_isEditingUsername)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                  onPressed: () {
                    setState(() {
                      _isEditingUsername = true;
                    });
                  },
                ),
              if (_isEditingUsername)
                Row(
                  children: [
                    TextButton(
                      onPressed: _isSavingUsername ? null : () => setState(() => _isEditingUsername = false),
                      child: const Text('Cancel', style: TextStyle(color: ProfileScreen.gold)),
                    ),
                    TextButton(
                      onPressed: _isSavingUsername ? null : _saveUsername,
                      child: _isSavingUsername
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text(
                        'Save',
                        style: TextStyle(color: ProfileScreen.gold, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              if (isVerified) const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
              _buildRoleBadge(),
              _buildPremiumBadge(),
            ],
          ),
          const SizedBox(height: 6),
          Center(child: Text(user?.email ?? '', style: const TextStyle(color: Colors.white70))),
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
          _menuSectionTitle("My Music"),
          _menuItem(Icons.playlist_play, 'Playlists', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistsScreen()))),
          _menuItem(Icons.favorite, 'Liked Songs', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LikedSongsScreen()))),
          _menuItem(Icons.download_for_offline, 'Downloads', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()))),
          _menuItem(Icons.history, 'Recently Played', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecentlyPlayedScreen()))),
          const SizedBox(height: 30),
          _menuSectionTitle("Account"),
          _menuItem(Icons.edit, 'Edit Profile', () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            if (result == true) _loadUser();
          }),
          _menuItem(Icons.lock, 'Change Password', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfileScreen.gold,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            icon: const Icon(Icons.logout, color: Colors.black),
            label: const Text('Logout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String title, int count) => Column(
    children: [
      Text('$count', style: const TextStyle(color: ProfileScreen.gold, fontSize: 20, fontWeight: FontWeight.bold)),
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

  Widget _menuSectionTitle(String title) => Text(
    title,
    style: const TextStyle(color: ProfileScreen.gold, fontSize: 16, fontWeight: FontWeight.bold),
  );

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ProfileScreen.cardBg,
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: ProfileScreen.gold)),
          ),
          TextButton(
            onPressed: () async {
              await supabase.auth.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (_) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
