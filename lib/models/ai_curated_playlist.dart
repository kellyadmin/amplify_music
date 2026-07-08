import 'package:amplify_music/models.dart'; // adjust path if needed

class AiCuratedPlaylist {
  final String id;
  final String title;
  final String mood; // e.g., Happy, Sad, Focus
  final String description;
  final String imageUrl; // thumbnail image
  final List<Song> songs;

  AiCuratedPlaylist({
    required this.id,
    required this.title,
    required this.mood,
    required this.description,
    required this.imageUrl,
    required this.songs,
  });

  // Alias getter for imageUrl as coverImageUrl
  String get coverImageUrl => imageUrl;

  factory AiCuratedPlaylist.fromMap(Map<String, dynamic> map, List<Song> songs) {
    return AiCuratedPlaylist(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      mood: map['mood']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      songs: songs,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'mood': mood,
    'description': description,
    'image_url': imageUrl,
  };

  @override
  String toString() {
    return 'AiCuratedPlaylist(id: $id, title: $title, mood: $mood, songs: ${songs.length})';
  }
}
