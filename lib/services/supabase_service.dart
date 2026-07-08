// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  String _userCountryCode = 'GLOBAL';
  String get userCountryCode => _userCountryCode;

  // Web-based geocoding fallback using OpenStreetMap Nominatim
  Future<String?> _getCountryFromWebService(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1'),
        headers: {
          'User-Agent': 'amplify_music/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['address'] != null) {
          final countryCode = data['address']['country_code'] as String?;
          if (countryCode != null && countryCode.isNotEmpty) {
            return countryCode.toUpperCase();
          }
        }
      }
    } catch (e) {
      debugPrint('Web geocoding failed: $e');
    }
    return null;
  }

  Future<void> determineUserCountry() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled. Using default country: GLOBAL');
        _userCountryCode = 'GLOBAL';
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied. Using default country: GLOBAL');
          _userCountryCode = 'GLOBAL';
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied. Using default country: GLOBAL');
        _userCountryCode = 'GLOBAL';
        return;
      }

      // Get current position with null check and timeout
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 15),
        ).timeout(const Duration(seconds: 20));
      } catch (e) {
        debugPrint('Error getting current position: $e. Using default country: GLOBAL');
        _userCountryCode = 'GLOBAL';
        return;
      }

      // Check if position is null
      if (position == null) {
        debugPrint('Position is null. Using default country: GLOBAL');
        _userCountryCode = 'GLOBAL';
        return;
      }

      debugPrint('Got position: ${position.latitude}, ${position.longitude}');

      // Try multiple strategies to get country code
      String? countryCode;

      // Strategy 1: Try direct geocoding with proper exception handling
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 10));

        if (placemarks.isNotEmpty) {
          countryCode = placemarks.first.isoCountryCode?.toUpperCase();
          debugPrint('Strategy 1 (direct geocoding) succeeded: $countryCode');
        }
      } catch (e) {
        debugPrint('Strategy 1 (direct geocoding) failed: $e');
      }

      // Strategy 2: Try with a small offset if first attempt failed
      if (countryCode == null || countryCode!.isEmpty) {
        try {
          // Add a small random offset to avoid exact coordinate issues
          final offsetLat = position.latitude + (Random().nextDouble() * 0.01 - 0.005);
          final offsetLon = position.longitude + (Random().nextDouble() * 0.01 - 0.005);

          final placemarks = await placemarkFromCoordinates(
            offsetLat,
            offsetLon,
          ).timeout(const Duration(seconds: 10));

          if (placemarks.isNotEmpty) {
            countryCode = placemarks.first.isoCountryCode?.toUpperCase();
            debugPrint('Strategy 2 (offset coordinates) succeeded: $countryCode');
          }
        } catch (e) {
          debugPrint('Strategy 2 (offset coordinates) failed: $e');
        }
      }

      // Strategy 3: Try web-based geocoding as a fallback
      if (countryCode == null || countryCode!.isEmpty) {
        try {
          countryCode = await _getCountryFromWebService(position.latitude, position.longitude);
          if (countryCode != null && countryCode.isNotEmpty) {
            debugPrint('Strategy 3 (web geocoding) succeeded: $countryCode');
          }
        } catch (e) {
          debugPrint('Strategy 3 (web geocoding) failed: $e');
        }
      }

      // Check if we got a valid country code
      if (countryCode != null && countryCode.isNotEmpty) {
        _userCountryCode = countryCode;
        debugPrint('User country code determined: $_userCountryCode');
      } else {
        debugPrint('All strategies failed. Using default country: GLOBAL');
        _userCountryCode = 'GLOBAL';
      }
    } catch (e) {
      debugPrint('Unexpected error in determineUserCountry: $e. Using default country: GLOBAL');
      _userCountryCode = 'GLOBAL';
    }
  }

  // Add a method to manually set country code
  Future<void> setUserCountryCode(String countryCode) async {
    _userCountryCode = countryCode.toUpperCase();
    debugPrint('User country code set manually to: $_userCountryCode');

    // Optionally save to SharedPreferences for persistence
    try {
      // import 'package:shared_preferences/shared_preferences.dart';
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setString('user_country_code', _userCountryCode);
    } catch (e) {
      debugPrint('Failed to save country code to preferences: $e');
    }
  }

  // Helper method to fetch global trending songs
  Future<List<Song>> _fetchGlobalTrendingSongs() async {
    debugPrint('Fetching global trending songs');

    try {
      final response = await _client
          .from('songs')
          .select()
          .order('play_count', ascending: false)
          .limit(20);

      if (response.hasError) {
        debugPrint('Error fetching global trending songs: ${response.error!.message}');
        return [];
      }

      final data = response.data as List<dynamic>;
      return data.map((item) => Song.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching global trending songs: $e');
      return [];
    }
  }

  Future<List<Song>> fetchTopSongsByRegion() async {
    // If country is GLOBAL, fetch global trending songs instead
    if (_userCountryCode == 'GLOBAL') {
      debugPrint('Fetching global trending songs since country is GLOBAL');
      return _fetchGlobalTrendingSongs();
    }

    // Otherwise, fetch regional songs directly from the songs table
    final countryCode = _userCountryCode;
    debugPrint('Fetching regional songs for country: $countryCode');

    try {
      final response = await _client
          .from('songs')
          .select()
          .eq('country_code', countryCode)
          .order('play_count', ascending: false)
          .limit(20);

      if (response.hasError) {
        debugPrint('Error fetching regional top songs: ${response.error!.message}');
        debugPrint('Falling back to global trending songs');
        return _fetchGlobalTrendingSongs();
      }

      final data = response.data as List<dynamic>;
      return data.map((item) => Song.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching regional songs: $e');
      debugPrint('Falling back to global trending songs');
      return _fetchGlobalTrendingSongs();
    }
  }

  Future<List<Playlist>> fetchRegionalPlaylists() async {
    // If country is GLOBAL, fetch popular playlists instead
    if (_userCountryCode == 'GLOBAL') {
      debugPrint('Fetching popular playlists since country is GLOBAL');
      final response = await _client
          .from('playlists')
          .select()
          .order('followers', ascending: false)
          .limit(10);

      if (response.hasError) {
        debugPrint('Error fetching popular playlists: ${response.error!.message}');
        return [];
      }

      final data = response.data as List<dynamic>;
      return data.map((item) => Playlist.fromMap(item as Map<String, dynamic>)).toList();
    }

    // Otherwise, fetch regional playlists
    final response = await _client
        .from('regional_playlists')
        .select()
        .eq('region', _userCountryCode);

    if (response.hasError) {
      debugPrint('Error fetching regional playlists: ${response.error!.message}');
      // Fallback to popular playlists
      final fallbackResponse = await _client
          .from('playlists')
          .select()
          .order('followers', ascending: false)
          .limit(10);

      if (fallbackResponse.hasError) {
        debugPrint('Error fetching fallback popular playlists: ${fallbackResponse.error!.message}');
        return [];
      }

      final fallbackData = fallbackResponse.data as List<dynamic>;
      return fallbackData.map((item) => Playlist.fromMap(item as Map<String, dynamic>)).toList();
    }

    final data = response.data as List<dynamic>;
    return data.map((item) => Playlist.fromMap(item as Map<String, dynamic>)).toList();
  }

  Future<List<String>> fetchRecommendedSongIds(String userId, {int limit = 10}) async {
    try {
      final data = await _client.rpc(
        'recommend_songs_for_user',
        params: {
          'target_user': userId,
          'limit_count': limit,
        },
      );

      if (data == null || data is! List) {
        debugPrint('Recommendation RPC returned no data');
        return [];
      }

      return (data as List<dynamic>).map((row) => row['song_id'].toString()).toList();
    } catch (e) {
      debugPrint('Error fetching recommended song IDs: $e');
      return [];
    }
  }

  Future<List<Song>> fetchRecommendedSongs(String userId, {int limit = 10}) async {
    try {
      final ids = await fetchRecommendedSongIds(userId, limit: limit);
      if (ids.isEmpty) return [];

      final response = await _client
          .from('songs')
          .select()
          .in_('id', ids);

      if (response.hasError) {
        debugPrint('Error fetching recommended songs: ${response.error!.message}');
        return [];
      }

      final rows = response.data;
      if (rows == null || rows is! List) {
        debugPrint('Failed to load recommended songs');
        return [];
      }

      return (rows as List<dynamic>).map((m) => Song.fromMap(m as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error in fetchRecommendedSongs: $e');
      return [];
    }
  }

  Future<Artist?> fetchArtistById(String artistId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;

      final response = await _client
          .from('artists')
          .select('id, name, image_url, bio, followers, following, downloads, verified')
          .eq('id', artistId)
          .single();

      // Convert response to Artist model
      Artist artist = Artist.fromMap(response as Map<String, dynamic>);

      // Check if the current user follows this artist
      if (currentUserId != null) {
        try {
          final followResponse = await _client
              .from('user_follows_artist')
              .select('user_id')
              .eq('user_id', currentUserId)
              .eq('artist_id', artistId)
              .limit(1); // Limit to 1, just to check existence

          final isFollowed = followResponse.isNotEmpty;
          // Use copyWith to update the existing artist object with the followed status
          artist = artist.copyWith(followedByUser: isFollowed);
        } catch (e) {
          debugPrint('Error checking follow status: $e');
        }
      }

      return artist;
    } on PostgrestException catch (e) {
      debugPrint('Error fetching artist by ID $artistId: ${e.message}');
      if (e.message?.contains('Row not found') ?? false) {
        return null;
      }
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error fetching artist by ID $artistId: $e');
      return null;
    }
  }

  Future<List<Song>> fetchSongsByArtistName(String artistName) async {
    try {
      // 1. Get songs with an exact artist name match
      final exactMatchResponse = await _client
          .from('songs')
          .select()
          .ilike('artist', artistName);

      // 2. Get songs where the artist is listed first in a collaboration
      final ftResponse1 = await _client
          .from('songs')
          .select()
          .ilike('artist', '$artistName% ft.%');
      final andResponse1 = await _client
          .from('songs')
          .select()
          .ilike('artist', '$artistName% &%');
      final xResponse1 = await _client
          .from('songs')
          .select()
          .ilike('artist', '$artistName% x%');

      // 3. Get songs where the artist is listed second or later in a collaboration
      final ftResponse2 = await _client
          .from('songs')
          .select()
          .ilike('artist', '% ft. $artistName%');
      final andResponse2 = await _client
          .from('songs')
          .select()
          .ilike('artist', '% & $artistName%');
      final xResponse2 = await _client
          .from('songs')
          .select()
          .ilike('artist', '% x $artistName%');

      // Combine all results into a single list
      final List<dynamic> allResults = [
        ...exactMatchResponse,
        ...ftResponse1,
        ...andResponse1,
        ...xResponse1,
        ...ftResponse2,
        ...andResponse2,
        ...xResponse2,
      ];

      // Convert dynamic data to Song objects and remove duplicates
      final Map<String, Song> songMap = {};
      for (var item in allResults) {
        try {
          final song = Song.fromMap(item as Map<String, dynamic>);
          songMap[song.id] = song; // Using a map to automatically handle duplicates by ID
        } catch (e) {
          debugPrint('Error mapping song: $e');
        }
      }

      final List<Song> uniqueSongs = songMap.values.toList();
      debugPrint('Found ${uniqueSongs.length} songs for artist $artistName');
      return uniqueSongs;
    } on PostgrestException catch (e) {
      debugPrint('Error fetching songs for artist $artistName: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Unexpected error fetching songs by artist $artistName: $e');
      return [];
    }
  }

  Future<void> followArtist(String userId, String artistId) async {
    try {
      await _client.from('user_follows_artist').insert({
        'user_id': userId,
        'artist_id': artistId,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('User $userId followed artist $artistId');
    } on PostgrestException catch (e) {
      debugPrint('Error following artist: ${e.message}');
      if (e.code == '23505') { // Unique violation
        debugPrint('User already follows this artist.');
      } else {
        rethrow;
      }
    } catch (e) {
      debugPrint('Unexpected error following artist: $e');
      rethrow;
    }
  }

  Future<void> unfollowArtist(String userId, String artistId) async {
    try {
      await _client.from('user_follows_artist').delete().eq('user_id', userId).eq('artist_id', artistId);
      debugPrint('User $userId unfollowed artist $artistId');
    } on PostgrestException catch (e) {
      debugPrint('Error unfollowing artist: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error unfollowing artist: $e');
      rethrow;
    }
  }

  // Method to increment play count for a song
  Future<void> incrementPlayCount(String songId) async {
    try {
      // First, get the current play count
      final currentSong = await _client
          .from('songs')
          .select('play_count')
          .eq('id', songId)
          .single();

      final currentPlayCount = currentSong['play_count'] as int;

      // Update the play count
      await _client
          .from('songs')
          .update({'play_count': currentPlayCount + 1})
          .eq('id', songId);

      debugPrint('Incremented play count for song $songId to ${currentPlayCount + 1}');
    } catch (e) {
      debugPrint('Error incrementing play count: $e');
    }
  }

  // Method to increment download count for a song
  Future<void> incrementDownloadCount(String songId) async {
    try {
      // First, get the current download count
      final currentSong = await _client
          .from('songs')
          .select('downloads')
          .eq('id', songId)
          .single();

      final currentDownloadCount = currentSong['downloads'] as int;

      // Update the download count
      await _client
          .from('songs')
          .update({'downloads': currentDownloadCount + 1})
          .eq('id', songId);

      debugPrint('Incremented download count for song $songId to ${currentDownloadCount + 1}');
    } catch (e) {
      debugPrint('Error incrementing download count: $e');
    }
  }

  // Method to get trending songs globally
  Future<List<Song>> getTrendingSongs({int limit = 20}) async {
    try {
      final response = await _client
          .from('songs')
          .select()
          .order('play_count', ascending: false)
          .limit(limit);

      if (response.hasError) {
        debugPrint('Error fetching trending songs: ${response.error!.message}');
        return [];
      }

      final data = response.data as List<dynamic>;
      return data.map((item) => Song.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error in getTrendingSongs: $e');
      return [];
    }
  }

  // Method to get new releases
  Future<List<Song>> getNewReleases({int limit = 10}) async {
    try {
      final response = await _client
          .from('songs')
          .select()
          .order('release_date', ascending: false)
          .limit(limit);

      if (response.hasError) {
        debugPrint('Error fetching new releases: ${response.error!.message}');
        return [];
      }

      final data = response.data as List<dynamic>;
      return data.map((item) => Song.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error in getNewReleases: $e');
      return [];
    }
  }
}
