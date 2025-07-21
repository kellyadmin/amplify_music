import 'package:flutter/material.dart';
import '../models.dart';

class SearchScreen extends StatefulWidget {
  final List<Song> allSongs;

  const SearchScreen({Key? key, required this.allSongs}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    // Filter songs by title or artist name
    final List<Song> filteredSongs = widget.allSongs.where((song) {
      final titleMatch = song.title.toLowerCase().contains(query.toLowerCase());
      final artistMatch = song.artist.toLowerCase().contains(query.toLowerCase());
      return titleMatch || artistMatch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              query = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search by song or artist...',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      body: filteredSongs.isEmpty
          ? const Center(
        child: Text(
          'No songs found',
          style: TextStyle(color: Colors.white54),
        ),
      )
          : ListView.builder(
        itemCount: filteredSongs.length,
        itemBuilder: (context, index) {
          final song = filteredSongs[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: song.albumArtUrl != null
                  ? AssetImage(song.albumArtUrl!)
                  : null,
              backgroundColor: Colors.grey[800],
            ),
            title: Text(
              song.title,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              song.artist,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            onTap: () {
              // TODO: Play the song or navigate to player screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Play: ${song.title}')),
              );
            },
          );
        },
      ),
    );
  }
}
