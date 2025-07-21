import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';
import 'artist_detail_screen.dart';

class ArtistListScreen extends StatelessWidget {
  const ArtistListScreen({super.key});

  Stream<List<Artist>> getArtistsStream() {
    return FirebaseFirestore.instance
        .collection('artists')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return Artist.fromMap(doc.data());
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🎤 Artists'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<List<Artist>>(
        stream: getArtistsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final artists = snapshot.data!;
          if (artists.isEmpty) {
            return const Center(
              child: Text('No artists found', style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(artist.imageUrl),
                ),
                title: Text(artist.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text('${artist.followers} followers',
                    style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtistDetailScreen(artist: artist),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
