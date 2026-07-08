import 'package:supabase_flutter/supabase_flutter.dart';

class InteractionService {
  static final _client = Supabase.instance.client;

  // Records a user interaction (e.g., play, like)
  static Future<void> recordInteraction({
    required String userId,
    required String songId,
    required String type,
    double? value,
  }) async {
    final response = await _client.from('user_song_interactions').insert({
      'user_id': userId,
      'song_id': songId,
      'interaction_type': type,
      if (value != null) 'interaction_value': value,
    }).execute();

    if (response.status != 201 && response.status != 200) {
      print('Interaction insert error: ${response}');
    }
  }

  // Fetch recommended song IDs for the given user (from the Postgres function)
  static Future<List<String>> fetchRecommendedSongIds(String userId) async {
    final response = await _client
        .rpc('get_recommendations_for_user', params: {'target_user': userId})
        .execute();

    if (response.status != 200 || response.data == null) {
      print('Recommendation fetch error: ${response}');
      return [];
    }

    final List<dynamic> data = response.data;
    return data.map((item) => item['song_id'] as String).toList();
  }
}
