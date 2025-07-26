import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import 'music_player_screen.dart';

class SongDetailScreen extends StatefulWidget {
  final String songId;

  const SongDetailScreen({Key? key, required this.songId}) : super(key: key);

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  final _supabase = Supabase.instance.client;
  late Future<Song> _songFuture;

  @override
  void initState() {
    super.initState();
    _songFuture = _loadSong();
  }

  Future<Song> _loadSong() async {
    final resp = await _supabase
        .from('songs')
        .select('id, title, artist, audio_url, album_art_url')
        .eq('id', widget.songId)
        .maybeSingle();
    if (resp.errorMessage != null) {
      throw Exception('Failed to load song: ${resp.errorMessage}');
    }
    return Song.fromMap(resp.data as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Song Details'),
      ),
      body: FutureBuilder<Song>(
        future: _songFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }
          final song = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Album art
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: song.albumArtUrl.isNotEmpty
                      ? Image.network(
                    song.albumArtUrl,
                    width: 240,
                    height: 240,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 240,
                      height: 240,
                      color: Colors.grey,
                    ),
                  )
                      : Container(width: 240, height: 240, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Title & Artist
                Text(
                  song.title,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  song.artist,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const Spacer(),

                // Play button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MusicPlayerScreen(
                          song: song,
                          playlist: [song],
                          onSongChanged: (_) {},
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.black),
                  label: const Text('Play', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),

                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}
