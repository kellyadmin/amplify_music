import 'dart:convert';
import 'package:http/http.dart' as http;

// IMPORTANT: Replace this with your actual live Render API URL!
const String API_BASE_URL = "https://amplify-ai-api-1.onrender.com";

/// Fetches playlist recommendations from the backend.
/// Uses a POST request to the /recommend_playlist endpoint.
Future<Map<String, dynamic>> getPlaylistRecommendations({
  required String userId,
  required String mood,
  String likedSongs = "",
  double similarityThreshold = 0.05,
  int numMatches = 30,
}) async {
  final url = Uri.parse('$API_BASE_URL/recommend_playlist');
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'user_id': userId,
        'mood': mood,
        'liked_songs': likedSongs,
        'similarity_threshold': similarityThreshold,
        'num_matches': numMatches,
      }),
    );

    if (response.statusCode == 200) {
      // API call successful, parse the JSON response
      return json.decode(response.body);
    } else {
      // API call failed with an error status code from the server
      final errorBody = json.decode(response.body);
      throw Exception('Failed to get playlist: ${response.statusCode} - ${errorBody['detail'] ?? response.reasonPhrase}');
    }
  } catch (e) {
    // Network error (e.g., no internet, server unreachable, CORS issues not caught by server)
    throw Exception('Failed to connect to API: $e');
  }
}

/// Searches for songs by keyword from the backend.
/// Uses a GET request to the /search_song_db endpoint.
Future<Map<String, dynamic>> searchSongs({required String query}) async {
  // Encode the query to handle spaces and special characters
  final url = Uri.parse('$API_BASE_URL/search_song_db?query=${Uri.encodeComponent(query)}');
  try {
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      throw Exception('Failed to search songs: ${response.statusCode} - ${errorBody['detail'] ?? response.reasonPhrase}');
    }
  } catch (e) {
    throw Exception('Failed to connect to API: $e');
  }
}

/// Adds a new song to the database with an auto-generated embedding.
/// Uses a POST request to the /add_song endpoint.
Future<Map<String, dynamic>> addNewSong({
  required String title,
  String artist = "Unknown Artist",
  String genre = "Unknown Genre",
  String mood = "",
  String tempo = "",
}) async {
  final url = Uri.parse('$API_BASE_URL/add_song');
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'title': title,
        'artist': artist,
        'genre': genre,
        'mood': mood,
        'tempo': tempo,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      throw Exception('Failed to add song: ${response.statusCode} - ${errorBody['detail'] ?? response.reasonPhrase}');
    }
  } catch (e) {
    throw Exception('Failed to connect to API: $e');
  }
}
