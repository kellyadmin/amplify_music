import '../models.dart';

class GeneratedPlaylist {
  final String id;
  final String title;
  final String description;
  final String coverImageUrl;
  final List<Song> songs;

  GeneratedPlaylist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.songs,
  });

  GeneratedPlaylist copyWith({
    String? id,
    String? title,
    String? description,
    String? coverImageUrl,
    List<Song>? songs,
  }) {
    return GeneratedPlaylist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      songs: songs ?? this.songs,
    );
  }

  factory GeneratedPlaylist.fromMap(Map<String, dynamic> map) {
    return GeneratedPlaylist(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      coverImageUrl: map['cover_image_url'] ?? map['image_url'] ?? 'https://placehold.co/150x150/282828/FFFFFF?text=Mix',
      songs: (map['songs'] as List).map((i) => Song.fromMap(i)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_image_url': coverImageUrl,
      'songs': songs.map((s) => s.toMap()).toList(),
    };
  }
}
