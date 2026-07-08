import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import 'ai_curated_playlist_detail_screen.dart';

class AiCuratedPlaylistsScreen extends StatefulWidget {
  const AiCuratedPlaylistsScreen({super.key});

  @override
  State<AiCuratedPlaylistsScreen> createState() => _AiCuratedPlaylistsScreenState();
}

class _AiCuratedPlaylistsScreenState extends State<AiCuratedPlaylistsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Future<List<AiCuratedPlaylist>> _playlistsFuture;

  final Map<String, ScrollController> _scrollControllers = {};
  final Map<String, Timer> _timers = {};

  @override
  void initState() {
    super.initState();
    _playlistsFuture = _fetchPlaylistsWithSongs();
  }

  @override
  void dispose() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<List<AiCuratedPlaylist>> _fetchPlaylistsWithSongs() async {
    try {
      final playlistsResponse = await supabase
          .from('ai_curated_playlists')
          .select()
          .order('title', ascending: true);

      final playlistsData = playlistsResponse as List<dynamic>;
      List<AiCuratedPlaylist> playlists = [];

      for (final playlistMap in playlistsData) {
        final String playlistId = playlistMap['id'];

        final songsResponse = await supabase
            .from('ai_curated_playlist_songs')
            .select('songs(id, title, artist, audio_url, album_art_url, play_count, likes, downloads, lyrics)')
            .eq('playlist_id', playlistId)
            .order('id', ascending: true);

        final songsData = songsResponse as List<dynamic>;

        List<Song> songs = songsData.map((songRow) {
          final songMap = songRow['songs'] as Map<String, dynamic>;
          return Song.fromMap(songMap);
        }).toList();

        playlists.add(AiCuratedPlaylist.fromMap(playlistMap as Map<String, dynamic>, songs));
      }

      return playlists;
    } catch (e) {
      throw Exception('Error fetching playlists and songs: $e');
    }
  }

  void _startAutoScroll(String mood) {
    final controller = _scrollControllers[mood]!;
    _timers[mood] = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (controller.hasClients) {
        final max = controller.position.maxScrollExtent;
        final current = controller.offset;
        if (current >= max) {
          controller.jumpTo(0);
        } else {
          controller.jumpTo(current + 1.5);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curated Playlists by Mood'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<List<AiCuratedPlaylist>>(
        future: _playlistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: const Color(0xFFE63950))),
            );
          }

          final playlists = snapshot.data ?? [];

          final Map<String, List<AiCuratedPlaylist>> playlistsByMood = {};
          for (var playlist in playlists) {
            playlistsByMood.putIfAbsent(playlist.mood, () => []).add(playlist);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: playlistsByMood.entries.map((entry) {
              final mood = entry.key;
              final moodPlaylists = entry.value;

              _scrollControllers[mood] ??= ScrollController();
              if (!_timers.containsKey(mood)) {
                _startAutoScroll(mood);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mood.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      controller: _scrollControllers[mood],
                      scrollDirection: Axis.horizontal,
                      itemCount: moodPlaylists.length,
                      itemBuilder: (context, index) {
                        final playlist = moodPlaylists[index];
                        return _buildPlaylistCard(playlist);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistCard(AiCuratedPlaylist playlist) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AiCuratedPlaylistDetailScreen(playlistId: playlist.id),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF171514),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                playlist.coverImageUrl,
                height: 120,
                width: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    width: 160,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, size: 60, color: Colors.white54),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                playlist.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                playlist.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
