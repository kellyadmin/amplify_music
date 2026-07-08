import 'package:flutter/material.dart';
import '../utils/auth_dialogs.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../models.dart';
import 'auth_screen.dart';

class AudioPlayerScreen extends StatefulWidget {
  final Song? song;
  final String? localFilePath;

  const AudioPlayerScreen({super.key, required this.song}) : localFilePath = null;
  const AudioPlayerScreen.localFile({super.key, required this.localFilePath}) : song = null;

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _player;
  final supabase = Supabase.instance.client;

  // NEW: Add a state to track buffering
  bool _isBuffering = true;
  bool _isPlaying = false;
  bool _isLiked = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initializePlayer();

    // NEW: Listen to player state changes to update the UI
    _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
        if (mounted) setState(() => _isBuffering = true);
      } else {
        if (mounted) setState(() => _isBuffering = false);
      }

      if (mounted) setState(() => _isPlaying = isPlaying);
    });

    if (widget.song != null) {
      _loadLikeStatus();
    }
  }

  // NEW: This is the updated function with automatic caching
  Future<void> _initializePlayer() async {
    try {
      if (widget.localFilePath != null) {
        // Play from a pre-downloaded local file, no caching needed here
        await _player.setFilePath(widget.localFilePath!);
      } else if (widget.song != null) {
        // This is where the magic happens!
        // We use LockCachingAudioSource to automatically stream AND cache the song.
        final audioSource = LockCachingAudioSource(
          Uri.parse(widget.song!.url),
          // OPTIONAL: You can define where to cache files and for how long
          // cacheFile: File('${(await getTemporaryDirectory()).path}/${sanitizeFileName(widget.song!.title)}.mp3'),
        );
        await _player.setAudioSource(audioSource);
      } else {
        throw Exception("No audio source provided");
      }

      _player.play();

    } catch (e) {
      debugPrint('Failed to play audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: ${e.toString()}')),
      );
    }
  }

  void _togglePlayPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _handleProtectedAction(Function onConfirmed) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      final didLogin = await AuthDialogs.showLoginRequired(
        context,
        title: 'Sign in to use this feature',
        message:
            'Create your music space, save your interactions, and unlock protected actions by signing in.',
        actionLabel: 'Sign In',
      );
      if (!didLogin) return;
    }
    onConfirmed();
  }

  Future<void> _loadLikeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final liked = prefs.getBool('like_${widget.song!.id}') ?? false;
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _likeSong() async {
    final user = supabase.auth.currentUser;
    if (user == null || widget.song == null) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() => _isLiked = !_isLiked);
    await prefs.setBool('like_${widget.song!.id}', _isLiked);

    if (_isLiked) {
      await supabase.from('song_likes').insert({
        'user_id': user.id,
        'song_id': widget.song!.id,
      });
    } else {
      await supabase
          .from('song_likes')
          .delete()
          .match({'user_id': user.id, 'song_id': widget.song!.id});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isLiked ? "Liked ❤️" : "Unliked")),
    );
  }

  String sanitizeFileName(String input) {
    return input.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  }

  Future<void> _downloadSong() async {
    if (widget.song == null) return;

    final tempDir = await getExternalStorageDirectory();
    if (tempDir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot access storage")),
      );
      return;
    }
    final filePath = '${tempDir.path}/${sanitizeFileName(widget.song!.title)}.mp3';

    final dio = Dio();

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await dio.download(
        widget.song!.url,
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
    final title = widget.song?.title ?? widget.localFilePath?.split('/').last ?? 'Unknown Song';
    final artist = widget.song?.artist ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title),
        actions: [
          if (widget.song != null)
            IconButton(
              icon: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? const Color(0xFFE63950) : Colors.white,
              ),
              onPressed: () => _handleProtectedAction(_likeSong),
            ),
          if (widget.song != null && !_isDownloading)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: () => _handleProtectedAction(_downloadSong),
            ),
          if (_isDownloading)
            Padding(
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
            ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.song?.albumArtUrl != null && widget.song!.albumArtUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  widget.song!.albumArtUrl!,
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
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (artist.isNotEmpty)
            const SizedBox(height: 8),
          if (artist.isNotEmpty)
            Text(
              artist,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          const SizedBox(height: 40),

          // NEW: Show a loading indicator while buffering
          if (_isBuffering)
            const SizedBox(
              height: 80,
              width: 80,
              child: CircularProgressIndicator(color: Color(0xFFF2B84B)),
            )
          else
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause_circle : Icons.play_circle,
                size: 80,
                color: Color(0xFFF2B84B),
              ),
              onPressed: _togglePlayPause,
            ),
        ],
      ),
    );
  }
}
