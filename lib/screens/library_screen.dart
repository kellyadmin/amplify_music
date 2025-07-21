import 'package:flutter/material.dart';
import '../models.dart';
import 'music_player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color goldColor = const Color(0xFFFFD700);

  final List<Song> downloadedSongs = [
    Song(
      id: 'dl1',
      title: 'Sability',
      artist: 'Fik Fameica',
      url: 'assets/audio/fameica.mp3',
      albumArtUrl: 'assets/images/sability.jpg',
    ),
    Song(
      id: 'dl2',
      title: 'Vyroota Fire',
      artist: 'Vyroota',
      url: 'assets/audio/vyroota.mp3',
      albumArtUrl: 'assets/images/vyroota.jpg',
    ),
    Song(
      id: 'dl3',
      title: 'Burna Blaze',
      artist: 'Burna Boy',
      url: 'assets/audio/burna.mp3',
      albumArtUrl: 'assets/images/burna.jpg',
    ),
  ];

  final List<Song> likedSongs = [
    Song(
      id: 'like1',
      title: 'Bankyaye',
      artist: 'Fik Fameica',
      url: 'assets/audio/fameica.mp3',
      albumArtUrl: 'assets/images/fameica.jpg',
    ),
    Song(
      id: 'like2',
      title: 'Hustle Hard',
      artist: 'Vyroota',
      url: 'assets/audio/vyroota.mp3',
      albumArtUrl: 'assets/images/vyroota.jpg',
    ),
  ];

  final List<Song> recentSongs = [
    Song(
      id: 'recent1',
      title: 'Old School',
      artist: 'Burna Boy',
      url: 'assets/audio/burna.mp3',
      albumArtUrl: 'assets/images/burna.jpg',
    ),
    Song(
      id: 'recent2',
      title: 'New Wave',
      artist: 'Fik Fameica',
      url: 'assets/audio/fameica.mp3',
      albumArtUrl: 'assets/images/sability.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildSongCard(List<Song> playlist, int index) {
    final song = playlist[index];
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            song.albumArtUrl ?? '',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(song.artist, style: const TextStyle(color: Colors.white70)),
        trailing: Icon(Icons.play_circle_fill, color: goldColor, size: 32),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MusicPlayerScreen(
                song: song,
                playlist: playlist,
                onSongChanged: (newSong) {},
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Library',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: goldColor,
          labelColor: goldColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Downloaded"),
            Tab(text: "Liked"),
            Tab(text: "Recent"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                hintText: 'Search your library',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: downloadedSongs.length,
                  itemBuilder: (context, index) => _buildSongCard(downloadedSongs, index),
                ),
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: likedSongs.length,
                  itemBuilder: (context, index) => _buildSongCard(likedSongs, index),
                ),
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: recentSongs.length,
                  itemBuilder: (context, index) => _buildSongCard(recentSongs, index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
