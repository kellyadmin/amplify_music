import 'package:flutter/material.dart';
import '../models.dart'; // Centralized models file

class MiniPlayerWidget extends StatelessWidget {
  final String songTitle;
  final String artistName;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final bool isPlaying;
  final List<Song> queue;
  final int currentIndex;

  const MiniPlayerWidget({
    super.key,
    required this.songTitle,
    required this.artistName,
    required this.onTap,
    required this.onPlayPause,
    required this.isPlaying,
    required this.queue,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black87,
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, -2)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.music_note, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    songTitle,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    artistName,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle : Icons.play_circle,
                color: Colors.white,
                size: 32,
              ),
              onPressed: onPlayPause,
            ),
          ],
        ),
      ),
    );
  }
}
