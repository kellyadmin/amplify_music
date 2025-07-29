import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import 'download_manager.dart'; // adjust import path if needed

class LocalSongsScreen extends StatefulWidget {
  const LocalSongsScreen({super.key});

  @override
  State<LocalSongsScreen> createState() => _LocalSongsScreenState();
}

class _LocalSongsScreenState extends State<LocalSongsScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _player = AudioPlayer();
  final DownloadManager _downloadManager = DownloadManager();

  List<SongModel> _songs = [];
  List<DownloadedSong> _downloadedSongs = [];
  Map<String, double> _downloadProgress = {}; // songId -> progress

  bool _loading = true;
  int? _currentlyPlayingIndex;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _requestPermissionAndLoadSongs();
    await _loadDownloadedSongs();
  }

  Future<void> _requestPermissionAndLoadSongs() async {
    final status = await Permission.storage.request();

    if (status.isGranted) {
      List<SongModel> songs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      setState(() {
        _songs = songs;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission denied")),
      );
    }
  }

  Future<void> _loadDownloadedSongs() async {
    final downloaded = await _downloadManager.getDownloadedSongs();
    setState(() {
      _downloadedSongs = downloaded;
    });
  }

  bool _isDownloaded(String id) {
    return _downloadedSongs.any((s) => s.id == id);
  }

  DownloadedSong? _getDownloadedSong(String id) {
    try {
      return _downloadedSongs.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _playSong(SongModel song, int index) async {
    String? uriToPlay = song.uri;

    if (_isDownloaded(song.id.toString())) {
      final downloadedSong = _getDownloadedSong(song.id.toString());
      if (downloadedSong != null) {
        uriToPlay = downloadedSong.filePath;
      }
    }

    if (uriToPlay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This song cannot be played")),
      );
      return;
    }

    try {
      if (_currentlyPlayingIndex == index && _player.playing) {
        await _player.pause();
        setState(() => _currentlyPlayingIndex = null);
      } else {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(uriToPlay)));
        await _player.play();
        setState(() => _currentlyPlayingIndex = index);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error playing song: $e")),
      );
    }
  }

  Future<void> _downloadSong(SongModel song) async {
    final songId = song.id.toString();

    setState(() {
      _downloadProgress[songId] = 0.0;
    });

    // IMPORTANT: Replace song.uri! below with your remote URL for actual downloads.
    final path = await _downloadManager.downloadSong(
      url: song.uri!,
      id: songId,
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      onProgress: (received, total) {
        if (total != -1) {
          setState(() {
            _downloadProgress[songId] = received / total;
          });
        }
      },
    );

    setState(() {
      _downloadProgress.remove(songId);
    });

    if (path != null) {
      final downloadedSong = DownloadedSong(
        id: songId,
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        filePath: path,
      );
      await _downloadManager.addDownloadedSong(downloadedSong);
      await _loadDownloadedSongs();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded "${song.title}"')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download "${song.title}"')),
      );
    }
  }

  Future<void> _deleteDownloadedSong(String id) async {
    await _downloadManager.removeDownloadedSong(id);
    await _loadDownloadedSongs();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted downloaded song')),
    );
  }

  Widget _buildSongTile(SongModel song, int index) {
    final isPlaying = _currentlyPlayingIndex == index && _player.playing;
    final isDownloaded = _isDownloaded(song.id.toString());
    final progress = _downloadProgress[song.id.toString()] ?? 0.0;

    return ListTile(
      leading: QueryArtworkWidget(
        id: song.id,
        type: ArtworkType.AUDIO,
        nullArtworkWidget: const Icon(Icons.music_note),
      ),
      title: Text(song.title),
      subtitle: Text(song.artist ?? "Unknown Artist"),
      trailing: SizedBox(
        width: 110,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_downloadProgress.containsKey(song.id.toString()))
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(value: progress),
              )
            else if (isDownloaded)
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete Download',
                onPressed: () => _deleteDownloadedSong(song.id.toString()),
              )
            else
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Download Song',
                onPressed: () => _downloadSong(song),
              ),
            Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
          ],
        ),
      ),
      onTap: () => _playSong(song, index),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Local Songs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () async {
              await _player.stop();
              setState(() => _currentlyPlayingIndex = null);
            },
            tooltip: 'Stop playback',
          ),
        ],
      ),
      body: _songs.isEmpty
          ? const Center(child: Text("No songs found"))
          : ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          return _buildSongTile(_songs[index], index);
        },
      ),
    );
  }
}
