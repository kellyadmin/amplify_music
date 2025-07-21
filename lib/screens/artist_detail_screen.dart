import 'package:flutter/material.dart';
import '../models.dart';
import 'music_player_screen.dart';

class ArtistDetailScreen extends StatelessWidget {
  final Artist artist;

  const ArtistDetailScreen({Key? key, required this.artist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(artist.name),
        backgroundColor: const Color(0xFF121212),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 70,
            backgroundImage: AssetImage(artist.imageUrl),
          ),
          const SizedBox(height: 16),
          Text(artist.name,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            '${artist.followers} followers',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            artist.bio,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          const Text('Songs',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          ...artist.songs.map((song) {
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: song.albumArtUrl != null && song.albumArtUrl!.isNotEmpty
                    ? Image.network(song.albumArtUrl!,
                    width: 50, height: 50, fit: BoxFit.cover)
                    : Image.asset('assets/images/default_album.jpg',
                    width: 50, height: 50, fit: BoxFit.cover),
              ),
              title: Text(song.title,
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(song.artist,
                  style: const TextStyle(color: Colors.white70)),
              trailing: const Icon(Icons.play_circle_fill, color: Colors.yellow, size: 30),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MusicPlayerScreen(
                      song: song,
                      playlist: artist.songs,
                      onSongChanged: (_) {}, // Add logic if needed
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
