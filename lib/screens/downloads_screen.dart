import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<File> downloadedSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> paths = prefs.getStringList('downloads') ?? [];

      // Filter out files that do not exist on disk anymore
      List<File> files = [];
      for (var path in paths) {
        final file = File(path);
        if (await file.exists()) {
          files.add(file);
        }
      }

      setState(() {
        downloadedSongs = files;
      });
    } catch (e) {
      // Handle error gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load downloads: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDownload(int index) async {
    final file = downloadedSongs[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download?'),
        content: Text('Are you sure you want to delete "${file.path.split(Platform.pathSeparator).last}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await file.delete();

      final prefs = await SharedPreferences.getInstance();
      List<String> paths = prefs.getStringList('downloads') ?? [];
      paths.remove(file.path);
      await prefs.setStringList('downloads', paths);

      setState(() {
        downloadedSongs.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Downloads')),
      body: downloadedSongs.isEmpty
          ? const Center(child: Text('Your downloads will appear here'))
          : ListView.builder(
        itemCount: downloadedSongs.length,
        itemBuilder: (context, index) {
          final file = downloadedSongs[index];
          final title = file.path.split(Platform.pathSeparator).last;

          return ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(title),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteDownload(index),
            ),
            onTap: () {
              // TODO: Open music player screen or play audio file
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Play "$title" functionality coming soon!')),
              );
            },
          );
        },
      ),
    );
  }
}
