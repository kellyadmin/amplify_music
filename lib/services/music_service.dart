// lib/services/music_service.dart

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import 'recent_service.dart';

class MusicService extends ChangeNotifier {
  // Make the player public but not directly assignable
  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  final SupabaseClient _supabase = Supabase.instance.client;
  final RecentService _recentService;

  List<Song> _currentQueue = [];
  final Set<String> _likedSongIds = {};
  List<Song> _likedSongs = [];

  // --- Simplified Getters ---
  // The UI will now listen directly to the player's streams for most of this
  Song? get currentSong {
    if (_player.sequenceState?.currentSource?.tag is! Song) return null;
    return _player.sequenceState?.currentSource?.tag as Song;
  }

  List<Song> get currentQueue => _currentQueue;

  // Changed to non-nullable int: returns -1 when there's no current index.
  // This prevents the `int?` -> `int` assignment errors in UI code that expects an int.
  int get currentIndex => _player.currentIndex ?? -1;

  bool get isPlaying => _player.playing;
  Duration get duration => _player.duration ?? Duration.zero;
  bool get isShuffling => _player.shuffleModeEnabled;
  LoopMode get loopMode => _player.loopMode;
  List<Song> get likedSongs => _likedSongs;

  // Expose player streams directly for the UI to build from
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  ValueNotifier<PlayerState> get playbackStateNotifier => ValueNotifier(_player.playerState);


  int _lastProgressSaveMs = 0;
  String? _lastProgressSongId;

  MusicService(this._recentService) {
    _initAudioPlayer();
    _loadInitialData();
  }

