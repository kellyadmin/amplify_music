import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_player_screen.dart';

class DownloadedSongsScreen extends StatefulWidget {
  const DownloadedSongsScreen({super.key});

  @override
  State<DownloadedSongsScreen> createState() => _DownloadedSongsScreenState();
}

class _DownloadedSongsScreenState extends State<DownloadedSongsScreen> {
  List<FileSystemEntity> downloadedSongs = [];

  @override
  void initState() {
    super.initState();
    _loadDownloadedSongs();
  }

  Future<void> _loadDownloadedSongs() async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) return;
    final files = dir.listSync().where((f) => f.path.endsWith('.mp3')).toList();
    setState(() {
      downloadedSongs = files;
    });
  }

  Future<void> _deleteSong(FileSystemEntity file) async {
    try {
      await file.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted song')),
      );
      _loadDownloadedSongs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete song')),
      );
    }
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Songs'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: downloadedSongs.isEmpty
          ? const Center(
        child: Text(
          'No downloaded songs',
          style: TextStyle(color: Colors.white70),
        ),
      )
          : ListView.builder(
        itemCount: downloadedSongs.length,
        itemBuilder: (context, index) {
          final file = downloadedSongs[index];
          final fileName = _getFileName(file.path);

          return ListTile(
            title: Text(
              fileName,
              style: const TextStyle(color: Colors.white),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.amber),
                  onPressed: () {
                    // Open AudioPlayerScreen with local file path
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AudioPlayerScreen.localFile(path: file.path),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteSong(file),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
