import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants.dart';
import '../../models.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final List<Song> songSuggestions;
  final List<Artist> artistSuggestions;
  final bool showSuggestions;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onMicTap;
  final Function(Song) onPlaySong;
  final Function(Artist) onViewArtist;

  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.songSuggestions,
    required this.artistSuggestions,
    required this.showSuggestions,
    required this.onSubmitted,
    required this.onClear,
    required this.onMicTap,
    required this.onPlaySong,
    required this.onViewArtist,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: spacingXl, vertical: spacingSm),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: isFocused
                  ? surfaceElevated
                  : surfaceElevated.withOpacity(0.8),
              border: Border.all(
                color: isFocused
                    ? primaryColor.withOpacity(0.3)
                    : Colors.white.withOpacity(0.08),
                width: isFocused ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isFocused
                      ? primaryColor.withOpacity(0.15)
                      : Colors.black.withOpacity(0.25),
                  blurRadius: isFocused ? 20 : 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: 'Search songs, artists, moods...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: subtitleColor.withOpacity(0.65),
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isFocused ? Icons.search_rounded : Icons.search_outlined,
                    color: isFocused ? primaryColor : subtitleColor,
                    key: ValueKey(isFocused),
                  ),
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear, color: subtitleColor),
                        onPressed: onClear,
                      )
                    : IconButton(
                        tooltip: 'Voice search',
                        icon:
                            const Icon(Icons.mic_rounded, color: primaryColor),
                        onPressed: onMicTap,
                      ),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          if (showSuggestions &&
              (songSuggestions.isNotEmpty || artistSuggestions.isNotEmpty)) ...[
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ListView(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                children: [
                  if (artistSuggestions.isNotEmpty) ...[
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, top: 12, bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded,
                              color: primaryColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Artists',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...artistSuggestions.map((artist) => _ArtistSuggestionTile(
                          artist: artist,
                          onTap: () => onViewArtist(artist),
                        )),
                  ],
                  if (songSuggestions.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        top: artistSuggestions.isNotEmpty ? 12 : 12,
                        bottom: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.music_note_rounded,
                              color: primaryColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Songs',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...songSuggestions.map((song) => _SearchSuggestionTile(
                          song: song,
                          onPlay: () => onPlaySong(song),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchSuggestionTile extends StatelessWidget {
  final Song song;
  final VoidCallback onPlay;

  const _SearchSuggestionTile({required this.song, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: song.albumArtUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: cardColor,
              child:
                  const Icon(Icons.music_note, color: subtitleColor, size: 24),
            ),
            errorWidget: (context, url, error) => Container(
              color: cardColor,
              child:
                  const Icon(Icons.music_note, color: subtitleColor, size: 24),
            ),
          ),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 14, color: subtitleColor),
      ),
      trailing: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: IconButton(
          icon: const Icon(Icons.play_arrow_rounded,
              color: primaryColor, size: 20),
          onPressed: onPlay,
        ),
      ),
      onTap: onPlay,
    );
  }
}

class _ArtistSuggestionTile extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const _ArtistSuggestionTile({required this.artist, required this.onTap});

  String _formatFollowerCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final followerCount = (artist.name.hashCode % 100000) + 1000;
    final isVerified = followerCount > 50000;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isVerified ? primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: artist.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: cardColor,
              child: const Icon(Icons.person, color: subtitleColor, size: 24),
            ),
            errorWidget: (context, url, error) => Container(
              color: cardColor,
              child: const Icon(Icons.person, color: subtitleColor, size: 24),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
          if (isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: primaryColor, size: 16),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Icon(Icons.people, color: subtitleColor, size: 12),
          const SizedBox(width: 4),
          Text(
            '${_formatFollowerCount(followerCount)} followers',
            style: TextStyle(fontSize: 12, color: subtitleColor),
          ),
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Active',
            style: TextStyle(fontSize: 12, color: Colors.green),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: Text(
          'View',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
