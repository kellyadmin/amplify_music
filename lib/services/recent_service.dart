import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models.dart';

class RecentService extends ChangeNotifier {
  final List<Song> _recentSongs = [];
  final Map<String, int> _songProgressMs = {};
  final Map<String, int> _songDurationMs = {};

  List<Song> get recentSongs => _recentSongs;

  RecentService() {
    _loadRecentSongsFromStorage();
  }

  // Adds a song to the top of the recent list.
  void addRecentSong(Song song) {
    // Remove the song if it's already in the list to move it to the top
    _recentSongs.removeWhere((s) => s.id == song.id);
    // Add the new song at the beginning of the list
    _recentSongs.insert(0, song);
    // Keep the list to a manageable size (e.g., 20 songs)
    if (_recentSongs.length > 20) {
      _recentSongs.removeLast();
    }
    _saveRecentSongsToStorage();
    notifyListeners();
  }

  double getProgressForSong(String songId) {
    final position = _songProgressMs[songId] ?? 0;
    final duration = _songDurationMs[songId] ?? 0;
    if (duration <= 0) return 0;
    return (position / duration).clamp(0.0, 1.0);
  }

  Duration getSavedPositionForSong(String songId) {
    return Duration(milliseconds: _songProgressMs[songId] ?? 0);
  }

  void updateSongProgress(String songId, Duration position, Duration duration) {
    if (duration.inMilliseconds <= 0) return;

    final isCompleted = position.inMilliseconds >=
        (duration.inMilliseconds * 0.95).round();
    final normalizedPosition = isCompleted ? 0 : position.inMilliseconds;
    final previousPosition = _songProgressMs[songId] ?? 0;
    final previousDuration = _songDurationMs[songId] ?? 0;

    if ((normalizedPosition - previousPosition).abs() < 4000 &&
        (duration.inMilliseconds - previousDuration).abs() < 1000) {
      return;
    }

    _songProgressMs[songId] = normalizedPosition;
    _songDurationMs[songId] = duration.inMilliseconds;
    _saveProgressToStorage();
    notifyListeners();
  }

  // Clear all recent songs
  void clearRecentSongs() {
    _recentSongs.clear();
    _songProgressMs.clear();
    _songDurationMs.clear();
    _saveRecentSongsToStorage();
    _saveProgressToStorage();
    notifyListeners();
  }

  // Save recent songs to persistent storage
  Future<void> _saveRecentSongsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert songs to a list of JSON strings
      final songsJson = _recentSongs.map((song) => jsonEncode(song.toMap())).toList();

      // Save to SharedPreferences
      await prefs.setStringList('recent_songs', songsJson);
    } catch (e) {
      debugPrint("Error saving recent songs: $e");
    }
  }

  Future<void> _saveProgressToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recent_song_progress', jsonEncode(_songProgressMs));
      await prefs.setString('recent_song_duration', jsonEncode(_songDurationMs));
    } catch (e) {
      debugPrint("Error saving recent song progress: $e");
    }
  }

  // Load recent songs from persistent storage
  Future<void> _loadRecentSongsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get the list of JSON strings
      final songsJson = prefs.getStringList('recent_songs') ?? [];

      final progressJson = prefs.getString('recent_song_progress');
      final durationJson = prefs.getString('recent_song_duration');

      _songProgressMs
        ..clear()
        ..addAll(_parseIntMap(progressJson));
      _songDurationMs
        ..clear()
        ..addAll(_parseIntMap(durationJson));

      // Convert back to Song objects
      _recentSongs.clear();
      for (final jsonStr in songsJson) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          _recentSongs.add(Song.fromMap(map));
        } catch (e) {
          debugPrint("Error parsing song from JSON: $e");
        }
      }

      notifyListeners();
      debugPrint("Loaded ${_recentSongs.length} recent songs from storage");
    } catch (e) {
      debugPrint("Error loading recent songs: $e");
    }
  }

  Map<String, int> _parseIntMap(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return {};

    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }
}
