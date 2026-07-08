import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadedSong {
  final String id; // Unique id to link with original song (could be song id or URL hash)
  final String title;
  final String artist;
  final String filePath;

  DownloadedSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'filePath': filePath,
  };

  factory DownloadedSong.fromJson(Map<String, dynamic> json) => DownloadedSong(
    id: json['id'],
    title: json['title'],
    artist: json['artist'],
    filePath: json['filePath'],
  );
}

class DownloadManager {
  static const String _storageKey = 'downloaded_songs';

  final Dio _dio = Dio();

  Future<List<DownloadedSong>> getDownloadedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];
    final List<dynamic> list = jsonDecode(jsonString);
    return list.map((e) => DownloadedSong.fromJson(e)).toList();
  }

  Future<void> saveDownloadedSongs(List<DownloadedSong> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(songs.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  Future<String?> downloadSong({
    required String url,
    required String id,
    required String title,
    required String artist,
    required Function(int received, int total) onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = '$id-${title.replaceAll(' ', '_')}.mp3';
      final savePath = '${dir.path}/$fileName';

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
      );

      return savePath;
    } catch (e) {
      print('Download failed: $e');
      return null;
    }
  }

  Future<void> addDownloadedSong(DownloadedSong song) async {
    final songs = await getDownloadedSongs();
    songs.add(song);
    await saveDownloadedSongs(songs);
  }

  Future<void> removeDownloadedSong(String id) async {
    final songs = await getDownloadedSongs();

    DownloadedSong? songToRemove;
    try {
      songToRemove = songs.firstWhere((s) => s.id == id);
    } catch (e) {
      songToRemove = null;
    }

    if (songToRemove != null) {
      final file = File(songToRemove.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      songs.removeWhere((s) => s.id == id);
      await saveDownloadedSongs(songs);
    }
  }

  Future<bool> isSongDownloaded(String id) async {
    final songs = await getDownloadedSongs();
    return songs.any((s) => s.id == id);
  }
}
