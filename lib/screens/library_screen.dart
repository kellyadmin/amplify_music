import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/gradient_text.dart';
// import 'package:on_audio_query/on_audio_query.dart'; // DISABLED - removed dependency
import 'package:permission_handler/permission_handler.dart';
import '../utils/audio_query_stub.dart';
import 'package:provider/provider.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models.dart';
import 'music_player_screen.dart';
import '../services/music_service.dart';
import '../services/recent_service.dart';
import '../services/download_notifier_service.dart';
import '../utils/auth_dialogs.dart';

import '../constants.dart';
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryBenefitRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LibraryBenefitRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF2B84B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFF2B84B),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<dynamic> localSongs = [];
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Constants for a cleaner, more maintainable design
  static const Color primaryColor = Color(0xFFF2B84B); // Viba gold
  static const Color secondaryColor = Color(0xFF0A0A0B); // Dark background
  static const Color cardColor = Color(0xFF211C16); // Darker card background
  static const Color textColor = Colors.white;
  static const Color subtitleColor = Colors.white70;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
    requestPermissionAndLoadSongs();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> requestPermissionAndLoadSongs() async {
    // Request both audio and storage permissions for broader compatibility
    final audioStatus = await Permission.audio.request();
    final storageStatus = await Permission.storage.request();
    if (audioStatus.isGranted || storageStatus.isGranted) {
      try {
        final songs = await _audioQuery.querySongs(
          sortType: SongSortType.TITLE,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );
        setState(() {
          localSongs = songs;
        });
      } catch (e) {
        debugPrint('Error querying local songs: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load local songs: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied to access local audio files.')),
        );
      }
    }
  }

  // Filter songs based on search query
  List<Song> _filterSongs(List<Song> songs) {
    if (_searchQuery.isEmpty) return songs;
    return songs.where((song) {
      return song.title.toLowerCase().contains(_searchQuery) ||
          song.artist.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  // Filter local songs based on search query
  List<dynamic> _filterLocalSongs() {
    if (_searchQuery.isEmpty) return localSongs;
    return localSongs.where((song) {
      try {
        return (song.title?.toLowerCase().contains(_searchQuery) ?? false) ||
            (song.artist?.toLowerCase().contains(_searchQuery) ?? false);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  // Build login required message
  Widget _buildLoginRequiredMessage(String message) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: primaryColor.withOpacity(0.16)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF171514),
                cardColor.withOpacity(0.92),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: primaryColor.withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.1),
                  border: Border.all(color: primaryColor.withOpacity(0.18)),
                ),
                child: const Icon(
                  Icons.library_music_rounded,
                  color: primaryColor,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: primaryColor.withOpacity(0.16)),
                ),
                child: const Text(
                  'Personal library sync',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Sign in to keep your likes, downloads, and listening activity synced across devices with a more personalized library experience.',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: const Column(
                  children: [
                    _LibraryBenefitRow(
                      icon: Icons.favorite_rounded,
                      label: 'Keep your liked songs in sync',
                    ),
                    SizedBox(height: 12),
                    _LibraryBenefitRow(
                      icon: Icons.download_rounded,
                      label: 'Access downloads and saved activity faster',
                    ),
                    SizedBox(height: 12),
                    _LibraryBenefitRow(
                      icon: Icons.history_rounded,
                      label: 'Resume recent listening from where you left off',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final didLogin = await AuthDialogs.showLoginRequired(
                      context,
                      title: 'Unlock your library',
                      message:
                          'Sign in to sync your downloaded tracks, liked songs, and recent listening across your devices.',
                      actionLabel: 'Sign In',
                    );
                    if (didLogin && mounted) {
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: secondaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Unlock Library',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build empty state message
  Widget _buildEmptyStateMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              color: subtitleColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: subtitleColor,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Builders ---
  Widget _buildSongCard(List<Song> playlist, int index) {
    // Use the Provider's state to determine the current song and liked status
    final musicService = p.Provider.of<MusicService>(context);
    final song = playlist[index];
    final bool isCurrentPlaying = musicService.currentSong?.id == song.id && musicService.isPlaying;

    return Card(
      color: isCurrentPlaying ? cardColor.withOpacity(0.8) : cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          musicService.playSong(song, playlist, initialIndex: index);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MusicPlayerScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: song.albumArtUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 70,
                    height: 70,
                    color: secondaryColor,
                    child: const Icon(Icons.music_note, color: subtitleColor, size: 30),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 70,
                    height: 70,
                    color: secondaryColor,
                    child: const Icon(Icons.broken_image, color: const Color(0xFFE63950), size: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        color: isCurrentPlaying ? primaryColor : textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: const TextStyle(color: subtitleColor, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  musicService.isSongLikedLocally(song.id) ? Icons.favorite : Icons.favorite_border,
                  color: musicService.isSongLikedLocally(song.id) ? const Color(0xFFE63950) : subtitleColor,
                ),
                onPressed: () {
                  musicService.toggleLike(song);
                },
              ),
              IconButton(
                icon: Icon(
                  isCurrentPlaying && musicService.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: primaryColor,
                  size: 36,
                ),
                onPressed: () {
                  if (isCurrentPlaying) {
                    musicService.togglePlayPause();
                  } else {
                    musicService.playSong(song, playlist, initialIndex: index);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalCard(dynamic song) {
    final musicService = p.Provider.of<MusicService>(context);
    // Convert SongModel to your app's Song model for consistency
    final appSong = Song(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist ?? "Unknown Artist",
      audioUrl: song.uri ?? '',
      albumArtUrl: '', // Local songs might not have direct album art URLs
      durationSeconds: (song.duration ?? 0) ~/ 1000,
      playCount: 0,
      likes: 0,
      downloads: 0,
      likedByUser: false,
    );
    final bool isCurrentPlaying = musicService.currentSong?.id == appSong.id;

    return Card(
      color: isCurrentPlaying ? cardColor.withOpacity(0.8) : cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          musicService.playSong(appSong, [appSong], initialIndex: 0);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MusicPlayerScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkBorder: BorderRadius.circular(12),
                  nullArtworkWidget: Container(
                    width: 70,
                    height: 70,
                    color: secondaryColor,
                    child: const Icon(Icons.music_note, size: 30, color: subtitleColor),
                  ),
                  size: 200,
                  quality: 100,
                  artworkFit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        color: isCurrentPlaying ? primaryColor : textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist ?? "Unknown Artist",
                      style: const TextStyle(color: subtitleColor, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isCurrentPlaying && musicService.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: primaryColor,
                  size: 36,
                ),
                onPressed: () {
                  if (isCurrentPlaying) {
                    musicService.togglePlayPause();
                  } else {
                    musicService.playSong(appSong, [appSong], initialIndex: 0);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final isLoggedIn = supabase.auth.currentUser != null;

    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        elevation: 0,
        title: const Text(
          'Library',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: subtitleColor,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: "Downloaded"),
            Tab(text: "Liked"),
            Tab(text: "Recent"),
            Tab(text: "Local"),
          ],
        ),
      ),
      body: Stack(
        children: [
          const Positioned(top: -90, right: -70, child: GlowOrb(size: 300, color: primaryColor, opacity: 0.16)),
          const Positioned(bottom: -120, left: -90, child: GlowOrb(size: 320, color: accentColor, opacity: 0.12)),
          Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: textColor),
              decoration: InputDecoration(
                filled: true,
                fillColor: cardColor,
                prefixIcon: const Icon(Icons.search, color: primaryColor),
                hintText: 'Search your library',
                hintStyle: const TextStyle(color: subtitleColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Downloaded Songs Tab
                p.Consumer<DownloadNotifierService>(
                  builder: (context, downloadService, child) {
                    if (!isLoggedIn) {
                      return _buildLoginRequiredMessage('Log in to see your downloaded songs');
                    }

                    // Sort songs by most recent (newest first)
                    final sortedSongs = List<Song>.from(downloadService.downloadedSongs)
                      ..sort((a, b) => b.createdAt?.compareTo(a.createdAt ?? DateTime.now()) ?? 0);

                    final filteredSongs = _filterSongs(sortedSongs);

                    if (filteredSongs.isEmpty) {
                      return _buildEmptyStateMessage('You have not yet downloaded any songs');
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredSongs.length,
                      itemBuilder: (context, index) => _buildSongCard(filteredSongs, index),
                    );
                  },
                ),

                // Liked Songs Tab
                p.Consumer<MusicService>(
                  builder: (context, musicService, child) {
                    if (!isLoggedIn) {
                      return _buildLoginRequiredMessage('Log in to see your liked songs');
                    }

                    // Sort songs by most recent (newest first)
                    final sortedSongs = List<Song>.from(musicService.likedSongs)
                      ..sort((a, b) => b.createdAt?.compareTo(a.createdAt ?? DateTime.now()) ?? 0);

                    final filteredSongs = _filterSongs(sortedSongs);

                    if (filteredSongs.isEmpty) {
                      return _buildEmptyStateMessage('You have not yet liked any songs');
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredSongs.length,
                      itemBuilder: (context, index) => _buildSongCard(filteredSongs, index),
                    );
                  },
                ),

                // Recent Songs Tab
                p.Consumer<RecentService>(
                  builder: (context, recentService, child) {
                    if (!isLoggedIn) {
                      return _buildLoginRequiredMessage('Log in to see your recent songs');
                    }

                    // Recent songs are already sorted by most recent first
                    final filteredSongs = _filterSongs(recentService.recentSongs);

                    if (filteredSongs.isEmpty) {
                      return _buildEmptyStateMessage('You have not yet played any songs');
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredSongs.length,
                      itemBuilder: (context, index) => _buildSongCard(filteredSongs, index),
                    );
                  },
                ),

                // Local Songs Tab
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _filterLocalSongs().length,
                  itemBuilder: (context, index) => _buildLocalCard(_filterLocalSongs()[index]),
                ),
              ],
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}
