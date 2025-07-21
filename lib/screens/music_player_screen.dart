import 'package:flutter/material.dart';
import '../models.dart';

class MusicPlayerScreen extends StatefulWidget {
  final Song song;
  final List<Song> playlist;
  final ValueChanged<Song>? onSongChanged; // Add this optional callback

  const MusicPlayerScreen({
    Key? key,
    required this.song,
    required this.playlist,
    this.onSongChanged,
  }) : super(key: key);

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late Song currentSong;
  bool isPlaying = true;

  @override
  void initState() {
    super.initState();
    currentSong = widget.song;
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void _playNext() {
    final currentIndex = widget.playlist.indexOf(currentSong);
    final nextIndex = (currentIndex + 1) % widget.playlist.length;
    setState(() {
      currentSong = widget.playlist[nextIndex];
      isPlaying = true;
    });
    if (widget.onSongChanged != null) widget.onSongChanged!(currentSong);
  }

  void _playPrevious() {
    final currentIndex = widget.playlist.indexOf(currentSong);
    final prevIndex = (currentIndex - 1 + widget.playlist.length) % widget.playlist.length;
    setState(() {
      currentSong = widget.playlist[prevIndex];
      isPlaying = true;
    });
    if (widget.onSongChanged != null) widget.onSongChanged!(currentSong);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(currentSong.title),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              currentSong.albumArtUrl ?? 'assets/images/default_album.jpg',
              width: 300,
              height: 300,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 24),
            Text(currentSong.title,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(currentSong.artist,
                style: const TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous,
                      size: 48, color: Colors.white),
                  onPressed: _playPrevious,
                ),
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    size: 64,
                    color: Colors.white,
                  ),
                  onPressed: _togglePlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 48, color: Colors.white),
                  onPressed: _playNext,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
