// lib/download_manager.dart
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DownloadManager {
  final Dio _dio = Dio();

  Future<String?> downloadSong({
    required String url,
    required String id,
    required String title,
    required String artist,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${sanitizeFileName('$artist-$title-$id.mp3')}';

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
      );

      return savePath;
    } catch (e) {
      print("Download error: $e");
      return null;
    }
  }

  String sanitizeFileName(String input) {
    return input.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  }
}
