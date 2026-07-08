import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart' as p;
import 'package:cached_network_image/cached_network_image.dart';
import '../constants.dart';

import '../models.dart';
import '../services/music_service.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/vibrant_card.dart';
class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({Key? key}) : super(key: key);

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _toastAnimationController;
  late AnimationController _dotsAnimationController;
  late AnimationController _artRotationController;
  late AnimationController _ledPulseController;
  late AnimationController _strobeController;
  late AnimationController _glowController;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  int? _currentlyPlayingIndex;
  OverlayEntry? _overlayEntry;

  Timer? _playbackTimeoutTimer;

  double _manualRotation = 0.0;
  bool _isScratching = false;
  double _rotationOnPanStart = 0.0;
  bool _isTouching = false;

  bool _karaokeMode = true;
  double _lyricsFontSize = 18.0;

  // Branding colors
  static const Color brandYellow = Color(0xFFF2B84B);
  static const Color brandBlack = Color(0xFF0B0B0B);
  static const Color cardColor = Color(0xFF0A0A0B);
  static const Color textColor = Colors.white;
  static const Color subtitleColor = Colors.white70;
  static const Color accentColor = Color(0xFF222222);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _toastAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _dotsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _artRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _ledPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.6,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _strobeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    final musicService = p.Provider.of<MusicService>(context, listen: false);
    _currentlyPlayingIndex = musicService.currentIndex;

    // UI-level state listener and watchdog (extra safety)
    _playerStateSub = musicService.playerStateStream.listen((state) {
      if (!mounted) return;
      final newIndex = musicService.currentIndex;
      final bool songChanged = newIndex != _currentlyPlayingIndex;
      _currentlyPlayingIndex = newIndex;

      if (songChanged) {
        try {
          musicService.player.play();
        } catch (_) {}

        _playbackTimeoutTimer?.cancel();
        _playbackTimeoutTimer = Timer(const Duration(seconds: 3), () {
          final currentState = musicService.player.playerState;
          if (!currentState.playing && currentState.processingState != ProcessingState.buffering) {
            final queue = musicService.currentQueue;
            final idx = musicService.currentIndex;
            final hasNext = idx != null && idx < queue.length - 1;
            if (hasNext) {
              musicService.playNext();
              _showPremiumToast(context, 'Skipping track — failed to start.');
            } else {
              _showPremiumToast(context, 'Unable to play track.');
            }
          }
        });
      }

      if (state.playing && state.processingState != ProcessingState.buffering) {
        if (!_artRotationController.isAnimating && !_isScratching) {
          _artRotationController.repeat();
        }
      } else {
        if (!_isScratching) _artRotationController.stop();
      }
    });

    // Playback error handling (UI-level)
    musicService.player.playbackEventStream.listen((_) {}, onError: (Object e, [StackTrace? s]) {
      if (!mounted) return;
      final currentIndex = musicService.currentIndex;
      final queue = musicService.currentQueue;
      final hasNext = currentIndex != null && currentIndex < queue.length - 1;
      if (hasNext) {
        musicService.playNext();
        _showPremiumToast(context, 'Track failed — playing next track.');
      } else {
        _showPremiumToast(context, 'Playback error.');
      }
    });

    _positionSub = musicService.positionStream.listen((_) {});
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _toastAnimationController.dispose();
    _dotsAnimationController.dispose();
    _artRotationController.dispose();
    _ledPulseController.dispose();
    _strobeController.dispose();
    _glowController.dispose();
    _overlayEntry?.remove();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _playbackTimeoutTimer?.cancel();
    super.dispose();
  }

  void _showPremiumToast(BuildContext context, String message) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).size.height * 0.15,
        left: MediaQuery.of(context).size.width * 0.12,
        right: MediaQuery.of(context).size.width * 0.12,
        child: PremiumToast(
          animation: _toastAnimationController,
          message: message,
          primaryColor: brandYellow,
          secondaryColor: brandBlack,
        ),
      ),
    );

    Overlay.of(context)?.insert(_overlayEntry!);
    _toastAnimationController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _toastAnimationController.reverse().then((_) {
          _overlayEntry?.remove();
          _overlayEntry = null;
        });
      }
    });
  }

  Widget _buildNeumorphicButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
    double size = 32,
    bool isMain = false,
    bool isActive = false,
  }) {
    return Container(
      width: isMain ? 78 : 52,
      height: isMain ? 78 : 52,
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            offset: const Offset(6, 6),
            blurRadius: 20,
          ),
          BoxShadow(
            color: brandYellow.withOpacity(0.06),
            offset: const Offset(-6, -6),
            blurRadius: 18,
          ),
        ],
      ),
      child: Center(
        child: isMain
            ? Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [brandYellow, brandYellow.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: brandYellow.withOpacity(0.75),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: brandBlack),
            iconSize: isMain ? 36 : size,
            onPressed: onTap,
          ),
        )
            : isActive
            ? ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [brandYellow, Colors.orangeAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            iconSize: size,
            onPressed: onTap,
          ),
        )
            : IconButton(
          icon: Icon(icon, color: iconColor),
          iconSize: size,
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _buildNowPlayingTab(MusicService musicService) {
    final currentSong = musicService.currentSong;
    if (currentSong == null) {
      return const Center(child: Text('No song selected', style: TextStyle(color: subtitleColor)));
    }

    // Precache album art
    precacheImage(NetworkImage(currentSong.albumArtUrl), context).catchError((_) {});

    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF070707), Color(0xFF0A0A0B)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final double artSize = (screenWidth * 0.75).clamp(260.0, 440.0);

                    final double autoRotationAngle = _artRotationController.value * 2 * math.pi;
                    final double combinedAngle = _isScratching ? _manualRotation : autoRotationAngle + _manualRotation;

                    return GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _isScratching = true;
                          _isTouching = true;
                          _rotationOnPanStart = _manualRotation;
                          _artRotationController.stop();
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _manualRotation = _rotationOnPanStart + details.delta.dx * 0.02;
                          final musicPosition = musicService.player.position;
                          final duration = musicService.duration;
                          if (duration.inMilliseconds > 0) {
                            final percentDelta = (details.delta.dx * 0.02) / (2 * math.pi);
                            final newMs = (musicPosition.inMilliseconds + (percentDelta * duration.inMilliseconds)).toInt();
                            final newPos = Duration(milliseconds: newMs.clamp(0, duration.inMilliseconds));
                            musicService.seekToPosition(newPos);
                          }
                        });
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _isScratching = false;
                          _isTouching = false;
                        });
                        final controllerValue = (_artRotationController.value + (_manualRotation / (2 * math.pi))) % 1.0;
                        _artRotationController.value = controllerValue;
                        _artRotationController.repeat();
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Starfield background
                          Container(
                            width: artSize + 80,
                            height: artSize + 80,
                            child: CustomPaint(
                              painter: StarfieldPainter(
                                starCount: 150,
                                brightness: _glowController.value,
                              ),
                            ),
                          ),

                          // Outer glow effect when touching
                          if (_isTouching)
                            AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) {
                                return Container(
                                  width: artSize + 70,
                                  height: artSize + 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: brandYellow.withOpacity(0.8 * _glowController.value),
                                        blurRadius: 30,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                          // Outer platter rim with enhanced details
                          Container(
                            width: artSize + 46,
                            height: artSize + 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [Colors.black.withOpacity(0.98), Colors.black.withOpacity(0.7), brandYellow.withOpacity(0.03)],
                                stops: const [0.0, 0.8, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.9),
                                  blurRadius: 36,
                                  spreadRadius: 6,
                                ),
                                BoxShadow(
                                  color: brandYellow.withOpacity(0.04),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              painter: PlatterRimPainter(
                                accentColor: brandYellow,
                                pulseValue: _ledPulseController.value,
                              ),
                            ),
                          ),

                          // Rotating platter with enhanced vinyl details
                          Transform.rotate(
                            angle: combinedAngle,
                            child: Container(
                              width: artSize,
                              height: artSize,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Enhanced vinyl record
                                  CustomPaint(
                                    size: Size(artSize, artSize),
                                    painter: VinylRecordPainter(
                                      outerGlow: true,
                                      grooveDensity: 40,
                                      yellowTint: brandYellow,
                                      strobeValue: _strobeController.value,
                                    ),
                                  ),

                                  // Album art with enhanced frame
                                  Container(
                                    width: artSize * 0.58,
                                    height: artSize * 0.58,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [Colors.black.withOpacity(0.35), Colors.black.withOpacity(0.05), Colors.transparent],
                                        stops: const [0.0, 0.65, 1.0],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: currentSong.albumArtUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: accentColor,
                                          child: const Center(child: CircularProgressIndicator(color: brandYellow)),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: accentColor,
                                          child: Icon(Icons.music_note, color: brandYellow.withOpacity(0.85), size: 80),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Enhanced center spindle
                                  Container(
                                    width: artSize * 0.07,
                                    height: artSize * 0.07,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                      border: Border.all(color: brandYellow.withOpacity(0.95), width: 5),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.9), blurRadius: 10),
                                        BoxShadow(color: brandYellow.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Enhanced LED ring with more dynamic effects
                          SizedBox(
                            width: artSize + 10,
                            height: artSize + 10,
                            child: CustomPaint(
                              painter: LedRingPainter(
                                pulse: _ledPulseController.value,
                                dotCount: 48,
                                color: brandYellow,
                                playing: musicService.isPlaying,
                                strobe: _strobeController.value,
                              ),
                            ),
                          ),

                          // Enhanced DJ badge with pulsing effect
                          Positioned(
                            bottom: artSize * -0.08,
                            child: AnimatedBuilder(
                              animation: _ledPulseController,
                              builder: (context, child) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: brandYellow.withOpacity(0.25 + 0.25 * _ledPulseController.value)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: brandYellow.withOpacity(0.3 * _ledPulseController.value),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                      BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 12),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.turned_in_not, color: brandYellow, size: 18),
                                      const SizedBox(width: 8),
                                      Text('DJ MODE', style: TextStyle(color: brandYellow, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // Song Info with enhanced styling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: brandYellow.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: brandYellow.withOpacity(0.18)),
                      ),
                      child: const Text(
                        'PREMIUM PLAYBACK',
                        style: TextStyle(
                          color: brandYellow,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  currentSong.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.08,
                    letterSpacing: -0.4,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  currentSong.artist,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.74),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildInfoChip(Icons.graphic_eq_rounded, 'Hi-Fi vibe'),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.album_rounded, 'Immersive player'),
                  ],
                ),
                const SizedBox(height: 14),
                _buildProgressBar(musicService),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: brandYellow),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(MusicService musicService) {
    return StreamBuilder<Duration>(
      stream: musicService.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = musicService.duration;
        double sliderValue = (position.inSeconds > duration.inSeconds || duration.inSeconds == 0) ? 0.0 : position.inSeconds.toDouble();
        double maxSliderValue = duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                trackHeight: 5.0,
                activeTrackColor: const Color(0xFFF2B84B),
                inactiveTrackColor: Colors.white12,
                thumbColor: const Color(0xFFC8901F),
                overlayColor: const Color(0xFFC8901F).withOpacity(0.2),
              ),
                    child: Slider(
                      value: sliderValue,
                      max: maxSliderValue,
                      onChanged: (value) {
                        musicService.seekToPosition(Duration(seconds: value.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position), style: const TextStyle(color: subtitleColor, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(_formatDuration(duration), style: const TextStyle(color: subtitleColor, fontSize: 13, fontWeight: FontWeight.w600))
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLyricsTab(MusicService musicService) {
    final lyricsRaw = musicService.currentSong?.lyrics ?? "No lyrics available for this song.";
    final lines = <String>[];
    final timestamps = <Duration?>[];

    final regex = RegExp(r'^\s*\[(\d{1,2}):(\d{1,2})(?:\.(\d{1,2}))?\]\s*(.*)$');
    for (final raw in lyricsRaw.split('\n')) {
      final m = regex.firstMatch(raw);
      if (m != null) {
        final mm = int.tryParse(m.group(1) ?? '0') ?? 0;
        final ss = int.tryParse(m.group(2) ?? '0') ?? 0;
        final ms = int.tryParse((m.group(3) ?? '0').padRight(2, '0')) ?? 0;
        final dur = Duration(minutes: mm, seconds: ss, milliseconds: ms * 10);
        lines.add(m.group(4) ?? '');
        timestamps.add(dur);
      } else {
        lines.add(raw.trim());
        timestamps.add(null);
      }
    }

    final hasTimestamps = timestamps.any((t) => t != null);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B0B0B), Color(0xFF111111)]),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [const Icon(Icons.music_note, color: brandYellow), const SizedBox(width: 8), Text('Lyrics', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold))]),
              Row(
                children: [
                  IconButton(icon: Icon(_karaokeMode ? Icons.closed_caption : Icons.closed_caption_off, color: subtitleColor), onPressed: () => setState(() => _karaokeMode = !_karaokeMode)),
                  IconButton(icon: Icon(Icons.text_fields, color: subtitleColor), onPressed: () => setState(() => _lyricsFontSize = (_lyricsFontSize >= 26.0) ? 18.0 : _lyricsFontSize + 2.0)),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (musicService.currentSong?.albumArtUrl != null)
                    CachedNetworkImage(
                      imageUrl: musicService.currentSong!.albumArtUrl,
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.black.withOpacity(0.48))),
                      ),
                      placeholder: (context, url) => Container(color: Colors.black.withOpacity(0.6)),
                      errorWidget: (context, url, error) => Container(color: Colors.black.withOpacity(0.6)),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                    child: StreamBuilder<Duration>(
                      stream: musicService.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        int currentIndex = 0;
                        if (hasTimestamps) {
                          for (int i = 0; i < timestamps.length; i++) {
                            final ts = timestamps[i];
                            if (ts == null) continue;
                            if (position >= ts) currentIndex = i;
                          }
                        } else {
                          final durationMs = musicService.duration.inMilliseconds > 0 ? musicService.duration.inMilliseconds : 1;
                          final pct = position.inMilliseconds / durationMs;
                          currentIndex = (pct * (lines.length - 1)).round().clamp(0, lines.length - 1);
                        }

                        return ListView.builder(
                          itemCount: lines.length,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          itemBuilder: (context, index) {
                            final line = lines[index];
                            final isActive = index == currentIndex && _karaokeMode;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                              margin: EdgeInsets.symmetric(vertical: isActive ? 8 : 6),
                              padding: EdgeInsets.symmetric(horizontal: isActive ? 12 : 8, vertical: isActive ? 12 : 8),
                              decoration: BoxDecoration(
                                color: isActive ? brandYellow.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: isActive ? Border.all(color: brandYellow.withOpacity(0.6), width: 1.2) : null,
                              ),
                              child: Text(line.isEmpty ? ' ' : line, textAlign: TextAlign.center, style: TextStyle(color: isActive ? brandYellow : Colors.white70, fontSize: _lyricsFontSize, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400, height: 1.6)),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueTab(MusicService musicService) {
    final queue = musicService.currentQueue;
    if (queue.isEmpty) return const Center(child: Text("Queue is empty", style: TextStyle(color: subtitleColor)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: queue.length,
      itemBuilder: (context, index) {
        final song = queue[index];
        final bool isCurrent = musicService.currentIndex == index;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
              color: isCurrent ? brandYellow.withOpacity(0.06) : cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isCurrent ? brandYellow.withOpacity(0.85) : Colors.transparent, width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.24), blurRadius: 8, offset: const Offset(0, 2))
              ]
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                    imageUrl: song.albumArtUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover
                )
            ),
            title: Text(
                song.title,
                style: TextStyle(
                    color: isCurrent ? brandYellow : textColor,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal
                )
            ),
            subtitle: Text(song.artist, style: const TextStyle(color: subtitleColor)),
            trailing: isCurrent ? Icon(Icons.equalizer, color: brandYellow, size: 20) : null,
            onTap: () async {
              try {
                await musicService.playSong(song, queue, initialIndex: index);
              } catch (_) {
                musicService.playSong(song, queue, initialIndex: index);
              }
              _tabController.animateTo(0);
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaybackControls(MusicService musicService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.05),
            cardColor,
            const Color(0xFF0D0D0D),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 6,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNeumorphicButton(
                    icon: musicService.isShuffling ? Icons.shuffle_on : Icons.shuffle,
                    onTap: () => musicService.toggleShuffle(),
                    iconColor: musicService.isShuffling ? brandYellow : subtitleColor,
                    size: 24,
                    isActive: musicService.isShuffling
                ),
                _buildNeumorphicButton(
                    icon: Icons.skip_previous_rounded,
                    onTap: () {
                      final currentIndex = musicService.currentIndex;
                      final queue = musicService.currentQueue;
                      final hasPrevious = currentIndex != null && currentIndex > 0;
                      if (hasPrevious) musicService.playPrevious();
                      else _showPremiumToast(context, 'Start of queue');
                    },
                    iconColor: textColor,
                    size: 30
                ),
                StreamBuilder<PlayerState>(
                    stream: musicService.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final isPlaying = playerState?.playing ?? false;
                      final processingState = playerState?.processingState;
                      if (processingState != ProcessingState.ready) {
                        return SizedBox(width: 78, height: 78, child: Center(child: CircularProgressIndicator(color: brandYellow, strokeWidth: 4)));
                      }
                      return _buildNeumorphicButton(
                          icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          onTap: musicService.togglePlayPause,
                          iconColor: Colors.white,
                          isMain: true
                      );
                    }
                ),
                _buildNeumorphicButton(
                    icon: Icons.skip_next_rounded,
                    onTap: () {
                      final currentIndex = musicService.currentIndex;
                      final queue = musicService.currentQueue;
                      final hasNext = currentIndex != null && currentIndex < queue.length - 1;
                      if (hasNext) musicService.playNext();
                      else _showPremiumToast(context, 'End of queue');
                    },
                    iconColor: textColor,
                    size: 30
                ),
                _buildNeumorphicButton(
                    icon: musicService.loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                    onTap: () => musicService.toggleLoop(),
                    iconColor: musicService.loopMode != LoopMode.off ? brandYellow : subtitleColor,
                    size: 24,
                    isActive: musicService.loopMode != LoopMode.off
                ),
              ]
          ),
          const SizedBox(height: 10),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: brandYellow.withOpacity(0.12))
                    ),
                    child: AnimatedBuilder(
                      animation: _ledPulseController,
                      builder: (context, child) {
                        final pct = _ledPulseController.value;
                        return Row(children: List.generate(10, (i) {
                          final active = pct * 10 > i;
                          return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 4), decoration: BoxDecoration(color: active ? brandYellow : Colors.white10, borderRadius: BorderRadius.circular(2))));
                        }));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${musicService.currentQueue.length} in queue', style: const TextStyle(color: subtitleColor)),
                ]),
                Row(children: [
                  if (musicService.currentSong != null)
                    SizedBox(
                        width: 36,
                        height: 36,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                                imageUrl: musicService.currentSong!.albumArtUrl,
                                fit: BoxFit.cover
                            )
                        )
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.white70),
                      onPressed: () => _showMoreOptions(context, musicService)
                  ),
                ])
              ]
          )
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context, MusicService musicService) {
    final song = musicService.currentSong;
    if (song == null) {
      _showPremiumToast(context, 'No song selected.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(color: cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Wrap(children: [
            _buildMoreOptionItem(icon: Icons.file_download, title: 'Download', onTap: () {
              Navigator.of(ctx).pop();
              _downloadSong(song);
            }),
            _buildMoreOptionItem(icon: Icons.info_outline, title: 'Song metrics', onTap: () {
              Navigator.of(ctx).pop();
              _showSongMetrics(context, musicService);
            }),
            _buildMoreOptionItem(icon: Icons.queue_music, title: 'Add to queue', onTap: () {
              Navigator.of(ctx).pop();
              musicService.addToQueue(song);
              _showPremiumToast(context, 'Added to queue');
            }),
            _buildMoreOptionItem(icon: Icons.close, title: 'Close', onTap: () {
              Navigator.of(ctx).pop();
            }),
          ]),
        );
      },
    );
  }

  Widget _buildMoreOptionItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
        leading: Icon(icon, color: brandYellow),
        title: Text(title, style: const TextStyle(color: textColor)),
        onTap: onTap
    );
  }

  void _downloadSong(Song song) {
    _showPremiumToast(context, 'Downloading "${song.title}" ...');
    Future.delayed(const Duration(seconds: 1), () => _showPremiumToast(context, 'Download complete'));
  }

  void _showSongMetrics(BuildContext context, MusicService musicService) {
    final song = musicService.currentSong;
    if (song == null) return;
    final Duration songDuration = _getSongDuration(song, musicService);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text('Song Metrics', style: const TextStyle(color: textColor)),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMetricCard(title: 'Downloads', value: song.downloads.toString(), icon: Icons.file_download),
                const SizedBox(height: 8),
                _buildMetricCard(title: 'Likes', value: song.likes.toString(), icon: Icons.favorite_border),
                const SizedBox(height: 8),
                _buildMetricCard(title: 'Duration', value: _formatDuration(songDuration), icon: Icons.timer),
              ]
          ),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
        );
      },
    );
  }

  Duration _getSongDuration(Song song, MusicService musicService) {
    final dynamic s = song;
    try {
      final dyn = s.duration;
      if (dyn is Duration) return dyn;
      if (dyn is int) return Duration(milliseconds: dyn);
      if (dyn is double) return Duration(milliseconds: dyn.toInt());
      if (dyn is String) {
        final mmss = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(dyn);
        if (mmss != null) {
          final mm = int.tryParse(mmss.group(1)!) ?? 0;
          final ss = int.tryParse(mmss.group(2)!) ?? 0;
          return Duration(minutes: mm, seconds: ss);
        }
        final parsed = int.tryParse(dyn);
        if (parsed != null) return Duration(milliseconds: parsed);
      }
    } catch (_) {}
    try {
      final alt = s.durationMs ?? s.duration_ms ?? s.lengthMs ?? s.length_ms ?? s.lengthSeconds ?? s.durationSeconds ?? s.length;
      if (alt is int) {
        if (alt < 10000) return Duration(seconds: alt);
        return Duration(milliseconds: alt);
      }
      if (alt is double) return Duration(milliseconds: alt.toInt());
      if (alt is String) {
        final parsed = int.tryParse(alt);
        if (parsed != null) return Duration(milliseconds: parsed);
      }
    } catch (_) {}
    try {
      final playerDur = musicService.duration;
      if (playerDur != Duration.zero) return playerDur;
    } catch (_) {}
    return Duration.zero;
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Icon(icon, color: brandYellow),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: textColor, fontWeight: FontWeight.bold))
            ]
        ))
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicService = p.Provider.of<MusicService>(context);
    final currentSong = musicService.currentSong;

    return Scaffold(
      backgroundColor: brandBlack,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF050505),
                    const Color(0xFF0C0C0C),
                    brandBlack,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brandYellow.withOpacity(0.14),
                    brandYellow.withOpacity(0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 140,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textColor, size: 30),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          currentSong == null ? 'PLAYER' : 'NOW PLAYING',
                          style: TextStyle(
                            color: brandYellow.withOpacity(0.82),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Viba Music',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    AnimatedBuilder(
                      animation: _dotsAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_dotsAnimationController.value * 0.06),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.more_vert, color: brandYellow, size: 26),
                              onPressed: () => _showMoreOptions(context, musicService),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [Tab(text: 'PLAYER'), Tab(text: 'LYRICS'), Tab(text: 'QUEUE')],
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          brandYellow.withOpacity(0.18),
                          brandYellow.withOpacity(0.08),
                        ],
                      ),
                      border: Border.all(color: brandYellow.withOpacity(0.18)),
                    ),
                    indicatorPadding: const EdgeInsets.all(6),
                    labelColor: brandYellow,
                    unselectedLabelColor: subtitleColor,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    dividerColor: Colors.transparent,
                  ),
                ),
              ),
              Expanded(
                child: currentSong == null
                    ? const Center(child: Text("Select a song to play", style: TextStyle(color: subtitleColor)))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNowPlayingTab(musicService),
                          _buildLyricsTab(musicService),
                          _buildQueueTab(musicService)
                        ],
                      ),
              ),
              if (currentSong != null) _buildPlaybackControls(musicService),
            ]),
          ),
        ],
      ),
    );
  }
}

