import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalSongsScreen extends StatefulWidget {
  const LocalSongsScreen({super.key});

  @override
  State<LocalSongsScreen> createState() => _LocalSongsScreenState();
}

class _LocalSongsScreenState extends State<LocalSongsScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _player = AudioPlayer();

  List<SongModel> _songs = [];

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadSongs();
  }

  Future<void> _requestPermissionAndLoadSongs() async {
    var status = await Permission.audio.request();
    if (status.isGranted) {
      List<SongModel> songs = await _audioQuery.querySongs();
      setState(() {
        _songs = songs;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission denied")),
      );
    }
  }

  Future<void> _playSong(SongModel song) async {
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
      _player.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error playing song: $e")),
      );
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
      appBar: AppBar(
        title: const Text('My Local Songs'),
      ),
      body: _songs.isEmpty
          ? const Center(child: Text("No songs found"))
          : ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          return ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(song.title),
            subtitle: Text(song.artist ?? "Unknown Artist"),
            onTap: () => _playSong(song),
          );
        },
      ),
    );
  }
}
