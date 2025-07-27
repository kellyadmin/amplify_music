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

  final List<String> menuLabels = ['For You', 'Hot Songs', 'New', 'Top 20'];
  int selectedMenu = 0;

  @override
  void initState() {
    super.initState();
    _loadHomeData();

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      if (_pageController.hasClients && banners.isNotEmpty) {
        final nextPage = (_currentBanner + 1) % banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
        if (mounted) setState(() => _currentBanner = nextPage);
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

      final trendResp = await supabase
          .from('songs')
          .select()
          .eq('trending', true)
          .order('play_count', ascending: false)
          .limit(10)
          .execute();

      final artResp = await supabase
          .from('artists')
          .select('id, name, image_url, bio, verified, featured, followers, following, downloads')
          .eq('featured', true)
          .limit(10)
          .execute();

      banners = (bannerResp.data as List)
          .map((m) => BannerItem.fromMap(m as Map<String, dynamic>))
          .toList();

      trendingSongs = (trendResp.data as List)
          .map((m) => Song.fromMap(m as Map<String, dynamic>))
          .toList();

      featuredArtists = (artResp.data as List)
          .map((m) => Artist.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading home data: $e');
    }

    if (mounted) setState(() => isLoading = false);
  }

  String formatNumber(int number) {
    if (number >= 1000000000) return '${(number / 1000000000).toStringAsFixed(1)}B';
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}k';
    return number.toString();
  }

  String formatBoostedNumber(int number, {double boostFactor = 3}) {
    return formatNumber((number * boostFactor).toInt());
  }

  Widget buildFancyIconLabel(IconData icon, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          formatNumber(count),
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget buildTopMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(menuLabels.length, (index) {
          final isSelected = index == selectedMenu;
          return GestureDetector(
            onTap: () => setState(() => selectedMenu = index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber : Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                menuLabels[index],
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = supabase.auth.currentUser?.email ?? "👋";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Hi, $userEmail", style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
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

            // 🔥 BANNERS
            if (banners.isNotEmpty)
              Column(
                children: [
                  SizedBox(
                    height: 190,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: banners.length,
                      onPageChanged: (i) => setState(() => _currentBanner = i),
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
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: banners.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: Colors.amber,
                      dotColor: Colors.grey,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                      spacing: 6,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 30),

            // 🔥 TRENDING SONGS
            buildSectionTitle("Trending Songs"),
            const SizedBox(height: 12),
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
                          Wrap(
                            spacing: 6,
                            children: [
                              buildFancyIconLabel(Icons.play_arrow, s.playCount, Colors.amber),
                              buildFancyIconLabel(Icons.thumb_up, s.likes, Colors.redAccent),
                              buildFancyIconLabel(Icons.download, s.downloads, Colors.lightBlueAccent),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // 🌟 FEATURED ARTISTS
            buildSectionTitle("Featured Artists"),
            const SizedBox(height: 12),
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
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey, width: 80, height: 80),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 80,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  a.name,
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (a.verified)
                                const Icon(Icons.verified, size: 14, color: Colors.amber),
                            ],
                          ),
                        ),
                        Text(
                          '${formatBoostedNumber(a.followers)} followers',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
