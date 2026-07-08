import 'package:supabase_flutter/supabase_flutter.dart';

Future<List<String>> fetchRecommendedSongIds(String userId, {int limit = 10}) async {
  final response = await Supabase.instance.client
      .rpc('get_user_recommendations', params: {
    'target_user': userId,
    'limit_count': limit,
  });

  if (response.error != null) {
    throw Exception('Error: ${response.error!.message}');
  }

  final data = response.data as List<dynamic>;

  // This assumes the function returns rows with 'song_id'
  return data.map<String>((row) => row['song_id'].toString()).toList();
}
