import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart' as p;
import '../constants.dart';

import '../models.dart';
import 'music_player_screen.dart';
import '../services/music_service.dart';

import '../constants.dart';
class UnifiedPlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  final String? title;
  final String? description;
  final String? coverUrl;

  const UnifiedPlaylistDetailScreen({
    Key? key,
    required this.playlistId,
    this.title,
    this.description,
    this.coverUrl,
  }) : super(key: key);

  @override
  State<UnifiedPlaylistDetailScreen> createState() => _UnifiedPlaylistDetailScreenState();
}

class _UnifiedPlaylistDetailScreenState extends State<UnifiedPlaylistDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  static const Color primaryColor = Color(0xFFF2B84B);
  static const Color secondaryColor = Color(0xFF0A0A0B);
  static const Color cardColor = Color(0xFF211C16);
  static const Color textColor = Colors.white;
  static const Color subtitleColor = Colors.white70;
  static const Color verifiedColor = Color(0xFFC8901F);

  String? _title;
  String? _description;
  String? _coverUrl;
  bool _isVerified = false;

  List<Song> _songs = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  // Aggressive caching for instant loading
  static final Map<String, Map<String, dynamic>> _playlistCache = {};
  static final Map<String, List<Song>> _songsCache = {};
  static final Map<String, String> _descriptionCache = {};

  @override
  void initState() {
    super.initState();
    _loadDataInstantly();
  }

  Future<void> _loadDataInstantly() async {
    if (!mounted) return;

    // Check cache first for instant display
    if (_playlistCache.containsKey(widget.playlistId) &&
        _songsCache.containsKey(widget.playlistId)) {
      final cachedPlaylist = _playlistCache[widget.playlistId]!;
      final cachedSongs = _songsCache[widget.playlistId]!;

      setState(() {
        _title = cachedPlaylist['title'] ?? widget.title ?? 'Untitled';
        _description = cachedPlaylist['description'] ?? _generateAutoDescription(cachedSongs.length);
        _coverUrl = cachedPlaylist['cover_image_url'] ?? widget.coverUrl;
        _isVerified = cachedPlaylist['is_verified'] ?? false;
        _songs = cachedSongs;
        _isLoading = false;
      });

      // Refresh in background without blocking UI
      _fetchPlaylistAndSongs(refresh: true);
      return;
    }

    // If no cache, load immediately with minimal UI
    _fetchPlaylistAndSongs();
  }

  String _generateAutoDescription(int songCount) {
    if (songCount == 0) return "Empty playlist";
    if (songCount == 1) return "One amazing track";
    if (songCount < 10) return "$songCount handpicked songs";
    if (songCount < 30) return "$songCount curated tracks";
    return "$songCount songs for your listening pleasure";
  }

  Future<void> _fetchPlaylistAndSongs({bool refresh = false}) async {
    if (!mounted) return;

    try {
      // Use cached data if available and not refreshing
      if (!refresh && _playlistCache.containsKey(widget.playlistId)) {
        final cachedPlaylist = _playlistCache[widget.playlistId]!;
        final cachedSongs = _songsCache[widget.playlistId]!;

        if (mounted) {
          setState(() {
            _title = cachedPlaylist['title'] ?? widget.title ?? 'Untitled';
            _description = cachedPlaylist['description'] ?? _generateAutoDescription(cachedSongs.length);
            _coverUrl = cachedPlaylist['cover_image_url'] ?? widget.coverUrl;
            _isVerified = cachedPlaylist['is_verified'] ?? false;
            _songs = cachedSongs;
            _isLoading = false;
          });
        }
        return;
      }

      // Optimized parallel fetching
      final playlistFuture = supabase
          .from('ai_playlists')
          .select()
          .eq('id', widget.playlistId)
          .maybeSingle();

      final relationshipsFuture = supabase
          .from('ai_playlist_songs')
          .select('song_id, position')
          .eq('playlist_id', widget.playlistId)
          .order('position');

      final results = await Future.wait([playlistFuture, relationshipsFuture]);
      final playlistRes = results[0];
      final relationshipsRes = results[1];

      if (playlistRes == null) {
        if (mounted) {
          setState(() {
            _error = 'Playlist not found';
            _isLoading = false;
          });
        }
        return;
      }

      List<Song> songsList = [];

      if (relationshipsRes != null && (relationshipsRes as List).isNotEmpty) {
        List<String> songIds = (relationshipsRes as List)
            .map<String>((r) => r['song_id'].toString())
            .toList();

        if (songIds.isNotEmpty) {
          final songsRes = await supabase
              .from('songs')
              .select()
              .in_('id', songIds);

          if (songsRes != null && (songsRes as List).isNotEmpty) {
            Map<String, Song> songMap = {};
            for (var songData in songsRes) {
              final song = Song.fromMap(songData);
              songMap[song.id] = song;
            }

            for (var relationship in relationshipsRes) {
              final songId = relationship['song_id'].toString();
              if (songMap.containsKey(songId)) {
                songsList.add(songMap[songId]!);
              }
            }
          }
        }
      }

      // Generate auto description if none exists
      final autoDescription = _generateAutoDescription(songsList.length);

      // Cache the results
      _playlistCache[widget.playlistId] = {
        'title': playlistRes['title'],
        'description': playlistRes['description'] ?? autoDescription,
        'cover_image_url': playlistRes['cover_image_url'],
        'is_verified': playlistRes['is_verified'] ?? false,
      };
      _songsCache[widget.playlistId] = songsList;
      _descriptionCache[widget.playlistId] = autoDescription;

      if (mounted) {
        setState(() {
          _title = playlistRes['title'] ?? widget.title ?? 'Untitled';
          _description = playlistRes['description'] ?? autoDescription;
          _coverUrl = playlistRes['cover_image_url'] ?? widget.coverUrl;
          _isVerified = playlistRes['is_verified'] ?? false;
          _songs = songsList;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading playlist: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load playlist: $e';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    await _fetchPlaylistAndSongs(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final musicService = p.Provider.of<MusicService>(context);

    return Scaffold(
      backgroundColor: secondaryColor,
      body: _isLoading
          ? _buildInstantLoader()
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: const Color(0xFFE63950)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Retry', style: TextStyle(color: secondaryColor)),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryColor,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: secondaryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image with blur effect
                    _coverUrl != null && _coverUrl!.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: _coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: cardColor),
                      errorWidget: (context, url, error) => Container(color: cardColor, child: const Icon(Icons.broken_image, color: subtitleColor)),
                    )
                        : Container(
                      color: cardColor,
                      child: const Icon(Icons.queue_music, size: 100, color: subtitleColor),
                    ),
                    // Blur overlay
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                      child: Container(color: Colors.black.withOpacity(0.4)),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            secondaryColor.withOpacity(0.9),
                            Colors.transparent,
                            secondaryColor.withOpacity(0.9)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
                centerTitle: true,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _title ?? 'Playlist',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 24,
                      ),
                    ),
                    if (_isVerified)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.verified,
                          color: verifiedColor,
                          size: 24,
                        ),
                      ),
                  ],
                ),
                titlePadding: const EdgeInsets.only(bottom: 16),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20),
                child: Column(
                  children: [
                    if (_description != null && _description!.isNotEmpty)
                      Text(
                        _description!,
                        style: const TextStyle(color: subtitleColor, fontSize: 16, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _goldButton(Icons.play_arrow_rounded, "Play All", () {
                          if (_songs.isNotEmpty) {
                            musicService.playSong(_songs.first, _songs, initialIndex: 0);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MusicPlayerScreen(),
                              ),
                            );
                          }
                        }),
                        const SizedBox(width: 20),
                        _goldButton(Icons.shuffle_rounded, "Shuffle", () {
                          if (_songs.isNotEmpty) {
                            final shuffled = [..._songs]..shuffle();
                            musicService.playSong(shuffled.first, shuffled, initialIndex: 0);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MusicPlayerScreen(),
                              ),
                            );
                          }
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${_songs.length} songs",
                      style: const TextStyle(color: subtitleColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final song = _songs[index];
                  final currentSongState = musicService.currentQueue.firstWhere(
                        (queueSong) => queueSong.id == song.id,
                    orElse: () => song,
                  );
                  final isCurrentPlaying = musicService.currentSong?.id == currentSongState.id;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrentPlaying ? cardColor.withOpacity(0.8) : cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: currentSongState.albumArtUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 60,
                            height: 60,
                            color: secondaryColor,
                            child: const Icon(Icons.music_note, size: 30, color: subtitleColor),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: secondaryColor,
                            child: const Icon(Icons.broken_image, size: 30, color: const Color(0xFFE63950)),
                          ),
                        ),
                      ),
                      title: Text(
                        currentSongState.title,
                        style: TextStyle(
                          color: isCurrentPlaying ? primaryColor : textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        currentSongState.artist,
                        style: const TextStyle(color: subtitleColor),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              currentSongState.likedByUser ? Icons.favorite : Icons.favorite_border,
                              color: currentSongState.likedByUser ? const Color(0xFFE63950) : subtitleColor,
                            ),
                            onPressed: () {
                              musicService.toggleLike(currentSongState);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              isCurrentPlaying && musicService.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: primaryColor,
                              size: 30,
                            ),
                            onPressed: () {
                              if (isCurrentPlaying) {
                                musicService.togglePlayPause();
                              } else {
                                musicService.playSong(currentSongState, _songs, initialIndex: index);
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        musicService.playSong(currentSongState, _songs, initialIndex: index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MusicPlayerScreen(),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: _songs.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildInstantLoader() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: secondaryColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Placeholder for cover image
                Container(
                  color: cardColor,
                  child: const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
                // Blur overlay even during loading
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Placeholder for title with verified badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 24,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Placeholder for description
                Container(
                  height: 16,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 24),
                // Placeholder for buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 40,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      height: 40,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Placeholder for song count
                Container(
                  height: 14,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  title: Container(
                    height: 16,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  subtitle: Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            },
            childCount: 5,
          ),
        ),
      ],
    );
  }

  Widget _goldButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: secondaryColor),
      label: Text(label, style: const TextStyle(color: secondaryColor, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 10,
        shadowColor: primaryColor.withOpacity(0.6),
      ),
    );
  }
}
