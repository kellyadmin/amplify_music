import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import 'audio_player_screen.dart';

class SongsListScreen extends StatefulWidget {
  const SongsListScreen({super.key});

  @override
  State<SongsListScreen> createState() => _SongsListScreenState();
}

class _SongsListScreenState extends State<SongsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  Future<List<Song>> fetchSongs() async {
    final response = await Supabase.instance.client
        .from('songs')
        .select()
        .order('title', ascending: true);

    if (response == null) return [];

    return (response as List<dynamic>)
        .map((e) => Song.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 0, 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _horizontalSongList(List<Song> songs) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AudioPlayerScreen(song: song)),
            ),
            child: Container(
              width: 140,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      song.albumArtUrl ?? '',
                      height: 110,
                      width: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    song.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _songList(List<Song> songs) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: songs.length,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      separatorBuilder: (_, __) => const Divider(color: Colors.grey),
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          contentPadding: const EdgeInsets.all(6),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              song.albumArtUrl ?? '',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.music_note, color: Colors.white),
            ),
          ),
          title: Text(song.title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(song.artist,
              style: const TextStyle(color: Colors.white70)),
          trailing: IconButton(
            icon: const Icon(Icons.play_arrow_rounded,
                color: Colors.yellow, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AudioPlayerScreen(song: song)),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.black,
        elevation: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) =>
                setState(() => _searchText = value.toLowerCase()),
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.yellow,
            decoration: const InputDecoration(
              hintText: 'Search songs or artists...',
              hintStyle: TextStyle(color: Colors.white54),
              prefixIcon: Icon(Icons.search, color: Colors.white70),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 8),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Song>>(
        future: fetchSongs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final songs = snapshot.data ?? [];

          final filtered = songs.where((song) {
            final title = song.title.toLowerCase();
            final artist = song.artist.toLowerCase();
            return title.contains(_searchText) ||
                artist.contains(_searchText);
          }).toList();

          final trending = songs.take(6).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('🔥 Trending'),
                _horizontalSongList(trending),
                if (_searchText.isEmpty) ...[
                  _sectionTitle('🎵 All Songs'),
                  _songList(songs),
                ] else ...[
                  _sectionTitle('🔍 Results for "$_searchText"'),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No songs found',
                          style: TextStyle(color: Colors.white70)),
                    )
                  else
                    _songList(filtered),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
