import 'package:flutter/material.dart';
import '../models.dart';

class MusicPlayerScreen extends StatefulWidget {
  final Song song;
  final List<Song> playlist;
  final Function(Song) onSongChanged;

  const MusicPlayerScreen({
    super.key,
    required this.song,
    required this.playlist,
    required this.onSongChanged,
  });

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late Song currentSong;

  @override
  void initState() {
    super.initState();
    currentSong = widget.song;
  }

  void _playNext() {
    int currentIndex = widget.playlist.indexOf(currentSong);
    int nextIndex = (currentIndex + 1) % widget.playlist.length;
    setState(() {
      currentSong = widget.playlist[nextIndex];
    });
    widget.onSongChanged(currentSong);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Now Playing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (currentSong.albumArtUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  currentSong.albumArtUrl!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              currentSong.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              currentSong.artist,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _playNext,
              icon: const Icon(Icons.skip_next),
              label: const Text("Next Song"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
