import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models.dart';

class FloatingPremiumVideoPlayer extends StatefulWidget {
  final MusicVideo video;
  final VideoPlayerController videoController;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onFullScreen;
  final VoidCallback onClose;
  final Offset initialPosition;
  final Function(Offset)? onPositionChanged;

  const FloatingPremiumVideoPlayer({
    Key? key,
    required this.video,
    required this.videoController,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onFullScreen,
    required this.onClose,
    this.initialPosition = const Offset(10, 100),
    this.onPositionChanged,
  }) : super(key: key);

  @override
  State<FloatingPremiumVideoPlayer> createState() =>
      _FloatingPremiumVideoPlayerState();
}

class _FloatingPremiumVideoPlayerState
    extends State<FloatingPremiumVideoPlayer>
    with SingleTickerProviderStateMixin {
  late Offset _position;
  bool _isMinimized = false;
  bool _showControls = true;
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _initPulseController();
  }

  void _initPulseController() {
    _pulseController?.dispose();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _pulseController = null;
    super.dispose();
  }

  void _toggleMinimized() {
    setState(() {
      _isMinimized = !_isMinimized;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final playerWidth = _isMinimized ? 180.0 : 320.0;
    final playerHeight = _isMinimized ? 120.0 : 200.0;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx)
                  .clamp(0.0, screenSize.width - playerWidth),
              (_position.dy + details.delta.dy)
                  .clamp(0.0, screenSize.height - playerHeight),
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
                // Glassmorphism background with video
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Video player
                      if (widget.videoController.value.isInitialized)
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: widget.videoController.value.size.width,
                              height: widget.videoController.value.size.height,
                              child: VideoPlayer(widget.videoController),
                            ),
                          ),
                        )
                      else
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: widget.video.thumbnailUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.black87,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFF2B84B),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.black87,
                              child: const Icon(
                                Icons.videocam,
                                color: Colors.white54,
                                size: 48,
                              ),
                            ),
                          ),
                        ),

                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Glassmorphism border
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 24,
                                  spreadRadius: 6,
                                ),
                                BoxShadow(
                                  color: const Color(0xFFF2B84B).withOpacity(0.2),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content overlay
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showControls = !_showControls;
                        });
                      },
                      child: Stack(
                        children: [
                          // Video info at top
                          if (!_isMinimized)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: AnimatedOpacity(
                                opacity: _showControls ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.video.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black87,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.video.artist,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black87,
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
                              ),
                            ),

                          // Center play button
                          Center(
                            child: AnimatedOpacity(
                              opacity: _showControls ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: _buildPlayButton(),
                            ),
                          ),

                          // Bottom controls
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: AnimatedOpacity(
                              opacity: _showControls ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Progress bar
                                    if (widget.videoController.value.isInitialized)
                                      VideoProgressIndicator(
                                        widget.videoController,
                                        allowScrubbing: true,
                                        padding: EdgeInsets.zero,
                                        colors: const VideoProgressColors(
                                          playedColor: Color(0xFFF2B84B),
                                          bufferedColor: Colors.white30,
                                          backgroundColor: Colors.white10,
                                        ),
                                      ),
                                    
                                    if (!_isMinimized) ...[
                                      const SizedBox(height: 8),
                                      // Time display
                                      if (widget.videoController.value.isInitialized)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatDuration(
                                                  widget.videoController.value.position,
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black87,
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                _formatDuration(
                                                  widget.videoController.value.duration,
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black87,
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top right controls
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
                          icon: _isMinimized
                              ? Icons.aspect_ratio
                              : Icons.picture_in_picture_alt,
                          onPressed: _toggleMinimized,
                        ),
                        const SizedBox(width: 4),
                        _buildControlButton(
                          icon: Icons.fullscreen,
                          onPressed: widget.onFullScreen,
                        ),
                        const SizedBox(width: 4),
                        _buildControlButton(
                          icon: Icons.close,
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ),
                ),

                // Playing indicator
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

  Widget _buildPlayButton() {
    return Container(
      width: 56,
      height: 56,
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
            color: const Color(0xFFF2B84B).withOpacity(0.6),
            blurRadius: 12,
            spreadRadius: 2,
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
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.5),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
