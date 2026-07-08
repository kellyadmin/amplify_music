import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';

class PlaylistService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<AiCuratedPlaylist>> fetchAiCuratedPlaylists() async {
    final response = await supabase
        .from('ai_curated_playlists')
        .select('*, songs(*)') // assumes you have a relation named 'songs'
        .execute();

    if (response.status != 200 || response.data == null) {
      throw Exception('Failed to fetch playlists: ${response.status}');
    }

    final List<dynamic> data = response.data;

    List<AiCuratedPlaylist> playlists = [];

    for (final playlistMap in data) {
      final songsRaw = playlistMap['songs'] as List<dynamic>? ?? [];

      final songs = songsRaw.map((songMap) {
        return Song.fromMap(songMap as Map<String, dynamic>);
      }).toList();

      final playlist = AiCuratedPlaylist.fromMap(
        playlistMap as Map<String, dynamic>,
        songs,
      );

      playlists.add(playlist);
    }

    return playlists;
  }
}
