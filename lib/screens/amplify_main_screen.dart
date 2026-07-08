import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart' as p; // Use alias for provider

import '../models.dart' as models;
import 'ArtistDashboardScreen.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'artist_dashboard_screen.dart';
import '../utils/auth_dialogs.dart';
import 'admin_upload_screen.dart';
import '../widgets/floating_premium_player.dart';
import '../widgets/floating_chat_button.dart';
import 'music_player_screen.dart';
import 'chat_screen_premium.dart';
import '../services/music_service.dart'; // Import your MusicService
import '../services/music_chat_service.dart';
import 'music_chat_screen.dart';
import '../constants.dart';

class AmplifyMainScreen extends StatefulWidget {
  final List<models.Song>? allSongs;
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
  late final PageController _pageController;
  int _currentIndex = 0;

  late final List<Widget> _screens;

  final supabase = Supabase.instance.client;

  // Floating player position
  Offset _playerPosition = const Offset(10, 100);

  // Removed local currentSong and isPlaying as MusicService will manage these
  // models.Song? currentSong;
  // bool isPlaying = false;

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

    // Removed initial song setup here as MusicService will handle it
    // if ((widget.allSongs?.isNotEmpty ?? false)) {
    //   currentSong = widget.allSongs!.first;
    //   isPlaying = true;
    // }
  }

  void _onTap(int index) async {
    // Check if user needs to login for Profile tab
    if (index == 3 && supabase.auth.currentUser == null) {
      // Show login dialog instead of navigating directly
      final didLogin = await _showLoginDialog();

      if (didLogin && mounted) {
        setState(() => _currentIndex = 3);
        _pageController.jumpToPage(3);
      }
      return;
    }

    if (_currentIndex == index) return;

    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<bool> _showLoginDialog() {
    return AuthDialogs.showLoginRequired(
      context,
      title: 'Sign in to continue',
      message:
          'Access your profile, saved music, and personalized recommendations by signing in.',
      actionLabel: 'Sign In',
    );
  }

  // _onMiniPlayerTap and _onMiniPlayerPlayPause will now delegate to MusicService
  void _onMiniPlayerTap(MusicService musicService) {
    if (musicService.currentSong == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MusicPlayerScreen(), // MusicPlayerScreen now gets data from MusicService
      ),
    );
  }

  void _onMiniPlayerPlayPause(MusicService musicService) {
    musicService.togglePlayPause(); // Delegate to MusicService
  }

  void _navigateToChatWithAnimation(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ChatScreenPremium(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide and fade transition
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var slideTween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(slideTween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToActiveChatRooms(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildActiveChatRoomsSheet(),
    );
  }

  Widget _buildActiveChatRoomsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_rounded,
                  color: primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Active Discussions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Active rooms list
          Expanded(
            child: FutureBuilder<List<ChatRoom>>(
              future: MusicChatService().getActiveRooms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                final rooms = snapshot.data ?? [];

                if (rooms.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No active discussions yet',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start chatting about songs and artists!',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return _buildRoomTile(room);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTile(ChatRoom room) {
    IconData roomIcon;
    switch (room.type) {
      case ChatRoomType.song:
        roomIcon = Icons.music_note;
        break;
      case ChatRoomType.artist:
        roomIcon = Icons.person;
        break;
      default:
        roomIcon = Icons.chat;
    }

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          roomIcon,
          color: primaryColor,
        ),
      ),
      title: Text(
        room.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${room.activeUsers} active users',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: room.activeUsers > 0
              ? primaryColor.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          room.activeUsers.toString(),
          style: TextStyle(
            color: room.activeUsers > 0
                ? primaryColor
                : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusicChatScreen(chatRoom: room),
          ),
        );
      },
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
    final bool isMobilePlatform =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final Color inactiveColor = isDarkMode ? Colors.white54 : Colors.grey[600]!;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 4,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cardColor, backgroundColor],
                ),
                border: Border.all(color: primaryColor.withOpacity(0.28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: primaryColor.withOpacity(0.08),
                    blurRadius: 18,
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  Icon(Icons.graphic_eq_rounded, color: primaryColor, size: 18),
                  Positioned(
                    bottom: 7,
                    child: Icon(Icons.multitrack_audio_rounded, color: Colors.white70, size: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Viba Music',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Premium listening',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.onToggleTheme != null && isMobilePlatform)
            IconButton(
              tooltip: isDarkMode ? 'Light Mode' : 'Dark Mode',
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onToggleTheme,
              color: primaryColor,
            ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            color: Colors.white,
            tooltip: "Notifications",
            onPressed: () {
              // TODO: handle notifications
            },
          ),
          if (widget.isArtist) ...[
            IconButton(
              tooltip: 'Artist Dashboard',
              icon: const Icon(Icons.dashboard_customize),
              color: primaryColor,
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
              color: primaryColor,
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
      body: Stack(
        children: [
          // Main content
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _screens,
            onPageChanged: (index) => setState(() => _currentIndex = index),
          ),

          // Floating Premium Player
          p.Consumer<MusicService>(
            builder: (context, musicService, child) {
              final song = musicService.currentSong;
              if (song == null) return const SizedBox.shrink();

              return StreamBuilder<Duration>(
                stream: musicService.positionStream,
                builder: (context, positionSnapshot) {
                  // Calculate progress
                  double progress = 0.0;
                  if (musicService.duration.inMilliseconds > 0) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    progress = position.inMilliseconds /
                              musicService.duration.inMilliseconds;
                  }

                  return StreamBuilder<bool>(
                    stream: musicService.player.playingStream,
                    initialData: musicService.isPlaying,
                    builder: (context, playingSnapshot) {
                      final isPlaying = playingSnapshot.data ?? false;

                      return FloatingPremiumPlayer(
                        key: ValueKey(song.id),
                        song: song,
                        isPlaying: isPlaying,
                        progress: progress.clamp(0.0, 1.0),
                        onPlayPause: () {
                          musicService.togglePlayPause();
                        },
                        onTap: () => _onMiniPlayerTap(musicService),
                        onNext: () => musicService.playNext(),
                        onPrevious: () => musicService.playPrevious(),
                        onClose: () {
                          musicService.player.stop();
                        },
                        initialPosition: _playerPosition,
                        onPositionChanged: (newPos) {
                          if (mounted) {
                            setState(() => _playerPosition = newPos);
                          }
                        },
                      );
                    },
                  );
                },
              );
            },
          ),

          // Floating Chat Rooms Button (replaces complex chat)
          Positioned(
            right: 16,
            bottom: 84,
            child: StreamBuilder<List<ChatRoom>>(
              stream: MusicChatService().roomsStream,
              builder: (context, snapshot) {
                final activeRooms = snapshot.data ?? [];
                final totalUsers = activeRooms.fold<int>(
                  0, (sum, room) => sum + room.activeUsers
                );

                return FloatingActionButton(
                  onPressed: () => _navigateToActiveChatRooms(context),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.chat_rounded, size: 24),
                      if (totalUsers > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: errorColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                totalUsers > 99 ? '99+' : totalUsers.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cardColor, backgroundColor],
          ),
          border: Border(
            top: BorderSide(color: primaryColor.withOpacity(0.22)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
            BoxShadow(
              color: primaryColor.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: primaryColor,
          unselectedItemColor: inactiveColor,
          currentIndex: _currentIndex,
          onTap: _onTap,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music_rounded),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
