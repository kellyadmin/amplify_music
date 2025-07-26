import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models.dart';

class MusicPlayerScreen extends StatefulWidget {
  final Song? song;
  final List<Song>? playlist;

  final SongModel? localSong;
  final List<SongModel>? localPlaylist;

  final ValueChanged<Song>? onSongChanged;

  const MusicPlayerScreen({
    Key? key,
    this.song,
    this.playlist,
    this.localSong,
    this.localPlaylist,
    this.onSongChanged,
  }) : super(key: key);

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      if (widget.song != null) {
        currentIndex = widget.playlist!.indexOf(widget.song!);
        await _player.setAsset(widget.song!.url);
      } else if (widget.localSong != null) {
        currentIndex = widget.localPlaylist!.indexWhere((s) => s.id == widget.localSong!.id);
        await _player.setFilePath(widget.localSong!.data);
      }
      _player.play();
      setState(() => isPlaying = true);
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  void _togglePlayPause() {
    setState(() => isPlaying = !isPlaying);
    isPlaying ? _player.play() : _player.pause();
  }

  Future<void> _playNext() async {
    if (widget.song != null && widget.playlist != null) {
      currentIndex = (currentIndex + 1) % widget.playlist!.length;
      final next = widget.playlist![currentIndex];
      await _player.setAsset(next.url);
      _player.play();
      setState(() => isPlaying = true);
      if (widget.onSongChanged != null) widget.onSongChanged!(next);
    } else if (widget.localPlaylist != null) {
      currentIndex = (currentIndex + 1) % widget.localPlaylist!.length;
      final next = widget.localPlaylist![currentIndex];
      await _player.setFilePath(next.data);
      _player.play();
      setState(() => isPlaying = true);
    }
  }

  Future<void> _playPrevious() async {
    if (widget.song != null && widget.playlist != null) {
      currentIndex = (currentIndex - 1 + widget.playlist!.length) % widget.playlist!.length;
      final prev = widget.playlist![currentIndex];
      await _player.setAsset(prev.url);
      _player.play();
      setState(() => isPlaying = true);
      if (widget.onSongChanged != null) widget.onSongChanged!(prev);
    } else if (widget.localPlaylist != null) {
      currentIndex = (currentIndex - 1 + widget.localPlaylist!.length) % widget.localPlaylist!.length;
      final prev = widget.localPlaylist![currentIndex];
      await _player.setFilePath(prev.data);
      _player.play();
      setState(() => isPlaying = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.song?.title ?? widget.localPlaylist?[currentIndex].title ?? 'Unknown';
    final artist = widget.song?.artist ?? widget.localPlaylist?[currentIndex].artist ?? 'Unknown';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Now Playing', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.song != null && widget.song!.albumArtUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(widget.song!.albumArtUrl!, width: 260, height: 260, fit: BoxFit.cover),
            )
          else if (widget.localPlaylist != null)
            QueryArtworkWidget(
              id: widget.localPlaylist![currentIndex].id,
              type: ArtworkType.AUDIO,
              artworkHeight: 260,
              artworkWidth: 260,
              artworkBorder: BorderRadius.circular(20),
              nullArtworkWidget: const Icon(Icons.music_note, size: 130, color: Colors.white30),
            ),
          const SizedBox(height: 32),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(artist, style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 42, color: Colors.white),
                onPressed: _playPrevious,
              ),
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_circle_fill,
                  size: 64,
                  color: const Color(0xFFFFD700),
                ),
                onPressed: _togglePlayPause,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 42, color: Colors.white),
                onPressed: _playNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
