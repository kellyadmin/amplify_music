import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models.dart';
import '../widgets/banner_item.dart';
import 'audio_player_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Song> allSongs;
  const HomeScreen({super.key, required this.allSongs});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<BannerItem> banners = [];
  List<Song> trendingSongs = [];
  List<Artist> featuredArtists = [];
  bool isLoading = true;

  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentBanner = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _loadHomeData();

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && banners.isNotEmpty) {
        int nextPage = _currentBanner + 1;
        if (nextPage >= banners.length) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    try {
      final bannerResp = await supabase
          .from('banners')
          .select()
          .eq('active', true)
          .order('inserted_at', ascending: false)
          .execute();

      banners = (bannerResp.data as List)
          .map((m) => BannerItem.fromMap(m as Map<String, dynamic>))
          .toList();

      final trendResp = await supabase
          .from('songs')
          .select()
          .eq('trending', true)
          .order('play_count', ascending: false)
          .limit(10)
          .execute();

      trendingSongs = (trendResp.data as List)
          .map((m) => Song.fromMap(m as Map<String, dynamic>))
          .toList();

      final artResp = await supabase
          .from('artists')
          .select()
          .eq('featured', true)
          .limit(10)
          .execute();

      featuredArtists = (artResp.data as List)
          .map((m) => Artist.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Home loading error: $e');
    }

    setState(() => isLoading = false);
  }

  Widget buildIconLabel(IconData icon, int count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text('$count',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          TextButton(
            onPressed: onViewAll,
            child: const Text("View All",
                style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget buildTopMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _menuButton("For You", true),
          _menuButton("Hot Songs", false),
          _menuButton("New", false),
          _menuButton("Top 20", false),
        ],
      ),
    );
  }

  Widget _menuButton(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFD700) : Colors.grey[850],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.w500,
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFFFD700);
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? "Hi 👋";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Hi, $userEmail", style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          )
        ],
      ),
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            buildTopMenu(),
            const SizedBox(height: 20),

            // 🎞 Banner
            if (banners.isNotEmpty) ...[
              SizedBox(
                height: 190,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: banners.length,
                  onPageChanged: (index) {
                    setState(() => _currentBanner = index);
                  },
                  itemBuilder: (context, i) {
                    final b = banners[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        image: DecorationImage(
                          image: NetworkImage(b.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: banners.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: gold,
                    dotColor: Colors.grey,
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 3,
                    spacing: 6,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 🔥 Trending Songs
            buildSectionTitle("Trending Songs", () {}),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: trendingSongs.length,
                itemBuilder: (_, i) {
                  final s = trendingSongs[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AudioPlayerScreen(song: s),
                      ),
                    ),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'cover_${s.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                s.albumArtUrl,
                                height: 120,
                                width: 140,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              buildIconLabel(Icons.thumb_up_alt_outlined,
                                  s.likes ?? 0, () {}),
                              const SizedBox(width: 12),
                              buildIconLabel(Icons.download_outlined,
                                  s.downloads ?? 0, () {}),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 👤 Featured Artists
            buildSectionTitle("Featured Artists", () {}),
            const SizedBox(height: 10),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: featuredArtists.length,
                itemBuilder: (_, i) {
                  final a = featuredArtists[i];
                  return Container(
                    margin: const EdgeInsets.only(right: 14),
                    child: Column(
                      children: [
                        ClipOval(
                          child: Image.network(
                            a.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey,
                              width: 80,
                              height: 80,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 80,
                          child: Text(
                            a.name,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
