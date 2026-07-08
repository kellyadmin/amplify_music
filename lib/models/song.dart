class Song {
  final String id;
  final String title;
  final String artist;
  final String audioUrl; // formerly 'url'
  final String albumArtUrl;
  int playCount;
  final int likes;
  final int downloads;
  final bool likedByUser;
  final String? lyrics;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.albumArtUrl,
    this.playCount = 0,
    this.likes = 0,
    this.downloads = 0,
    this.likedByUser = false,
    this.lyrics,
  });

  // Backward compatibility
  String get url => audioUrl;

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      artist: map['artist']?.toString() ?? '',
      audioUrl: map['audio_url']?.toString() ?? '',
      albumArtUrl: map['album_art_url']?.toString() ?? '',
      playCount: _toInt(map['play_count']),
      likes: _toInt(map['likes']),
      downloads: _toInt(map['downloads']),
      likedByUser: map['liked_by_user'] == true || map['liked_by_user'] == 1,
      lyrics: map['lyrics']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'artist': artist,
    'audio_url': audioUrl,
    'album_art_url': albumArtUrl,
    'play_count': playCount,
    'likes': likes,
    'downloads': downloads,
    'liked_by_user': likedByUser,
    'lyrics': lyrics,
  };

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? audioUrl,
    String? albumArtUrl,
    int? playCount,
    int? likes,
    int? downloads,
    bool? likedByUser,
    String? lyrics,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      audioUrl: audioUrl ?? this.audioUrl,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      playCount: playCount ?? this.playCount,
      likes: likes ?? this.likes,
      downloads: downloads ?? this.downloads,
      likedByUser: likedByUser ?? this.likedByUser,
      lyrics: lyrics ?? this.lyrics,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  String toString() => 'Song(id: $id, title: $title, artist: $artist, audioUrl: $audioUrl)';
}

class Album {
  final String id;
  final String title;
  final String artist;
  final String albumArtUrl;
  final String description;
  final DateTime? releaseDate;
  final List<Song> songs;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    this.description = '',
    this.releaseDate,
    this.songs = const [],
  });

  factory Album.fromMap(Map<String, dynamic> map, List<Song> songs) {
    return Album(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      artist: map['artist']?.toString() ?? '',
      albumArtUrl: map['album_art_url']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      releaseDate: map['release_date'] != null ? DateTime.tryParse(map['release_date']) : null,
      songs: songs,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album_art_url': albumArtUrl,
    'description': description,
    'release_date': releaseDate?.toIso8601String(),
  };
}

class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final String bio;
  final int followers;
  final int following;
  final int downloads;
  final bool followedByUser;
  final bool verified;
  final List<Song> songs;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.bio = '',
    this.followers = 0,
    this.following = 0,
    this.downloads = 0,
    this.followedByUser = false,
    this.verified = false,
    this.songs = const [],
  });

  factory Artist.fromMap(Map<String, dynamic> map, {List<Song> songs = const []}) {
    return Artist(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      bio: map['bio']?.toString() ?? '',
      followers: _toInt(map['followers']),
      following: _toInt(map['following']),
      downloads: _toInt(map['downloads']),
      followedByUser: map['followed_by_user'] == true || map['followed_by_user'] == 1,
      verified: map['verified'] == true || map['verified'] == 1,
      songs: songs,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'image_url': imageUrl,
    'bio': bio,
    'followers': followers,
    'following': following,
    'downloads': downloads,
    'followed_by_user': followedByUser,
    'verified': verified,
  };

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
