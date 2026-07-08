import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants.dart';
import '../../models.dart';
import '../chat/chat_access_button.dart';

class HomeArtistCard extends StatefulWidget {
  final Artist artist;
  final VoidCallback onTap;

  const HomeArtistCard({
    super.key,
    required this.artist,
    required this.onTap,
  });

  @override
  State<HomeArtistCard> createState() => _HomeArtistCardState();
}

class _HomeArtistCardState extends State<HomeArtistCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 110,
          margin: const EdgeInsets.only(right: 18),
          child: Column(
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'artist_profile_image_${widget.artist.id}',
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            primaryColor.withOpacity(0.35),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: cardColor,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: widget.artist.imageUrl,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: cardColor,
                              child: const Icon(Icons.person,
                                  size: 40, color: subtitleColor),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: cardColor,
                              child: const Icon(Icons.person,
                                  size: 40, color: subtitleColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Chat access button (appears on hover)
                  if (_isHovered)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: 1.0,
                        child: ChatAccessButton.artist(
                          artist: widget.artist,
                          tooltip: 'Join ${widget.artist.name} fan room',
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13, 
                        fontWeight: FontWeight.w700, 
                        color: textColor
                      ),
                    ),
                  ),
                  if (widget.artist.isVerified) ...[
                    const SizedBox(width: 3),
                    const Icon(Icons.verified, color: primaryColor, size: 14),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
