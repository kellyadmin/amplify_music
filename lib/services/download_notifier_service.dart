import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models.dart';
import 'download_service.dart';

class DownloadNotifierService extends ChangeNotifier {
  final List<Song> _downloadedSongs = [];

  List<Song> get downloadedSongs => _downloadedSongs;

  DownloadNotifierService() {
    _loadDownloadedSongsFromStorage();
  }

  // Check if a song is already downloaded
  bool isDownloaded(String songId) {
    return _downloadedSongs.any((song) => song.id == songId);
  }

  // Start downloading a song
  Future<void> startDownload(Song song) async {
    if (isDownloaded(song.id)) {
      debugPrint("Song ${song.title} is already downloaded");
      return;
    }

    try {
      // Use the song's actual audio URL instead of a hardcoded path
      final downloadedFile = await DownloadService.downloadSong(song.audioUrl, song.title);

      // Create a new Song object with the local file path
      final newSong = song.copyWith(audioUrl: downloadedFile.path);

      // Add to the list and save to storage
      _downloadedSongs.add(newSong);
      await _saveDownloadedSongsToStorage();
      notifyListeners();

      debugPrint("Downloaded song: ${song.title}");
    } catch (e) {
      debugPrint("Error downloading song: $e");
    }
  }

  // Remove a downloaded song
  Future<void> removeDownloadedSong(String songId) async {
    try {
      final songIndex = _downloadedSongs.indexWhere((song) => song.id == songId);
      if (songIndex != -1) {
        final song = _downloadedSongs[songIndex];

        // Delete the file from storage
        final file = File(song.audioUrl);
        if (await file.exists()) {
          await file.delete();
        }

        // Remove from the list and save to storage
        _downloadedSongs.removeAt(songIndex);
        await _saveDownloadedSongsToStorage();
        notifyListeners();

        debugPrint("Removed downloaded song: ${song.title}");
      }
    } catch (e) {
      debugPrint("Error removing downloaded song: $e");
    }
  }

  // Save downloaded songs to persistent storage
  Future<void> _saveDownloadedSongsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert songs to a list of JSON strings
      final songsJson = _downloadedSongs.map((song) => jsonEncode(song.toMap())).toList();

      // Save to SharedPreferences
      await prefs.setStringList('downloaded_songs', songsJson);
    } catch (e) {
      debugPrint("Error saving downloaded songs: $e");
    }
  }

  // Load downloaded songs from persistent storage
  Future<void> _loadDownloadedSongsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get the list of JSON strings
      final songsJson = prefs.getStringList('downloaded_songs') ?? [];

      // Convert back to Song objects
      _downloadedSongs.clear();
      for (final jsonStr in songsJson) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          _downloadedSongs.add(Song.fromMap(map));
        } catch (e) {
          debugPrint("Error parsing song from JSON: $e");
        }
      }

      notifyListeners();
      debugPrint("Loaded ${_downloadedSongs.length} downloaded songs from storage");
    } catch (e) {
      debugPrint("Error loading downloaded songs: $e");
    }
  }
}