// --- CUSTOM WIDGETS ---

class PremiumToast extends StatelessWidget {
  const PremiumToast({Key? key, required this.animation, required this.message, required this.primaryColor, required this.secondaryColor}) : super(key: key);

  final Animation<double> animation;
  final String message;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.elasticOut)),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
                color: message.startsWith('Unable') ? const Color(0xFFE63950) : primaryColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: (message.startsWith('Unable') ? const Color(0xFFE63950) : primaryColor).withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2
                  )
                ]
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    message.startsWith('Unable') ? Icons.error_outline : Icons.info_outline,
                    color: message.startsWith('Unable') ? Colors.white : secondaryColor
                ),
                const SizedBox(width: 12),
                Flexible(
                    child: Text(
                        message,
                        style: TextStyle(
                            color: message.startsWith('Unable') ? Colors.white : secondaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                        ),
                        textAlign: TextAlign.center
                    )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Starfield background painter
class StarfieldPainter extends CustomPainter {
  final int starCount;
  final double brightness;

  StarfieldPainter({this.starCount = 100, this.brightness = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF050510);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final random = math.Random(42);
    final starPaint = Paint()..color = Colors.white;

    for (int i = 0; i < starCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5;
      final opacity = 0.3 + random.nextDouble() * 0.7 * brightness;

      starPaint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, starPaint);

      // Add glow to some stars
      if (random.nextDouble() > 0.8) {
        final glowPaint = Paint()
          ..color = Colors.white.withOpacity(opacity * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(x, y), radius * 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Enhanced Platter Rim Painter
class PlatterRimPainter extends CustomPainter {
  final Color accentColor;
  final double pulseValue;

  PlatterRimPainter({required this.accentColor, this.pulseValue = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw outer rim with metallic gradient
    final rimPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.black.withOpacity(0.9),
          accentColor.withOpacity(0.2 * pulseValue),
          Colors.black.withOpacity(0.9),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, rimPaint);

    // Draw metallic details
    final detailPaint = Paint()
      ..color = accentColor.withOpacity(0.15 * pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 24; i++) {
      final angle = (2 * math.pi / 24) * i;
      final innerRadius = radius * 0.92;
      final outerRadius = radius * 0.98;

      final x1 = center.dx + innerRadius * math.cos(angle);
      final y1 = center.dy + innerRadius * math.sin(angle);
      final x2 = center.dx + outerRadius * math.cos(angle);
      final y2 = center.dy + outerRadius * math.sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), detailPaint);
    }

    // Draw additional metallic rings
    for (int i = 0; i < 3; i++) {
      final ringRadius = radius * (0.95 - i * 0.03);
      final ringPaint = Paint()
        ..color = accentColor.withOpacity(0.1 * pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawCircle(center, ringRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Enhanced Vinyl Record Painter
class VinylRecordPainter extends CustomPainter {
  final bool outerGlow;
  final int grooveDensity;
  final Color yellowTint;
  final double strobeValue;

  VinylRecordPainter({
    this.outerGlow = false,
    this.grooveDensity = 40,
    this.yellowTint = Colors.amber,
    this.strobeValue = 1.0
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw base vinyl with gradient
    final paint = Paint()
      ..shader = RadialGradient(
          colors: [
            const Color(0xFF050505),
            const Color(0xFF0E0E0E),
            const Color(0xFF171717),
          ],
          stops: const [0.0, 0.6, 1.0]
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);

    // Draw grooves with enhanced details
    final groovePaint = Paint()
      ..color = Colors.black.withOpacity(0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    for (int i = 0; i < grooveDensity; i++) {
      final r = radius * (0.9 - (i / (grooveDensity * 1.05)));
      canvas.drawCircle(center, r, groovePaint);

      if (i % 4 == 0) {
        final highlight = Paint()
          ..color = yellowTint.withOpacity(0.02 * strobeValue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9;
        canvas.drawCircle(center, r - (radius * 0.004), highlight);
      }
    }

    // Draw concentric circles for more realistic vinyl look
    for (int i = 0; i < 8; i++) {
      final circleRadius = radius * (0.85 - i * 0.08);
      final circlePaint = Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(center, circleRadius, circlePaint);
    }

    // Draw center label with enhanced styling
    final labelPaint = Paint()
      ..color = const Color(0xFF0C0C0C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.36, labelPaint);

    // Draw label details
    final labelDetailPaint = Paint()
      ..color = yellowTint.withOpacity(0.08 * strobeValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius * 0.37, labelDetailPaint);

    // Draw center hole
    final holePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.04, holePaint);

    // Draw center spindle with enhanced details
    final spindlePaint = Paint()
      ..color = yellowTint.withOpacity(0.6 * strobeValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.05, spindlePaint);

    // Draw outer glow if enabled
    if (outerGlow) {
      final rimPaint = Paint()
        ..shader = SweepGradient(
            colors: [
              yellowTint.withOpacity(0.06 * strobeValue),
              Colors.transparent,
              yellowTint.withOpacity(0.02 * strobeValue)
            ]
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius - (radius * 0.015), rimPaint);
    }

    // Draw radial highlights
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.1 * strobeValue),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
        center: const Alignment(0.3, 0.3),
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.7));
    canvas.drawCircle(center, radius * 0.7, highlightPaint);

    // Draw texture lines for more realistic vinyl look
    final texturePaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;

    for (int i = 0; i < 120; i++) {
      final angle = (2 * math.pi / 120) * i;
      final startRadius = radius * 0.4;
      final endRadius = radius * 0.95;

      final x1 = center.dx + startRadius * math.cos(angle);
      final y1 = center.dy + startRadius * math.sin(angle);
      final x2 = center.dx + endRadius * math.cos(angle);
      final y2 = center.dy + endRadius * math.sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), texturePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Enhanced LED Ring Painter
class LedRingPainter extends CustomPainter {
  final double pulse;
  final int dotCount;
  final Color color;
  final bool playing;
  final double strobe;

  LedRingPainter({
    required this.pulse,
    this.dotCount = 48,
    this.color = Colors.yellow,
    this.playing = false,
    this.strobe = 1.0
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final dotRadius = 4.0;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * math.pi / dotCount) * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      final t = (i / dotCount);

      // Enhanced brightness calculation with strobe effect
      double intensity;
      if (playing) {
        intensity = (0.7 + pulse * 0.3) * (0.6 + 0.4 * (0.5 + 0.5 * math.sin(2 * math.pi * t + pulse * 2 * math.pi))) * strobe;
      } else {
        intensity = 0.3;
      }

      paint.color = color.withOpacity(intensity.clamp(0.1, 1.0));

      // Draw LED with glow effect
      canvas.drawCircle(Offset(x, y), dotRadius, paint);

      // Enhanced glow effect
      final glowPaint = Paint()
        ..color = color.withOpacity(intensity * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), dotRadius * 2, glowPaint);
    }

    // Draw connecting lines between LEDs for a more professional look
    final linePaint = Paint()
      ..color = color.withOpacity(0.2 * strobe)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < dotCount; i++) {
      final angle1 = (2 * math.pi / dotCount) * i;
      final angle2 = (2 * math.pi / dotCount) * ((i + 1) % dotCount);

      final x1 = center.dx + radius * math.cos(angle1);
      final y1 = center.dy + radius * math.sin(angle1);
      final x2 = center.dx + radius * math.cos(angle2);
      final y2 = center.dy + radius * math.sin(angle2);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant LedRingPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.playing != playing ||
        oldDelegate.strobe != strobe;
  }
}
