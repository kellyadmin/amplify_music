import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  /// Simulate downloading a song file and saving it locally.
  /// This just copies a file from assets to local app directory for simulation.
  static Future<File> downloadSong(String assetFilePath, String songTitle) async {
    // Get the app documents directory to save file
    final directory = await getApplicationDocumentsDirectory();
    final savePath = '${directory.path}/$songTitle.mp3';

    // Check if file already exists, then return it
    final file = File(savePath);
    if (await file.exists()) {
      return file;
    }

    // Load asset file as bytes
    final byteData = await File(assetFilePath).readAsBytes();

    // Write bytes to local file
    final savedFile = await file.writeAsBytes(byteData, flush: true);
    return savedFile;
  }
}
