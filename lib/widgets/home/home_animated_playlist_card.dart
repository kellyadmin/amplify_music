import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants.dart';
import '../../models/generated_playlist.dart';
import '../../screens/generated_playlist_detail_screen.dart';

class HomeAnimatedPlaylistCard extends StatefulWidget {
  final GeneratedPlaylist playlist;
  const HomeAnimatedPlaylistCard({Key? key, required this.playlist}) : super(key: key);

  @override
  State<HomeAnimatedPlaylistCard> createState() => _HomeAnimatedPlaylistCardState();
}

class _HomeAnimatedPlaylistCardState extends State<HomeAnimatedPlaylistCard> {
  Timer? _timer;
  int _currentImageIndex = -1;

  @override
  void initState() {
    super.initState();
    if (widget.playlist.songs.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
        if (!mounted) return;
        setState(() {
          int newIndex;
          do {
            newIndex = Random().nextInt(widget.playlist.songs.length);
          } while (newIndex == _currentImageIndex);
          _currentImageIndex = newIndex;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showPlaylistSongs(BuildContext context, GeneratedPlaylist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  String get _currentImageUrl {
    if (_currentImageIndex == -1 || _currentImageIndex >= widget.playlist.songs.length) {
      return widget.playlist.coverImageUrl;
    }
    return widget.playlist.songs[_currentImageIndex].albumArtUrl;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 360 ? 130.0 : 150.0;
    final imageHeight = screenWidth < 360 ? 100.0 : 120.0;

    return GestureDetector(
      onTap: () {
        if (widget.playlist.songs.isNotEmpty) {
          _showPlaylistSongs(context, widget.playlist);
        }
      },
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'playlist_cover_${widget.playlist.id}',
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 700),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: CachedNetworkImage(
                        key: ValueKey<String>(_currentImageUrl),
                        imageUrl: _currentImageUrl,
                        height: imageHeight,
                        width: cardWidth,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: imageHeight,
                          width: cardWidth,
                          color: cardColor,
                          child: const Icon(Icons.collections, size: 40, color: subtitleColor),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: imageHeight,
                          width: cardWidth,
                          color: cardColor,
                          child: const Icon(Icons.broken_image, size: 40, color: subtitleColor),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                widget.playlist.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth < 360 ? 13 : 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
