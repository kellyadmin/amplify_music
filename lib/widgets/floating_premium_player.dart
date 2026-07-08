import 'package:flutter/material.dart';
import 'dart:ui';
import '../models.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FloatingPremiumPlayer extends StatefulWidget {
  final Song? song;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onTap;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onClose;
  final double progress; // 0.0 to 1.0
  final Offset initialPosition;
  final Function(Offset)? onPositionChanged;

  const FloatingPremiumPlayer({
    Key? key,
    required this.song,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onTap,
    this.onNext,
    this.onPrevious,
    this.onClose,
    this.progress = 0.0,
    this.initialPosition = const Offset(10, 100),
    this.onPositionChanged,
  }) : super(key: key);

  @override
  State<FloatingPremiumPlayer> createState() => _FloatingPremiumPlayerState();
}

class _FloatingPremiumPlayerState extends State<FloatingPremiumPlayer>
    with TickerProviderStateMixin {
  late Offset _position;
  bool _isExpanded = false;
  bool _showControls = true;
  AnimationController? _pulseController;
  AnimationController? _rotationController;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _initControllers();
  }

  void _initControllers() {
    _pulseController?.dispose();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotationController?.dispose();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    
    if (widget.isPlaying) {
      _rotationController?.repeat();
    }
  }

  @override
  void didUpdateWidget(FloatingPremiumPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _rotationController?.repeat();
      } else {
        _rotationController?.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _pulseController = null;
    _rotationController?.dispose();
    _rotationController = null;
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.song == null) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;
    final playerWidth = _isExpanded ? 320.0 : 200.0;
    final playerHeight = _isExpanded ? 180.0 : 80.0;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(0.0, screenSize.width - playerWidth),
              (_position.dy + details.delta.dy).clamp(0.0, screenSize.height - playerHeight),
            );
          });
        },
        onPanEnd: (details) {
          // Snap to edges
          setState(() {
            double newX = _position.dx;
            if (_position.dx < screenSize.width / 2) {
              newX = 10;
            } else {
              newX = screenSize.width - playerWidth - 10;
            }
            _position = Offset(newX, _position.dy);
          });
          widget.onPositionChanged?.call(_position);
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _showControls = true),
          onExit: (_) => setState(() => _showControls = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: playerWidth,
            height: playerHeight,
            child: Stack(
              children: [
                // Glassmorphism background
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Content
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _isExpanded
                            ? _buildExpandedContent()
                            : _buildCompactContent(),
                      ),
                    ),
                  ),
                ),

                // Progress indicator at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFFF2B84B),
                      ),
                      minHeight: 3,
                    ),
                  ),
                ),

                // Expand/Collapse button
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildControlButton(
                          icon: _isExpanded ? Icons.unfold_less : Icons.unfold_more,
                          onPressed: _toggleExpanded,
                        ),
                        if (widget.onClose != null) ...[
                          const SizedBox(width: 4),
                          _buildControlButton(
                            icon: Icons.close,
                            onPressed: widget.onClose!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Playing animation indicator
                if (widget.isPlaying && _pulseController != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: AnimatedBuilder(
                      animation: _pulseController!,
                      builder: (context, child) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF2B84B),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF2B84B).withOpacity(
                                  0.5 + (_pulseController!.value * 0.5),
                                ),
                                blurRadius: 8 + (_pulseController!.value * 4),
                                spreadRadius: 2 + (_pulseController!.value * 2),
                              ),
                            ],
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
    );
  }

  Widget _buildCompactContent() {
    return Row(
      children: [
        // Album art with shimmer effect and rotation
        AnimatedBuilder(
          animation: _rotationController ?? AlwaysStoppedAnimation(0),
          builder: (context, child) {
            return Transform.rotate(
              angle: (_rotationController?.value ?? 0) * 2 * 3.14159,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF2B84B).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.song!.albumArtUrl != null && widget.song!.albumArtUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.song!.albumArtUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildDefaultAlbumArt(),
                          errorWidget: (context, url, error) => _buildDefaultAlbumArt(),
                        )
                      : _buildDefaultAlbumArt(),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        
        // Song info
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.song!.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.song!.artist,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        
        // Play/Pause button
        _buildPlayButton(),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        const SizedBox(height: 24), // Space for controls
        
        // Album art (larger) with rotation
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: _rotationController ?? AlwaysStoppedAnimation(0),
              builder: (context, child) {
                return Transform.rotate(
                  angle: (_rotationController?.value ?? 0) * 2 * 3.14159,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF2B84B).withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.song!.albumArtUrl != null && widget.song!.albumArtUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.song!.albumArtUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => _buildDefaultAlbumArt(),
                              errorWidget: (context, url, error) => _buildDefaultAlbumArt(),
                            )
                          : _buildDefaultAlbumArt(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Song info
        Text(
          widget.song!.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 4,
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          widget.song!.artist,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13,
            shadows: const [
              Shadow(
                color: Colors.black54,
                blurRadius: 4,
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        // Playback controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.onPrevious != null)
              _buildControlButton(
                icon: Icons.skip_previous,
                onPressed: widget.onPrevious!,
                size: 28,
              ),
            const SizedBox(width: 16),
            _buildPlayButton(size: 40),
            const SizedBox(width: 16),
            if (widget.onNext != null)
              _buildControlButton(
                icon: Icons.skip_next,
                onPressed: widget.onNext!,
                size: 28,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayButton({double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF2B84B),
            Color(0xFFF2B84B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2B84B).withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPlayPause,
          customBorder: const CircleBorder(),
          child: Icon(
            widget.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.black87,
            size: size * 0.6,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 24,
  }) {
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.7,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAlbumArt() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF2B84B).withOpacity(0.3),
            const Color(0xFFF2B84B).withOpacity(0.3),
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white70,
        size: 32,
      ),
    );
  }
}
