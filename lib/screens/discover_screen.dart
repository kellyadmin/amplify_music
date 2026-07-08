import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart' as p;
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'dart:ui';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:path/path.dart' as path;

import '../constants.dart';
import '../widgets/gradient_text.dart';
import '../widgets/vibrant_card.dart';
import '../widgets/animated_gradient_background.dart';
import '../utils/html.dart' as html;
import '../widgets/floating_premium_video_player.dart';
import '../utils/auth_dialogs.dart';
import 'auth_screen.dart';
import 'upload_video_screen.dart' hide primaryColor, secondaryColor, cardColor, textColor, subtitleColor, surfaceElevated, surfaceGlass;
import 'artist_detail_screen.dart' hide primaryColor, secondaryColor, cardColor, textColor, subtitleColor, surfaceElevated, surfaceGlass;
import 'chat_screen.dart' hide primaryColor, secondaryColor, cardColor, textColor, subtitleColor, surfaceElevated, surfaceGlass;
import '../models.dart';
import '../services/supabase_service.dart';
import '../services/music_service.dart';
import '../services/cache_service.dart';
import 'music_player_screen.dart';
import 'add_artist_screen.dart';

class CuratedPlaylist {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> songIds;

  CuratedPlaylist({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.songIds = const [],
  });

  factory CuratedPlaylist.fromMap(Map<String, dynamic> map) {
    return CuratedPlaylist(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      imageUrl: map['image_url'] as String,
      songIds: (map['song_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();
  final CacheService _cacheService = CacheService();

  List<Artist> _artists = [];
  Map<String, List<Song>> _countryCharts = {};
  List<MusicVideo> _musicVideos = [];
  List<Song> _currentDisplayedCountryChart = [];
  List<Song> _allCountryChartSongs = [];
  List<Song> _oldiesSongs = [];
  bool _showAllArtists = false;
  bool _showAllCountryCharts = false;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isLoadingAllCountryCharts = false;
  bool _isLoadingMusicVideos = true;
  bool _isLoadingCountryCharts = true;
  bool _isLoadingOldies = true;
  Map<String, bool> _animatedLikes = {};
  bool _showAnimatedMessageOverlay = false;
  String _animatedMessageText = '';
  Timer? _animatedMessageTimer;
  Artist? _selectedArtistForRadio;
  List<Song> _currentArtistRadioSongs = [];
  bool _isLoadingArtistRadioSongs = false;
  MusicVideo? _selectedVideoForPlayback;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isFullScreenVideo = false;
  List<VideoComment> _videoComments = [];
  bool _isLoadingComments = false;
  final TextEditingController _commentController = TextEditingController();
  Offset _miniPlayerPosition = const Offset(10, 100);
  bool _showMiniPlayerOverlay = false;
  Timer? _miniPlayerOverlayTimer;
  bool _isMiniPlayerMinimized = false;
  Timer? _contentShuffleTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    debugPrint('DiscoverScreen: initState called');
    _loadAllDiscoverData();
    p.Provider.of<MusicService>(context, listen: false).addListener(_onMusicServiceChange);
  }

  @override
  void dispose() {
    debugPrint('DiscoverScreen: dispose called');
    p.Provider.of<MusicService>(context, listen: false).removeListener(_onMusicServiceChange);
    _animatedMessageTimer?.cancel();
    _contentShuffleTimer?.cancel();
    _miniPlayerOverlayTimer?.cancel();
    _disposeVideoPlayer();
    _commentController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _onMusicServiceChange() {
    if (!mounted) return;
    final musicService = p.Provider.of<MusicService>(context, listen: false);
    _updateSongListsBasedOnMusicService(musicService);
    setState(() {});
  }

  Future<void> _incrementVideoViewCount(String videoId) async {
    try {
      await _supabase.rpc('increment_video_view', params: {'video_id_to_update': videoId});
      debugPrint('Successfully incremented view count for video $videoId');

      if (mounted) {
        setState(() {
          final index = _musicVideos.indexWhere((v) => v.id == videoId);
          if (index != -1) {
            final video = _musicVideos[index];
            _musicVideos[index] = video.copyWith(views: video.views + 1);
          }
          if (_selectedVideoForPlayback?.id == videoId) {
            _selectedVideoForPlayback = _selectedVideoForPlayback?.copyWith(views: _selectedVideoForPlayback!.views + 1);
          }
        });
      }
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  Future<void> _initializeVideoPlayer(MusicVideo video, {bool isFullScreen = true}) async {
    debugPrint('DiscoverScreen: Initializing video player for video: ${video.title} (ID: ${video.id})');
    debugPrint('DiscoverScreen: Video URL: ${video.videoUrl}');

    await _disposeVideoPlayer();
    setState(() {
      _selectedVideoForPlayback = video;
      _isFullScreenVideo = isFullScreen;
      _videoComments.clear();
      // Don't reset mini-player size preference
      // _isMiniPlayerMinimized = false;
    });

    if (isFullScreen) {
      debugPrint('DiscoverScreen: Fetching video comments for video ID: ${video.id}');
      _fetchVideoComments(video.id);
    }

    debugPrint('DiscoverScreen: Incrementing view count for video ID: ${video.id}');
    _incrementVideoViewCount(video.id);

    debugPrint('DiscoverScreen: Creating VideoPlayerController with URL: ${video.videoUrl}');
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(video.videoUrl));

    try {
      debugPrint('DiscoverScreen: Initializing video player...');
      await _videoPlayerController!.initialize();
      debugPrint('DiscoverScreen: Video player initialized successfully');

      debugPrint('DiscoverScreen: Creating ChewieController');
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: _buildVideoLoadingPlaceholder(), // Use custom placeholder
        errorBuilder: (context, errorMessage) {
          debugPrint('DiscoverScreen: Video player error: $errorMessage');
          return Center(
            child: Text(
              'Error playing video: $errorMessage',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          );
        },
      );

      debugPrint('DiscoverScreen: ChewieController created successfully');
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('DiscoverScreen: Error initializing video player: $e');
      _showAnimatedMessage('Error playing video: $e');
      if (mounted) {
        setState(() {
          _selectedVideoForPlayback = null;
        });
      }
    }
  }

  // Helper widget for video placeholder
  Widget _buildVideoLoadingPlaceholder() {
    final video = _selectedVideoForPlayback;
    return Container(
      color: secondaryColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (video != null && video.thumbnailUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: video.thumbnailUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          const CircularProgressIndicator(color: primaryColor),
        ],
      ),
    );
  }

  Future<void> _disposeVideoPlayer() async {
    await _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController = null;
    _chewieController = null;
  }

  void _updateSongDetailsInLists(String songId, bool isLiked, int newLikesCount) {
    void _updateList(List<Song> list) {
      final index = list.indexWhere((s) => s.id == songId);
      if (index != -1) {
        list[index] = list[index].copyWith(likedByUser: isLiked, likes: newLikesCount);
      }
    }
    _updateList(_currentArtistRadioSongs);
    _updateList(_allCountryChartSongs);
    _updateList(_oldiesSongs);
    _countryCharts.values.forEach((chartSongs) {
      _updateList(chartSongs);
    });
    _updateList(_currentDisplayedCountryChart);
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
    _updateList(_currentArtistRadioSongs);
    _updateList(_allCountryChartSongs);
    _updateList(_oldiesSongs);
    _countryCharts.values.forEach((chartSongs) {
      _updateList(chartSongs);
    });
    _updateList(_currentDisplayedCountryChart);
  }

  Future<void> _loadAllDiscoverData({bool refresh = false}) async {
    debugPrint('DiscoverScreen: _loadAllDiscoverData called, refresh: $refresh');
    if (!mounted) return;
    if (!refresh) {
      setState(() {
        _isLoading = true;
        _isLoadingMusicVideos = true;
        _isLoadingCountryCharts = true;
        _isLoadingOldies = true;
        _errorMessage = '';
      });
      await _loadDataFromCache();
    } else {
      _errorMessage = '';
    }

    // Run fetches in parallel for faster loading
    Future.wait([
      _fetchArtists(),
      _fetchMusicVideos(),
      _fetchOldiesSongs(),
      // determineUserCountry must complete before fetchCountryCharts can start
      _supabaseService.determineUserCountry().then((_) => _fetchCountryCharts()),
    ]);

    _startDynamicTimers();
  }

  Future<void> _loadDataFromCache() async {
    debugPrint('DiscoverScreen: _loadDataFromCache called');
    final cachedArtists = await _cacheService.loadFromCache<Artist>('discover_artists.json', Artist.fromMap);
    final cachedMusicVideos = await _cacheService.loadFromCache<MusicVideo>('music_videos.json', MusicVideo.fromMap);
    final cachedCountryCharts = await _cacheService.loadFromCache<Song>('discover_country_chart_${_supabaseService.userCountryCode}.json', Song.fromMap);
    final cachedOldies = await _cacheService.loadFromCache<Song>('discover_oldies.json', Song.fromMap);

    bool hasInitialContent = false;
    if (mounted) {
      if (cachedArtists != null && cachedArtists.isNotEmpty) {
        debugPrint('DiscoverScreen: Loaded ${cachedArtists.length} artists from cache');
        _artists = cachedArtists;
        hasInitialContent = true;
      }
      if (cachedMusicVideos != null && cachedMusicVideos.isNotEmpty) {
        debugPrint('DiscoverScreen: Loaded ${cachedMusicVideos.length} music videos from cache');
        _musicVideos = cachedMusicVideos;
        hasInitialContent = true;
      }
      if (cachedCountryCharts != null && cachedCountryCharts.isNotEmpty) {
        debugPrint('DiscoverScreen: Loaded ${cachedCountryCharts.length} country chart songs from cache');
        _countryCharts[_supabaseService.userCountryCode] = cachedCountryCharts;
        _updateDisplayedCountryChart();
        hasInitialContent = true;
      }
      if (cachedOldies != null && cachedOldies.isNotEmpty) {
        debugPrint('DiscoverScreen: Loaded ${cachedOldies.length} oldies songs from cache');
        _oldiesSongs = cachedOldies;
        hasInitialContent = true;
      }
      if (hasInitialContent) {
        setState(() {
          _isLoading = false;
          debugPrint('DiscoverScreen: Displaying cached data immediately');
        });
      }
    }
  }

  Future<void> _fetchArtists() async {
    debugPrint('DiscoverScreen: _fetchArtists called');
    try {
      final response = await _supabase.from('artists').select().limit(20);
      if (!mounted) return;
      final newArtists = (response as List<dynamic>).map((m) => Artist.fromMap(m as Map<String, dynamic>)).toList();
      await _cacheService.saveToCache<Artist>(newArtists, 'discover_artists.json');
      setState(() {
        _artists = newArtists;
        _isLoading = false;
      });
      debugPrint('DiscoverScreen: Fetched ${newArtists.length} artists');
    } catch (e) {
      debugPrint('Error fetching artists: $e');
      if (mounted) setState(() { _errorMessage = 'Could not load artists.'; _isLoading = false; });
    }
  }

  Future<void> _fetchMusicVideos() async {
    debugPrint('DiscoverScreen: _fetchMusicVideos called');
    final userId = _supabase.auth.currentUser?.id;
    debugPrint('DiscoverScreen: Current user ID: $userId');

    try {
      debugPrint('DiscoverScreen: Fetching music videos from Supabase');
      final videosResponse = await _supabase
          .from('music_videos')
          .select()
          .order('views', ascending: false)
          .limit(20);

      if (!mounted) return;

      if (videosResponse == null) {
        debugPrint('DiscoverScreen: Error fetching music videos: Supabase returned a null response.');
        if(mounted) setState(() => _musicVideos = []);
        return;
      }

      final List<dynamic> videoDataList = videosResponse;
      debugPrint('DiscoverScreen: Received ${videoDataList.length} videos from Supabase');

      if (videoDataList.isEmpty) {
        debugPrint('DiscoverScreen: No music videos were found in the database table. This might be due to RLS policies.');
        if(mounted) setState(() => _musicVideos = []);
        return;
      }

      List<MusicVideo> newMusicVideos = videoDataList
          .map((data) => MusicVideo.fromMap(data as Map<String, dynamic>))
          .toList();

      debugPrint('DiscoverScreen: Processed ${newMusicVideos.length} music videos');

      if (userId != null && newMusicVideos.isNotEmpty) {
        debugPrint('DiscoverScreen: Fetching user like/dislike status for videos');
        final videoIds = newMusicVideos.map((v) => v.id).toList();

        final responses = await Future.wait([
          _supabase
              .from('user_likes_video')
              .select('video_id')
              .in_('video_id', videoIds)
              .eq('user_id', userId),
          _supabase
              .from('user_dislikes_video')
              .select('video_id')
              .in_('video_id', videoIds)
              .eq('user_id', userId),
        ]);

        final likesResponse = responses[0];
        final dislikesResponse = responses[1];

        debugPrint('DiscoverScreen: Likes response: $likesResponse');
        debugPrint('DiscoverScreen: Dislikes response: $dislikesResponse');

        if (likesResponse != null) {
          final likedVideoIds = (likesResponse as List<dynamic>)
              .map((like) => like['video_id'] as String)
              .toSet();

          newMusicVideos = newMusicVideos.map((video) {
            return video.copyWith(likedByUser: likedVideoIds.contains(video.id));
          }).toList();
        }

        if (dislikesResponse != null) {
          final dislikedVideoIds = (dislikesResponse as List<dynamic>)
              .map((dislike) => dislike['video_id'] as String)
              .toSet();

          newMusicVideos = newMusicVideos.map((video) {
            return video.copyWith(dislikedByUser: dislikedVideoIds.contains(video.id));
          }).toList();
        }
      }

      debugPrint('DiscoverScreen: Saving music videos to cache');
      await _cacheService.saveToCache<MusicVideo>(newMusicVideos, 'music_videos.json');

      if (mounted) {
        setState(() {
          _musicVideos = newMusicVideos;
        });
      }

      debugPrint('DiscoverScreen: Successfully updated UI with ${newMusicVideos.length} music videos');
    } catch (e) {
      debugPrint('DiscoverScreen: An error occurred in _fetchMusicVideos: $e');
      debugPrint('DiscoverScreen: Stack trace: ${StackTrace.current}');
      if(mounted) setState(() => _musicVideos = []);
    } finally {
      if (mounted) {
        setState(() => _isLoadingMusicVideos = false);
      }
    }
  }

  Future<void> _fetchCountryCharts() async {
    debugPrint('DiscoverScreen: _fetchCountryCharts called');
    final chartCountry = _supabaseService.userCountryCode.isNotEmpty && _supabaseService.userCountryCode != 'GLOBAL'
        ? _supabaseService.userCountryCode
        : 'GLOBAL';
    try {
      final chartResult = chartCountry == 'GLOBAL'
          ? await _supabase.from('songs').select().order('play_count', ascending: false).limit(20)
          : await _supabase.from('songs').select().eq('country_code', chartCountry).order('play_count', ascending: false).limit(20);
      if (!mounted) return;
      final fetchedChartSongs = (chartResult as List<dynamic>)
          .map((m) => Song.fromMap(m as Map<String, dynamic>))
          .toList();
      await _cacheService.saveToCache<Song>(fetchedChartSongs, 'discover_country_chart_${chartCountry}.json');
      if(mounted){
        setState(() {
          _countryCharts[chartCountry] = fetchedChartSongs;
          _updateDisplayedCountryChart();
        });
      }
      debugPrint('DiscoverScreen: Fetched ${fetchedChartSongs.length} songs for $chartCountry chart');
    } catch (e) {
      debugPrint('Error fetching chart for $chartCountry: $e');
    } finally {
      if(mounted) {
        setState(() => _isLoadingCountryCharts = false);
      }
    }
  }

  Future<void> _fetchOldiesSongs() async {
    debugPrint('DiscoverScreen: _fetchOldiesSongs called');
    try {
      // First check if the release_date column exists
      final columnsResponse = await _supabase
          .from('songs')
          .select()
          .limit(1);

      if (columnsResponse == null || columnsResponse.isEmpty) {
        debugPrint('No songs found in the database');
        return;
      }

      // Check if release_date exists in the first song
      final firstSong = columnsResponse[0] as Map<String, dynamic>;
      final hasReleaseDate = firstSong.containsKey('release_date');

      List<dynamic> response;
      if (hasReleaseDate) {
        response = await _supabase
            .from('songs')
            .select()
            .lte('release_date', '2016-12-31T23:59:59Z')
            .order('play_count', ascending: false)
            .limit(20);
      } else {
        // Fallback: get all songs and filter locally
        response = await _supabase
            .from('songs')
            .select()
            .order('play_count', ascending: false)
            .limit(100); // Get more to filter locally
      }

      if (!mounted) return;

      final musicService = p.Provider.of<MusicService>(context, listen: false);
      List<Song> newOldiesSongs = (response as List<dynamic>)
          .map((data) => Song.fromMap(data as Map<String, dynamic>))
          .toList();

      // If we didn't filter by release_date in the query, filter locally
      if (!hasReleaseDate) {
        newOldiesSongs = newOldiesSongs.where((song) {
          // Try to parse release_date if available, otherwise consider it old
          if (song.releaseDate != null) {
            return song.releaseDate!.isBefore(DateTime(2017));
          }
          return true; // If no release date, include in oldies
        }).toList();
      }

      await _cacheService.saveToCache<Song>(newOldiesSongs, 'discover_oldies.json');

      if (mounted) {
        setState(() {
          _oldiesSongs = newOldiesSongs.map((song) {
            final isLiked = musicService.isSongLikedLocally(song.id);
            return song.copyWith(likedByUser: isLiked);
          }).toList();
        });
      }
      debugPrint('DiscoverScreen: Fetched ${newOldiesSongs.length} oldies songs');
    } catch (e) {
      debugPrint('Error fetching oldies songs: $e. This might be because a `release_date` column is missing from your `songs` table.');
    } finally {
      if (mounted) {
        setState(() => _isLoadingOldies = false);
      }
    }
  }

  Future<void> _fetchAllCountryChartSongs() async {
    if (!mounted) return;
    setState(() => _isLoadingAllCountryCharts = true);
    final chartCountry = _supabaseService.userCountryCode.isNotEmpty && _supabaseService.userCountryCode != 'GLOBAL'
        ? _supabaseService.userCountryCode
        : 'GLOBAL';
    try {
      final chartResult = chartCountry == 'GLOBAL'
          ? await _supabase.from('songs').select().order('play_count', ascending: false)
          : await _supabase.from('songs').select().eq('country_code', chartCountry).order('play_count', ascending: false);
      if (!mounted) return;
      final musicService = p.Provider.of<MusicService>(context, listen: false);
      final allSongs = (chartResult as List<dynamic>)
          .map((m) => Song.fromMap(m as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _allCountryChartSongs = allSongs.map((song) {
            final isLiked = musicService.isSongLikedLocally(song.id);
            return song.copyWith(likedByUser: isLiked);
          }).toList();
          _isLoadingAllCountryCharts = false;
        });
      }
      debugPrint('DiscoverScreen: Fetched all ${allSongs.length} chart songs for $chartCountry');
    } catch (e) {
      debugPrint('Error fetching all chart songs for $chartCountry: $e');
      if (mounted) setState(() => _isLoadingAllCountryCharts = false);
    }
  }

  void _startDynamicTimers() {
    debugPrint('DiscoverScreen: _startDynamicTimers called');
    _contentShuffleTimer?.cancel();
    _contentShuffleTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _shuffleAllContent();
    });
  }

  void _shuffleAllContent() {
    debugPrint('DiscoverScreen: _shuffleAllContent called');
    _updateDisplayedCountryChart();
    _shuffleArtists();
    _shuffleMusicVideos();
    _showAnimatedMessage("Content updated! ✨");
  }

  void _updateDisplayedCountryChart() {
    debugPrint('DiscoverScreen: _updateDisplayedCountryChart called');
    final String userCountryCode = _supabaseService.userCountryCode;
    final String displayChartCountry = userCountryCode != 'GLOBAL' && userCountryCode.isNotEmpty
        ? userCountryCode
        : 'GLOBAL';
    final List<Song> chartSongs = _countryCharts[displayChartCountry] ?? [];
    if (chartSongs.isNotEmpty) {
      final List<Song> shuffledSongs = List.from(chartSongs)..shuffle(_random);
      if (mounted) {
        setState(() {
          _currentDisplayedCountryChart = shuffledSongs.take(10).toList();
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _currentDisplayedCountryChart = [];
        });
      }
    }
  }

  void _shuffleArtists() {
    debugPrint('DiscoverScreen: _shuffleArtists called');
    if (_artists.isNotEmpty) {
      setState(() {
        _artists.shuffle(_random);
      });
    }
  }

  void _shuffleMusicVideos() {
    debugPrint('DiscoverScreen: _shuffleMusicVideos called');
    if (_musicVideos.isNotEmpty) {
      setState(() {
        _musicVideos.shuffle(_random);
      });
    }
  }

  Future<void> _handleLikeTap(Song song) async {
    if (!mounted) return;
    final musicService = p.Provider.of<MusicService>(context, listen: false);
    final bool wasLiked = musicService.isSongLikedLocally(song.id);
    await musicService.toggleLike(song);
    final bool nowLiked = musicService.isSongLikedLocally(song.id);
    final int newLikesCount = song.likes + (nowLiked && !wasLiked ? 1 : (wasLiked && !nowLiked ? -1 : 0));
    _updateSongDetailsInLists(song.id, nowLiked, newLikesCount);
    if (mounted) {
      setState(() {
        _animatedLikes[song.id] = true;
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _animatedLikes[song.id] = false;
          });
        }
      });
      _showAnimatedMessage(nowLiked ? 'You liked "${song.title}"! 🎉' : 'You unliked "${song.title}"');
    }
  }

  Future<void> _handleVideoLike(MusicVideo video) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _showAnimatedMessage('You must be logged in to like videos.');
      return;
    }

    // Optimistic UI update
    final originalLikedStatus = video.likedByUser;
    final newLikedStatus = !originalLikedStatus;
    final newLikesCount = video.likes + (newLikedStatus ? 1 : -1);

    setState(() {
      final index = _musicVideos.indexWhere((v) => v.id == video.id);
      if (index != -1) {
        _musicVideos[index] = _musicVideos[index].copyWith(
          likedByUser: newLikedStatus,
          likes: newLikesCount,
        );
      }
      if (_selectedVideoForPlayback?.id == video.id) {
        _selectedVideoForPlayback = _selectedVideoForPlayback?.copyWith(
          likedByUser: newLikedStatus,
          likes: newLikesCount,
        );
      }
    });

    // Call the RPC function to update the backend
    try {
      await _supabase.rpc('update_video_like', params: {
        'video_id_to_update': video.id,
        'user_id_to_update': userId,
      });
      debugPrint('Successfully updated like status for video ${video.id}');
    } catch (e) {
      _showAnimatedMessage('Error updating like status.');
      // Revert the optimistic update on failure
      setState(() {
        final index = _musicVideos.indexWhere((v) => v.id == video.id);
        if (index != -1) {
          _musicVideos[index] = _musicVideos[index].copyWith(
            likedByUser: originalLikedStatus,
            likes: video.likes,
          );
        }
        if (_selectedVideoForPlayback?.id == video.id) {
          _selectedVideoForPlayback = _selectedVideoForPlayback?.copyWith(
            likedByUser: originalLikedStatus,
            likes: video.likes,
          );
        }
      });
    }
  }

  Future<void> _handleVideoDislike(MusicVideo video) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _showAnimatedMessage('You must be logged in to dislike videos.');
      return;
    }

    // Optimistic UI update
    final originalDislikedStatus = video.dislikedByUser;
    final newDislikedStatus = !originalDislikedStatus;

    setState(() {
      final index = _musicVideos.indexWhere((v) => v.id == video.id);
      if (index != -1) {
        _musicVideos[index] = _musicVideos[index].copyWith(
          dislikedByUser: newDislikedStatus,
        );
      }
      if (_selectedVideoForPlayback?.id == video.id) {
        _selectedVideoForPlayback = _selectedVideoForPlayback?.copyWith(
          dislikedByUser: newDislikedStatus,
        );
      }
    });

    try {
      await _supabase.rpc('update_video_dislike', params: {
        'video_id_to_update': video.id,
        'user_id_to_update': userId,
      });
      debugPrint('Successfully updated dislike status for video ${video.id}');
    } catch (e) {
      _showAnimatedMessage('Error updating dislike status.');
      // Revert the optimistic update on failure
      setState(() {
        final index = _musicVideos.indexWhere((v) => v.id == video.id);
        if (index != -1) {
          _musicVideos[index] = _musicVideos[index].copyWith(
            dislikedByUser: originalDislikedStatus,
          );
        }
        if (_selectedVideoForPlayback?.id == video.id) {
          _selectedVideoForPlayback = _selectedVideoForPlayback?.copyWith(
            dislikedByUser: originalDislikedStatus,
          );
        }
      });
    }
  }

  Future<void> _handleVideoShare(MusicVideo video) async {
    try {
      final String text = 'Check out this music video: ${video.title} by ${video.artist}\n\nWatch on Amplify Music: https://amplifymusic.site/video/${video.id}';

      if (kIsWeb) {
        // For web, we'll copy to clipboard
        _copyToClipboard(text);
        _showAnimatedMessage('Link copied to clipboard!');
      } else {
        // For mobile, we'll show a message that the feature is coming soon
        _showAnimatedMessage('Share feature coming soon for mobile!');
      }
    } catch (e) {
      debugPrint('Error sharing video: $e');
      _showAnimatedMessage('Error sharing video.');
    }
  }

  void _copyToClipboard(String text) {
    if (kIsWeb) {
      // Web-only clipboard functionality
      final textarea = html.TextAreaElement();
      textarea.value = text;
      html.document.body?.append(textarea);
      textarea.select();
      html.document.execCommand('copy');
      textarea.remove();
    }
    // Show confirmation regardless of platform
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(kIsWeb ? 'Link copied to clipboard!' : 'Sharing not available on mobile')),
    );
  }

  Future<void> _fetchVideoComments(String videoId) async {
    if (!mounted) return;
    setState(() => _isLoadingComments = true);
    try {
      final response = await _supabase
          .from('video_comments')
          .select()
          .eq('video_id', videoId)
          .order('created_at', ascending: false);
      final commentsData = response as List;
      if (commentsData.isEmpty) {
        if(mounted) {
          setState(() {
            _videoComments = [];
            _isLoadingComments = false;
          });
        }
        return;
      }
      final userIds = commentsData.map((c) => c['user_id'] as String).toSet().toList();
      final profilesResponse = await _supabase.from('profiles').select('id, username').in_('id', userIds);
      final profilesData = profilesResponse as List;
      final usernameMap = { for (var profile in profilesData) profile['id'] : profile['username'] };
      final comments = commentsData.map((data) {
        final commentMap = data as Map<String, dynamic>;
        commentMap['username'] = usernameMap[commentMap['user_id']] ?? 'Anonymous';
        return VideoComment.fromMap(commentMap);
      }).toList();
      if (mounted) {
        setState(() {
          _videoComments = comments;
        });
      }
      debugPrint('DiscoverScreen: Fetched ${comments.length} comments for video $videoId');
    } catch (e) {
      debugPrint("Error fetching comments: $e");
      if (mounted) {
        _showAnimatedMessage('Could not load comments.');
      }
    } finally {
      if(mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _postComment() async {
    String? userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('DiscoverScreen: Cannot post comment - user not logged in');
      final didLogin = await AuthDialogs.showLoginRequired(
        context,
        title: 'Sign in to join the conversation',
        message:
            'Post comments, connect with other listeners, and keep your activity synced by signing in.',
        actionLabel: 'Sign In',
      );
      if (!didLogin) return;
      userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
    }

    final videoId = _selectedVideoForPlayback?.id;
    final commentText = _commentController.text.trim();

    debugPrint('DiscoverScreen: Posting comment for video ID: $videoId');
    debugPrint('DiscoverScreen: Comment text: $commentText');

    if (videoId == null || commentText.isEmpty) {
      debugPrint('DiscoverScreen: Cannot post comment - missing video ID or empty comment');
      return;
    }

    final originalCommentCount = _selectedVideoForPlayback?.comments ?? 0;
    debugPrint('DiscoverScreen: Original comment count: $originalCommentCount');

    // Optimistic UI update
    setState(() {
      final index = _musicVideos.indexWhere((v) => v.id == videoId);
      if (index != -1) {
        _musicVideos[index] = _musicVideos[index].copyWith(comments: originalCommentCount + 1);
      }
      if (_selectedVideoForPlayback?.id == videoId) {
        _selectedVideoForPlayback = _selectedVideoForPlayback?.copyWith(comments: originalCommentCount + 1);
      }
    });

    try {
      debugPrint('DiscoverScreen: Inserting comment into database');
      // Insert the comment first
      await _supabase.from('video_comments').insert({
        'video_id': videoId,
        'user_id': userId,
        'comment': commentText,
      });

      debugPrint('DiscoverScreen: Comment inserted successfully, incrementing comment count');
      // Then, increment the comment count on the music_videos table
      await _supabase.rpc('increment_video_comment_count', params: {
        'video_id_to_update': videoId
      });

      debugPrint('DiscoverScreen: Comment count incremented successfully');
      _commentController.clear();
      FocusScope.of(context).unfocus();
      _showAnimatedMessage('Comment posted! 🎉');
      _fetchVideoComments(videoId);

    } catch (e) {
      debugPrint("DiscoverScreen: Error posting comment: $e");
      _showAnimatedMessage('Failed to post comment: $e');
      // Revert optimistic update on failure
      setState(() {
        final index = _musicVideos.indexWhere((v) => v.id == videoId);
        if (index != -1) {
          _musicVideos[index] = _musicVideos[index].copyWith(comments: originalCommentCount);
        }
        if (_selectedVideoForPlayback?.id == videoId) {
          _selectedVideoForPlayback = _selectedVideoForPlayback?.copyWith(comments: originalCommentCount);
        }
      });
    }
  }

  Future<void> _editComment(VideoComment comment, String newText) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId != comment.userId) {
      _showAnimatedMessage('You can only edit your own comments.');
      return;
    }

    if (comment.editCount >= 2) {
      _showAnimatedMessage('You can only edit a comment twice.');
      return;
    }

    try {
      await _supabase
          .from('video_comments')
          .update({
        'comment': newText,
        'edit_count': comment.editCount + 1,
      })
          .eq('id', comment.id);

      // Update local state
      setState(() {
        final index = _videoComments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          _videoComments[index] = VideoComment(
            id: comment.id,
            videoId: comment.videoId,
            userId: comment.userId,
            username: comment.username,
            comment: newText,
            createdAt: comment.createdAt,
            editCount: comment.editCount + 1,
          );
        }
      });

      _showAnimatedMessage('Comment updated successfully!');
    } catch (e) {
      debugPrint('Error editing comment: $e');
      _showAnimatedMessage('Error updating comment.');
    }
  }

  Future<void> _deleteComment(VideoComment comment) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId != comment.userId) {
      _showAnimatedMessage('You can only delete your own comments.');
      return;
    }

    try {
      await _supabase
          .from('video_comments')
          .delete()
          .eq('id', comment.id);

      // Update local state
      setState(() {
        _videoComments.removeWhere((c) => c.id == comment.id);

        // Update comment count
        if (_selectedVideoForPlayback?.id == comment.videoId) {
          _selectedVideoForPlayback = _selectedVideoForPlayback?.copyWith(
            comments: _selectedVideoForPlayback!.comments - 1,
          );
        }
      });

      _showAnimatedMessage('Comment deleted successfully!');
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      _showAnimatedMessage('Error deleting comment.');
    }
  }

  Future<void> _handleVideoDownload(MusicVideo video) async {
    if (!mounted) return;
    _showAnimatedMessage('Preparing to download "${video.title}"...');
    if (kIsWeb) {
      try {
        final response = await http.get(Uri.parse(video.videoUrl));
        if (response.statusCode == 200) {
          final blob = html.Blob([response.bodyBytes], 'video/mp4'); // Assuming mp4
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url);
          anchor.setAttribute('download', '${video.title}.mp4');
          html.document.body?.append(anchor);
          anchor.click();
          anchor.remove();
          Future.delayed(const Duration(milliseconds: 100), () {
            html.Url.revokeObjectUrl(url);
          });
          if (mounted) {
            _showAnimatedMessage('Downloading "${video.title}"');
          }
        } else {
          if (mounted) {
            _showAnimatedMessage('Failed to fetch video for download: HTTP ${response.statusCode}');
          }
        }
      } catch (e) {
        if (mounted) {
          _showAnimatedMessage('Web download error: $e');
        }
      }
    } else {
      final dio = Dio();
      try {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage permission denied')));
          }
          return;
        }
        final directory = await getApplicationDocumentsDirectory();
        final savePath = '${directory.path}/${video.title}-${video.id}.mp4';
        final response = await dio.download(video.videoUrl, savePath);
        if (response.statusCode == 200 && mounted) {
          _showAnimatedMessage('Downloaded "${video.title}" to Documents');
        }
      } catch (e) {
        if (mounted) {
          _showAnimatedMessage('Download failed: $e');
        }
      }
    }
  }

  Future<void> _handleArtistSubscription(String artistId, String artistName) async {
    try {
      String? userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        final didLogin = await AuthDialogs.showLoginRequired(
          context,
          title: 'Sign in to subscribe',
          message:
              'Subscribe to artists, get updates on new releases, and build a more personalized feed by signing in.',
          actionLabel: 'Sign In',
        );
        if (!didLogin) return;
        userId = _supabase.auth.currentUser?.id;
        if (userId == null) return;
      }

      // Check if already subscribed
      final isCurrentlySubscribed = await _isUserSubscribed(artistId);

      if (isCurrentlySubscribed) {
        // Unsubscribe
        final response = await _supabase.rpc('unsubscribe_from_artist', params: {
          'artist_id': artistId
        });

        if (response as bool) {
          _showAnimatedMessage('Unsubscribed from $artistName');

          // Update UI
          setState(() {
            if (_selectedVideoForPlayback?.artistId == artistId) {
              _selectedVideoForPlayback = _selectedVideoForPlayback?.copyWith(isSubscribed: false);
            }

            final index = _musicVideos.indexWhere((v) => v.artistId == artistId);
            if (index != -1) {
              _musicVideos[index] = _musicVideos[index].copyWith(isSubscribed: false);
            }
          });
        }
      } else {
        // Subscribe
        final response = await _supabase.rpc('subscribe_to_artist', params: {
          'artist_id': artistId
        });

        if (response as bool) {
          _showAnimatedMessage('Subscribed to $artistName!');

          // Update UI
          setState(() {
            if (_selectedVideoForPlayback?.artistId == artistId) {
              _selectedVideoForPlayback = _selectedVideoForPlayback?.copyWith(isSubscribed: true);
            }

            final index = _musicVideos.indexWhere((v) => v.artistId == artistId);
            if (index != -1) {
              _musicVideos[index] = _musicVideos[index].copyWith(isSubscribed: true);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error handling subscription: $e');
      _showAnimatedMessage('Error updating subscription status.');
    }
  }

  Future<bool> _isUserSubscribed(String artistId) async {
    try {
      final response = await _supabase.rpc('is_user_subscribed_to_artist', params: {
        'artist_id': artistId
      });
      return response as bool;
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return false;
    }
  }

  void _showAnimatedMessage(String message) {
    if (_animatedMessageTimer != null && _animatedMessageTimer!.isActive) {
      _animatedMessageTimer?.cancel();
    }
    setState(() {
      _animatedMessageText = message;
      _showAnimatedMessageOverlay = true;
    });
    _animatedMessageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showAnimatedMessageOverlay = false;
        });
      }
    });
  }

  String formatBoostedNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Widget _buildFancyIconLabel(IconData icon, int count, {Color? color, String? songId}) {
    final musicService = p.Provider.of<MusicService>(context);
    final bool isLiked = songId != null ? musicService.isSongLikedLocally(songId) : false;
    IconData actualIcon = icon;
    Color actualColor = color ?? subtitleColor;
    if (icon == Icons.thumb_up_alt_rounded || icon == Icons.thumb_up_alt_outlined) {
      actualIcon = isLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined;
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAllTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: subtitleColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          if (onSeeAllTap != null)
            InkWell(
              onTap: onSeeAllTap,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'VIEW ALL',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.8), primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Unlock Exclusive Content.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryColor.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              _showAnimatedMessage('Amplify Premium coming soon!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: textColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              elevation: 5,
            ),
            child: const Text(
              'Subscribe to Amplify premium to Stream exclusive',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistText(String artistText) {
    final collabRegex = RegExp(r'\s+(ft|feat|&|,)\s+', caseSensitive: false);
    final match = collabRegex.firstMatch(artistText);
    if (match == null) {
      return Text(
        artistText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: subtitleColor,
          fontSize: 12,
        ),
      );
    }
    final mainArtist = artistText.substring(0, match.start);
    final featuring = artistText.substring(match.start);
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'Inter',
        ),
        children: <TextSpan>[
          TextSpan(text: mainArtist, style: const TextStyle(color: subtitleColor)),
          TextSpan(
            text: featuring,
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSongCard(Song s, List<Song> songQueue, int index) {
    return p.Consumer<MusicService>(
      builder: (context, musicService, child) {
        final bool isPlaying = musicService.currentSong?.id == s.id && musicService.isPlaying;
        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              musicService.playSong(s, songQueue, initialIndex: index);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MusicPlayerScreen(),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: s.albumArtUrl,
                        height: 160,
                        width: 160,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 160,
                          width: 160,
                          color: cardColor,
                          child: const Icon(Icons.music_note, size: 60, color: subtitleColor),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 160,
                          width: 160,
                          color: cardColor,
                          child: const Icon(Icons.error_outline, size: 60, color: subtitleColor),
                        ),
                      ),
                      if (isPlaying)
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Lottie.asset('assets/lottie/audio-playing.json', width: 40, height: 40),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildArtistText(s.artist),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtistCard(Artist artist) {
    return GestureDetector(
      onTap: () async {
        _showAnimatedMessage('Opening ${artist.name} Radio...');
        setState(() {
          _selectedArtistForRadio = artist;
          _isLoadingArtistRadioSongs = true;
          _currentArtistRadioSongs.clear();
        });
        await _fetchSongsForArtistRadio(artist);
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: artist.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CircleAvatar(
                    radius: 40,
                    backgroundColor: cardColor,
                  ),
                  errorWidget: (context, url, error) => CircleAvatar(
                    radius: 40,
                    backgroundColor: primaryColor,
                    child: Text(
                      artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: secondaryColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              artist.name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchSongsForArtistRadio(Artist artist) async {
    if (!mounted) return;
    try {
      final artistSongs = await _supabase
          .from('songs')
          .select()
          .eq('artist', artist.name)
          .order('play_count', ascending: false)
          .limit(50);
      if (artistSongs != null && artistSongs.isNotEmpty) {
        final musicService = p.Provider.of<MusicService>(context, listen: false);
        final List<Song> fetchedSongs = (artistSongs as List)
            .map<Song>((e) => Song.fromMap(e as Map<String, dynamic>))
            .toList();
        _currentArtistRadioSongs = fetchedSongs.map((song) {
          final isLiked = musicService.isSongLikedLocally(song.id);
          return song.copyWith(likedByUser: isLiked);
        }).toList();
      } else {
        _currentArtistRadioSongs = [];
        _showAnimatedMessage('No songs found for ${artist.name}.');
      }
    } catch (e) {
      debugPrint('Error fetching artist radio songs for ${artist.name}: $e');
      _currentArtistRadioSongs = [];
      _showAnimatedMessage('Failed to load ${artist.name} Radio songs: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingArtistRadioSongs = false;
        });
      }
    }
  }

  Widget _buildSongCardShimmer() {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[850]!,
        highlightColor: Colors.grey[800]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 140,
              color: Colors.white,
              margin: const EdgeInsets.only(left: 4),
            ),
            const SizedBox(height: 4),
            Container(
              height: 12,
              width: 100,
              color: Colors.white,
              margin: const EdgeInsets.only(left: 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistCardShimmer() {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[850]!,
        highlightColor: Colors.grey[800]!,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 14,
              width: 80,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSection<T>({
    required bool isLoading,
    required List<T> items,
    required Widget Function(BuildContext context, int index) itemBuilder,
    required Widget shimmerBuilder,
    required String emptyMessage,
    double height = 210,
    int shimmerCount = 5,
  }) {
    if (isLoading && items.isEmpty) {
      return SizedBox(
        height: height,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: shimmerCount,
          itemBuilder: (context, index) => shimmerBuilder,
        ),
      );
    }
    else if (!isLoading && items.isEmpty) {
      return Container(
        height: height - 60,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: subtitleColor, fontSize: 16),
          ),
        ),
      );
    }
    else {
      return SizedBox(
        height: height,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder: itemBuilder,
        ),
      );
    }
  }

  Widget _buildThumbnailLoading() {
    return Container(
      color: cardColor,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 40, color: subtitleColor),
            SizedBox(height: 8),
            Text(
              'Generating thumbnail...',
              style: TextStyle(color: subtitleColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      color: cardColor,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 40, color: subtitleColor),
            SizedBox(height: 8),
            Text(
              'No thumbnail',
              style: TextStyle(color: subtitleColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(MusicVideo video) {
    if (video.thumbnailUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: video.thumbnailUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => _buildThumbnailLoading(),
        errorWidget: (context, url, error) => _buildDefaultThumbnail(), // Fallback to default
      );
    } else {
      return _buildDefaultThumbnail(); // Fallback to default
    }
  }

  Widget _buildYoutubeStyleVideoCard(MusicVideo video) {
    return InkWell(
      onTap: () {
        _initializeVideoPlayer(video);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildVideoThumbnail(video),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_random.nextInt(15) + 1}:${_random.nextInt(50) + 10}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primaryColor,
                    child: Text(
                      video.artist.isNotEmpty ? video.artist[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: secondaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                video.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: subtitleColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              ' • ${formatBoostedNumber(video.views)} views',
                              style: const TextStyle(
                                color: subtitleColor,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              ' • ${_formatUploadDate(video.uploadDate)}',
                              style: const TextStyle(
                                color: subtitleColor,
                                fontSize: 13,
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
          ],
        ),
      ),
    );
  }

  Widget _buildYoutubeStyleShimmerList() {
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = 1;
      if (constraints.maxWidth > 1200) {
        crossAxisCount = 4;
      } else if (constraints.maxWidth > 800) {
        crossAxisCount = 3;
      } else if (constraints.maxWidth > 500) {
        crossAxisCount = 2;
      }

      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: crossAxisCount * 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 0,
          childAspectRatio: 16 / 15,
        ),
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[850]!,
          highlightColor: Colors.grey[800]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: 150,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMoodGenreChip(String label, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        _navigateToMoodGenrePlaylist(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? textColor : cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? secondaryColor : textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final musicService = p.Provider.of<MusicService>(context);
    final bottomPadding = (musicService.currentSong != null ? 70.0 : 0.0);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: secondaryColor,
      appBar: _selectedArtistForRadio != null || (_selectedVideoForPlayback != null && _isFullScreenVideo)
          ? null
          : AppBar(
        backgroundColor: secondaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: textColor),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flash_on, color: primaryColor),
            const SizedBox(width: 8),
            const Text('Tune AI', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Go Live',
            icon: const Icon(Icons.podcasts_outlined, color: primaryColor),
            onPressed: () {
              _showAnimatedMessage('Go Live feature coming soon!');
            },
          ),
          IconButton(
            tooltip: 'Upload Video',
            icon: const Icon(Icons.video_call_outlined, color: textColor),
            onPressed: () {
              debugPrint('DiscoverScreen: Upload Video button pressed');
              _handleVideoUpload();
            },
          ),
          const SizedBox(width: 8), // Spacer
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search, color: textColor),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(
                onSongTap: (song, queue) {
                  musicService.playSong(song, queue);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicPlayerScreen()));
                },
                onArtistTap: (artist) {
                  setState(() => _selectedArtistForRadio = artist);
                  _fetchSongsForArtistRadio(artist);
                },
                onVideoTap: (video) => _initializeVideoPlayer(video),
              )));
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          const Positioned(top: -90, right: -70, child: GlowOrb(size: 300, color: primaryColor, opacity: 0.16)),
          const Positioned(bottom: -120, left: -90, child: GlowOrb(size: 320, color: accentColor, opacity: 0.12)),
          if (_selectedVideoForPlayback != null && _isFullScreenVideo)
            _buildFullScreenVideoPlayer()
          else if (_selectedArtistForRadio != null)
            _buildArtistRadioView()
          else
            RefreshIndicator(
              onRefresh: () => _loadAllDiscoverData(refresh: true),
              color: primaryColor,
              backgroundColor: cardColor,
              child: ListView(
                padding: EdgeInsets.only(bottom: bottomPadding),
                children: <Widget>[
                  SizedBox(
                    height: 50,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildMoodGenreChip('All', isSelected: true),
                        _buildMoodGenreChip('Music'),
                        _buildMoodGenreChip('African Music'),
                        _buildMoodGenreChip('Live'),
                        _buildMoodGenreChip('Podcasts'),
                      ],
                    ),
                  ),
                  _buildUploadBanner(context),
                  _buildSectionHeader(
                    'Artists',
                    onSeeAllTap: _artists.length > 5 ? () {
                      setState(() { _showAllArtists = !_showAllArtists; });
                    } : null,
                  ),
                  const SizedBox(height: 4),
                  _showAllArtists
                      ? _buildAllArtistsList()
                      : _buildHorizontalSection<Artist>(
                    isLoading: _isLoading,
                    items: _artists.take(10).toList(),
                    height: 140,
                    emptyMessage: "No artists found.",
                    shimmerBuilder: _buildArtistCardShimmer(),
                    itemBuilder: (context, index) {
                      return _buildArtistCard(_artists[index]);
                    },
                  ),
                  _buildSectionHeader(
                    'Charts: ${_getCountryName(_supabaseService.userCountryCode)}',
                    onSeeAllTap: (_countryCharts[_supabaseService.userCountryCode] ?? []).isNotEmpty ? () {
                      setState(() => _showAllCountryCharts = true);
                      _fetchAllCountryChartSongs();
                    } : null,
                  ),
                  const SizedBox(height: 4),
                  _showAllCountryCharts
                      ? _buildAllCountryChartsList()
                      : _buildHorizontalSection<Song>(
                    isLoading: _isLoadingCountryCharts,
                    items: _currentDisplayedCountryChart,
                    height: 210,
                    emptyMessage: "Charts are currently empty.",
                    shimmerBuilder: _buildSongCardShimmer(),
                    itemBuilder: (context, index) {
                      return _buildHorizontalSongCard(
                          _currentDisplayedCountryChart[index],
                          _currentDisplayedCountryChart,
                          index);
                    },
                  ),
                  _buildSectionHeader('Music Videos'),
                  const SizedBox(height: 12),
                  _isLoadingMusicVideos && _musicVideos.isEmpty
                      ? _buildYoutubeStyleShimmerList()
                      : _musicVideos.isEmpty
                      ? Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "No music videos available right now.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subtitleColor, fontSize: 16),
                      ),
                    ),
                  )
                      : LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 1;
                      if (constraints.maxWidth > 1200) {
                        crossAxisCount = 4;
                      } else if (constraints.maxWidth > 800) {
                        crossAxisCount = 3;
                      } else if (constraints.maxWidth > 500) {
                        crossAxisCount = 2;
                      }
                      double childAspectRatio = 16 / 15;

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _musicVideos.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 0,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemBuilder: (context, index) {
                          return _buildYoutubeStyleVideoCard(_musicVideos[index]);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    'Golden Oldies (Pre-2017)',
                  ),
                  const SizedBox(height: 4),
                  _buildHorizontalSection<Song>(
                    isLoading: _isLoadingOldies,
                    items: _oldiesSongs,
                    height: 210,
                    emptyMessage: "Finding some classics...",
                    shimmerBuilder: _buildSongCardShimmer(),
                    itemBuilder: (context, index) {
                      return _buildHorizontalSongCard(
                          _oldiesSongs[index],
                          _oldiesSongs,
                          index);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      '© 2025 Amplify Music',
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          if (_selectedVideoForPlayback != null && !_isFullScreenVideo)
            _buildMiniVideoPlayer(),
          if (_showAnimatedMessageOverlay)
            _buildAnimatedMessageOverlay(),
        ],
      ),
    );
  }

  // Handle video upload with debug prints
  Future<void> _handleVideoUpload() async {
    debugPrint('DiscoverScreen: _handleVideoUpload called');

    // Check if user is logged in
    User? user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('DiscoverScreen: User not logged in, showing auth prompt');
      final didLogin = await AuthDialogs.showLoginRequired(
        context,
        title: 'Sign in to upload',
        message:
            'Upload videos, manage your content, and unlock creator tools by signing in.',
        actionLabel: 'Sign In',
      );
      if (!didLogin) return;
      user = _supabase.auth.currentUser;
      if (user == null) return;
    }

    debugPrint('DiscoverScreen: User is logged in, proceeding with upload');
    debugPrint('DiscoverScreen: User ID: ${user.id}');
    debugPrint('DiscoverScreen: User email: ${user.email}');

    // Navigate to upload screen
    debugPrint('DiscoverScreen: Navigating to UploadVideoScreen');
    try {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const UploadVideoScreen(),
        ),
      );

      debugPrint('DiscoverScreen: Returned from UploadVideoScreen with result: $result');

      if (result == true) {
        debugPrint('DiscoverScreen: Upload was successful, refreshing data');
        _loadAllDiscoverData(refresh: true);
        _showAnimatedMessage('Video uploaded successfully! 🎉');
      } else if (result == false) {
        debugPrint('DiscoverScreen: Upload failed or was cancelled');
        _showAnimatedMessage('Video upload failed or was cancelled');
      } else {
        debugPrint('DiscoverScreen: Upload returned null result');
        _showAnimatedMessage('Video upload completed');
      }
    } catch (e) {
      debugPrint('DiscoverScreen: Error during navigation to UploadVideoScreen: $e');
      _showAnimatedMessage('Error navigating to upload screen: $e');
    }
  }

  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: secondaryColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flash_on, color: primaryColor, size: 32),
                    const SizedBox(width: 8),
                    const Text('Tune AI', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Your Ultimate Music Companion', style: TextStyle(color: subtitleColor, fontSize: 14)),
              ],
            ),
          ),
          _buildDrawerItem(icon: Icons.home_filled, text: 'Home', onTap: () => Navigator.pop(context)),
          // Updated Chat button - now opens the full ChatScreen
          _buildDrawerItem(
              icon: Icons.chat_bubble_outline,
              text: 'Chat',
              onTap: () {
                Navigator.pop(context); // Close drawer
                _navigateToChatScreen();
              }
          ),
          const Divider(color: cardColor),
          _buildDrawerItem(icon: Icons.star, text: 'Subscribe to Premium', onTap: () => _showAnimatedMessage('Premium subscription coming soon!')),
          _buildDrawerItem(icon: Icons.settings, text: 'Settings', onTap: () => _showAnimatedMessage('Settings coming soon!')),
          _buildDrawerItem(icon: Icons.help_outline, text: 'Help & Feedback', onTap: () => _showAnimatedMessage('Help & Feedback coming soon!')),
        ],
      ),
    );
  }

  // Method to navigate to ChatScreen
  Future<void> _navigateToChatScreen() async {
    User? user = _supabase.auth.currentUser;
    if (user == null) {
      final didLogin = await AuthDialogs.showLoginRequired(
        context,
        title: 'Sign in to chat',
        message:
            'Join conversations, connect with listeners, and keep your chats synced by signing in.',
        actionLabel: 'Sign In',
      );
      if (!didLogin) return;
      user = _supabase.auth.currentUser;
      if (user == null) return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatScreen(),
      ),
    );
  }

  ListTile _buildDrawerItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: subtitleColor),
      title: Text(text, style: const TextStyle(color: textColor)),
      onTap: onTap,
    );
  }

  Widget _buildFullScreenVideoPlayer() {
    final video = _selectedVideoForPlayback;
    if (video == null) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: secondaryColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildVideoPlayerHeader(video)),
            SliverToBoxAdapter(
              child: (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized)
                  ? AspectRatio(
                aspectRatio: 16 / 9,
                child: Chewie(
                  controller: _chewieController!,
                ),
              )
                  : AspectRatio(
                aspectRatio: 16 / 9,
                // UPDATED: Show thumbnail + spinner while loading
                child: Container(
                  color: secondaryColor,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (video.thumbnailUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: video.thumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      const CircularProgressIndicator(color: primaryColor),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildVideoInfoSection(video)),
            SliverToBoxAdapter(child: _buildCommentsInputSection()),
            _buildCommentsSliverList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayerHeader(MusicVideo video) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
            onPressed: () {
              setState(() => _isFullScreenVideo = false);
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  video.artist,
                  style: const TextStyle(color: subtitleColor, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoInfoSection(MusicVideo video) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            video.title,
            style: const TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Artist row with subscribe button
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor,
                child: Text(
                  video.artist.isNotEmpty ? video.artist[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: secondaryColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.artist,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${formatBoostedNumber(video.views)} views',
                      style: const TextStyle(color: subtitleColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _handleArtistSubscription(video.artistId, video.artist),
                style: ElevatedButton.styleFrom(
                  backgroundColor: video.isSubscribed ? Colors.grey : primaryColor,
                  foregroundColor: secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(video.isSubscribed ? 'Subscribed' : 'Subscribe'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Upload date without "Uploaded by"
          Text(
            _formatUploadDate(video.uploadDate),
            style: const TextStyle(color: subtitleColor, fontSize: 14),
          ),
          const SizedBox(height: 16),
          // Action buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildVideoActionButton(
                  icon: video.likedByUser ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: 'Like',
                  onTap: () => _handleVideoLike(video),
                  isActive: video.likedByUser,
                ),
                const SizedBox(width: 24),
                _buildVideoActionButton(
                  icon: video.dislikedByUser ? Icons.thumb_down : Icons.thumb_down_outlined,
                  label: 'Dislike',
                  onTap: () => _handleVideoDislike(video),
                  isActive: video.dislikedByUser,
                ),
                const SizedBox(width: 24),
                _buildVideoActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () => _handleVideoShare(video),
                ),
                const SizedBox(width: 24),
                _buildVideoActionButton(
                  icon: Icons.download_outlined,
                  label: 'Download',
                  onTap: () => _handleVideoDownload(video),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoActionButton({required IconData icon, required String label, required VoidCallback onTap, bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? primaryColor : Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsInputSection() {
    final bool isLoggedIn = _supabase.auth.currentUser != null;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: TextStyle(color: isLoggedIn ? textColor : subtitleColor),
              decoration: InputDecoration(
                hintText: isLoggedIn ? 'Add a comment...' : 'Login to comment',
                hintStyle: const TextStyle(color: subtitleColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              enabled: isLoggedIn,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: isLoggedIn ? primaryColor : Colors.grey),
            onPressed: isLoggedIn ? _postComment : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSliverList() {
    if (_isLoadingComments) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }
    if (_videoComments.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('Be the first to comment!', style: TextStyle(color: subtitleColor)),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final comment = _videoComments[index];
          return _buildCommentTile(comment);
        },
        childCount: _videoComments.length,
      ),
    );
  }

  Widget _buildCommentTile(VideoComment comment) {
    final userId = _supabase.auth.currentUser?.id;
    final bool isOwnComment = userId == comment.userId;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: primaryColor,
        child: Text(comment.username.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: secondaryColor, fontWeight: FontWeight.bold)),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(comment.username,
                style: const TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ),
          if (isOwnComment)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditCommentDialog(comment);
                } else if (value == 'delete') {
                  _showDeleteCommentDialog(comment);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.comment, style: const TextStyle(color: subtitleColor)),
          if (comment.editCount > 0)
            Text(
              'Edited ${comment.editCount} time${comment.editCount > 1 ? 's' : ''}',
              style: const TextStyle(color: subtitleColor, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: 4),
          Text(
            _formatUploadDate(comment.createdAt),
            style: const TextStyle(color: subtitleColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showEditCommentDialog(VideoComment comment) {
    final TextEditingController controller = TextEditingController(text: comment.comment);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Edit Comment', style: TextStyle(color: textColor)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: textColor),
          decoration: const InputDecoration(
            hintText: 'Enter your comment',
            hintStyle: TextStyle(color: subtitleColor),
            filled: true,
            fillColor: secondaryColor,
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: subtitleColor)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _editComment(comment, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showDeleteCommentDialog(VideoComment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Delete Comment', style: TextStyle(color: textColor)),
        content: const Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
          style: TextStyle(color: subtitleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: subtitleColor)),
          ),
          TextButton(
            onPressed: () {
              _deleteComment(comment);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: const Color(0xFFE63950))),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _toggleMiniPlayerOverlay() {
    _miniPlayerOverlayTimer?.cancel();
    setState(() {
      _showMiniPlayerOverlay = true;
    });
    _miniPlayerOverlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showMiniPlayerOverlay = false;
        });
      }
    });
  }

  Widget _buildMiniVideoPlayer() {
    final video = _selectedVideoForPlayback;
    if (video == null || _videoPlayerController == null) return const SizedBox.shrink();

    return FloatingPremiumVideoPlayer(
      video: video,
      videoController: _videoPlayerController!,
      isPlaying: _videoPlayerController!.value.isPlaying,
      onPlayPause: () {
        setState(() {
          _videoPlayerController!.value.isPlaying
              ? _videoPlayerController!.pause()
              : _videoPlayerController!.play();
        });
      },
      onFullScreen: () {
        setState(() {
          _isFullScreenVideo = true;
        });
      },
      onClose: () {
        _disposeVideoPlayer();
        setState(() {
          _selectedVideoForPlayback = null;
          _isMiniPlayerMinimized = false;
        });
      },
      initialPosition: _miniPlayerPosition,
      onPositionChanged: (newPosition) {
        setState(() {
          _miniPlayerPosition = newPosition;
        });
      },
    );
  }

  void _showPlaybackSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Playback Speed', style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSpeedOption('0.25x', 0.25),
            _buildSpeedOption('0.5x', 0.5),
            _buildSpeedOption('0.75x', 0.75),
            _buildSpeedOption('Normal', 1.0),
            _buildSpeedOption('1.25x', 1.25),
            _buildSpeedOption('1.5x', 1.5),
            _buildSpeedOption('2x', 2.0),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedOption(String label, double speed) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: textColor)),
      onTap: () {
        _videoPlayerController?.setPlaybackSpeed(speed);
        Navigator.pop(context);
        _showAnimatedMessage('Playback speed set to $label');
      },
    );
  }

  String _formatUploadDate(DateTime? date) {
    if (date == null) return 'Unknown date';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  Widget _buildArtistRadioView() {
    return Scaffold(
      backgroundColor: secondaryColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: secondaryColor,
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: _selectedArtistForRadio != null
                  ? Text('${_selectedArtistForRadio!.name} Radio',
                  style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0,1))]))
                  : const Text('Artist Radio',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              background: _selectedArtistForRadio != null
                  ? CachedNetworkImage(
                imageUrl: _selectedArtistForRadio!.imageUrl,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.5),
                colorBlendMode: BlendMode.darken,
              )
                  : Container(color: cardColor),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedArtistForRadio = null;
                  _currentArtistRadioSongs.clear();
                });
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.shuffle, color: primaryColor),
                onPressed: () {
                  setState(() { _currentArtistRadioSongs.shuffle(); });
                  _showAnimatedMessage('Shuffled ${_selectedArtistForRadio?.name} Radio!');
                },
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded, color: primaryColor),
                onPressed: () {
                  _showAnimatedMessage('Downloading all songs from this radio...');
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                if (_isLoadingArtistRadioSongs) {
                  return _buildSongListTileShimmer();
                }
                final song = _currentArtistRadioSongs[index];
                return _buildSongListTile(song, _currentArtistRadioSongs, index);
              },
              childCount: _isLoadingArtistRadioSongs ? 5 : _currentArtistRadioSongs.length,
            ),
          ),
          if (!_isLoadingArtistRadioSongs && _currentArtistRadioSongs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No songs found for ${_selectedArtistForRadio?.name} radio.',
                  style: const TextStyle(color: subtitleColor, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSongListTile(Song s, List<Song> songQueue, int index) {
    final musicService = p.Provider.of<MusicService>(context);
    final bool isPlayingThisSong = musicService.currentSong?.id == s.id;
    return InkWell(
      onTap: () {
        musicService.playSong(s, songQueue, initialIndex: index);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MusicPlayerScreen(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: s.albumArtUrl,
                height: 50,
                width: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: cardColor,
                  height: 50,
                  width: 50,
                ),
                errorWidget: (context, url, error) => Container(
                  color: cardColor,
                  height: 50,
                  width: 50,
                  child: const Icon(Icons.music_note, color: subtitleColor),
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
                    style: TextStyle(
                      color: isPlayingThisSong ? primaryColor : textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.artist,
                    style: const TextStyle(
                      color: subtitleColor,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                s.likedByUser ? Icons.favorite : Icons.favorite_border,
                color: s.likedByUser ? const Color(0xFFE63950) : Colors.white54,
              ),
              onPressed: () => _handleLikeTap(s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongListTileShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[850]!,
        highlightColor: Colors.grey[800]!,
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 14,
                    width: 150,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMessageOverlay() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: Center(
          child: AnimatedOpacity(
            opacity: _showAnimatedMessageOverlay ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: Text(
                      _animatedMessageText,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getCountryName(String code) {
    switch (code) {
      case 'UG': return 'Uganda';
      case 'US': return 'USA';
      case 'UK': return 'UK';
      case 'CA': return 'Canada'; // <-- Fixed: Removed extra colon
      case 'DE': return 'Germany';
      case 'GLOBAL': return 'Global';
      default: return code;
    }
  }

  void _navigateToMoodGenrePlaylist(String label) {
    _showAnimatedMessage('Navigating to $label playlist... (Feature Coming Soon!)');
  }

  Widget _buildAllArtistsList() {
    return Column(
      children: [
        _buildBackButton(),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _artists.length,
          itemBuilder: (context, index) {
            return _buildArtistListTile(_artists[index]);
          },
        ),
      ],
    );
  }

  Widget _buildArtistListTile(Artist artist) {
    return InkWell(
      onTap: () {
        _showAnimatedMessage('Opening ${artist.name} Radio...');
        setState(() {
          _selectedArtistForRadio = artist;
          _isLoadingArtistRadioSongs = true;
          _currentArtistRadioSongs.clear();
        });
        _fetchSongsForArtistRadio(artist);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: artist.imageUrl,
                height: 60,
                width: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => const CircleAvatar(
                  radius: 30,
                  backgroundColor: cardColor,
                ),
                errorWidget: (context, url, error) => CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryColor,
                  child: Text(
                    artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: secondaryColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                artist.name,
                style: const TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (artist.isVerified)
              const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAllCountryChartsList() {
    return Column(
      children: [
        _buildBackButton(),
        if (_isLoadingAllCountryCharts)
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: 10,
            itemBuilder: (context, index) => _buildSongListTileShimmer(),
          )
        else
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _allCountryChartSongs.length,
            itemBuilder: (context, index) {
              return _buildSongListTile(_allCountryChartSongs[index], _allCountryChartSongs, index);
            },
          ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              _showAllArtists = false;
              _showAllCountryCharts = false;
            });
          },
          icon: const Icon(Icons.arrow_back_ios, color: primaryColor, size: 16),
          label: const Text('Back to Discover', style: TextStyle(color: primaryColor, fontSize: 16)),
        ),
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  final Function(Song, List<Song>) onSongTap;
  final Function(Artist) onArtistTap;
  final Function(MusicVideo) onVideoTap;

  const SearchScreen({
    super.key,
    required this.onSongTap,
    required this.onArtistTap,
    required this.onVideoTap,
  });

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<Song> _songResults = [];
  List<Artist> _artistResults = [];
  List<MusicVideo> _videoResults = [];
  String _lastSearchQuery = '';

  Future<void> _performSearch(String query) async {
    if (query.isEmpty || query == _lastSearchQuery) return;
    setState(() {
      _isLoading = true;
      _lastSearchQuery = query;
      _songResults = [];
      _artistResults = [];
      _videoResults = [];
    });

    try {
      // Search songs
      final songResponse = await _supabase.from('songs').select().ilike('title', '%$query%').limit(15);
      if (mounted) {
        setState(() {
          _songResults = (songResponse as List<dynamic>).map((data) => Song.fromMap(data)).toList();
        });
      }

      // Search artists
      final artistResponse = await _supabase.from('artists').select().ilike('name', '%$query%').limit(15);
      if (mounted) {
        setState(() {
          _artistResults = (artistResponse as List<dynamic>).map((data) => Artist.fromMap(data)).toList();
        });
      }

      // Search videos
      final videoResponse = await _supabase.from('music_videos').select().ilike('title', '%$query%').limit(15); // <-- Fixed: Removed extra quote
      if (mounted) {
        setState(() {
          _videoResults = (videoResponse as List<dynamic>).map((data) => MusicVideo.fromMap(data)).toList();
        });
      }

    } catch (e) {
      debugPrint('Error performing search: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: textColor),
          decoration: const InputDecoration(
            hintText: 'Search for songs, artists, videos...',
            hintStyle: TextStyle(color: subtitleColor),
            border: InputBorder.none,
          ),
          onSubmitted: _performSearch,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : ListView(
        children: [
          if (_songResults.isNotEmpty) _buildSearchResultsSection('Songs', _songResults),
          if (_artistResults.isNotEmpty) _buildSearchResultsSection('Artists', _artistResults),
          if (_videoResults.isNotEmpty) _buildSearchResultsSection('Music Videos', _videoResults),
          if (_songResults.isEmpty && _artistResults.isEmpty && _videoResults.isEmpty && _lastSearchQuery.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text('No results found.', style: TextStyle(color: subtitleColor, fontSize: 18)),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildSearchResultsSection(String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(title, style: const TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item is Song) return _buildSongListTile(item, _songResults, index);
            if (item is Artist) return _buildArtistListTile(item);
            if (item is MusicVideo) return _buildMusicVideoListTile(item);
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildSongListTile(Song s, List<Song> songQueue, int index) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(imageUrl: s.albumArtUrl, width: 50, height: 50, fit: BoxFit.cover),
      ),
      title: Text(s.title, style: const TextStyle(color: textColor)),
      subtitle: Text(s.artist, style: const TextStyle(color: subtitleColor)),
      onTap: () => widget.onSongTap(s, songQueue),
    );
  }

  Widget _buildArtistListTile(Artist artist) {
    return ListTile(
      leading: ClipOval(
        child: CachedNetworkImage(imageUrl: artist.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
      ),
      title: Text(artist.name, style: const TextStyle(color: textColor)),
      onTap: () {
        Navigator.pop(context); // Close search screen first
        widget.onArtistTap(artist);
      },
    );
  }

  Widget _buildMusicVideoListTile(MusicVideo video) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: video.thumbnailUrl.isNotEmpty
            ? CachedNetworkImage(imageUrl: video.thumbnailUrl, width: 50, height: 50, fit: BoxFit.cover)
            : Container(
          width: 50,
          height: 50,
          color: cardColor,
          child: const Icon(Icons.videocam, color: subtitleColor),
        ),
      ),
      title: Text(video.title, style: const TextStyle(color: textColor)),
      subtitle: Text(video.artist, style: const TextStyle(color: subtitleColor)),
      onTap: () {
        Navigator.pop(context); // Close search screen first
        widget.onVideoTap(video);
      },
    );
  }
}
