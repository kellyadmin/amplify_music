// lib/models.dart

class Song {
  final String id;
  final String title;
  final String artist;
  final String url;
  final String albumArtUrl;
  final int playCount;
  final int likes;
  final int downloads;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    required this.albumArtUrl,
    this.playCount = 0,
    this.likes = 0,
    this.downloads = 0,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      artist: map['artist']?.toString() ?? '',
      url: map['audio_url']?.toString() ?? '',
      albumArtUrl: map['album_art_url']?.toString() ?? '',
      playCount: map['play_count'] ?? 0,
      likes: map['likes'] ?? 0,
      downloads: map['downloads'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audio_url': url,
      'album_art_url': albumArtUrl,
      'play_count': playCount,
      'likes': likes,
      'downloads': downloads,
    };
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? url,
    String? albumArtUrl,
    int? playCount,
    int? likes,
    int? downloads,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      url: url ?? this.url,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      playCount: playCount ?? this.playCount,
      likes: likes ?? this.likes,
      downloads: downloads ?? this.downloads,
    );
  }
}

class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final String bio;
  final int followers;
  final int following;
  final int downloads;
  final List<Song> songs;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.bio,
    required this.followers,
    required this.following,
    required this.downloads,
    required this.songs,
  });

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      bio: map['bio']?.toString() ?? '',
      followers: int.tryParse(map['followers']?.toString() ?? '0') ?? 0,
      following: int.tryParse(map['following']?.toString() ?? '0') ?? 0,
      downloads: int.tryParse(map['downloads']?.toString() ?? '0') ?? 0,
      songs: (map['songs'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((songMap) => Song.fromMap(songMap))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'bio': bio,
      'followers': followers,
      'following': following,
      'downloads': downloads,
      'songs': songs.map((song) => song.toMap()).toList(),
    };
  }
}

/// Album model representing a music album with its tracks
class Album {
  final String id;
  final String title;
  final String artistId;
  final String coverUrl;
  final DateTime? releaseDate;
  final String description;
  final List<Song> songs;

  Album({
    required this.id,
    required this.title,
    required this.artistId,
    required this.coverUrl,
    this.releaseDate,
    required this.description,
    required this.songs,
  });

  factory Album.fromMap(Map<String, dynamic> map, List<Song> songs) {
    return Album(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      artistId: map['artist_id']?.toString() ?? '',
      coverUrl: map['cover_url']?.toString() ?? '',
      releaseDate: map['release_date'] != null
          ? DateTime.tryParse(map['release_date'].toString())
          : null,
      description: map['description']?.toString() ?? '',
      songs: songs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist_id': artistId,
      'cover_url': coverUrl,
      'release_date': releaseDate?.toIso8601String(),
      'description': description,
    };
  }
}
