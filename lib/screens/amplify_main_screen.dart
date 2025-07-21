import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import '../models.dart';
import 'artist_dashboard_screen.dart';
import 'admin_upload_screen.dart'; // ✅ import upload screen

class AmplifyMainScreen extends StatefulWidget {
  final List<Song> allSongs;
  final VoidCallback? onToggleTheme;
  final bool isArtist;

  const AmplifyMainScreen({
    super.key,
    required this.allSongs,
    this.onToggleTheme,
    this.isArtist = true,
  });

  @override
  State<AmplifyMainScreen> createState() => _AmplifyMainScreenState();
}

class _AmplifyMainScreenState extends State<AmplifyMainScreen> with TickerProviderStateMixin {
  static const Color _gold = Color(0xFFFFD700);
  static const Color _darkNavBarColor = Color(0xFF1E1E1E);

  late final PageController _pageController;
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      HomeScreen(allSongs: widget.allSongs),
      const DiscoverScreen(), // <-- No artists passed here!
      const LibraryScreen(),
      const ProfileScreen(),
    ];

    _pageController = PageController(initialPage: _currentIndex);
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;

    setState(() => _currentIndex = index);

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color inactiveColor = isDarkMode ? Colors.white54 : Colors.grey[600]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amplify Music'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.onToggleTheme != null)
            IconButton(
              tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onToggleTheme,
              color: isDarkMode ? _gold : Colors.black,
            ),
          if (widget.isArtist) ...[
            IconButton(
              tooltip: 'Artist Dashboard',
              icon: const Icon(Icons.dashboard_customize),
              color: _gold,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ArtistDashboardScreen()),
                );
              },
            ),
            IconButton(
              tooltip: 'Upload Song',
              icon: const Icon(Icons.upload_file),
              color: _gold,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUploadScreen()),
                );
              },
            ),
          ],
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
        onPageChanged: (index) => setState(() => _currentIndex = index),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: _darkNavBarColor,
        selectedItemColor: _gold,
        unselectedItemColor: inactiveColor,
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
