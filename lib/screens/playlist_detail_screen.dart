import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart'; // Song model
import 'music_player_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailScreen({Key? key, required this.playlistId}) : super(key: key);

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Future<Playlist> _playlistFuture;
  static const Color gold = Color(0xFFFFD700);

  // Hold current playlist and songs locally to update UI instantly
  Playlist? _currentPlaylist;

  @override
  void initState() {
    super.initState();
    _playlistFuture = _loadPlaylist();
  }

  Future<Playlist> _loadPlaylist() async {
    final resp = await supabase
        .from('playlists')
        .select('id, name, description')
        .eq('id', widget.playlistId)
        .maybeSingle()
        .execute();

    if (resp.status >= 300 || resp.data == null) {
      throw Exception('Failed to load playlist: status ${resp.status}');
    }
    final playlistMap = resp.data as Map<String, dynamic>;

    final songsResp = await supabase
        .from('playlist_songs')
        .select('songs(id, title, artist, audio_url, album_art_url, play_count, likes, downloads)')
        .eq('playlist_id', widget.playlistId)
        .order('order', ascending: true)
        .execute();

    if (songsResp.status >= 300 || songsResp.data == null) {
      throw Exception('Failed to load playlist songs: status ${songsResp.status}');
    }

    final List<Song> songs = (songsResp.data as List<dynamic>).map((row) {
      final songMap = (row as Map<String, dynamic>)['songs'] as Map<String, dynamic>;
      return Song.fromMap(songMap);
    }).toList();

    final playlist = Playlist(
      id: playlistMap['id'] as String,
      name: playlistMap['name'] as String,
      description: playlistMap['description'] as String? ?? '',
      songs: songs,
    );

    _currentPlaylist = playlist;
    return playlist;
  }

  Future<void> incrementPlayCount(String songId) async {
    final response = await supabase
        .from('songs')
        .select('play_count')
        .eq('id', songId)
        .maybeSingle()
        .execute();

    if (response.status == 200 && response.data != null) {
      final current = response.data['play_count'] ?? 0;
      await supabase
          .from('songs')
          .update({'play_count': current + 1})
          .eq('id', songId)
          .execute();

      // Update local state to reflect change immediately
      setState(() {
        if (_currentPlaylist != null) {
          final updatedSongs = _currentPlaylist!.songs.map((s) {
            if (s.id == songId) {
              return s.copyWith(playCount: current + 1);
            }
            return s;
          }).toList();

          _currentPlaylist = Playlist(
            id: _currentPlaylist!.id,
            name: _currentPlaylist!.name,
            description: _currentPlaylist!.description,
            songs: updatedSongs,
          );
        }
      });
    }
  }

  // Simple increment like count locally and update DB
  Future<void> incrementLikes(String songId) async {
    final response = await supabase
        .from('songs')
        .select('likes')
        .eq('id', songId)
        .maybeSingle()
        .execute();

    if (response.status == 200 && response.data != null) {
      final current = response.data['likes'] ?? 0;
      await supabase
          .from('songs')
          .update({'likes': current + 1})
          .eq('id', songId)
          .execute();

      setState(() {
        if (_currentPlaylist != null) {
          final updatedSongs = _currentPlaylist!.songs.map((s) {
            if (s.id == songId) {
              return s.copyWith(likes: current + 1);
            }
            return s;
          }).toList();

          _currentPlaylist = Playlist(
            id: _currentPlaylist!.id,
            name: _currentPlaylist!.name,
            description: _currentPlaylist!.description,
            songs: updatedSongs,
          );
        }
      });
    }
  }

  // Simple increment download count locally and update DB
  Future<void> incrementDownloads(String songId) async {
    final response = await supabase
        .from('songs')
        .select('downloads')
        .eq('id', songId)
        .maybeSingle()
        .execute();

    if (response.status == 200 && response.data != null) {
      final current = response.data['downloads'] ?? 0;
      await supabase
          .from('songs')
          .update({'downloads': current + 1})
          .eq('id', songId)
          .execute();

      setState(() {
        if (_currentPlaylist != null) {
          final updatedSongs = _currentPlaylist!.songs.map((s) {
            if (s.id == songId) {
              return s.copyWith(downloads: current + 1);
            }
            return s;
          }).toList();

          _currentPlaylist = Playlist(
            id: _currentPlaylist!.id,
            name: _currentPlaylist!.name,
            description: _currentPlaylist!.description,
            songs: updatedSongs,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Playlist'),
      ),
      body: FutureBuilder<Playlist>(
        future: _playlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            );
          }

          // Use local _currentPlaylist for UI updates after initial load
          final playlist = _currentPlaylist ?? snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                playlist.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (playlist.description.isNotEmpty)
                Text(
                  playlist.description,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),

              // Songs list with play, like, download counts and buttons
              ...playlist.songs.map((song) => Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.albumArtUrl.isNotEmpty
                        ? Image.network(song.albumArtUrl,
                        width: 50, height: 50, fit: BoxFit.cover)
                        : Container(width: 50, height: 50, color: Colors.grey),
                  ),
                  title: Text(song.title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(song.artist, style: const TextStyle(color: Colors.white70)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Play count with icon
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow, color: gold, size: 18),
                          Text('${song.playCount}', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Like button and count
                      InkWell(
                        onTap: () => incrementLikes(song.id),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite_border, color: gold, size: 18),
                            Text('${song.likes}', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Download button and count
                      InkWell(
                        onTap: () async {
                          // TODO: Add actual download functionality here
                          await incrementDownloads(song.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Download count incremented')),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.download, color: gold, size: 18),
                            Text('${song.downloads}', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Play song button
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill, color: gold, size: 30),
                        onPressed: () async {
                          await incrementPlayCount(song.id);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MusicPlayerScreen(
                                song: song,
                                playlist: playlist.songs,
                                onSongChanged: (_) {},
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ))
            ],
          );
        },
      ),
    );
  }
}

// Playlist model (keep it in models.dart if preferred)
class Playlist {
  final String id;
  final String name;
  final String description;
  final List<Song> songs;

  Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.songs,
  });
}
