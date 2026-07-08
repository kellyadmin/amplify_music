import 'dart:async';
import 'dart:ui'; // For ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart'; // For better image loading
import 'package:provider/provider.dart' as p; // Use alias for provider

import '../constants.dart';
import '../models.dart';
import 'music_player_screen.dart';
import '../services/music_service.dart'; // Import your MusicService

class AiCuratedPlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  const AiCuratedPlaylistDetailScreen({Key? key, required this.playlistId}) : super(key: key);

  @override
  State<AiCuratedPlaylistDetailScreen> createState() => _AiCuratedPlaylistDetailScreenState();
}

class _AiCuratedPlaylistDetailScreenState extends State<AiCuratedPlaylistDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  late Future<AiCuratedPlaylist> _playlistFuture;
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _playlistFuture = _loadPlaylist();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    const scrollSpeed = 1.5;
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final current = _scrollController.offset;
        if (current >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(current + scrollSpeed);
        }
      }
    });
  }

  Future<AiCuratedPlaylist> _loadPlaylist() async {
    try {
      final playlistMap = await supabase
          .from('ai_curated_playlists')
          .select()
          .eq('id', widget.playlistId)
          .maybeSingle();

      if (playlistMap == null) {
        throw Exception('Playlist not found');
      }

      final songsRes = await supabase
          .from('ai_curated_playlist_songs')
          .select('songs(id, title, artist, audio_url, album_art_url, likes, liked_by_user, lyrics, duration_seconds)') // Fetch all necessary song details
          .eq('playlist_id', widget.playlistId);

      final songs = (songsRes as List<dynamic>).map((row) {
        return Song.fromMap(row['songs'] as Map<String, dynamic>);
      }).toList();

      return AiCuratedPlaylist.fromMap(playlistMap as Map<String, dynamic>, songs);
    } catch (e) {
      debugPrint('Error loading AI playlist: $e');
      throw Exception('Failed to load AI playlist: $e');
    }
  }

  // Removed _updateField as MusicService handles play count updates

  @override
  Widget build(BuildContext context) {
    final musicService = p.Provider.of<MusicService>(context); // Listen to MusicService

    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder<AiCuratedPlaylist>(
        future: _playlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: errorColor)),
            );
          }

          final playlist = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300, // Increased height for a grander feel
                pinned: true,
                backgroundColor: backgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: playlist.coverImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: cardColor),
                        errorWidget: (context, url, error) => Container(color: cardColor, child: const Icon(Icons.broken_image, color: subtitleColor)),
                      ),
                      // Gradient overlay for better text readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              backgroundColor.withOpacity(0.8),
                              Colors.transparent,
                              backgroundColor.withOpacity(0.8)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      // Subtle blur effect for background image
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(color: Colors.black.withOpacity(0.2)),
                      ),
                    ],
                  ),
                  centerTitle: true,
                  title: Text(
                    playlist.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 24, // Larger title
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(bottom: 16), // Adjust title padding
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20), // Increased padding
                  child: Column(
                    children: [
                      if (playlist.description.isNotEmpty)
                        Text(
                          playlist.description,
                          style: const TextStyle(color: subtitleColor, fontSize: 16, height: 1.5), // Larger font, better line height
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 24), // More spacing
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _goldButton(Icons.play_arrow_rounded, "Play All", () {
                            musicService.playSong(playlist.songs.first, playlist.songs, initialIndex: 0);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                // Corrected: No arguments needed for MusicPlayerScreen
                                builder: (_) => const MusicPlayerScreen(),
                              ),
                            );
                          }),
                          const SizedBox(width: 20), // More spacing between buttons
                          _goldButton(Icons.shuffle_rounded, "Shuffle", () {
                            final shuffled = [...playlist.songs]..shuffle();
                            musicService.playSong(shuffled.first, shuffled, initialIndex: 0);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                // Corrected: No arguments needed for MusicPlayerScreen
                                builder: (_) => const MusicPlayerScreen(),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 12),
                  child: Text(
                    'Songs in this playlist',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 250, // Increased height for horizontal song list
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: playlist.songs.length,
                    itemBuilder: (context, index) {
                      final song = playlist.songs[index];
                      return _buildHorizontalSongCard(song, index, playlist, musicService);
                    },
                  ),
                ),
              ),
              // Add a vertical list of songs below the horizontal scroller
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final song = playlist.songs[index];
                    // Get the latest song state from MusicService's queue
                    final currentSongState = musicService.currentQueue.firstWhere(
                          (queueSong) => queueSong.id == song.id,
                      orElse: () => song, // Fallback to original if not in queue
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
                              color: backgroundColor,
                              child: const Icon(Icons.music_note, size: 30, color: subtitleColor),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 60,
                              height: 60,
                              color: backgroundColor,
                              child: const Icon(Icons.broken_image, size: 30, color: errorColor),
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
                                color: currentSongState.likedByUser ? errorColor : subtitleColor,
                              ),
                              onPressed: () {
                                musicService.toggleLike(currentSongState);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                isCurrentPlaying && musicService.playbackStateNotifier.value.playing // Corrected access
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                color: primaryColor,
                                size: 30,
                              ),
                              onPressed: () {
                                if (isCurrentPlaying) {
                                  musicService.togglePlayPause();
                                } else {
                                  musicService.playSong(currentSongState, playlist.songs, initialIndex: index);
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          musicService.playSong(currentSongState, playlist.songs, initialIndex: index);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Corrected: No arguments needed for MusicPlayerScreen
                              builder: (_) => const MusicPlayerScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: playlist.songs.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Padding for mini-player
            ],
          );
        },
      ),
    );
  }

  Widget _goldButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: backgroundColor), // Icon color is backgroundColor (black)
      label: Text(label, style: const TextStyle(color: backgroundColor, fontWeight: FontWeight.bold)), // Text color is backgroundColor (black)
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, // Button background is primaryColor (gold)
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Larger padding
        elevation: 10, // Added elevation
        shadowColor: primaryColor.withOpacity(0.6), // Purple glow shadow
      ),
    );
  }

  Widget _buildHorizontalSongCard(Song song, int idx, AiCuratedPlaylist playlist, MusicService musicService) {
    // Get the latest song state from MusicService's queue
    final currentSongState = musicService.currentQueue.firstWhere(
          (queueSong) => queueSong.id == song.id,
      orElse: () => song, // Fallback to original if not in queue
    );

    final isCurrentPlaying = musicService.currentSong?.id == currentSongState.id;

    return GestureDetector(
      onTap: () {
        musicService.playSong(currentSongState, playlist.songs, initialIndex: idx);
        Navigator.push(
          context,
          MaterialPageRoute(
            // Corrected: No arguments needed for MusicPlayerScreen
            builder: (_) => const MusicPlayerScreen(),
          ),
        );
      },
      child: Container(
        width: 180, // Slightly wider card
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentPlaying ? cardColor.withOpacity(0.8) : cardColor, // Highlight if playing
          borderRadius: BorderRadius.circular(18), // More rounded
          gradient: LinearGradient( // Subtle gradient
            colors: [cardColor.withOpacity(0.9), cardColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)), // More rounded
              child: CachedNetworkImage(
                imageUrl: currentSongState.albumArtUrl,
                height: 140, // Larger image
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 140,
                  width: double.infinity,
                  color: backgroundColor,
                  child: const Icon(Icons.music_note, color: subtitleColor, size: 40),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 140,
                  width: double.infinity,
                  color: backgroundColor,
                  child: const Icon(Icons.broken_image, color: errorColor, size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0), // Increased padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSongState.title,
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
                    currentSongState.artist,
                    style: const TextStyle(color: subtitleColor, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          currentSongState.likedByUser ? Icons.favorite : Icons.favorite_border,
                          color: currentSongState.likedByUser ? errorColor : subtitleColor,
                          size: 20,
                        ),
                        onPressed: () {
                          musicService.toggleLike(currentSongState);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          isCurrentPlaying && musicService.playbackStateNotifier.value.playing // Corrected access
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          color: primaryColor,
                          size: 28, // Slightly larger play button
                        ),
                        onPressed: () {
                          if (isCurrentPlaying) {
                            musicService.togglePlayPause();
                          } else {
                            musicService.playSong(currentSongState, playlist.songs, initialIndex: idx);
                          }
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
