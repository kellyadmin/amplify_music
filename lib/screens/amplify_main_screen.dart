import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import '../models.dart';
import 'artist_dashboard_screen.dart';
import 'admin_upload_screen.dart';

class AmplifyMainScreen extends StatefulWidget {
  final List<Song>? allSongs;
  final VoidCallback? onToggleTheme;
  final bool isArtist;

  const AmplifyMainScreen({
    super.key,
    this.allSongs,
    this.onToggleTheme,
    this.isArtist = false,
  });

  @override
  State<AmplifyMainScreen> createState() => _AmplifyMainScreenState();
}

class _AmplifyMainScreenState extends State<AmplifyMainScreen>
    with TickerProviderStateMixin {
  static const Color _gold = Color(0xFFFFD700);
  static const Color _darkNavBarColor = Color(0xFF1E1E1E);

  late final PageController _pageController;
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      HomeScreen(allSongs: widget.allSongs ?? []),
      const DiscoverScreen(),
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
    final Color inactiveColor =
    isDarkMode ? Colors.white54 : Colors.grey[600]!;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 4,
        centerTitle: false,
        title: Row(
          children: [
            const Icon(Icons.graphic_eq_rounded, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Amplify Music',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.onToggleTheme != null)
            IconButton(
              tooltip: isDarkMode ? 'Light Mode' : 'Dark Mode',
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onToggleTheme,
              color: _gold,
            ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            color: Colors.white,
            tooltip: "Notifications",
            onPressed: () {},
          ),
          if (widget.isArtist) ...[
            IconButton(
              tooltip: 'Artist Dashboard',
              icon: const Icon(Icons.dashboard_customize),
              color: _gold,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ArtistDashboardScreen()),
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
        elevation: 12,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded), label: 'Discover'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_music), label: 'Library'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
