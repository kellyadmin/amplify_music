import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadHelper {
  static Future<String?> downloadSong(String url, String fileName, Function(double)? onProgress) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) return null;

    try {
      final baseDir = await getExternalStorageDirectory();
      final downloadDir = Directory("${baseDir!.path}/AmplifyMusic");

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final filePath = "${downloadDir.path}/$fileName.mp3";

      final dio = Dio();

      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received / total);
          }
        },
      );

      return filePath;
    } catch (e) {
      print("Download failed: $e");
      return null;
    }
  }
}
