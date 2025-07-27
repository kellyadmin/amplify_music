import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../models.dart';
import 'auth_screen.dart';

class AudioPlayerScreen extends StatefulWidget {
  final Song song;

  const AudioPlayerScreen({super.key, required this.song});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _player;
  final supabase = Supabase.instance.client;

  bool _isPlaying = false;
  bool _isLiked = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initializePlayer();
    _loadLikeStatus();
  }

  Future<void> _initializePlayer() async {
    try {
      await _player.setUrl(widget.song.url);
      await _player.play();
      setState(() => _isPlaying = true);
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
    setState(() => _isPlaying = _player.playing);
  }

  void _handleProtectedAction(Function onConfirmed) {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please log in to use this feature."),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    } else {
      onConfirmed();
    }
  }

  Future<void> _loadLikeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final liked = prefs.getBool('like_${widget.song.id}') ?? false;
    setState(() => _isLiked = liked);
  }

  Future<void> _likeSong() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() => _isLiked = !_isLiked);
    await prefs.setBool('like_${widget.song.id}', _isLiked);

    if (_isLiked) {
      await supabase.from('song_likes').insert({
        'user_id': user.id,
        'song_id': widget.song.id,
      });
    } else {
      await supabase
          .from('song_likes')
          .delete()
          .match({'user_id': user.id, 'song_id': widget.song.id});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isLiked ? "Liked ❤️" : "Unliked")),
    );
  }

  String sanitizeFileName(String input) {
    return input.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  }

  Future<void> _downloadSong() async {
    final tempDir = await getExternalStorageDirectory();
    if (tempDir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot access storage")),
      );
      return;
    }
    final filePath = '${tempDir.path}/${sanitizeFileName(widget.song.title)}.mp3';

    final dio = Dio();

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await dio.download(
        widget.song.url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Download complete")),
      );
    } catch (e) {
      debugPrint("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Download failed")),
      );
    }

    setState(() => _isDownloading = false);
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
        backgroundColor: Colors.black,
        title: Text(widget.song.title),
        actions: [
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.redAccent : Colors.white,
            ),
            onPressed: () => _handleProtectedAction(_likeSong),
          ),
          _isDownloading
              ? Padding(
            padding: const EdgeInsets.all(14.0),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
                value: _downloadProgress,
              ),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _handleProtectedAction(_downloadSong),
          ),
        ],
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
