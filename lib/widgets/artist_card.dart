import 'package:flutter/material.dart';
import '../models.dart'; // make sure Song model is here
import '../screens/music_player_screen.dart';

class SongCard extends StatelessWidget {
  final Song song;

  const SongCard({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to player
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MusicPlayerScreen(song: song, songTitle: '',, songUrl: '',),
          ),
        );
      },
      child: Card(
        color: Colors.black,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: song.albumArtUrl != null
              ? Image.network(song.albumArtUrl!, width: 50, height: 50, fit: BoxFit.cover)
              : const Icon(Icons.music_note, color: Colors.yellow),
          title: Text(song.title),
        ),
      ),
    );
  }
}
