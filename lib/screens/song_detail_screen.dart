import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart' as p;
import 'package:amplify_music/services/music_service.dart';
import 'package:amplify_music/models.dart';
import '../utils/palette_stub.dart';
import '../utils/html.dart' as html; // Web-only shim (safe on mobile)
import 'artist_detail_screen.dart';
import '../constants.dart';
// import 'package:universal_html/html.dart' as html; // Web-only - commented for Android
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


import '../constants.dart';
// --- Constants ---
const Color primaryColor = Color(0xFFF2B84B);
const Color secondaryColor = Color(0xFF0A0A0B);
const Color cardColor = Color(0xFF211C16);
const Color textColor = Colors.white;
const Color subtitleColor = Colors.white70;

class SongDetailScreen extends StatefulWidget {
  final String songId;
  const SongDetailScreen({Key? key, required this.songId}) : super(key: key);

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Future<Map<String, dynamic>> _detailsFuture;
  late String _currentSongId;
  MusicService? _musicService;

  @override
  void initState() {
    super.initState();
    _currentSongId = widget.songId;
    _detailsFuture = _fetchSongAndArtistDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We listen to the MusicService to know when the song changes.
    final musicService = p.Provider.of<MusicService>(context, listen: false);
    if (_musicService != musicService) {
      _musicService?.removeListener(_onSongChanged);
      _musicService = musicService;
      _musicService?.addListener(_onSongChanged);
    }
  }

  @override
  void dispose() {
    _musicService?.removeListener(_onSongChanged);
    super.dispose();
  }

  // When the song changes in the service, we update the UI to show the new song.
  void _onSongChanged() {
    final newSong = _musicService?.currentSong;
    if (newSong != null && newSong.id != _currentSongId) {
      setState(() {
        _currentSongId = newSong.id;
        _detailsFuture = _fetchSongAndArtistDetails();
      });
    }
  }

