import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart'; // For better image loading
import 'package:provider/provider.dart' as p; // Use alias for provider

import '../constants.dart';
import '../models.dart' as models;
import 'music_player_screen.dart';
import '../services/music_service.dart'; // Import your MusicService

class AlbumDetailScreen extends StatefulWidget {
  final String albumId;
  const AlbumDetailScreen({Key? key, required this.albumId}) : super(key: key);

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final _supabase = Supabase.instance.client;
  late Future<models.Album> _albumFuture;

  List<models.Song> _songs = []; // This list will hold the songs for the current album

  @override
  void initState() {
    super.initState();
    _albumFuture = _loadAlbum();
  }

  Future<models.Album> _loadAlbum() async {
    try {
      final resp = await _supabase
          .from('albums')
          .select('id, title, artist, album_art_url, release_date, description')
          .eq('id', widget.albumId)
          .maybeSingle();

      if (resp == null) {
        throw Exception('Album not found');
      }

      final tracksResp = await _supabase
          .from('songs')
          .select('id, title, artist, audio_url, album_art_url, likes, liked_by_user, lyrics, duration_seconds') // Fetch all necessary fields
          .eq('album_id', widget.albumId)
          .order('track_number', ascending: true);

      final trackList = (tracksResp as List<dynamic>)
          .map((m) => models.Song.fromMap(m as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _songs = trackList; // Update the local songs list
        });
      }
      return models.Album.fromMap(resp as Map<String, dynamic>, trackList);
    } catch (e) {
      debugPrint('Failed to load album or songs: $e');
      throw Exception('Failed to load album or songs: $e');
    }
  }

  // This method now delegates to the MusicService
  void _playSong(int index, MusicService musicService) {
    if (_songs.isEmpty) return;
    musicService.playSong(_songs[index], _songs, initialIndex: index);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MusicPlayerScreen(), // MusicPlayerScreen gets data from MusicService
      ),
    );
  }

  // This method now delegates to the MusicService
  Future<void> _toggleLike(int index, MusicService musicService) async {
    if (_songs.isEmpty || index >= _songs.length) return;
    final songToLike = _songs[index];
    await musicService.toggleLike(songToLike);
    // The UI will rebuild automatically because MusicService notifies listeners,
    // and the song data displayed in the list will be updated via the Consumer.
  }

  @override
  Widget build(BuildContext context) {
    // Access MusicService to get the latest song states
    final musicService = p.Provider.of<MusicService>(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Album Details',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: primaryColor), // Back button color
      ),
      body: FutureBuilder<models.Album>(
        future: _albumFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          } else if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: errorColor)),
            );
          }

          final album = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Album Art with Play Button Overlay
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: album.albumArtUrl,
                      width: double.infinity,
                      height: 280, // Slightly larger for premium feel
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: double.infinity,
                        height: 280,
                        color: cardColor,
                        child: const Icon(Icons.album, size: 80, color: subtitleColor),
                      ),
                      errorWidget: (context, url, error) =>
                          Container(
                            width: double.infinity,
                            height: 280,
                            color: cardColor,
                            child: const Icon(Icons.broken_image, size: 80, color: errorColor),
                          ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      onPressed: () {
                        if (_songs.isNotEmpty) _playSong(0, musicService);
                      },
                      backgroundColor: primaryColor,
                      child: const Icon(Icons.play_arrow_rounded, color: backgroundColor, size: 36),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                album.title,
                style: const TextStyle(
                    color: textColor, fontSize: 30, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                album.artist,
                style: const TextStyle(
                    color: subtitleColor, fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (album.releaseDate != null)
                Text(
                  'Released on ${album.releaseDate!.toIso8601String().split('T').first}',
                  style: const TextStyle(color: subtitleColor, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              if (album.description.isNotEmpty) ...[
                Text(
                  album.description,
                  style: const TextStyle(color: subtitleColor, fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
              Text(
                'Tracks',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 16),
              // List of songs
              ..._songs.asMap().entries.map((e) {
                final idx = e.key;
                // Get the latest song state from MusicService's queue
                final song = musicService.currentQueue.firstWhere(
                      (queueSong) => queueSong.id == e.value.id,
                  orElse: () => e.value, // Fallback to original if not in queue
                );

                final isCurrentPlaying = musicService.currentSong?.id == song.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                    leading: Text(
                      '${idx + 1}',
                      style: TextStyle(
                        color: isCurrentPlaying ? primaryColor : subtitleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: TextStyle(
                        color: isCurrentPlaying ? primaryColor : textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      song.artist,
                      style: TextStyle(color: subtitleColor),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            song.likedByUser ? Icons.favorite : Icons.favorite_border,
                            color: song.likedByUser ? errorColor : subtitleColor,
                          ),
                          onPressed: () => _toggleLike(idx, musicService),
                        ),
                        IconButton(
                          icon: Icon(
                            isCurrentPlaying && musicService.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            color: primaryColor,
                            size: 30,
                          ),
                          onPressed: () => _playSong(idx, musicService),
                        ),
                      ],
                    ),
                    onTap: () => _playSong(idx, musicService),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
