import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> play(String url) async {
    await _audioPlayer.stop();  // stop current
    await _audioPlayer.play(UrlSource(url)); // play new
  }

  static Future<void> pause() async {
    await _audioPlayer.pause();
  }

  static Future<void> stop() async {
    await _audioPlayer.stop();
  }

  static Future<void> resume() async {
    await _audioPlayer.resume();
  }
}