  Future<Map<String, dynamic>> _fetchSongAndArtistDetails() async {
    try {
      // Step 1: Fetch the song details using the current song ID.
      final songResponse = await supabase.from('songs').select().eq('id', _currentSongId).single();
      final song = Song.fromMap(songResponse);

      // Step 2: Check if the song has an artist_id and fetch the artist if it does.
      Artist? artist;
      final artistId = songResponse['artist_id'];
      if (artistId != null) {
        final artistResponse = await supabase.from('artists').select().eq('id', artistId).maybeSingle();
        if (artistResponse != null) {
          artist = Artist.fromMap(artistResponse);
        }
      }

      // Step 3: Generate the color palette from the album art.
      final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(song.albumArtUrl),
        size: const Size(100, 100),
      );

      return {'song': song, 'artist': artist, 'palette': palette};

    } catch (e) {
      debugPrint("Error fetching song/artist details: $e");
      rethrow;
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showLyricsModal(BuildContext context, String lyrics, Color bgColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Lyrics', style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(lyrics, style: const TextStyle(color: textColor, fontSize: 16, height: 1.6), textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: primaryColor)))
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleShareTap(Song song) {
    final String shareUrl = 'https://amplifymusic.site/song/${song.id}';
    final String shareText = 'Check out "${song.title}" by ${song.artist} on Amplify Music!\n\n$shareUrl';
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Song link copied to clipboard!')),
    );
  }

  Future<void> _handleDownloadTap(Song song) async {
    final musicService = p.Provider.of<MusicService>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Starting download for "${song.title}"...')));

    if (kIsWeb) {
      try {
        final response = await http.get(Uri.parse(song.audioUrl));
        if (response.statusCode == 200) {
          final blob = html.Blob([response.bodyBytes], 'audio/mpeg');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)..setAttribute('download', '${song.title}.mp3');
          html.document.body?.append(anchor);
          anchor.click();
          anchor.remove();
          html.Url.revokeObjectUrl(url);
          await musicService.incrementDownloadCount(song);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } else {
      try {
        if (await Permission.storage.request().isGranted) {
          final directory = await getApplicationDocumentsDirectory();
          final savePath = '${directory.path}/${song.title}.mp3';
          await Dio().download(song.audioUrl, savePath);
          await musicService.incrementDownloadCount(song);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded to ${directory.path}')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: textColor)));
          }

          final song = snapshot.data!['song'] as Song;
          final artist = snapshot.data!['artist'] as Artist?;
          final palette = snapshot.data!['palette'] as PaletteGenerator;
          final dominantColor = palette.dominantColor?.color ?? secondaryColor;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [dominantColor.withOpacity(0.5), secondaryColor],
                stops: const [0.0, 0.6],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textColor, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: textColor),
                    color: cardColor,
                    onSelected: (value) {
                      switch (value) {
                        case 'download':
                          _handleDownloadTap(song);
                          break;
                        case 'artist':
                          if (artist != null && artist.id.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ArtistDetailScreen(artistId: artist.id)),
                            );
                          }
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'download',
                        child: Row(
                          children: [
                            Icon(Icons.download_outlined, color: textColor),
                            SizedBox(width: 16),
                            Text('Download', style: TextStyle(color: textColor)),
                          ],
                        ),
                      ),
                      if (artist != null)
                        const PopupMenuItem<String>(
                          value: 'artist',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, color: textColor),
                              SizedBox(width: 16),
                              Text('Go to Artist', style: TextStyle(color: textColor)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(),
                              Hero(
                                tag: 'album_art_${song.id}',
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 25, offset: const Offset(0, 8)),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 1,
                                          child: CachedNetworkImage(imageUrl: song.albumArtUrl, fit: BoxFit.cover),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.all(8.0),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.music_note_rounded, color: primaryColor, size: 12),
                                              SizedBox(width: 4),
                                              Text(
                                                'Viba Music',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
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
                              const SizedBox(height: 40),
                              Text(song.title, style: const TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  if (artist != null && artist.id.isNotEmpty) {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => ArtistDetailScreen(artistId: artist.id)));
                                  }
                                },
                                child: Text(song.artist, style: TextStyle(color: subtitleColor, fontSize: 16, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                              ),
                              const SizedBox(height: 30),
                              p.Consumer<MusicService>(
                                builder: (context, musicService, child) {
                                  return StreamBuilder<Duration>(
                                    // I'm assuming your MusicService has a 'positionStream'.
                                    // If it's named differently (e.g., 'onPositionChanged'), update it here.
                                      stream: musicService.positionStream,
                                      builder: (context, snapshot) {
                                        final position = snapshot.data ?? Duration.zero;
                                        final duration = musicService.duration;
                                        final sliderValue = (position.inSeconds > duration.inSeconds || duration.inSeconds == 0)
                                            ? 0.0
                                            : position.inSeconds.toDouble();

                                        return Column(
                                          children: [
                                            SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                                                trackHeight: 4.0,
                                              ),
                                              child: Slider(
                                                value: sliderValue,
                                                max: duration.inSeconds.toDouble(),
                                                onChanged: (value) {
                                                  musicService.seekToPosition(Duration(seconds: value.toInt()));
                                                },
                                                activeColor: textColor,
                                                inactiveColor: Colors.white.withOpacity(0.3),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(_formatDuration(position), style: const TextStyle(color: subtitleColor, fontSize: 12)),
                                                Text(_formatDuration(duration), style: const TextStyle(color: subtitleColor, fontSize: 12)),
                                              ],
                                            ),
                                          ],
                                        );
                                      }
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              p.Consumer<MusicService>(
                                builder: (context, musicService, child) {
                                  final isPlaying = musicService.isPlaying && musicService.currentSong?.id == song.id;
                                  final hasPrevious = musicService.currentIndex! > 0;
                                  final hasNext = musicService.currentQueue.isNotEmpty && musicService.currentIndex! < musicService.currentQueue.length - 1;

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.skip_previous_rounded,
                                          color: hasPrevious ? textColor : subtitleColor.withOpacity(0.5),
                                        ),
                                        iconSize: 36,
                                        onPressed: hasPrevious ? musicService.playPrevious : null,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                          color: textColor,
                                        ),
                                        iconSize: 70,
                                        onPressed: () {
                                          if (musicService.currentSong?.id != song.id) {
                                            musicService.playSong(song, [song]);
                                          } else {
                                            musicService.togglePlayPause();
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.skip_next_rounded,
                                          color: hasNext ? textColor : subtitleColor.withOpacity(0.5),
                                        ),
                                        iconSize: 36,
                                        onPressed: hasNext ? musicService.playNext : null,
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 30),
                              Container(
                                height: 48, // Maintain consistent height
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if(song.lyrics != null && song.lyrics!.isNotEmpty)
                                      IconButton(
                                          icon: const Icon(Icons.lyrics_outlined, color: subtitleColor),
                                          onPressed: () => _showLyricsModal(context, song.lyrics!, dominantColor)
                                      ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
