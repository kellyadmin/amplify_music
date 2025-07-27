import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import 'music_player_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String artistId;

  const ArtistDetailScreen({Key? key, required this.artistId}) : super(key: key);

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  final _supabase = Supabase.instance.client;
  late Future<Artist> _artistFuture;

  @override
  void initState() {
    super.initState();
    _artistFuture = _loadArtist();
  }

  Future<Artist> _loadArtist() async {
    final artistResp = await _supabase
        .from('artists')
        .select('id, name, image_url, bio, followers, following, downloads, verified')
        .eq('id', widget.artistId)
        .maybeSingle();

    if (artistResp.error != null) {
      throw Exception('Failed to load artist: ${artistResp.error!.message}');
    }

    final artistMap = artistResp.data as Map<String, dynamic>;

    final songsResp = await _supabase
        .from('songs')
        .select('id, title, artist, audio_url, album_art_url')
        .eq('artist_id', widget.artistId)
        .order('title', ascending: true);

    if (songsResp.error != null) {
      throw Exception('Failed to load songs: ${songsResp.error!.message}');
    }

    final songsList = (songsResp.data as List)
        .map((m) => Song.fromMap(m as Map<String, dynamic>))
        .toList();

    final isVerified = artistMap['verified'] == true ||
        artistMap['verified']?.toString().toLowerCase() == 'true';

    print("🔍 Verified status for ${artistMap['name']}: $isVerified");

    return Artist(
      id: artistMap['id'] as String,
      name: artistMap['name'] as String,
      imageUrl: artistMap['image_url'] as String,
      bio: artistMap['bio'] as String,
      followers: int.tryParse('${artistMap['followers']}') ?? 0,
      following: int.tryParse('${artistMap['following']}') ?? 0,
      downloads: int.tryParse('${artistMap['downloads']}') ?? 0,
      verified: isVerified,
      songs: songsList,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Artist Details'),
      ),
      body: FutureBuilder<Artist>(
        future: _artistFuture,
        builder: (context, snapshot) {
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

          final artist = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CircleAvatar(
                radius: 70,
                backgroundImage: NetworkImage(artist.imageUrl),
                onBackgroundImageError: (_, __) =>
                const Icon(Icons.person, size: 70, color: Colors.white70),
              ),
              const SizedBox(height: 16),

              // Name + Verified badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    artist.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (artist.verified)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.verified, size: 22, color: Colors.blue),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statItem('Followers', artist.followers, gold),
                  _statItem('Following', artist.following, gold),
                  _statItem('Downloads', artist.downloads, gold),
                ],
              ),
              const SizedBox(height: 16),

              // Bio
              Text(
                artist.bio,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Songs Section
              Text(
                'Songs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: gold,
                ),
              ),
              const SizedBox(height: 12),

              ...artist.songs.map((song) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.albumArtUrl.isNotEmpty
                        ? Image.network(
                      song.albumArtUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey,
                      ),
                    )
                        : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey,
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    song.artist,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Icon(Icons.play_circle_fill, color: gold, size: 30),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MusicPlayerScreen(
                          song: song,
                          playlist: artist.songs,
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

  Widget _statItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