  void _initAudioPlayer() {
    // Configure audio player for optimal performance
    _player.setAudioSource(
      AudioSource.uri(Uri.parse(''), tag: null),
      preload: false,
    ).catchError((_) {
      // Ignore initial empty source error
    });

    // Listen for changes in the currently playing item
    _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState?.currentSource != null) {
        notifyListeners(); // Notify that currentSong might have changed
      }
    });

    // Listen to loop and shuffle mode changes to update UI
    _player.loopModeStream.listen((_) => notifyListeners());
    _player.shuffleModeEnabledStream.listen((_) => notifyListeners());

    _player.positionStream.listen((position) {
      final song = currentSong;
      final duration = _player.duration ?? Duration.zero;
      if (song == null || duration == Duration.zero) return;

      final currentMs = position.inMilliseconds;
      final shouldSave = _lastProgressSongId != song.id ||
          (currentMs - _lastProgressSaveMs).abs() >= 5000 ||
          currentMs >= (duration.inMilliseconds * 0.95);

      if (!shouldSave) return;

      _recentService.updateSongProgress(song.id, position, duration);
      _lastProgressSongId = song.id;
      _lastProgressSaveMs = currentMs;
    });
  }

  Future<void> _loadInitialData() async {
    await fetchLikedSongs();
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.signedOut) {
        fetchLikedSongs();
      }
    });
  }

  bool isSongLikedLocally(String songId) {
    return _likedSongIds.contains(songId);
  }

  // --- Playback Controls ---
  Future<void> playSong(
    Song song,
    List<Song> queue, {
    int? initialIndex,
    Duration? startPosition,
  }) async {
    final nextQueue = List<Song>.from(queue);
    final indexToPlay = initialIndex ?? nextQueue.indexWhere((s) => s.id == song.id);

    if (indexToPlay == -1) return;

    final isSameQueue = _currentQueue.length == nextQueue.length &&
        _currentQueue.asMap().entries.every(
          (entry) => entry.value.id == nextQueue[entry.key].id,
        );

    try {
      if (isSameQueue && _player.audioSource is ConcatenatingAudioSource) {
        _currentQueue = nextQueue;
        await _player.seek(startPosition ?? Duration.zero, index: indexToPlay);
        if (!_player.playing || currentSong?.id != song.id) {
          await _player.play();
        }
        _logInteraction('play', songId: song.id);
        _recentService.addRecentSong(song);
        return;
      }

      _currentQueue = nextQueue;

      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: _currentQueue.map((s) {
          return AudioSource.uri(
            Uri.parse(s.audioUrl.trim()),
            tag: s,
          );
        }).toList(),
      );

      await _player.setAudioSource(
        playlist,
        initialIndex: indexToPlay,
        preload: true,
      );

      if (startPosition != null && startPosition > Duration.zero) {
        await _player.seek(startPosition);
      }

      await _player.play();

      _logInteraction('play', songId: song.id);
      _recentService.addRecentSong(song);
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      // Fade out before pausing for smooth transition
      final currentVolume = _player.volume;
      const fadeDuration = Duration(milliseconds: 300);
      const steps = 10;
      final stepDuration = fadeDuration.inMilliseconds ~/ steps;

      for (int i = steps; i > 0; i--) {
        await _player.setVolume(currentVolume * (i / steps));
        await Future.delayed(Duration(milliseconds: stepDuration));
      }

      await _player.pause();

      // Restore volume for next play
      await _player.setVolume(currentVolume);
    } else {
      await _player.play();
    }
  }

  Future<void> seekToPosition(Duration position) async {
    await _player.seek(position);
  }

  Future<void> playNext() async {
    await _player.seekToNext();
  }

  Future<void> playPrevious() async {
    await _player.seekToPrevious();
  }

  Future<void> toggleShuffle() async {
    await _player.setShuffleModeEnabled(!_player.shuffleModeEnabled);
  }

  Future<void> toggleLoop() async {
    final nextMode = {
      LoopMode.off: LoopMode.one,
      LoopMode.one: LoopMode.all,
      LoopMode.all: LoopMode.off,
    }[_player.loopMode];
    await _player.setLoopMode(nextMode!);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _player.setSpeed(speed);
    notifyListeners();
  }

  /// Set audio session for better performance (call this in app initialization)
  Future<void> configureAudioSession() async {
    try {
      // This helps with faster audio loading and better performance
      await _player.setVolume(1.0);
    } catch (e) {
      debugPrint('Error configuring audio session: $e');
    }
  }

  /// Adds a song to the current queue and, if possible, to the player's playlist.
  Future<void> addToQueue(Song song) async {
    _currentQueue.add(song);

    final currentSource = _player.audioSource;
    if (currentSource is ConcatenatingAudioSource) {
      try {
        await currentSource.add(
          AudioSource.uri(Uri.parse(song.audioUrl.trim()), tag: song),
        );
      } catch (e) {
        debugPrint('Failed to append to existing ConcatenatingAudioSource: $e');
        // As a fallback, rebuild the playlist
        final playlist = ConcatenatingAudioSource(
          children: _currentQueue.map((s) {
            return AudioSource.uri(Uri.parse(s.audioUrl.trim()), tag: s);
          }).toList(),
        );
        try {
          await _player.setAudioSource(playlist, preload: true);
        } catch (e2) {
          debugPrint('Failed to rebuild playlist when adding to queue: $e2');
        }
      }
    } else {
      // No existing concatenating source - build one from the current queue
      final playlist = ConcatenatingAudioSource(
        children: _currentQueue.map((s) {
          return AudioSource.uri(Uri.parse(s.audioUrl.trim()), tag: s);
        }).toList(),
      );
      try {
        await _player.setAudioSource(playlist, preload: true);
      } catch (e) {
        debugPrint('Failed to set playlist when adding to queue: $e');
      }
    }

    notifyListeners();
  }

  // --- Supabase Interaction (Unchanged) ---
  Future<void> fetchLikedSongs() async {
    try {
      _likedSongIds.clear();
      _likedSongs.clear();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('No user logged in, cannot fetch liked songs.');
        notifyListeners();
        return;
      }

      final response = await _supabase
          .from('user_likes_song')
          .select('song_id')
          .eq('user_id', userId);

      final List<String> likedIds = (response as List<dynamic>)
          .map((e) => e['song_id'] as String)
          .toList();

      _likedSongIds.addAll(likedIds);

      if (likedIds.isNotEmpty) {
        final songsResponse = await _supabase
            .from('songs')
            .select()
            .in_('id', likedIds);

        _likedSongs = (songsResponse as List)
            .map((map) => Song.fromMap(map))
            .toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching liked songs: $e');
    }
  }

  Future<void> toggleLike(Song song) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final newLikedState = !_likedSongIds.contains(song.id);
    final int newLikes = song.likes + (newLikedState ? 1 : -1);

    if (newLikedState) {
      _likedSongIds.add(song.id);
      _likedSongs.insert(0, song);
    } else {
      _likedSongIds.remove(song.id);
      _likedSongs.removeWhere((s) => s.id == song.id);
    }
    notifyListeners();

    try {
      if (newLikedState) {
        await _supabase.from('user_likes_song').insert({'user_id': userId, 'song_id': song.id});
      } else {
        await _supabase.from('user_likes_song').delete().eq('user_id', userId).eq('song_id', song.id);
      }
      await _supabase.from('songs').update({'likes': newLikes < 0 ? 0 : newLikes}).eq('id', song.id);
      _logInteraction('like', songId: song.id, value: newLikedState ? 1 : 0);
    } catch (e) {
      // Revert state on error
      if (newLikedState) {
        _likedSongIds.remove(song.id);
        _likedSongs.removeWhere((s) => s.id == song.id);
      } else {
        _likedSongIds.add(song.id);
        _likedSongs.add(song);
      }
      notifyListeners();
      debugPrint('Error toggling like: $e');
    }
  }

  Future<void> incrementDownloadCount(Song song) async {
    final newDownloads = song.downloads + 1;
    try {
      await _supabase.from('songs').update({
        'downloads': newDownloads,
      }).eq('id', song.id);
      _logInteraction('download', songId: song.id);
    } on PostgrestException catch (e) {
      debugPrint("Error incrementing download count: ${e.message}");
    } catch (e) {
      debugPrint("Unexpected error incrementing download count: $e");
    }
  }

  Future<void> _logInteraction(String type, {String? songId, int? value}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _supabase.from('interactions').insert({
        'user_id': userId,
        'type': type,
        'song_id': songId,
        'value': value,
      });
    } catch (e) {
      debugPrint('Error logging interaction: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
