import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../utils/platform_utils_mobile.dart'
    if (dart.library.html) '../utils/platform_utils_web.dart';
import '../constants.dart';
import '../models.dart';
import '../models/news_article.dart';
import '../models/generated_playlist.dart';
import '../services/supabase_service.dart';
import '../services/music_service.dart';
import '../services/cache_service.dart';
import '../services/recent_service.dart';
import '../utils/auth_dialogs.dart';
import 'music_player_screen.dart';
import 'artist_detail_screen.dart'
    hide
        primaryColor,
        secondaryColor,
        cardColor,
        textColor,
        subtitleColor,
        surfaceElevated,
        surfaceGlass;
import 'song_detail_screen.dart'
    hide
        primaryColor,
        secondaryColor,
        cardColor,
        textColor,
        subtitleColor,
        surfaceElevated,
        surfaceGlass;
import 'premium_subscription_page.dart'
    hide
        primaryColor,
        secondaryColor,
        cardColor,
        textColor,
        subtitleColor,
        surfaceElevated,
        surfaceGlass;
import 'news_list_screen.dart';
import 'article_detail_screen.dart';
import 'generated_playlist_detail_screen.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_live_activity.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/home_category_tabs.dart';
import '../widgets/home/home_song_card.dart';
import '../widgets/home/home_artist_card.dart';
import '../widgets/home/home_section_title.dart';
import '../widgets/home/home_shimmer.dart';
import '../widgets/home/home_animated_playlist_card.dart';
import '../widgets/home/home_share_sheet.dart';
import '../widgets/home/home_banners_section.dart';
import '../widgets/home/home_empty_state.dart';
import '../widgets/vibrant_card.dart';
import '../widgets/animated_gradient_background.dart';

const _uuid = Uuid();

class HomeScreen extends StatefulWidget {
  final List<Song> allSongs;
  const HomeScreen({Key? key, this.allSongs = const []}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<HomeScreen> {
  @override
  bool get wantKeepAlive => true;

  final supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();
  final CacheService _cacheService = CacheService();
  List<BannerItem> banners = [];
  List<Song> trendingSongs = [];
  List<Song> recommendedSongs = [];
  List<Song> newReleasesSongs = [];
  List<Song> aiRecommendedSongs = [];
  List<Song> keywordSearchResults = [];
  List<Artist> featuredArtists = [];
  List<Artist> emergingArtists = [];

  Map<String, bool> _expandedSections = {
    'dailyRecs': false,
    'moodActivity': false,
    'featuredPlaylists': false,
    'topCharts': false,
    'emergingArtists': false,
    'featuredArtists': false,
  };
  List<Song> _chartTopSongs = [];
  Map<String, bool> _animatedLikes = {};

  List<GeneratedPlaylist> _allFeaturedPlaylists = [];

  List<NewsArticle> _newsArticles = [];
  List<Song> _userLikedSongs = [];
  List<Song> _allAvailableSongsForAI = [];
  List<Song> _dailyRecommendedSongs = [];
  List<Song> _moodActivitySongs = [];
  Timer? _dynamicContentTimer;
  Map<int, bool> _showAllTabSongs = {};
  final TextEditingController _keywordSearchController =
      TextEditingController();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  List<Song> _searchSuggestions = [];
  List<Artist> _artistSearchSuggestions = [];
  bool _showSearchSuggestions = false;

  late AnimationController _liveActivityController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _gradientController;
  late Animation<double> _liveActivityAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _backgroundGradientAnimation;

  Timer? _liveActivityTimer;
  Timer? _onlineUsersTimer;
  int _onlineUsers = 0;
  bool _isLiveActivityVisible = true;
  List<String> _recentActivity = [];
  int _nowPlayingCount = 0;

  String _aiPlaylistOutput = 'Fetching your personalized AI daily mixes...';
  bool _isLoadingAIPlaylist = false;
  String _keywordSearchOutput = 'Keyword search results will appear here.';
  bool _isLoadingKeywordSearch = false;
  bool isLoading = false;
  bool _isError = false;
  String _errorMessage = '';
  final List<String> tabTitles = ['Made For You', 'Charts', 'Trending', 'New'];

  int _selectedTabIndex = 0;
  String? _hoveredSongId;

  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  static const String _dailyRecsCacheKey = 'daily_recommendations';
  static const String _featuredPlaylistsCacheKey = 'featured_playlists';
  static const String _moodActivityCacheKey = 'mood_activity';
  static const String _newsCacheKey = 'news_articles';
  static const String _chartsCacheKey = 'top_charts';

  final Set<String> _shownSongIds = {};

  bool _dailyRecsLoaded = false;
  bool _featuredPlaylistsLoaded = false;
  bool _moodActivityLoaded = false;
  bool _newsLoaded = false;
  bool _chartsLoaded = false;

  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _liveActivityController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _liveActivityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _liveActivityController,
      curve: Curves.easeInOutCirc,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOutSine,
    ));

