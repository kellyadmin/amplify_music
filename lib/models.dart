class Song {
  final String id;
  final String title;
  final String artist;
  final String url;
  final String albumArtUrl;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    required this.albumArtUrl,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      artist: map['artist']?.toString() ?? '',
      url: map['audio_url']?.toString() ?? '',
      albumArtUrl: map['album_art_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audio_url': url,
      'album_art_url': albumArtUrl,
    };
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
      songs: (map['songs'] as List<dynamic>? ?? [])
          .map((e) => Song.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
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
