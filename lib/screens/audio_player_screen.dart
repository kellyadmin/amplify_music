import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import 'auth_screen.dart'; // ✅ Needed for login redirect

class AudioPlayerScreen extends StatefulWidget {
  final Song song;

  const AudioPlayerScreen({super.key, required this.song});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await _player.setUrl(widget.song.url);
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

  void _handleProtectedAction(Function onConfirmed) {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to use this feature.")),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    } else {
      onConfirmed();
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              _handleProtectedAction(() {
                // TODO: Implement like logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Liked!")),
                );
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              _handleProtectedAction(() {
                // TODO: Implement download logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Download started")),
                );
              });
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.song.albumArtUrl != null &&
              widget.song.albumArtUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  widget.song.albumArtUrl!,
                  height: 250,
                  width: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.music_note,
                    size: 100,
                    color: Colors.white,
                  ),
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
