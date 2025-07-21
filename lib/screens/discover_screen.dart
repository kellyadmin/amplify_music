import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart'; // Song & Artist classes
import 'audio_player_screen.dart';
import 'add_artist_screen.dart'; // Import the new screen

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late Future<List<Song>> _futureSongs;
  late Future<List<Artist>> _futureArtists;

  @override
  void initState() {
    super.initState();
    _futureSongs = _loadTrendingSongs();
    _futureArtists = _loadArtists();
  }

  Future<List<Song>> _loadTrendingSongs() async {
    final result = await _supabase
        .from('songs')
        .select()
        .order('play_count', ascending: false)
        .limit(20);

    if (result is List<dynamic>) {
      return result
          .map((m) => Song.fromMap(m as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Artist>> _loadArtists() async {
    final result = await _supabase.from('artists').select();

    if (result is List<dynamic>) {
      return result
          .map((m) => Artist.fromMap(m as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Discover',
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.yellow,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddArtistScreen()),
          );
        },
      ),
      body: RefreshIndicator(
        color: Colors.yellow,
        onRefresh: () async {
          setState(() {
            _futureSongs = _loadTrendingSongs();
            _futureArtists = _loadArtists();
          });
          await Future.wait([_futureSongs, _futureArtists]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            const Text(
              '🔥 Trending Songs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Song>>(
              future: _futureSongs,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.yellow),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Error loading songs: ${snap.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                final songs = snap.data ?? [];
                if (songs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No trending songs available',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                return Column(
                  children: songs.map(_buildSongCard).toList(),
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              '🎤 Featured Artists',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Artist>>(
              future: _futureArtists,
              builder: (context, artistSnap) {
                if (artistSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.yellow));
                }
                if (artistSnap.hasError) {
                  return const Text('Failed to load artists',
                      style: TextStyle(color: Colors.red));
                }
                final artists = artistSnap.data ?? [];
                if (artists.isEmpty) {
                  return const Text('No artists available',
                      style: TextStyle(color: Colors.white54));
                }
                return _buildArtistRow(artists);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(30),
      ),
      child: const TextField(
        style: TextStyle(color: Colors.white),
        cursorColor: Colors.yellow,
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.yellow),
          hintText: 'Search songs or artists...',
          hintStyle: TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSongCard(Song song) {
    final art = song.albumArtUrl.isNotEmpty
        ? song.albumArtUrl
        : 'https://via.placeholder.com/60';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            art,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, color: Colors.white),
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          song.artist,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.play_circle_fill, color: Colors.yellow),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPlayerScreen(song: song),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistRow(List<Artist> artists) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        itemBuilder: (context, idx) {
          final artist = artists[idx];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtistProfileScreen(artist: artist),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(artist.imageUrl),
                    onBackgroundImageError: (_, __) {},
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artist.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ArtistProfileScreen extends StatelessWidget {
  final Artist artist;

  const ArtistProfileScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          artist.name,
          style: const TextStyle(color: Colors.yellow),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(artist.imageUrl),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(height: 16),
          Text(
            artist.bio,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Songs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (artist.songs.isEmpty)
            const Text(
              'No songs available',
              style: TextStyle(color: Colors.white54),
            )
          else
            ...artist.songs.map(
                  (song) => ListTile(
                title: Text(song.title,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(song.artist,
                    style: const TextStyle(color: Colors.white70)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AudioPlayerScreen(song: song),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}
