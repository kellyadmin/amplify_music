import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart' as p;
import '../constants.dart';
import '../models/generated_playlist.dart';
import '../models.dart';
import '../services/music_service.dart';
import 'music_player_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final GeneratedPlaylist playlist;

  const PlaylistDetailScreen({Key? key, required this.playlist}) : super(key: key);

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late GeneratedPlaylist _playlist;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
  }

  @override
  Widget build(BuildContext context) {
    final musicService = p.Provider.of<MusicService>(context);
    final songs = _playlist.songs;

    return Scaffold(
      backgroundColor: secondaryColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: secondaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_playlist.coverImageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: _playlist.coverImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: cardColor),
                      errorWidget: (_, __, ___) => Container(color: cardColor),
                    )
                  else
                    Container(color: cardColor, child: const Icon(Icons.queue_music, size: 80, color: subtitleColor)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [secondaryColor.withOpacity(0.9), Colors.transparent, secondaryColor.withOpacity(0.9)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                children: [
                  Text(
                    _playlist.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  if (_playlist.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _playlist.description,
                      style: const TextStyle(fontSize: 15, color: subtitleColor, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _actionButton(Icons.play_arrow_rounded, 'Play All', () {
                        if (songs.isNotEmpty) {
                          musicService.playSong(songs.first, songs, initialIndex: 0);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicPlayerScreen()));
                        }
                      }),
                      const SizedBox(width: 16),
                      _actionButton(Icons.shuffle_rounded, 'Shuffle', () {
                        if (songs.isNotEmpty) {
                          final shuffled = [...songs]..shuffle(Random());
                          musicService.playSong(shuffled.first, shuffled, initialIndex: 0);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicPlayerScreen()));
                        }
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('${songs.length} songs', style: const TextStyle(color: subtitleColor, fontSize: 13)),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = songs[index];
                final isCurrentPlaying = musicService.currentSong?.id == song.id;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCurrentPlaying ? surfaceElevated : cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: song.albumArtUrl,
                        width: 54, height: 54, fit: BoxFit.cover,
                        placeholder: (_, __) => Container(width: 54, height: 54, color: secondaryColor),
                        errorWidget: (_, __, ___) => Container(width: 54, height: 54, color: secondaryColor, child: const Icon(Icons.music_note, color: subtitleColor)),
                      ),
                    ),
                    title: Text(song.title, style: TextStyle(color: isCurrentPlaying ? primaryColor : textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text(song.artist, style: const TextStyle(color: subtitleColor, fontSize: 13)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(song.likedByUser ? Icons.favorite : Icons.favorite_border, color: song.likedByUser ? const Color(0xFFE63950) : subtitleColor, size: 22),
                          onPressed: () => musicService.toggleLike(song),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isCurrentPlaying && musicService.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: primaryColor, size: 30,
                        ),
                      ],
                    ),
                    onTap: () {
                      musicService.playSong(song, songs, initialIndex: index);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicPlayerScreen()));
                    },
                  ),
                );
              },
              childCount: songs.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: secondaryColor, size: 22),
      label: Text(label, style: const TextStyle(color: secondaryColor, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    );
  }
}
