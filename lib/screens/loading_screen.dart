import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import 'amplify_main_screen.dart';
import 'splash_screen.dart';
import '../services/cache_service.dart';

class SongsLoaderScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  const SongsLoaderScreen({Key? key, this.onToggleTheme}) : super(key: key);

  @override
  State<SongsLoaderScreen> createState() => _SongsLoaderScreenState();
}

class _SongsLoaderScreenState extends State<SongsLoaderScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CacheService _cacheService = CacheService();

  List<Song>? _songs;
  String? _error;
  bool _isLoading = true;

  // Briefly shows the branded splash on cold start for a premium first
  // impression. Data loading below still kicks off immediately in
  // parallel, so this never adds real wait time beyond a fixed, short
  // reveal - it does not block or slow down the "instant load" behavior.
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _loadSongsInstantly();
  }

  Future<void> _loadSongsInstantly() async {
    try {
      // Try cache first - instant load (no delay)
      final cachedSongs = await _cacheService.loadFromCache<Song>(
        'songs_cache.json',
        (json) => Song.fromMap(json),
      );

      if (cachedSongs != null && cachedSongs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _songs = cachedSongs;
            _isLoading = false;
          });
        }
        // Refresh in background silently (no await, no delay)
        _refreshDataInBackground();
        return;
      }

      // No cache - fetch from network immediately (no artificial delay)
      final res = await _supabase.from('songs').select().execute();
      final raw = res.data as List<dynamic>;
      final songs = List<Song>.from(
        raw.map((e) => Song.fromMap(e as Map<String, dynamic>)),
      );

      // Cache for next time
      await _cacheService.saveToCache(songs, 'songs_cache.json');

      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshDataInBackground() async {
    try {
      final res = await _supabase.from('songs').select().execute();
      final raw = res.data as List<dynamic>;
      final freshSongs = List<Song>.from(
        raw.map((e) => Song.fromMap(e as Map<String, dynamic>)),
      );
      await _cacheService.saveToCache(freshSongs, 'songs_cache.json');
    } catch (e) {
      debugPrint('Background refresh failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onComplete: () {
          if (mounted) setState(() => _showSplash = false);
        },
      );
    }

    // Show error if any
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: const Color(0xFFE63950), size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _error = null);
                  _loadSongsInstantly();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show main app with songs (or empty if still loading)
    // No loading screen - show app instantly with empty state
    return AmplifyMainScreen(
        allSongs: _songs ?? [], onToggleTheme: widget.onToggleTheme);
  }
}
