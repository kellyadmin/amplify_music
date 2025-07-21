import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models.dart'; // Correct import for Song

class AudioPlayerScreen extends StatefulWidget {
  final Song song;

  const AudioPlayerScreen({super.key, required this.song});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await _player.setUrl(widget.song.url); // ✅ Correct field name
      await _player.play();
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      debugPrint('Failed to play audio: $e');
    }
  }

  void _togglePlayPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
    setState(() {
      _isPlaying = _player.playing;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.song.title),
        backgroundColor: Colors.black,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.song.albumArtUrl != null && widget.song.albumArtUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  widget.song.albumArtUrl!,
                  height: 250,
                  width: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.music_note, size: 100, color: Colors.white),
                ),
              ),
            ),
          Text(
            widget.song.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.song.artist,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 40),
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle : Icons.play_circle,
              size: 80,
              color: Colors.yellow,
            ),
            onPressed: _togglePlayPause,
          ),
        ],
      ),
    );
  }
}
