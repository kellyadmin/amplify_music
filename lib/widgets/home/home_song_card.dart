import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart' as p;
import '../../constants.dart';
import '../../models.dart';
import '../../services/music_service.dart';
import '../../screens/music_player_screen.dart';
import '../chat/chat_access_button.dart';

class HomeSongCard extends StatelessWidget {
  final Song song;
  final int index;
  final List<Song> songQueue;
  final bool isHovered;
  final String? hoveredSongId;
  final Animation<double> shimmerAnimation;
  final Animation<double> liveActivityAnimation;
  final Animation<double> pulseAnimation;
  final ValueChanged<String> onHover;
  final VoidCallback onHoverExit;
  final Function(Song) onLike;
  final Function(Song) onDownload;
  final Function(Song) onShare;
  final Function(Song) onAddToPlaylist;
  final Function(Song) onAddToQueue;
  final Function(Song) onShowDetails;

  const HomeSongCard({
    super.key,
    required this.song,
    required this.index,
    required this.songQueue,
    required this.isHovered,
    required this.hoveredSongId,
    required this.shimmerAnimation,
    required this.liveActivityAnimation,
    required this.pulseAnimation,
    required this.onHover,
    required this.onHoverExit,
    required this.onLike,
    required this.onDownload,
    required this.onShare,
    required this.onAddToPlaylist,
    required this.onAddToQueue,
    required this.onShowDetails,
  });

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 11),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.18)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.64),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.28),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSongActionsSheet(BuildContext context, bool isLiked) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.82;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF171514), Color(0xFF0A0A0B)],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: song.albumArtUrl,
                              width: 58,
                              height: 58,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.64),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                            color: Colors.white70,
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildStatChip(
                            Icons.favorite_rounded,
                            _formatCount(song.likes),
                          ),
                          _buildStatChip(
                            Icons.play_arrow_rounded,
                            _formatCount(song.playCount),
                          ),
                          _buildStatChip(
                            Icons.download_rounded,
                            _formatCount(song.downloads),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Artist snapshot',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.78),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              song.artist,
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Genre: ${song.genre ?? 'Contemporary'} • Mood: ${song.mood ?? (song.moods != null && song.moods!.isNotEmpty ? song.moods!.first : 'Versatile')}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.64),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildActionTile(
                      context: sheetContext,
                      icon: isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      title:
                          isLiked ? 'Remove from liked' : 'Add to liked songs',
                      subtitle: 'Save this track for faster access',
                      color: primaryColor,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onLike(song);
                      },
                    ),
                    _buildActionTile(
                      context: sheetContext,
                      icon: Icons.queue_music_rounded,
                      title: 'Add to queue',
                      subtitle: 'Play this right after your current track',
                      color: const Color(0xFF60A5FA),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onAddToQueue(song);
                      },
                    ),
                    _buildActionTile(
                      context: sheetContext,
                      icon: Icons.playlist_add_rounded,
                      title: 'Add to playlist',
                      subtitle: 'Place this song in one of your playlists',
                      color: const Color(0xFF34D399),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onAddToPlaylist(song);
                      },
                    ),
                    _buildActionTile(
                      context: sheetContext,
                      icon: Icons.download_rounded,
                      title: 'Download',
                      subtitle: 'Keep this song available offline',
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onDownload(song);
                      },
                    ),
                    _buildActionTile(
                      context: sheetContext,
                      icon: Icons.share_rounded,
                      title: 'Share',
                      subtitle: 'Send this song to friends',
                      color: const Color(0xFFA78BFA),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onShare(song);
                      },
                    ),
                    _buildActionTile(
                      context: sheetContext,
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Join Discussion',
                      subtitle: 'Chat with other listeners about this song',
                      color: const Color(0xFFFF6B6B),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        // The ChatAccessButton will handle navigation
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text(
                            'Close',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PageRouteBuilder<void> _buildMusicPlayerRoute() {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const MusicPlayerScreen(),
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicService = p.Provider.of<MusicService>(context, listen: false);
    final isLiked = musicService.isSongLikedLocally(song.id);
    final isCurrentSong = musicService.currentSong?.id == song.id;
    bool showMetricsByLongPress = false;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        final showMetrics =
            isHovered || isCurrentSong || showMetricsByLongPress;

        return MouseRegion(
          onEnter: (_) {
            HapticFeedback.selectionClick();
            onHover(song.id);
          },
          onExit: (_) => onHoverExit(),
          child: AnimatedBuilder(
            animation: liveActivityAnimation,
            builder: (context, _) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 280 + ((index % 5) * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - value) * 18),
                    child:
                        Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                  );
                },
                child: GestureDetector(
                  onLongPressStart: (_) {
                    HapticFeedback.selectionClick();
                    setLocalState(() => showMetricsByLongPress = true);
                  },
                  onLongPressEnd: (_) {
                    setLocalState(() => showMetricsByLongPress = false);
                  },
                  onLongPressCancel: () {
                    setLocalState(() => showMetricsByLongPress = false);
                  },
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      musicService.playSong(song, songQueue,
                          initialIndex: index);
                      Navigator.push(context, _buildMusicPlayerRoute());
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      width: songCardWidth,
                      margin: const EdgeInsets.symmetric(vertical: spacingSm),
                      transform: Matrix4.identity()
                        ..translate(0.0, isHovered ? -4.0 : 0.0)
                        ..scale(isHovered ? 1.02 : 1.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Hero(
                                tag: 'song_cover_${song.id}',
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isCurrentSong
                                          ? [
                                              primaryColor.withOpacity(0.25),
                                              primaryColor.withOpacity(0.08),
                                            ]
                                          : [
                                              Colors.transparent,
                                              Colors.transparent
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isCurrentSong
                                          ? primaryColor.withOpacity(0.8)
                                          : Colors.white.withOpacity(
                                              isHovered ? 0.15 : 0.08,
                                            ),
                                      width: isCurrentSong ? 2.5 : 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isCurrentSong
                                            ? primaryColor.withOpacity(0.22)
                                            : Colors.black.withOpacity(0.30),
                                        blurRadius: isHovered ? 18 : 10,
                                        offset: Offset(0, isHovered ? 8 : 6),
                                        spreadRadius: -4,
                                      ),
                                      if (isCurrentSong)
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.22),
                                          blurRadius: 18,
                                          spreadRadius: -6,
                                        ),
                                      if (isHovered)
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.10),
                                          blurRadius: 22,
                                          offset: const Offset(0, 10),
                                          spreadRadius: -8,
                                        ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(17),
                                    child: Stack(
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: song.albumArtUrl,
                                          height: 158,
                                          width: 168,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            height: 158,
                                            width: 168,
                                            decoration: BoxDecoration(
                                              color: cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(17),
                                            ),
                                            child: const Icon(
                                              Icons.music_note,
                                              size: 52,
                                              color: subtitleColor,
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            height: 158,
                                            width: 168,
                                            decoration: BoxDecoration(
                                              color: cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(17),
                                            ),
                                            child: const Icon(
                                              Icons.broken_image,
                                              size: 52,
                                              color: subtitleColor,
                                            ),
                                          ),
                                        ),
                                        if (isHovered)
                                          Positioned.fill(
                                            child: AnimatedBuilder(
                                              animation: shimmerAnimation,
                                              builder: (context, _) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment(
                                                        -1.2 +
                                                            shimmerAnimation
                                                                .value,
                                                        -1.2,
                                                      ),
                                                      end: Alignment(
                                                        -0.4 +
                                                            shimmerAnimation
                                                                .value,
                                                        0.2,
                                                      ),
                                                      colors: [
                                                        Colors.transparent,
                                                        Colors.white
                                                            .withOpacity(0.1),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (isCurrentSong)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          primaryColor,
                                          primaryColor.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'NOW',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: secondaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              if (isHovered)
                                Positioned.fill(
                                  child: AnimatedOpacity(
                                    opacity: 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Center(
                                      child: Transform.scale(
                                        scale: pulseAnimation.value * 0.1 + 0.9,
                                        child: Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow,
                                            color: secondaryColor,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 220),
                                  opacity: showMetrics ? 1.0 : 0.0,
                                  child: AnimatedSlide(
                                    duration: const Duration(milliseconds: 220),
                                    offset: showMetrics
                                        ? Offset.zero
                                        : const Offset(0, 0.2),
                                    child: IgnorePointer(
                                      ignoring: !showMetrics,
                                      child: Row(
                                        children: [
                                          _buildStatChip(
                                            Icons.favorite_rounded,
                                            _formatCount(song.likes),
                                          ),
                                          const SizedBox(width: 6),
                                          _buildStatChip(
                                            Icons.play_arrow_rounded,
                                            _formatCount(song.playCount),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Chat access button
                                    if (isHovered)
                                      AnimatedOpacity(
                                        duration: const Duration(milliseconds: 200),
                                        opacity: 1.0,
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: ChatAccessButton.song(
                                            song: song,
                                            tooltip: 'Join song discussion',
                                          ),
                                        ),
                                      ),
                                    // More options button
                                    AnimatedScale(
                                      scale: isHovered ? 1.05 : 1.0,
                                      duration: const Duration(milliseconds: 180),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(999),
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            _showSongActionsSheet(context, isLiked);
                                          },
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.55),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.08),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.more_horiz_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: bodyLg,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: 0.3,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: bodySm,
                                    fontWeight: FontWeight.w500,
                                    color: subtitleColor,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
