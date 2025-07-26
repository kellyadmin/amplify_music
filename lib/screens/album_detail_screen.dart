import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import 'music_player_screen.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumId;
  const AlbumDetailScreen({Key? key, required this.albumId}) : super(key: key);

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final _supabase = Supabase.instance.client;
  late Future<Album> _albumFuture;
  static const Color gold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _albumFuture = _loadAlbum();
  }

  Future<Album> _loadAlbum() async {
    // Fetch album metadata
    final resp = await _supabase
        .from('albums')
        .select('id, title, artist_id, cover_url, release_date, description')
        .eq('id', widget.albumId)
        .maybeSingle()
        .execute();

    if (resp.status >= 300 || resp.data == null) {
      throw Exception('Failed to load album: status ${resp.status}');
    }
    final map = resp.data as Map<String, dynamic>;

    // Fetch tracks for this album
    final tracksResp = await _supabase
        .from('songs')
        .select('id, title, artist, audio_url, album_art_url')
        .eq('album_id', widget.albumId)
        .order('track_number', ascending: true)
        .execute();

    if (tracksResp.status >= 300 || tracksResp.data == null) {
      throw Exception('Failed to load tracks: status ${tracksResp.status}');
    }
    final trackList = (tracksResp.data as List<dynamic>)
        .map((m) => Song.fromMap(m as Map<String, dynamic>))
        .toList();

    return Album.fromMap(map, trackList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Album Details'),
      ),
      body: FutureBuilder<Album>(
        future: _albumFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.redAccent)),
            );
          }
          final album = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  album.coverUrl,
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(width: double.infinity, height: 240, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              Text(album.title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              if (album.releaseDate != null)
                Text(
                  'Released on ${album.releaseDate!.toIso8601String().split('T').first}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              if (album.description.isNotEmpty) ...[
                Text(album.description,
                    style:
                    const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 24),
              ],
              Text('Tracks',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: gold)),
              const SizedBox(height: 12),
              ...album.songs.asMap().entries.map((e) {
                final idx = e.key + 1;
                final song = e.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text('$idx', style: const TextStyle(color: Colors.white70)),
                  title: Text(song.title, style: const TextStyle(color: Colors.white)),
                  subtitle:
                  Text(song.artist, style: const TextStyle(color: Colors.white70)),
                  trailing: Icon(Icons.play_circle_fill, color: gold, size: 30),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MusicPlayerScreen(
                          song: song,
                          playlist: album.songs,
                          onSongChanged: (_) {},
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
