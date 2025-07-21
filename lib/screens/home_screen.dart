import 'package:flutter/material.dart';
import '../models.dart';
import 'artist_detail_screen.dart';
import 'music_player_screen.dart';
import '../widgets/mini_player.dart';

class HomeScreen extends StatefulWidget {
  final List<Song> allSongs;

  const HomeScreen({super.key, required this.allSongs});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Song? currentSong;
  bool isPlaying = false;

  late final List<Song> trendingSongs;
  late final List<Song> newReleases;

  late final List<Artist> topArtists;

  final List<Map<String, dynamic>> genres = [
    {'name': 'Afrobeats', 'color': Colors.deepPurpleAccent},
    {'name': 'Dancehall', 'color': Colors.greenAccent},
    {'name': 'Hip Hop', 'color': Colors.redAccent},
    {'name': 'R&B', 'color': Colors.pinkAccent},
    {'name': 'Reggae', 'color': Colors.orangeAccent},
    {'name': 'Amapiano', 'color': Colors.cyanAccent},
  ];

  int bannerIndex = 0;
  final PageController bannerController = PageController(viewportFraction: 0.9);

  final List<String> banners = [
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    int splitIndex = (widget.allSongs.length / 2).ceil();
    trendingSongs = widget.allSongs.sublist(0, splitIndex);
    newReleases = widget.allSongs.sublist(splitIndex);

    topArtists = [
      Artist(
        id: 'artist1',
        name: 'Fik Fameica',
        imageUrl: 'assets/images/fameica.jpg',
        bio:
        'Fik Fameica is a top Ugandan rapper and singer known for street anthems and energetic performances.',
        followers: 420000,
        following: 150, // Added required field
        downloads: 10000, // Added required field
        songs: [if (trendingSongs.isNotEmpty) trendingSongs[0]],
      ),
      Artist(
        id: 'artist2',
        name: 'Vyroota',
        imageUrl: 'assets/images/vyroota.jpg',
        bio:
        'Vyroota is a rising star in East Africa’s music scene with catchy melodies and modern beats.',
        followers: 130000,
        following: 75, // Added required field
        downloads: 5000, // Added required field
        songs: [if (trendingSongs.length > 1) trendingSongs[1]],
      ),
      Artist(
        id: 'artist3',
        name: 'Burna Boy',
        imageUrl: 'assets/images/burna.jpg',
        bio: 'Burna Boy is a Nigerian Afro-fusion superstar and Grammy award winner.',
        followers: 5200000,
        following: 500, // Added required field
        downloads: 200000, // Added required field
        songs: [if (trendingSongs.length > 2) trendingSongs[2]],
      ),
    ];
  }

  void _playSong(Song song) async {
    setState(() {
      currentSong = song;
      isPlaying = true;
    });

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MusicPlayerScreen(
          song: song,
          playlist: trendingSongs,
          onSongChanged: (updated) {
            setState(() {
              currentSong = updated;
              isPlaying = true;
            });
          },
        ),
      ),
    );

    if (result is Song) {
      setState(() {
        currentSong = result;
        isPlaying = true;
      });
    }
  }

  void _togglePlayPause() {
    if (currentSong != null) {
      setState(() {
        isPlaying = !isPlaying;
      });
    }
  }

  @override
  void dispose() {
    bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/amplify_logo.png', height: 30),
            const SizedBox(width: 10),
            const Text(
              'Amplify Music',
              style: TextStyle(fontWeight: FontWeight.bold, color: gold),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner carousel
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: bannerController,
              itemCount: banners.length,
              onPageChanged: (i) => setState(() => bannerIndex = i),
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: AssetImage(banners[i]),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))
                  ],
                ),
              ),
            ),
          ),

          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                width: bannerIndex == i ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: bannerIndex == i ? gold : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),
          const Text('🔥 Trending Songs',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),

          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: trendingSongs.length,
              itemBuilder: (_, idx) {
                final s = trendingSongs[idx];
                return GestureDetector(
                  onTap: () => _playSong(s),
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.asset(s.albumArtUrl!, height: 120, width: 150, fit: BoxFit.cover),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(s.title,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(s.artist,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          const Text('🆕 New Releases',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),

          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: newReleases.length,
              itemBuilder: (_, idx) {
                final s = newReleases[idx];
                return GestureDetector(
                  onTap: () => _playSong(s),
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.asset(s.albumArtUrl!, height: 120, width: 150, fit: BoxFit.cover),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(s.title,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(s.artist,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          const Text('🎶 Genres',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),

          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: genres.length,
              itemBuilder: (_, i) {
                final g = genres[i];
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: g['color'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: g['color'].withOpacity(0.8)),
                  ),
                  child: Center(
                    child: Text(g['name'],
                        style: TextStyle(
                            color: g['color'],
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          const Text('🎤 Top Artists',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),

          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: topArtists.length,
              itemBuilder: (_, idx) {
                final a = topArtists[idx];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ArtistDetailScreen(artist: a)),
                  ),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        CircleAvatar(radius: 32, backgroundImage: AssetImage(a.imageUrl)),
                        const SizedBox(height: 6),
                        Text(a.name,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: currentSong != null
          ? MiniPlayer(
        song: currentSong!,
        isPlaying: isPlaying,
        onPlayPause: _togglePlayPause,
        onTap: () => _playSong(currentSong!),
      )
          : const SizedBox.shrink(),
    );
  }
}
