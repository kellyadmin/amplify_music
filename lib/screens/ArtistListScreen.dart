import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import 'artist_detail_screen.dart';

class ArtistListScreen extends StatelessWidget {
  const ArtistListScreen({super.key});

  Stream<List<Artist>> getArtistsStream() {
    return Supabase.instance.client
        .from('artists')
        .stream(primaryKey: ['id'])  // <-- Correct usage here
        .order('name', ascending: true)
        .execute()
        .map((maps) {
      return (maps as List<dynamic>).map((map) {
        return Artist.fromMap(map as Map<String, dynamic>);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🎤 Artists'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<Artist>>(
        stream: getArtistsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: const Color(0xFFE63950)),
              ),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(artist.imageUrl),
                ),
                title: Text(
                  artist.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${artist.followers} followers',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtistDetailScreen(artistId: artist.id),
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