    _backgroundGradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOutSine,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -2),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    ));

    _liveActivityController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
    _gradientController.repeat(reverse: true);

    _startLiveActivity();

    _loadHomeData();
    _startDynamicContentTimer();
    for (int i = 0; i < tabTitles.length; i++) {
      _showAllTabSongs[i] = false;
    }
    _keywordSearchController.addListener(_onSearchQueryChanged);
    _searchController.addListener(_onSearchTextChanged);
    _searchFocusNode.addListener(_onSearchFocusChange);
    p.Provider.of<MusicService>(context, listen: false)
        .addListener(_onMusicServiceChange);

    _loadAllSectionsWithCache();
  }

  @override
  void dispose() {
    _dynamicContentTimer?.cancel();
    _liveActivityTimer?.cancel();
    _onlineUsersTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _keywordSearchController.removeListener(_onSearchQueryChanged);
    _keywordSearchController.dispose();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _animationController.dispose();
    _liveActivityController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _gradientController.dispose();
    p.Provider.of<MusicService>(context, listen: false)
        .removeListener(_onMusicServiceChange);
    super.dispose();
  }

  void _loadAllSectionsWithCache() {
    _loadFeaturedPlaylists();
    _loadNews();
    _loadDailyRecommendations();
    _loadMoodActivitySongs();
    _loadChartsData();
  }

  void _onSearchQueryChanged() {
    setState(() {});
  }

  void _onSearchTextChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        setState(() {
          _searchSuggestions = [];
          _artistSearchSuggestions = [];
          _showSearchSuggestions = false;
        });
        return;
      }

      final suggestions = _allAvailableSongsForAI
          .where((song) =>
              song.title.toLowerCase().contains(query.toLowerCase()) ||
              song.artist.toLowerCase().contains(query.toLowerCase()))
          .take(5)
          .toList();

      final artistSuggestions = [
        ...featuredArtists,
        ...emergingArtists,
      ]
          .where((artist) =>
              artist.name.toLowerCase().contains(query.toLowerCase()))
          .take(3)
          .toList();

      setState(() {
        _searchSuggestions = suggestions;
        _artistSearchSuggestions = artistSuggestions;
        _showSearchSuggestions =
            suggestions.isNotEmpty || artistSuggestions.isNotEmpty;
      });
    });
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
      if (!_isSearchFocused) {
        _showSearchSuggestions = false;
      } else if (_searchController.text.isNotEmpty) {
        _showSearchSuggestions = _searchSuggestions.isNotEmpty ||
            _artistSearchSuggestions.isNotEmpty;
      }
    });
  }

  void _updateSongDetailsInLists(
      String songId, bool isLiked, int newLikesCount) {
    void _updateList(List<Song> list) {
      final index = list.indexWhere((s) => s.id == songId);
      if (index != -1) {
        list[index] =
            list[index].copyWith(likedByUser: isLiked, likes: newLikesCount);
      }
    }

    _updateList(trendingSongs);
    _updateList(recommendedSongs);
    _updateList(newReleasesSongs);
    _updateList(aiRecommendedSongs);
    _updateList(keywordSearchResults);
    _updateList(_dailyRecommendedSongs);
    _updateList(_moodActivitySongs);
    _updateList(_chartTopSongs);
    for (var playlist in _allFeaturedPlaylists) {
      _updateList(playlist.songs);
    }
  }

  void _onMusicServiceChange() {
    if (!mounted) return;
    final musicService = p.Provider.of<MusicService>(context, listen: false);
    _updateSongListsBasedOnMusicService(musicService);
    _loadUserLikedSongs();
    _loadAllExistingSongDetailsForAI();
    setState(() {});
  }

  void _updateSongListsBasedOnMusicService(MusicService musicService) {
    void _updateList(List<Song> list) {
      for (int i = 0; i < list.length; i++) {
        final song = list[i];
        final bool isLikedInService = musicService.isSongLikedLocally(song.id);
        if (song.likedByUser != isLikedInService) {
          list[i] = song.copyWith(likedByUser: isLikedInService);
        }
      }
    }

    _updateList(trendingSongs);
    _updateList(recommendedSongs);
    _updateList(newReleasesSongs);
    _updateList(aiRecommendedSongs);
    _updateList(keywordSearchResults);
    _updateList(_dailyRecommendedSongs);
    _updateList(_moodActivitySongs);
    _updateList(_chartTopSongs);
    for (var playlist in _allFeaturedPlaylists) {
      _updateList(playlist.songs);
    }
  }

  void _startDynamicContentTimer() {
    _dynamicContentTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        featuredArtists.shuffle(Random());
        emergingArtists.shuffle(Random());
      });
    });
  }

  void _startLiveActivity() {
    _updateOnlineUsers();
    _onlineUsersTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _updateOnlineUsers();
    });

    _generateLiveActivity();
    _liveActivityTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _generateLiveActivity();
    });
  }

  void _updateOnlineUsers() {
    if (!mounted) return;
    final random = Random();
    setState(() {
      _onlineUsers = 15000 + random.nextInt(5000);
      _nowPlayingCount = 1200 + random.nextInt(300);
    });
  }

  void _generateLiveActivity() {
    if (!mounted) return;
    final random = Random();
    final activities = [
      '🎵 Sarah just discovered "Midnight Jazz"',
      '🔥 Mike added "Summer Vibes" to favorites',
      '🎧 Emma is now listening to "Lo-fi Beats"',
      '⭐ Alex rated "Indie Rock Mix" 5 stars',
      '📱 Jordan shared "Electronic Dreams"',
      '🎤 Taylor liked "Acoustic Sessions"',
      '🎸 Chris discovered "Rock Legends"',
      '💫 Maya created "Study Playlist"',
      '🎼 Sam exploring "Classical Favorites"',
      '🔊 Zoe boosted "Pop Hits 2024"',
    ];

    setState(() {
      _recentActivity.add(activities[random.nextInt(activities.length)]);
      if (_recentActivity.length > 5) {
        _recentActivity.removeAt(0);
      }
    });
  }

  Future<void> _safeApiCall(
      String operation, Future<void> Function() apiCall) async {
    try {
      setState(() {
        _isError = false;
        _errorMessage = '';
      });
      await apiCall();
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = 'Failed to load $operation. Please try again.';
      });
      debugPrint('Error in $operation: $e');
    }
  }

  Future<void> _loadHomeData() async {
    if (!mounted) return;

    final cachedDaily = await _cacheService.loadFromCache<Song>(
        _dailyRecsCacheKey, Song.fromMap);
    final cachedMood = await _cacheService.loadFromCache<Song>(
        _moodActivityCacheKey, Song.fromMap);

    final shouldShowGlobalLoader =
        (cachedDaily == null || cachedDaily.isEmpty) &&
            (cachedMood == null || cachedMood.isEmpty) &&
            banners.isEmpty &&
            _allFeaturedPlaylists.isEmpty &&
            _newsArticles.isEmpty;

    if (shouldShowGlobalLoader) {
      setState(() => isLoading = true);
    } else {
      setState(() => isLoading = false);
    }

    await _safeApiCall('core content', _loadCoreContent);
    await _supabaseService.determineUserCountry();
    await _safeApiCall('recommended songs', _loadRecommendedSongsFromSupabase);
    await _safeApiCall('user liked songs', _loadUserLikedSongs);
    await _safeApiCall('song details', _loadAllExistingSongDetailsForAI);

    await _triggerUserContentGenerationIfNeeded();
    await _safeApiCall('AI recommendations', _loadAIRecommendations);

    _loadAllSectionsWithCache();

    _shownSongIds.clear();

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _loadCoreContent() async {
    final cachedBanners = await _cacheService.loadFromCache<BannerItem>(
        'banners.json', BannerItem.fromMap);
    final cachedTrendingSongs = await _cacheService.loadFromCache<Song>(
        'trending_songs.json', Song.fromMap);
    final cachedFeaturedArtists =
        await _cache_service_try_load_artist('featured_artists.json');
    final cachedNewReleases = await _cacheService.loadFromCache<Song>(
        'new_releases.json', Song.fromMap);
    final cachedEmergingArtists =
        await _cache_service_try_load_artist('emerging_artists.json');

    if (mounted) {
      if (cachedBanners != null &&
          cachedTrendingSongs != null &&
          cachedFeaturedArtists != null &&
          cachedNewReleases != null &&
          cachedEmergingArtists != null) {
        setState(() {
          banners = cachedBanners;
          trendingSongs = cachedTrendingSongs;
          featuredArtists = cachedFeaturedArtists;
          emergingArtists = cachedEmergingArtists;
          newReleasesSongs = cachedNewReleases;
          isLoading = false;
        });
        debugPrint('[_loadCoreContent] Loaded core data from cache.');
      } else {
        debugPrint('[_loadCoreContent] No cache found, fetching from network.');
      }
    }

    try {
      final responses = await Future.wait([
        supabase.from('banners').select(),
        supabase.from('artists').select(),
        supabase
            .from('songs')
            .select()
            .order('likes', ascending: false)
            .limit(20),
        supabase
            .from('songs')
            .select()
            .order('release_date', ascending: false)
            .limit(20),
      ]);

      if (mounted) {
        final newBanners =
            (responses[0] as List).map((m) => BannerItem.fromMap(m)).toList();
        final allArtists =
            (responses[1] as List).map((m) => Artist.fromMap(m)).toList();
        final newFeaturedArtists =
            allArtists.where((a) => !a.isEmerging).toList();
        final newEmergingArtists =
            allArtists.where((a) => a.isEmerging).toList();
        final newTrendingSongs =
            (responses[2] as List).map((m) => Song.fromMap(m)).toList();
        final newNewReleases =
            (responses[3] as List).map((m) => Song.fromMap(m)).toList();

        setState(() {
          banners = newBanners;
          featuredArtists = newFeaturedArtists;
          emergingArtists = newEmergingArtists;
          trendingSongs = newTrendingSongs;
          newReleasesSongs = newNewReleases;
          isLoading = false;
        });

        debugPrint('[_loadCoreContent] Loaded fresh core data from network.');
        _cacheService.saveToCache<BannerItem>(newBanners, 'banners.json');
        _cacheService.saveToCache<Song>(
            newTrendingSongs, 'trending_songs.json');
        _cache_service_save_artist(newFeaturedArtists, 'featured_artists.json');
        _cache_service_save_artist(newEmergingArtists, 'emerging_artists.json');
        _cacheService.saveToCache<Song>(newNewReleases, 'new_releases.json');
      }
    } catch (e) {
      debugPrint('Error loading core content from network: $e');
      if (mounted && banners.isEmpty) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<List<Artist>?> _cache_service_try_load_artist(String key) async {
    try {
      return await _cacheService.loadFromCache<Artist>(key, Artist.fromMap);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cache_service_save_artist(List<Artist> list, String key) async {
    try {
      await _cacheService.saveToCache<Artist>(list, key);
    } catch (_) {}
  }

  Future<void> _triggerUserContentGenerationIfNeeded() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint(
          '[AI Content] User not logged in, skipping generation trigger.');
      return;
    }

    try {
      final response = await supabase
          .from('profiles')
          .select('last_ai_generation_at')
          .eq('id', user.id)
          .single();

      final lastGenerationString = response['last_ai_generation_at'] as String?;
      DateTime? lastGenerationDate;
      if (lastGenerationString != null) {
        lastGenerationDate = DateTime.tryParse(lastGenerationString);
      }

      final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));

      if (lastGenerationDate == null ||
          lastGenerationDate.isBefore(fiveDaysAgo)) {
        debugPrint(
            '[AI Content] Stale or no data. Triggering background generation...');

        final functionResponse =
            await supabase.functions.invoke('generate-user-content');

        if (functionResponse.status != 200) {
          debugPrint(
              '[AI Content] Background generation trigger failed: ${functionResponse.data}');
        } else {
          debugPrint(
              '[AI Content] Background generation triggered successfully.');
        }
      } else {
        debugPrint('[AI Content] User content is fresh. No generation needed.');
      }
    } catch (e) {
      debugPrint('Error checking or triggering AI content generation: $e');
    }
  }

  Future<void> _loadAIRecommendations() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAIPlaylist = true;
      _aiPlaylistOutput = 'Loading your personalized AI daily mixes...';
    });

    try {
      List<Song> fetchedAISongs = [];
      final user = supabase.auth.currentUser;

      if (user != null) {
        final response = await supabase
            .rpc('get_user_ai_songs', params: {'p_user_id': user.id});

        if (response is List && response.isNotEmpty) {
          fetchedAISongs = response
              .map<Song>((e) => Song.fromMap(e as Map<String, dynamic>))
              .toList();
        } else {
          fetchedAISongs = trendingSongs.take(5).toList();
          _aiPlaylistOutput =
              'Generating your first mix! Here are some trending songs for now.';
        }
      } else {
        debugPrint(
            '[AI Content] Guest user: loading regional/trending songs as AI recommendations.');
        final regionalSongs = await _supabaseService.fetchTopSongsByRegion();
        fetchedAISongs = regionalSongs.isNotEmpty
            ? regionalSongs.take(5).toList()
            : trendingSongs.take(5).toList();
        _aiPlaylistOutput =
            'Discover trending music. Sign in for personalized mixes!';
      }

      if (mounted) {
        setState(() {
          aiRecommendedSongs = fetchedAISongs;
          if (fetchedAISongs.isNotEmpty) {
            _aiPlaylistOutput = user != null
                ? 'Here are your personalized AI daily mixes:'
                : 'Trending in Your Region';
          }
        });
        await _cacheService.saveToCache<Song>(
            aiRecommendedSongs, 'ai_recommended_songs.json');
      }
    } catch (e) {
      debugPrint('Error loading AI recommendations: $e');
      if (mounted) {
        setState(() {
          _aiPlaylistOutput = 'Could not load recommendations.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAIPlaylist = false);
      }
    }
  }

  Future<void> _loadDailyRecommendations() async {
    if (!mounted) return;

    final cachedRecs = await _cacheService.loadFromCache<Song>(
        _dailyRecsCacheKey, Song.fromMap);
    if (mounted && cachedRecs != null && cachedRecs.isNotEmpty) {
      setState(() {
        _dailyRecommendedSongs = cachedRecs;
        _dailyRecsLoaded = true;
      });
      debugPrint('Loaded daily recommendations from cache.');
    } else {
      setState(() => _dailyRecsLoaded = false);
    }

    try {
      final thirtyDaysAgo =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      final newSongsResponse = await supabase
          .from('songs')
          .select()
          .gte('release_date', thirtyDaysAgo)
          .order('release_date', ascending: false)
          .limit(10);
      final popularSongsResponse = await supabase
          .from('songs')
          .select()
          .order('play_count', ascending: false)
          .limit(10);
      List<Song> regionalSongs = await _supabaseService.fetchTopSongsByRegion();

      final allSongs = [
        ...((newSongsResponse as List).map((e) => Song.fromMap(e)).toList()),
        ...((popularSongsResponse as List)
            .map((e) => Song.fromMap(e))
            .toList()),
        ...regionalSongs,
      ];

      final uniqueSongs = <Song>[];
      final songIds = <String>{};
      for (var song in allSongs) {
        if (songIds.add(song.id)) uniqueSongs.add(song);
      }
      uniqueSongs.shuffle(Random());
      final finalRecs = uniqueSongs.take(15).toList();

      if (mounted) {
        setState(() {
          _dailyRecommendedSongs = finalRecs;
          _dailyRecsLoaded = true;
        });
        await _cacheService.saveToCache<Song>(finalRecs, _dailyRecsCacheKey);
        debugPrint(
            'Refreshed and cached ${finalRecs.length} daily recommendations.');
      }
    } catch (e) {
      debugPrint('Error loading daily recommendations from network: $e');
      if (mounted) setState(() => _dailyRecsLoaded = true);
    }
  }

  Future<void> _loadNews() async {
    if (!mounted) return;
    setState(() => _newsLoaded = false);

    try {
      final response = await supabase
          .from('news_articles')
          .select()
          .order('created_at', ascending: false)
          .limit(20);

      final articles =
          (response as List).map((data) => NewsArticle.fromMap(data)).toList();
      articles.shuffle();
      if (mounted) {
        setState(() {
          _newsArticles = articles;
          _newsLoaded = true;
        });
      }
      debugPrint('Loaded ${articles.length} news articles from the database.');
    } catch (e) {
      debugPrint('Error loading news from database: $e');
      if (mounted) setState(() => _newsLoaded = true);
    }
  }

  Future<void> _loadMoodActivitySongs() async {
    if (!mounted) return;

    final cachedRecs = await _cacheService.loadFromCache<Song>(
        _moodActivityCacheKey, Song.fromMap);
    if (mounted && cachedRecs != null && cachedRecs.isNotEmpty) {
      setState(() {
        _moodActivitySongs = cachedRecs;
        _moodActivityLoaded = true;
      });
      debugPrint('Loaded Mood & Activity songs from cache.');
    } else {
      setState(() => _moodActivityLoaded = false);
    }

    try {
      final List<String> moods = [
        'Workout',
        'Chill',
        'Focus',
        'Party',
        'Romance',
        'Sleep'
      ];
      List<Song> fetchedSongs = [];
      for (var mood in moods) {
        final moodSongsResponse = await supabase
            .from('songs')
            .select()
            .like('mood', '%$mood%')
            .order('play_count', ascending: false)
            .limit(3);
        fetchedSongs.addAll(
            (moodSongsResponse as List).map((e) => Song.fromMap(e)).toList());
      }

      if (fetchedSongs.length < 12) {
        fetchedSongs.addAll(trendingSongs.take(12 - fetchedSongs.length));
      }

      final uniqueSongs = <Song>[];
      final songIds = <String>{};
      for (var song in fetchedSongs) {
        if (songIds.add(song.id)) uniqueSongs.add(song);
      }
      uniqueSongs.shuffle(Random());
      final finalRecs = uniqueSongs.take(12).toList();

      if (mounted) {
        setState(() {
          _moodActivitySongs = finalRecs;
          _moodActivityLoaded = true;
        });
        await _cacheService.saveToCache<Song>(finalRecs, _moodActivityCacheKey);
        debugPrint(
            'Refreshed and cached ${finalRecs.length} Mood & Activity songs.');
      }
    } catch (e) {
      debugPrint('Error loading Mood & Activity songs from network: $e');
      if (mounted) setState(() => _moodActivityLoaded = true);
    }
  }

  Future<void> _loadRecommendedSongsFromSupabase() async {
    try {
      final userCountryCode = _supabaseService.userCountryCode;
      debugPrint(
          '[_loadRecommendedSongsFromSupabase] User country code: $userCountryCode');
      List<Song> fetchedSongs = [];

      if (userCountryCode != 'GLOBAL' && userCountryCode.isNotEmpty) {
        debugPrint(
            '[_loadRecommendedSongsFromSupabase] Attempting to fetch regional top songs for $userCountryCode');
        try {
          fetchedSongs = await _supabaseService.fetchTopSongsByRegion();
        } catch (e) {
          debugPrint('Error fetching regional songs: $e');
          fetchedSongs = [];
        }
      }

      if (fetchedSongs.isEmpty) {
        debugPrint(
            '[_loadRecommendedSongsFromSupabase] No regional songs found. Falling back to a balanced global recommendation.');
        try {
          final topSongsResponse = await supabase
              .from('songs')
              .select('*')
              .order('likes', ascending: false)
              .limit(5);
          final List<Song> topSongs = (topSongsResponse as List? ?? [])
              .map((item) => Song.fromMap(item))
              .toList();
          final ninetyDaysAgo = DateTime.now()
              .subtract(const Duration(days: 90))
              .toIso8601String();
          final recentSongsResponse = await supabase
              .from('songs')
              .select('*')
              .gte('release_date', ninetyDaysAgo)
              .order('play_count', ascending: false)
              .limit(5);
          final List<Song> recentSongs = (recentSongsResponse as List? ?? [])
              .map((item) => Song.fromMap(item))
              .toList();
          final newReleasesResponse = await supabase
              .from('songs')
              .select('*')
              .order('release_date', ascending: false)
              .limit(5);
          final List<Song> newReleases = (newReleasesResponse as List? ?? [])
              .map((item) => Song.fromMap(item))
              .toList();
          final combined = <Song>[];
          final songIds = <String>{};
          for (var song in [...topSongs, ...recentSongs, ...newReleases]) {
            if (songIds.add(song.id)) {
              combined.add(song);
            }
          }
          combined.shuffle(Random());
          fetchedSongs = combined;
        } catch (e) {
          debugPrint('Error fetching global songs: $e');
          fetchedSongs = trendingSongs.isNotEmpty ? trendingSongs : [];
        }
      }

      if (mounted) {
        setState(() {
          recommendedSongs = fetchedSongs;
        });
        debugPrint(
            '[_loadRecommendedSongsFromSupabase] Loaded ${recommendedSongs.length} recommended songs.');
      }
    } catch (e) {
      debugPrint('Failed to load recommended songs from Supabase: $e');
    }
  }

  Future<void> _loadAllExistingSongDetailsForAI() async {
    try {
      final response = await supabase
          .from('songs')
          .select('id, title, artist, genre, mood, album_art_url');
      if (response != null && response is List) {
        final List<Song> allSongsInDb = response
            .map<Song>((e) => Song.fromMap(e as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _allAvailableSongsForAI = allSongsInDb;
          });
          debugPrint(
              '[_loadAllExistingSongDetailsForAI] Loaded ${_allAvailableSongsForAI.length} available songs for AI recommendation (including liked).');
        }
      } else {
        debugPrint(
            '[_loadAllExistingSongDetailsForAI] Failed to load existing song details: Unexpected response format.');
      }
    } catch (e) {
      debugPrint(
          '[_loadAllExistingSongDetailsForAI] Error loading all existing song details: $e');
      if (mounted) {
        setState(() {
          _allAvailableSongsForAI = [];
        });
      }
    }
  }

  Future<void> _loadUserLikedSongs() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _userLikedSongs = []);
      return;
    }
    try {
      final likedSongIdsResponse = await supabase
          .from('user_likes_song')
          .select('song_id')
          .eq('user_id', userId)
          .limit(10);
      if (likedSongIdsResponse.isEmpty) {
        if (mounted) setState(() => _userLikedSongs = []);
        return;
      }
      final List<String> likedIds = (likedSongIdsResponse as List)
          .map<String>((e) => e['song_id'] as String)
          .toList();
      if (likedIds.isEmpty) {
        if (mounted) setState(() => _userLikedSongs = []);
        return;
      }
      final likedSongsDetailsResponse =
          await supabase.from('songs').select().in_('id', likedIds);
      final List<Song> fetchedLikedSongs = (likedSongsDetailsResponse as List)
          .map<Song>((e) => Song.fromMap(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _userLikedSongs = fetchedLikedSongs
              .map((song) => song.copyWith(likedByUser: true))
              .toList();
        });
      }
    } catch (e) {
      debugPrint(
          '[_loadUserLikedSongs] Error fetching user liked songs from Supabase: $e');
      if (mounted) setState(() => _userLikedSongs = []);
    }
  }

  Future<void> _searchSongsByKeyword(String keyword) async {
    if (keyword.isEmpty) {
      if (!mounted) return;
      setState(() {
        keywordSearchResults.clear();
        _keywordSearchOutput = 'Please enter a keyword to search.';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoadingKeywordSearch = true;
      _keywordSearchOutput = 'Searching for "$keyword"...';
      keywordSearchResults.clear();
    });
    final lowerCaseKeyword = keyword.toLowerCase();
    List<Song> foundSongs = [];
    foundSongs = _allAvailableSongsForAI.where((song) {
      return (song.title?.toLowerCase().contains(lowerCaseKeyword) ?? false) ||
          (song.artist?.toLowerCase().contains(lowerCaseKeyword) ?? false) ||
          (song.genre?.toLowerCase().contains(lowerCaseKeyword) ?? false) ||
          (song.mood?.toLowerCase().contains(lowerCaseKeyword) ?? false);
    }).toList();
    if (foundSongs.isNotEmpty) {
      if (mounted) {
        setState(() {
          keywordSearchResults = foundSongs;
          _keywordSearchOutput = 'Here are songs for "$keyword" (local cache):';
          _isLoadingKeywordSearch = false;
        });
      }
      return;
    }
    try {
      final directSupabaseResponse = await supabase
          .from('songs')
          .select()
          .or('title.ilike.%$keyword%,artist.ilike.%$keyword%')
          .limit(10);
      if (directSupabaseResponse != null && directSupabaseResponse.isNotEmpty) {
        foundSongs = (directSupabaseResponse as List)
            .map<Song>((e) => Song.fromMap(e as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            keywordSearchResults = foundSongs;
            _keywordSearchOutput = 'Here are songs for "$keyword":';
            _isLoadingKeywordSearch = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Error during direct Supabase search: $e');
    } finally {
      if (mounted) setState(() => _isLoadingKeywordSearch = false);
    }
  }

  Future<void> _loadFeaturedPlaylists() async {
    if (!mounted) return;

    final cachedPlaylists =
        await _cacheService.loadFromCache<GeneratedPlaylist>(
            _featuredPlaylistsCacheKey, GeneratedPlaylist.fromMap);
    if (mounted && cachedPlaylists != null && cachedPlaylists.isNotEmpty) {
      setState(() {
        _allFeaturedPlaylists = cachedPlaylists;
        _featuredPlaylistsLoaded = true;
      });
      debugPrint(
          'Loaded ${_allFeaturedPlaylists.length} featured playlists from cache.');
    } else {
      setState(() => _featuredPlaylistsLoaded = false);
    }

    try {
      List<GeneratedPlaylist> fetchedPlaylists =
          await _fetchPlaylistsFromSupabase();

      if (fetchedPlaylists.length < 8) {
        debugPrint(
            "Fetched only ${fetchedPlaylists.length} playlists, generating more to meet minimum.");
        final fallbackPlaylists = await _generateFeaturedPlaylistsFromSongs();
        final existingTitles = fetchedPlaylists.map((p) => p.title).toSet();

        for (var fallback in fallbackPlaylists) {
          if (!existingTitles.contains(fallback.title)) {
            fetchedPlaylists.add(fallback);
          }
        }
      }

      if (mounted) {
        setState(() {
          _allFeaturedPlaylists = fetchedPlaylists;
          _featuredPlaylistsLoaded = true;
        });
        await _cacheService.saveToCache<GeneratedPlaylist>(
            fetchedPlaylists, _featuredPlaylistsCacheKey);
        debugPrint(
            'Refreshed and cached ${_allFeaturedPlaylists.length} featured playlists from network.');
      }
    } catch (e) {
      debugPrint(
          "Error loading featured playlists from network, running fallback: $e");
      final fallbackPlaylists = await _generateFeaturedPlaylistsFromSongs();
      if (mounted) {
        setState(() {
          _allFeaturedPlaylists = fallbackPlaylists;
          _featuredPlaylistsLoaded = true;
        });
        await _cacheService.saveToCache<GeneratedPlaylist>(
            fallbackPlaylists, _featuredPlaylistsCacheKey);
      }
    }
  }

  Future<List<GeneratedPlaylist>> _fetchPlaylistsFromSupabase() async {
    final playlistsResponse =
        await supabase.from('ai_playlists').select().limit(50);
    if ((playlistsResponse as List).isEmpty) {
      throw Exception('No playlists found in Supabase.');
    }

    List<GeneratedPlaylist> fetchedPlaylists = [];
    List<String> playlistIds = [];
    for (var pData in (playlistsResponse as List)) {
      playlistIds.add(pData['id']);
      fetchedPlaylists.add(GeneratedPlaylist(
        id: pData['id'],
        title: pData['title'] ?? 'Untitled Playlist',
        description:
            pData['description'] ?? 'A curated collection of great tracks.',
        coverImageUrl: pData['cover_image_url'] ?? '',
        songs: [],
      ));
    }

    final relationshipsResponse = await supabase
        .from('ai_playlist_songs')
        .select('playlist_id, song_id, position')
        .in_('playlist_id', playlistIds);
    final songIds = (relationshipsResponse as List)
        .map<String>((r) => r['song_id'])
        .toSet();
    if (songIds.isEmpty) return [];

    final songsResponse =
        await supabase.from('songs').select().in_('id', songIds.toList());
    final songMap = {
      for (var sData in (songsResponse as List))
        sData['id']: Song.fromMap(sData)
    };

    final playlistSongsMap = <String, List<Map<String, dynamic>>>{};
    for (var rel in (relationshipsResponse as List)) {
      playlistSongsMap.putIfAbsent(rel['playlist_id'], () => []).add(rel);
    }

    for (int i = 0; i < fetchedPlaylists.length; i++) {
      final playlist = fetchedPlaylists[i];
      final relationships = playlistSongsMap[playlist.id] ?? [];
      relationships
          .sort((a, b) => (a['position'] ?? 99).compareTo(b['position'] ?? 99));

      final List<Song> playlistSongs = relationships
          .map((r) => songMap[r['song_id']])
          .whereType<Song>()
          .where((s) =>
              s.albumArtUrl.isNotEmpty &&
              !s.albumArtUrl.contains('placehold.co'))
          .toList();

      String coverUrl = playlist.coverImageUrl;
      if ((coverUrl.isEmpty || coverUrl.contains('placehold.co')) &&
          playlistSongs.isNotEmpty) {
        coverUrl =
            playlistSongs[Random().nextInt(playlistSongs.length)].albumArtUrl;
      }

      fetchedPlaylists[i] =
          playlist.copyWith(songs: playlistSongs, coverImageUrl: coverUrl);
    }

    fetchedPlaylists
        .removeWhere((p) => p.songs.isEmpty || p.coverImageUrl.isEmpty);
    return fetchedPlaylists;
  }

  Future<List<GeneratedPlaylist>> _generateFeaturedPlaylistsFromSongs() async {
    final List<GeneratedPlaylist> generatedPlaylists = [];
    final random = Random();

    final allSongsWithArt = _allAvailableSongsForAI
        .where((s) =>
            s.albumArtUrl.isNotEmpty && !s.albumArtUrl.contains('placehold.co'))
        .toList();

    if (allSongsWithArt.isEmpty) {
      debugPrint('No songs with valid art available for playlist generation');
      return [];
    }
    allSongsWithArt.shuffle();

    final Map<String, List<Song>> songsByGenre = {};
    final Map<String, List<Song>> songsByMood = {};

    for (var song in allSongsWithArt) {
      if (song.genre != null) {
        song.genre!.split(',').forEach(
            (g) => songsByGenre.putIfAbsent(g.trim(), () => []).add(song));
      }
      if (song.mood != null) {
        song.mood!.split(',').forEach(
            (m) => songsByMood.putIfAbsent(m.trim(), () => []).add(song));
      }
    }

    final descriptionTemplates = [
      'The essential sound of {NAME}.',
      'The ultimate {NAME} collection.',
      '{NAME} deep cuts and classic hits.',
      'Your perfect {NAME} soundtrack.',
    ];

    songsByGenre.entries
        .where((e) => e.value.length >= 3)
        .take(20)
        .forEach((entry) {
      final genreSongs = entry.value.take(12).toList();
      generatedPlaylists.add(GeneratedPlaylist(
        id: _uuid.v4(),
        title: '${entry.key} Essentials',
        description:
            descriptionTemplates[random.nextInt(descriptionTemplates.length)]
                .replaceAll('{NAME}', entry.key),
        coverImageUrl:
            genreSongs[random.nextInt(genreSongs.length)].albumArtUrl,
        songs: genreSongs,
      ));
    });

    songsByMood.entries
        .where((e) => e.value.length >= 3)
        .take(20)
        .forEach((entry) {
      final moodSongs = entry.value.take(12).toList();
      generatedPlaylists.add(GeneratedPlaylist(
        id: _uuid.v4(),
        title: '${entry.key} Mix',
        description: 'A curated mix for your ${entry.key} moments.',
        coverImageUrl: moodSongs[random.nextInt(moodSongs.length)].albumArtUrl,
        songs: moodSongs,
      ));
    });

    generatedPlaylists.shuffle(Random());
    return generatedPlaylists.take(40).toList();
  }

  Future<void> _loadChartsData() async {
    if (!mounted) return;

    final cachedCharts =
        await _cacheService.loadFromCache<Song>(_chartsCacheKey, Song.fromMap);
    if (mounted && cachedCharts != null && cachedCharts.isNotEmpty) {
      setState(() {
        _chartTopSongs = cachedCharts;
        _chartsLoaded = true;
      });
      debugPrint('Loaded chart songs from cache.');
    } else {
      setState(() => _chartsLoaded = false);
    }

    try {
      final eighteenMonthsAgo =
          DateTime.now().subtract(const Duration(days: 540)).toIso8601String();
      final response = await supabase
          .from('songs')
          .select()
          .gte('release_date', eighteenMonthsAgo)
          .order('play_count', ascending: false)
          .limit(15);
      final topSongs = (response as List).map((e) => Song.fromMap(e)).toList();

      if (mounted) {
        setState(() {
          _chartTopSongs = topSongs;
          _chartsLoaded = true;
        });
        await _cacheService.saveToCache<Song>(topSongs, _chartsCacheKey);
        debugPrint('Refreshed and cached ${topSongs.length} chart songs.');
      }
    } catch (e) {
      debugPrint('Error loading chart songs from network: $e');
      if (mounted) setState(() => _chartsLoaded = true);
    }
  }

  Future<List<Song>> _fetchSongsForPlaylistGeneration() async {
    try {
      final response = await supabase.from('songs').select().limit(100);

      if (response != null && response is List) {
        return (response as List)
            .map((e) => Song.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching songs for playlist generation: $e');
    }

    return [];
  }

  List<Song> get _filteredSongsForTabs {
    switch (_selectedTabIndex) {
      case 1:
        final sorted = List<Song>.from(trendingSongs);
        sorted.sort((a, b) => b.playCount.compareTo(a.playCount));
        return sorted.take(20).toList();
      case 2:
        return trendingSongs;
      case 3:
        return newReleasesSongs;
      default:
        return recommendedSongs.isNotEmpty ? recommendedSongs : trendingSongs;
    }
  }

  Future<void> _handleLikeTap(Song song) async {
    if (supabase.auth.currentUser == null) {
      final didLogin = await AuthDialogs.showLoginRequired(
        context,
        title: 'Sign in to save your likes',
        message:
            'Build your taste profile, save favorite songs, and keep your liked music synced by signing in.',
        actionLabel: 'Sign In',
      );
      if (!didLogin || !mounted) return;
    }

    if (!mounted) return;
    final musicService = p.Provider.of<MusicService>(context, listen: false);
    final bool wasLiked = musicService.isSongLikedLocally(song.id);
    await musicService.toggleLike(song);
    final bool nowLiked = musicService.isSongLikedLocally(song.id);
    final int newLikesCount = song.likes +
        (nowLiked && !wasLiked ? 1 : (wasLiked && !nowLiked ? -1 : 0));
    _updateSongDetailsInLists(song.id, nowLiked, newLikesCount);
    _showAnimatedMessage(
      nowLiked
          ? 'Added "${song.title}" to your likes'
          : 'Removed "${song.title}" from your likes',
      iconData:
          nowLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
    );
  }

  void _handleShareTap(Song song) {
    showHomeShareSheet(context, song);
  }

  Future<void> _handleAddToPlaylist(Song song) async {
    if (supabase.auth.currentUser == null) {
      final didLogin = await AuthDialogs.showLoginRequired(
        context,
        title: 'Sign in to create playlists',
        message:
            'Organize your favorite songs into playlists and keep them available across your devices by signing in.',
        actionLabel: 'Sign In',
      );
      if (!didLogin || !mounted) return;
    }
    _showAnimatedMessage(
      'Added "${song.title}" to playlist',
      iconData: Icons.playlist_add_rounded,
    );
  }

  void _handleAddToQueue(Song song) {
    final musicService = p.Provider.of<MusicService>(context, listen: false);
    musicService.addToQueue(song);
    _showAnimatedMessage(
      'Added "${song.title}" to queue',
      iconData: Icons.queue_music_rounded,
    );
  }

  void _handleShowDetails(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongDetailScreen(songId: song.id),
      ),
    );
  }

  void _animateLikeButton(String songId) {
    if (!mounted) return;
    setState(() => _animatedLikes[songId] = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _animatedLikes[songId] = false);
      }
    });
  }

  void _showAnimatedMessage(String message,
      {bool isError = false, IconData? iconData}) {
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (_) {}
      _overlayEntry = null;
      try {
        _animationController.reset();
      } catch (_) {}
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).viewPadding.top + 20,
          left: 20,
          right: 20,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              elevation: 20,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isError
                        ? [
                            const Color(0xFFFF6B6B).withOpacity(0.95),
                            const Color(0xFFFF5757).withOpacity(0.98),
                          ]
                        : [
                            const Color(0xFF51CF66).withOpacity(0.95),
                            const Color(0xFF40C057).withOpacity(0.98),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isError
                        ? const Color(0xFFFFE0E0).withOpacity(0.3)
                        : const Color(0xFFE8F5E8).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isError
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFF51CF66))
                          .withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                      spreadRadius: -5,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -3,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        iconData ??
                            (isError
                                ? Icons.error_outline_rounded
                                : Icons.check_circle_outline_rounded),
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                isError ? 'Error' : 'Success',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  DateTime.now().toString().substring(11, 16),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 12),
                      child: GestureDetector(
                        onTap: () {
                          try {
                            _overlayEntry?.remove();
                          } catch (_) {}
                          _overlayEntry = null;
                          try {
                            _animationController.reverse();
                          } catch (_) {}
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
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

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          try {
            _overlayEntry?.remove();
          } catch (_) {}
          _overlayEntry = null;
        });
      }
    });
  }

  Future<void> _handleDownloadTap(Song song) async {
    if (!mounted) return;
    final musicService = p.Provider.of<MusicService>(context, listen: false);
    if (kIsWeb) {
      try {
        final response = await http.get(Uri.parse(song.audioUrl));
        if (response.statusCode == 200) {
          PlatformUtils.downloadFile(
              response.bodyBytes, '${song.title}.mp3', 'audio/mpeg');
          await musicService.incrementDownloadCount(song);
          if (mounted) {
            _showAnimatedMessage('Downloading "${song.title}"',
                iconData: Icons.download_done_rounded);
          }
        } else {
          if (mounted) {
            _showAnimatedMessage('Download failed. Please try again.',
                isError: true);
          }
        }
      } catch (e) {
        if (mounted) {
          _showAnimatedMessage('Download error. Please try again.',
              isError: true);
        }
      }
    } else {
      if (mounted) {
        _showAnimatedMessage('Download is only available on the web app.',
            isError: true);
      }
    }
  }

  String formatBoostedNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Widget _buildFancyIconLabel(IconData icon, int count,
      {Color? color, String? songId}) {
    final musicService = p.Provider.of<MusicService>(context);
    final bool isLiked =
        songId != null ? musicService.isSongLikedLocally(songId) : false;
    IconData actualIcon = icon;
    Color actualColor = color ?? subtitleColor;
    if (icon == Icons.thumb_up_alt_rounded ||
        icon == Icons.thumb_up_alt_outlined) {
      actualIcon =
          isLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined;
      actualColor = isLiked ? primaryColor : subtitleColor;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(actualIcon, color: actualColor, size: 18),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              formatBoostedNumber(count),
              style: const TextStyle(color: textColor, fontSize: 11),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<String> _fetchUsername() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return 'Guest';
      final response = await supabase
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();
      return response?['username'] ?? user.email?.split('@').first ?? 'User';
    } catch (e) {
      debugPrint('Error fetching username: $e');
      return supabase.auth.currentUser?.email?.split('@').first ?? 'User';
    }
  }

  Widget _buildLoadingShimmer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'animations/loader_animation.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            repeat: true,
            animate: true,
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading your musical journey...',
            style: TextStyle(
                color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please wait a moment while we fetch your data.',
            style: TextStyle(color: subtitleColor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: const Color(0xFFE63950), size: 60),
          const SizedBox(height: 20),
          Text(
            _errorMessage.isNotEmpty
                ? _errorMessage
                : 'Something went wrong. Please try again.',
            style: const TextStyle(color: textColor, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isError = false;
                _errorMessage = '';
              });
              _loadHomeData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: secondaryColor,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: article.imageUrl,
                height: 100,
                width: 250,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: secondaryColor,
                  child: const Center(
                      child: Icon(Icons.newspaper,
                          color: subtitleColor, size: 40)),
                ),
                errorWidget: (context, url, error) => Container(
                  color: secondaryColor,
                  child: const Center(
                      child: Icon(Icons.newspaper,
                          color: subtitleColor, size: 40)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTileSongItem(Song s, int i, List<Song> songQueue) {
    return p.Consumer<MusicService>(
      builder: (context, musicService, child) {
        final isCurrent = musicService.currentSong?.id == s.id;
        final isPlaying = musicService.isPlaying && isCurrent;
        final int currentLikes = s.likes;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              musicService.playSong(s, songQueue, initialIndex: i);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MusicPlayerScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: isCurrent
                    ? LinearGradient(
                        colors: [primaryColor.withOpacity(0.14), cardColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: isCurrent ? null : cardColor.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent
                      ? primaryColor.withOpacity(0.45)
                      : Colors.white.withOpacity(0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: isPlaying
                        ? Icon(Icons.equalizer_rounded,
                            color: primaryColor, size: 22)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: subtitleColor),
                          ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Hero(
                      tag: 'song_cover_${s.id}',
                      child: CachedNetworkImage(
                        imageUrl: s.albumArtUrl,
                        height: 54,
                        width: 54,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: secondaryColor,
                          child: const Icon(Icons.music_note,
                              size: 24, color: subtitleColor),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: secondaryColor,
                          child: const Icon(Icons.music_note,
                              size: 24, color: subtitleColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isCurrent ? primaryColor : textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          s.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      musicService.isSongLikedLocally(s.id)
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: musicService.isSongLikedLocally(s.id)
                          ? primaryColor
                          : subtitleColor,
                      size: 22,
                    ),
                    onPressed: () => _handleLikeTap(s),
                  ),
                  GestureDetector(
                    onTap: () => _handleLikeTap(s),
                    child: Text(
                      formatBoostedNumber(currentLikes),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumHeroSection() {
    final heroQueue = _dailyRecommendedSongs.isNotEmpty
        ? _dailyRecommendedSongs
        : recommendedSongs.isNotEmpty
            ? recommendedSongs
            : _chartTopSongs.isNotEmpty
                ? _chartTopSongs
                : trendingSongs.isNotEmpty
                    ? trendingSongs
                    : widget.allSongs;

    if (heroQueue.isEmpty) {
      return const SizedBox.shrink();
    }

    final song = heroQueue.first;
    final musicService = p.Provider.of<MusicService>(context, listen: false);
    final durationMinutes = song.durationSeconds > 0
        ? '${(song.durationSeconds / 60).ceil()} min'
        : 'Featured now';

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(spacingXl, spacingSm, spacingXl, spacingXl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: song.albumArtUrl,
              height: 256,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.12),
                      Colors.black.withOpacity(0.22),
                      Colors.black.withOpacity(0.82),
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFB88919).withOpacity(0.12),
                      Colors.transparent,
                      Colors.black.withOpacity(0.18),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.32),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
                child: Text(
                  'Daily pick',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${song.artist} • $durationMinutes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start with a standout track selected from your latest recommendations.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.70),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            musicService.playSong(song, heroQueue,
                                initialIndex: 0);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MusicPlayerScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: secondaryColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text(
                            'Play',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: Colors.black.withOpacity(0.20),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: () => _handleShowDetails(song),
                          tooltip: 'Song details',
                          icon: const Icon(
                            Icons.more_horiz_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMiniDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildContinueListeningCard(
    Song song,
    int index,
    List<Song> songs,
    double progress,
    Duration savedPosition,
  ) {
    final musicService = p.Provider.of<MusicService>(context, listen: false);

    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.mediumImpact();
            musicService.playSong(
              song,
              songs,
              initialIndex: index,
              startPosition: savedPosition,
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MusicPlayerScreen()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF191919), Color(0xFF111111)],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: song.albumArtUrl,
                        height: 132,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.12),
                              Colors.black.withOpacity(0.55),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.38),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: const Text(
                                  'Resume',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(progress * 100).round()}%',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress <= 0 ? 0.04 : progress,
                              minHeight: 5,
                              backgroundColor: Colors.white.withOpacity(0.10),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFC8901F)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 16,
                            color: primaryColor.withOpacity(0.92),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            savedPosition > Duration.zero
                                ? 'Resume at ${_formatMiniDuration(savedPosition)}'
                                : 'Play from the start',
                            style: TextStyle(
                              color: primaryColor.withOpacity(0.92),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
  }

  Widget _buildContinueListeningSection(RecentService recentService) {
    final recentSongs = recentService.recentSongs;
    final songs = recentSongs.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionDivider(
          title: 'Jump back in',
          badge: 'Recently played',
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _SongListScreen(
                  songs: recentSongs,
                  title: 'Jump back in',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: spacingMd),
        SizedBox(
          height: 272,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: spacingLg),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: spacingLg,
                  left: index == 0 ? spacingXs : 0,
                ),
                child: _buildContinueListeningCard(
                  song,
                  index,
                  songs,
                  recentService.getProgressForSong(song.id),
                  recentService.getSavedPositionForSong(song.id),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: sectionBottomMargin),
      ],
    );
  }

  Widget _buildDailyRecommendationsSection() {
    final isExpanded = _expandedSections['dailyRecs'] ?? false;
    final displayCount = isExpanded
        ? _dailyRecommendedSongs.length
        : (_dailyRecommendedSongs.length > 15
            ? 15
            : _dailyRecommendedSongs.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionDivider(
          title: 'Made for you',
          badge: 'Fresh picks',
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _SongListScreen(
                  songs: _dailyRecommendedSongs,
                  title: 'Made for you',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: spacingMd),
        if (_dailyRecsLoaded && _dailyRecommendedSongs.isNotEmpty)
          SizedBox(
            height: 276,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: spacingLg),
              itemCount: displayCount,
              itemBuilder: (context, index) {
                final song = _dailyRecommendedSongs[index];
                return Padding(
                  padding: EdgeInsets.only(
                      right: spacingLg, left: index == 0 ? spacingXs : 0),
                  child: _buildSongCard(song, index, _dailyRecommendedSongs),
                );
              },
            ),
          )
        else if (!_dailyRecsLoaded)
          SizedBox(
            height: 276,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: spacingLg),
              itemCount: 8,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                    right: spacingLg, left: index == 0 ? spacingXs : 0),
                child: const HomeShimmerSongCard(),
              ),
            ),
          )
        else
          const HomeEmptyState(
            icon: Icons.refresh_outlined,
            message:
                'Your recommendations are being prepared. Check back soon!',
          ),
        const SizedBox(height: sectionBottomMargin),
      ],
    );
  }

  Widget _buildMoodActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionDivider(
          title: 'Mood mixes',
          badge: 'Soundtracks for now',
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _SongListScreen(
                  songs: _moodActivitySongs,
                  title: 'Mood mixes',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: spacingMd),
        if (_moodActivityLoaded && _moodActivitySongs.isNotEmpty)
          SizedBox(
            height: 276,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: spacingLg),
              itemCount: _moodActivitySongs.length > 15
                  ? 15
                  : _moodActivitySongs.length,
              itemBuilder: (context, index) {
                final song = _moodActivitySongs[index];
                return Padding(
                  padding: EdgeInsets.only(
                      right: spacingLg, left: index == 0 ? spacingXs : 0),
                  child: _buildSongCard(song, index, _moodActivitySongs),
                );
              },
            ),
          )
        else if (!_moodActivityLoaded)
          SizedBox(
            height: 276,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: spacingLg),
              itemCount: 8,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                    right: spacingLg, left: index == 0 ? spacingXs : 0),
                child: const HomeShimmerSongCard(),
              ),
            ),
          )
        else
          const HomeEmptyState(
            icon: Icons.mood_outlined,
            message:
                'Mood-based playlists are being prepared. Check back soon!',
          ),
        const SizedBox(height: sectionBottomMargin),
      ],
    );
  }

  void _showPlaylistSongs(BuildContext context, GeneratedPlaylist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionTitle(
          title: 'Music stories',
          icon: Icons.newspaper_rounded,
          subtitle: 'Fresh headlines from the music world.',
          showSeeAll: _newsArticles.isNotEmpty,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      NewsListScreen(articles: _newsArticles)),
            );
          },
        ),
        const SizedBox(height: spacingMd),
        if (_newsLoaded && _newsArticles.isNotEmpty)
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: spacingLg),
              itemCount: _newsArticles.length > 10 ? 10 : _newsArticles.length,
              itemBuilder: (context, index) {
                final article = _newsArticles[index];
                return Padding(
                  padding: EdgeInsets.only(
                      right: spacingMd, left: index == 0 ? spacingXs : 0),
                  child: _buildNewsCard(article),
                );
              },
            ),
          )
        else if (!_newsLoaded)
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: spacingXl),
              itemCount: 5,
              itemBuilder: (context, index) => const HomeShimmerNewsCard(),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(
                horizontal: spacingXl, vertical: spacingXl),
            child: HomeEmptyState(
              icon: Icons.newspaper,
              message: 'Could not load news at the moment.',
            ),
          ),
        const SizedBox(height: sectionBottomMargin),
      ],
    );
  }

  Widget _buildFeaturedPlaylistsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionDivider(
          title: 'Featured playlists',
          badge: 'Curated collections',
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _PlaylistsListScreen(
                  playlists: _allFeaturedPlaylists,
                  title: 'Featured playlists',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: spacingMd),
        if (_featuredPlaylistsLoaded && _allFeaturedPlaylists.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final cardHeight = screenWidth < 360 ? 180.0 : 200.0;

              return SizedBox(
                height: cardHeight,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: spacingLg),
                  itemCount: _allFeaturedPlaylists.length > 12
                      ? 12
                      : _allFeaturedPlaylists.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                          right: spacingMd, left: index == 0 ? spacingXs : 0),
                      child: HomeAnimatedPlaylistCard(
                          playlist: _allFeaturedPlaylists[index]),
                    );
                  },
                ),
              );
            },
          )
        else if (!_featuredPlaylistsLoaded)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: spacingLg),
              itemCount: 8,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                    right: spacingMd, left: index == 0 ? spacingXs : 0),
                child: const HomeShimmerPlaylistCard(),
              ),
            ),
          )
        else
          const HomeEmptyState(
            icon: Icons.playlist_play,
            message: 'Creating your personalized playlists...',
          ),
        const SizedBox(height: sectionBottomMargin),
      ],
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionDivider(
          title: 'Top charts',
          badge: 'Most played',
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _SongListScreen(
                  songs: _chartTopSongs,
                  title: 'Top Charts',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: spacingMd),
        if (_chartsLoaded && _chartTopSongs.isNotEmpty)
          SizedBox(
            height: 276,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: spacingLg),
              itemCount:
                  _chartTopSongs.length > 18 ? 18 : _chartTopSongs.length,
              itemBuilder: (context, index) {
                final song = _chartTopSongs[index];
                return Padding(
                  padding: EdgeInsets.only(
                      right: spacingLg, left: index == 0 ? spacingXs : 0),
                  child: _buildSongCard(song, index, _chartTopSongs),
                );
              },
            ),
          )
        else if (!_chartsLoaded)
          SizedBox(
            height: 276,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: spacingLg),
              itemCount: 8,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                    right: spacingLg, left: index == 0 ? spacingXs : 0),
                child: const HomeShimmerSongCard(),
              ),
            ),
          )
        else
          const HomeEmptyState(
            icon: Icons.bar_chart_rounded,
            message: 'Charts are currently unavailable.',
          ),
        const SizedBox(height: sectionBottomMargin),
      ],
    );
  }

  Widget _buildEmergingArtistsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionDivider(
          title: 'Emerging Artists',
          badge: 'New talent',
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _ArtistsListScreen(
                  artists: emergingArtists,
                  title: 'Emerging Artists',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: spacingMd),
        if (emergingArtists.isNotEmpty)
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: spacingXl),
              itemCount: emergingArtists.length,
              itemBuilder: (context, index) {
                return HomeArtistCard(
                  artist: emergingArtists[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtistDetailScreen(
                            artistId: emergingArtists[index].id),
                      ),
                    );
                  },
                );
              },
            ),
          )
        else
          const HomeEmptyState(
            icon: Icons.person_outline,
            message: 'No emerging artists available.',
          ),
        const SizedBox(height: sectionBottomMargin),
      ],
    );
  }

  Widget _buildSongCard(Song s, int i, List<Song> songQueue) {
    final isHovered = _hoveredSongId == s.id;

    return HomeSongCard(
      song: s,
      index: i,
      songQueue: songQueue,
      isHovered: isHovered,
      hoveredSongId: _hoveredSongId,
      shimmerAnimation: _shimmerAnimation,
      liveActivityAnimation: _liveActivityAnimation,
      pulseAnimation: _pulseAnimation,
      onHover: (id) {
        HapticFeedback.selectionClick();
        setState(() => _hoveredSongId = id);
      },
      onHoverExit: () => setState(() => _hoveredSongId = null),
      onLike: _handleLikeTap,
      onDownload: _handleDownloadTap,
      onShare: _handleShareTap,
      onAddToPlaylist: _handleAddToPlaylist,
      onAddToQueue: _handleAddToQueue,
      onShowDetails: _handleShowDetails,
    );
  }

  String _formatUserCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final bool showGlobalLoader = isLoading &&
        banners.isEmpty &&
        !_dailyRecsLoaded &&
        !_moodActivityLoaded &&
        !_featuredPlaylistsLoaded &&
        !_newsLoaded &&
        _chartTopSongs.isEmpty &&
        recommendedSongs.isEmpty;

    return Scaffold(
      backgroundColor: secondaryColor,
      body: SafeArea(
        child: _isError
            ? _buildErrorWidget()
            : showGlobalLoader
                ? _buildLoadingShimmer()
                : Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _backgroundGradientAnimation,
                          builder: (context, child) {
                            final animation =
                                _backgroundGradientAnimation.value;

                            return ClipRect(
                              child: Stack(
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color.lerp(
                                            const Color(0xFF0A0A0B),
                                            const Color(0xFF17102E),
                                            animation * 0.65,
                                          )!,
                                          Color.lerp(
                                            const Color(0xFF0D0826),
                                            const Color(0xFF1E1030),
                                            animation * 0.55,
                                          )!,
                                          Color.lerp(
                                            const Color(0xFF0A0A0B),
                                            secondaryColor,
                                            animation * 0.85,
                                          )!,
                                        ],
                                        stops: const [0.0, 0.4, 1.0],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -120 + (animation * 26),
                                    right: -72 + (animation * 18),
                                    child: Container(
                                      width: 320,
                                      height: 320,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            primaryColor.withOpacity(0.18),
                                            primaryColor.withOpacity(0.05),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.42, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -190 + (animation * 20),
                                    left: -120 + ((1 - animation) * 12),
                                    child: Container(
                                      width: 360,
                                      height: 360,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            accentColor.withOpacity(0.18),
                                            accentColor.withOpacity(0.05),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withOpacity(0.03),
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.28),
                                        ],
                                        stops: const [0.0, 0.22, 1.0],
                                      ),
                                    ),
                                  ),
                                  BackdropFilter(
                                    filter: ui.ImageFilter.blur(
                                      sigmaX: 14.0,
                                      sigmaY: 14.0,
                                    ),
                                    child: Container(
                                      color: Colors.black.withOpacity(0.02),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: _loadHomeData,
                        color: primaryColor,
                        backgroundColor: cardColor,
                        child: ListView(
                          padding: EdgeInsets.only(bottom: 110),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            FutureBuilder<String>(
                              future: _fetchUsername(),
                              builder: (context, snapshot) {
                                final username = snapshot.data ?? 'User';
                                return HomeHeader(
                                  username: username,
                                  greeting: _getGreetingMessage(),
                                  onlineUsersText:
                                      '${_formatUserCount(_onlineUsers)} listeners online',
                                  shimmerAnimation: _shimmerAnimation,
                                  liveActivityAnimation: _liveActivityAnimation,
                                  pulseAnimation: _pulseAnimation,
                                  isLoggedIn: supabase.auth.currentUser != null,
                                  onPremiumTap: () async {
                                    if (supabase.auth.currentUser == null) {
                                      final didLogin =
                                          await AuthDialogs.showLoginRequired(
                                        context,
                                        title: 'Go premium with an account',
                                        message:
                                            'Sign in to unlock premium upgrades, ad-free listening, and a more personalized music experience.',
                                        actionLabel: 'Sign In',
                                      );

                                      if (!didLogin || !mounted) return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PremiumSubscriptionPage(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            HomeSearchBar(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              isFocused: _isSearchFocused,
                              songSuggestions: _searchSuggestions,
                              artistSuggestions: _artistSearchSuggestions,
                              showSuggestions: _showSearchSuggestions,
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty &&
                                    _searchSuggestions.isNotEmpty) {
                                  _playSongFromSearch(_searchSuggestions.first);
                                }
                              },
                              onClear: () {
                                _searchController.clear();
                                _searchFocusNode.unfocus();
                              },
                              onMicTap: () {
                                _showAnimatedMessage(
                                  'Voice search coming soon!',
                                  iconData: Icons.mic_off_rounded,
                                );
                              },
                              onPlaySong: _playSongFromSearch,
                              onViewArtist: (artist) {
                                _searchController.clear();
                                _searchFocusNode.unfocus();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ArtistDetailScreen(artistId: artist.id),
                                  ),
                                );
                              },
                            ),
                            p.Consumer<RecentService>(
                              builder: (context, recentService, child) {
                                if (recentService.recentSongs.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return _buildContinueListeningSection(
                                  recentService,
                                );
                              },
                            ),
                            _buildPremiumHeroSection(),
                            HomeLiveActivityBar(
                              nowPlayingCount:
                                  _formatUserCount(_nowPlayingCount),
                              recentActivity: _recentActivity.isNotEmpty
                                  ? _recentActivity.last
                                  : '',
                              pulseAnimation: _pulseAnimation,
                              isVisible: _isLiveActivityVisible,
                              onDismiss: () => setState(
                                  () => _isLiveActivityVisible = false),
                            ),
                            const SizedBox(height: spacingSm),
                            if (keywordSearchResults.isNotEmpty ||
                                _isLoadingKeywordSearch ||
                                _keywordSearchController.text.isNotEmpty) ...[
                              HomeSectionTitle(
                                  title:
                                      'Search Results for "${_keywordSearchController.text}"'),
                              const SizedBox(height: spacingMd),
                              _isLoadingKeywordSearch
                                  ? const HomeVerticalSongListShimmer()
                                  : keywordSearchResults.isNotEmpty
                                      ? ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount:
                                              keywordSearchResults.length,
                                          itemBuilder: (context, index) {
                                            final song =
                                                keywordSearchResults[index];
                                            return _buildListTileSongItem(song,
                                                index, keywordSearchResults);
                                          },
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20.0),
                                          child: Text(
                                            _keywordSearchOutput,
                                            style: const TextStyle(
                                                color: subtitleColor,
                                                fontSize: 16),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                              const SizedBox(height: sectionBottomMargin),
                            ],
                            HomeCategoryTabs(
                              tabs: tabTitles,
                              selectedIndex: _selectedTabIndex,
                              onTabSelected: (index) {
                                HapticFeedback.lightImpact();
                                setState(() => _selectedTabIndex = index);
                              },
                            ),
                            const SizedBox(height: spacingXl),
                            RepaintBoundary(
                              child: HomeSectionTitle(
                                title: tabTitles[_selectedTabIndex],
                                showSeeAll: _filteredSongsForTabs.isNotEmpty,
                                isExpanded:
                                    _showAllTabSongs[_selectedTabIndex] ??
                                        false,
                                onTap: () {
                                  setState(() {
                                    _showAllTabSongs[_selectedTabIndex] =
                                        !(_showAllTabSongs[_selectedTabIndex] ??
                                            false);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: spacingMd),
                            if (_filteredSongsForTabs.isEmpty)
                              const HomeEmptyState(
                                icon: Icons.music_note,
                                message: 'No songs available in this category.',
                              )
                            else if (_showAllTabSongs[_selectedTabIndex] ==
                                true)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredSongsForTabs.length,
                                itemBuilder: (context, index) {
                                  final song = _filteredSongsForTabs[index];
                                  return RepaintBoundary(
                                    child: _buildListTileSongItem(
                                        song, index, _filteredSongsForTabs),
                                  );
                                },
                              )
                            else
                              RepaintBoundary(
                                child: SizedBox(
                                  height: 240,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: spacingXl),
                                    itemCount: _filteredSongsForTabs.length,
                                    itemBuilder: (context, index) {
                                      final song = _filteredSongsForTabs[index];
                                      return Container(
                                        margin: EdgeInsets.only(
                                          right: index <
                                                  _filteredSongsForTabs.length -
                                                      1
                                              ? spacingXl
                                              : spacingSm,
                                        ),
                                        child: _buildSongCard(
                                            song, index, _filteredSongsForTabs),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            const SizedBox(height: spacingSectionLg),
                            if (featuredArtists.isNotEmpty) ...[
                              RepaintBoundary(
                                child: HomeSectionDivider(
                                  title: 'Featured Artists',
                                  badge: 'Handpicked',
                                  onSeeAll: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            _ArtistsListScreen(
                                          artists: featuredArtists,
                                          title: 'Featured Artists',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: spacingMd),
                              RepaintBoundary(
                                child: SizedBox(
                                  height: 150,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: spacingXl),
                                    itemCount: featuredArtists.length,
                                    itemBuilder: (context, index) {
                                      return HomeArtistCard(
                                        artist: featuredArtists[index],
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ArtistDetailScreen(
                                                      artistId:
                                                          featuredArtists[index]
                                                              .id),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: sectionBottomMargin),
                            ],
                            RepaintBoundary(
                                child: _buildDailyRecommendationsSection()),
                            RepaintBoundary(child: _buildMoodActivitySection()),
                            RepaintBoundary(
                                child: _buildFeaturedPlaylistsSection()),
                            RepaintBoundary(child: _buildChartsSection()),
                            RepaintBoundary(
                                child: _buildEmergingArtistsSection()),
                            RepaintBoundary(child: _buildNewsSection()),
                            if (banners.isNotEmpty)
                              RepaintBoundary(
                                child: HomeBannersSection(banners: banners),
                              ),
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(vertical: spacingXl),
                              child: Center(
                                child: Text(
                                  '© Amplify Music 2025',
                                  style: TextStyle(
                                      color: subtitleColor, fontSize: bodyMd),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
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

  void _playSongFromSearch(Song song) {
    final musicService = p.Provider.of<MusicService>(context, listen: false);
    musicService.playSong(song, [song]);

    _searchController.clear();
    _searchFocusNode.unfocus();

    Navigator.push(context, _buildMusicPlayerRoute());
  }
}

class _SongListScreen extends StatelessWidget {
  final List<Song> songs;
  final String title;

  const _SongListScreen({required this.songs, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: spacingSm),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return p.Consumer<MusicService>(
            builder: (context, musicService, child) {
              final isCurrent = musicService.currentSong?.id == song.id;
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: song.albumArtUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        color: cardColor,
                        child:
                            const Icon(Icons.music_note, color: subtitleColor)),
                    errorWidget: (_, __, ___) => Container(
                        color: cardColor,
                        child:
                            const Icon(Icons.music_note, color: subtitleColor)),
                  ),
                ),
                title: Text(song.title,
                    style: TextStyle(
                        color: isCurrent ? primaryColor : textColor,
                        fontWeight: FontWeight.w600)),
                subtitle: Text(song.artist,
                    style: const TextStyle(color: subtitleColor)),
                trailing: IconButton(
                  icon: Icon(
                    musicService.isSongLikedLocally(song.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: musicService.isSongLikedLocally(song.id)
                        ? primaryColor
                        : subtitleColor,
                  ),
                  onPressed: () => _toggleLike(context, song),
                ),
                onTap: () {
                  musicService.playSong(song, songs, initialIndex: index);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MusicPlayerScreen()));
                },
              );
            },
          );
        },
      ),
    );
  }

  void _toggleLike(BuildContext context, Song song) {
    final musicService = p.Provider.of<MusicService>(context, listen: false);
    musicService.toggleLike(song);
  }
}

class _ArtistsListScreen extends StatelessWidget {
  final List<Artist> artists;
  final String title;

  const _ArtistsListScreen({required this.artists, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: spacingSm),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: CachedNetworkImageProvider(artist.imageUrl),
              backgroundColor: cardColor,
            ),
            title: Row(
              children: [
                Text(artist.name,
                    style: const TextStyle(
                        color: textColor, fontWeight: FontWeight.w600)),
                if (artist.isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, color: primaryColor, size: 16),
                ],
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: subtitleColor),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ArtistDetailScreen(artistId: artist.id)),
              );
            },
          );
        },
      ),
    );
  }
}

class _PlaylistsListScreen extends StatelessWidget {
  final List<GeneratedPlaylist> playlists;
  final String title;

  const _PlaylistsListScreen({required this.playlists, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: spacingSm),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: playlist.coverImageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                    color: cardColor,
                    child:
                        const Icon(Icons.playlist_play, color: subtitleColor)),
                errorWidget: (_, __, ___) => Container(
                    color: cardColor,
                    child:
                        const Icon(Icons.playlist_play, color: subtitleColor)),
              ),
            ),
            title: Text(playlist.title,
                style: const TextStyle(
                    color: textColor, fontWeight: FontWeight.w600)),
            subtitle: Text(playlist.description,
                style: const TextStyle(color: subtitleColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right, color: subtitleColor),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PlaylistDetailScreen(playlist: playlist)),
              );
            },
          );
        },
      ),
    );
  }
}
