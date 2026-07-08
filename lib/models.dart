import 'package:flutter/material.dart';

// Represents a Song object with all its properties, directly mapped from Supabase.
// Added 'mood' and 'tags' fields to support richer AI recommendations and search.
class Song {
  final String id;
  final String title;
  final String artist; // Artist name string
  final String albumArtUrl;
  final String audioUrl;
  int likes;
  int downloads;
  int playCount;
  bool likedByUser;
  final String? genre;
  final String? lyrics;
  final int durationSeconds; // Standardized duration field (in seconds)
  final DateTime? releaseDate;
  final String? mood; // Original mood field (singular string)
  final List<String>? tags; // Original tags field (list of strings)
  final List<String>? moods; // NEW: Field for multiple song moods (e.g., ['party', 'sad', 'romantic'])
  // These fields were in a previous `Song` model I provided, but not in yours.
  // Including them as nullable to ensure they don't break if your Supabase table
  // unexpectedly contains them later, but they are not strictly required based on your provided `Song` model.
  final DateTime? createdAt;
  final String? category;
  final bool? trending;
  final bool? featured;
  final List<double>? embeddingVector;
  final List<double>? embedding;
  final int? tempo;
  final String? countryCode;
  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    required this.audioUrl,
    required this.durationSeconds, // This is now a required parameter
    this.likes = 0,
    this.downloads = 0,
    this.playCount = 0,
    this.likedByUser = false,
    this.genre,
    this.lyrics,
    this.releaseDate,
    this.mood, // Initialize existing singular mood field
    this.tags, // Initialize existing tags field
    this.moods, // NEW: Initialize the new moods field
    // Initialize nullable fields that might not be in your current DB/Map
    this.createdAt,
    this.category,
    this.trending,
    this.featured,
    this.embeddingVector,
    this.embedding,
    this.tempo,
    this.countryCode,
  });
  // Backward compatibility getter for 'url' (renamed from 'url' to 'audioUrl')
  String get url => audioUrl;
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Unknown Title',
      artist: map['artist']?.toString() ?? 'Unknown Artist',
      albumArtUrl: map['album_art_url']?.toString() ?? 'https://placehold.co/150x150/FACC15/000?text=No+Art',
      audioUrl: map['audio_url']?.toString() ?? '',
      // Prioritize 'duration_seconds', then 'duration', default to 0.
      durationSeconds: _toInt(map['duration_seconds'] ?? map['duration'] ?? 0),
      likes: _toInt(map['likes']),
      downloads: _toInt(map['downloads']),
      playCount: _toInt(map['play_count']),
      likedByUser: map['liked_by_user'] == true || map['liked_by_user'] == 1,
      genre: map['genre']?.toString(),
      lyrics: map['lyrics']?.toString(),
      releaseDate: map['release_date'] != null
          ? DateTime.tryParse(map['release_date'].toString())
          : null,
      mood: map['mood']?.toString(), // Parse the singular mood field
      tags: (map['tags'] is List) ? (map['tags'] as List).map((e) => e.toString()).toList() : null, // Parse the tags field
      // NEW: Safely cast 'moods' to List and then to List<String>
      moods: (map['moods'] is List) ? (map['moods'] as List).map((e) => e.toString()).toList() : null,
      // Parse optional fields that might exist in Supabase but were not in your previous model
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      category: map['category']?.toString(),
      trending: map['trending'] as bool?,
      featured: map['featured'] as bool?,
      embeddingVector: (map['embedding_vector'] is List) ? (map['embedding_vector'] as List).map((e) => _toDouble(e)).toList() : null, // Ensure toDouble helper
      embedding: (map['embedding'] is List) ? (map['embedding'] as List).map((e) => _toDouble(e)).toList() : null, // Ensure toDouble helper
      tempo: _toInt(map['tempo']), // Use _toInt for tempo
      countryCode: map['country_code']?.toString(),
    );
  }
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album_art_url': albumArtUrl,
    'audio_url': audioUrl,
    'likes': likes,
    'downloads': downloads,
    'play_count': playCount,
    'liked_by_user': likedByUser,
    'genre': genre,
    'lyrics': lyrics,
    'duration_seconds': durationSeconds,
    'release_date': releaseDate?.toIso8601String(),
    'mood': mood, // Include singular mood in toMap
    'tags': tags, // Include tags in toMap
    'moods': moods, // NEW: Include moods in toMap
    // Include optional fields if they exist to be mapped back to Supabase
    'created_at': createdAt?.toIso8601String(),
    'category': category,
    'trending': trending,
    'featured': featured,
    'embedding_vector': embeddingVector,
    'embedding': embedding,
    'tempo': tempo,
    'country_code': countryCode,
  };
  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArtUrl,
    String? audioUrl,
    int? likes,
    int? downloads,
    int? playCount,
    bool? likedByUser,
    String? genre,
    String? lyrics,
    int? durationSeconds,
    DateTime? releaseDate,
    String? mood,
    List<String>? tags,
    List<String>? moods, // NEW: Add moods to copyWith
    DateTime? createdAt,
    String? category,
    bool? trending,
    bool? featured,
    List<double>? embeddingVector,
    List<double>? embedding,
    int? tempo,
    String? countryCode,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      likes: likes ?? this.likes,
      downloads: downloads ?? this.downloads,
      playCount: playCount ?? this.playCount,
      likedByUser: likedByUser ?? this.likedByUser,
      genre: genre ?? this.genre,
      lyrics: lyrics ?? this.lyrics,
      releaseDate: releaseDate ?? this.releaseDate,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      moods: moods ?? this.moods, // NEW: Handle moods in copyWith
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      trending: trending ?? this.trending,
      featured: featured ?? this.trending, // Fixed potential typo here (featured uses trending)
      embeddingVector: embeddingVector ?? this.embeddingVector,
      embedding: embedding ?? this.embedding,
      tempo: tempo ?? this.tempo,
      countryCode: countryCode ?? this.countryCode,
    );
  }
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  @override
  String toString() =>
      'Song(id: $id, title: $title, artist: $artist, audioUrl: $audioUrl, durationSeconds: $durationSeconds, genre: $genre, mood: $mood, tags: $tags, moods: $moods, releaseDate: $releaseDate)';
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
      releaseDate: map['release_date'] != null
          ? DateTime.tryParse(map['release_date'].toString())
          : null,
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
  final bool followedByUser; // Renamed from 'isFollowed'
  final bool isVerified; // Changed from 'verified' to 'isVerified'
  final bool isHot;
  final bool isEmerging; // Added this new property

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.bio = '',
    this.followers = 0,
    this.following = 0,
    this.downloads = 0,
    this.followedByUser = false,
    this.isVerified = false, // Changed from 'verified'
    this.isHot = false,
    this.isEmerging = false, // Added this with default value
  });

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      bio: map['bio']?.toString() ?? '',
      followers: _toInt(map['followers']),
      following: _toInt(map['following']),
      downloads: _toInt(map['downloads']),
      followedByUser: map['followed_by_user'] == true || map['followed_by_user'] == 1,
      isVerified: map['is_verified'] == true || map['is_verified'] == 1, // Changed from 'verified'
      isHot: map['is_hot'] as bool? ?? false,
      isEmerging: map['is_emerging'] as bool? ?? false, // Added this
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
    'is_verified': isVerified, // Changed from 'verified'
    'is_hot': isHot,
    'is_emerging': isEmerging, // Added this
  };

  // copyWith method for easier state updates
  Artist copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? bio,
    int? followers,
    int? following,
    int? downloads,
    bool? followedByUser,
    bool? isVerified, // Changed from 'verified'
    bool? isHot,
    bool? isEmerging, // Added this
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      downloads: downloads ?? this.downloads,
      followedByUser: followedByUser ?? this.followedByUser,
      isVerified: isVerified ?? this.isVerified, // Changed from 'verified'
      isHot: isHot ?? this.isHot,
      isEmerging: isEmerging ?? this.isEmerging, // Added this
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}

class Playlist {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? region;
  Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.region,
  });
  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      region: map['region']?.toString(),
    );
  }
}

class AiCuratedPlaylist {
  final String id;
  final String title;
  final String mood;
  final String description;
  final String imageUrl;
  final List<Song> songs;
  AiCuratedPlaylist({
    required this.id,
    required this.title,
    required this.mood,
    required this.description,
    required this.imageUrl,
    required this.songs,
  });
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

// ============================
// CHAT MODELS
// ============================

class Chat {
  final String id;
  final String? name;
  final bool isGroup;
  final String? lastMessage;
  final DateTime? lastMessageSentAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatParticipant> participants;
  final int unreadCount;

  Chat({
    required this.id,
    this.name,
    required this.isGroup,
    this.lastMessage,
    this.lastMessageSentAt,
    required this.createdAt,
    required this.updatedAt,
    required this.participants,
    this.unreadCount = 0,
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString(),
      isGroup: map['is_group'] as bool? ?? false,
      lastMessage: map['last_message']?.toString(),
      lastMessageSentAt: map['last_message_sent_at'] != null
          ? DateTime.tryParse(map['last_message_sent_at'].toString())
          : null,
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
      participants: [],
      unreadCount: _toInt(map['unread_count']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'is_group': isGroup,
    'last_message': lastMessage,
    'last_message_sent_at': lastMessageSentAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Chat copyWith({
    String? id,
    String? name,
    bool? isGroup,
    String? lastMessage,
    DateTime? lastMessageSentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatParticipant>? participants,
    int? unreadCount,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      isGroup: isGroup ?? this.isGroup,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSentAt: lastMessageSentAt ?? this.lastMessageSentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  @override
  String toString() {
    return 'Chat(id: $id, name: $name, isGroup: $isGroup, lastMessage: $lastMessage, participants: ${participants.length})';
  }
}

class ChatParticipant {
  final String id;
  final String chatId;
  final String userId;
  final String? username;
  final String? avatarUrl;
  final DateTime joinedAt;

  ChatParticipant({
    required this.id,
    required this.chatId,
    required this.userId,
    this.username,
    this.avatarUrl,
    required this.joinedAt,
  });

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      id: map['id']?.toString() ?? '',
      chatId: map['chat_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      username: map['username']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      joinedAt: DateTime.parse(map['joined_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'chat_id': chatId,
    'user_id': userId,
    'username': username,
    'avatar_url': avatarUrl,
    'joined_at': joinedAt.toIso8601String(),
  };

  ChatParticipant copyWith({
    String? id,
    String? chatId,
    String? userId,
    String? username,
    String? avatarUrl,
    DateTime? joinedAt,
  }) {
    return ChatParticipant(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  String toString() {
    return 'ChatParticipant(id: $id, userId: $userId, username: $username)';
  }
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final List<String> readBy;
  final String? senderUsername;
  final String? senderAvatarUrl;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.messageType = 'text',
    required this.createdAt,
    required this.readBy,
    this.senderUsername,
    this.senderAvatarUrl,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id']?.toString() ?? '',
      chatId: map['chat_id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      messageType: map['message_type']?.toString() ?? 'text',
      createdAt: DateTime.parse(map['created_at'].toString()),
      readBy: List<String>.from(map['read_by'] ?? []),
      senderUsername: map['sender_username']?.toString(),
      senderAvatarUrl: map['sender_avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'chat_id': chatId,
    'sender_id': senderId,
    'content': content,
    'message_type': messageType,
    'created_at': createdAt.toIso8601String(),
    'read_by': readBy,
  };

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    String? messageType,
    DateTime? createdAt,
    List<String>? readBy,
    String? senderUsername,
    String? senderAvatarUrl,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
      senderUsername: senderUsername ?? this.senderUsername,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
    );
  }

  // Helper method to check if message is read by a specific user
  bool isReadByUser(String userId) {
    return readBy.contains(userId);
  }

  @override
  String toString() {
    return 'Message(id: $id, chatId: $chatId, senderId: $senderId, content: $content, type: $messageType)';
  }
}

// ============================
// VIDEO MODELS
// ============================

class VideoComment {
  final String id;
  final String videoId;
  final String userId;
  final String username;
  final String comment;
  final DateTime createdAt;
  final int editCount;

  VideoComment({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.username,
    required this.comment,
    required this.createdAt,
    this.editCount = 0,
  });

  factory VideoComment.fromMap(Map<String, dynamic> map) {
    return VideoComment(
      id: map['id'] as String,
      videoId: map['video_id'] as String,
      userId: map['user_id'] as String,
      username: map['username'] as String? ?? 'Anonymous',
      comment: map['comment'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      editCount: map['edit_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'video_id': videoId,
    'user_id': userId,
    'username': username,
    'comment': comment,
    'created_at': createdAt.toIso8601String(),
    'edit_count': editCount,
  };

  @override
  String toString() {
    return 'VideoComment(id: $id, videoId: $videoId, username: $username, comment: $comment)';
  }
}

class MusicVideo {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String thumbnailUrl;
  final String videoUrl;
  int likes;
  int comments;
  int views;
  final DateTime uploadDate;
  bool likedByUser;
  bool isSubscribed;
  bool dislikedByUser;
  final DateTime? releaseDate;

  MusicVideo({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.thumbnailUrl,
    required this.videoUrl,
    this.likes = 0,
    this.comments = 0,
    this.views = 0,
    required this.uploadDate,
    this.likedByUser = false,
    this.isSubscribed = false,
    this.dislikedByUser = false,
    this.releaseDate,
  });

  factory MusicVideo.fromMap(Map<String, dynamic> map) {
    DateTime? uploadDate;
    if (map['upload_date'] != null) {
      try {
        uploadDate = DateTime.parse(map['upload_date'] as String);
      } catch (e) {
        debugPrint('Error parsing upload date: $e');
        uploadDate = DateTime.now();
      }
    } else {
      uploadDate = DateTime.now();
    }

    DateTime? releaseDate;
    if (map['release_date'] != null) {
      try {
        releaseDate = DateTime.parse(map['release_date'] as String);
      } catch (e) {
        debugPrint('Error parsing release date: $e');
        releaseDate = null;
      }
    }

    return MusicVideo(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled Video',
      artist: map['artist'] as String? ?? 'Unknown Artist',
      artistId: map['artist_id'] as String? ?? '',
      thumbnailUrl: map['thumbnail_url'] as String? ?? '',
      videoUrl: map['video_url'] as String? ?? '',
      likes: map['likes'] as int? ?? 0,
      comments: map['comments'] as int? ?? 0,
      views: map['views'] as int? ?? 0,
      uploadDate: uploadDate,
      likedByUser: map['liked_by_user'] as bool? ?? false,
      isSubscribed: map['is_subscribed'] as bool? ?? false,
      dislikedByUser: map['disliked_by_user'] as bool? ?? false,
      releaseDate: releaseDate,
    );
  }

  MusicVideo copyWith({
    int? likes,
    int? comments,
    int? views,
    bool? likedByUser,
    bool? isSubscribed,
    bool? dislikedByUser,
    DateTime? releaseDate,
  }) {
    return MusicVideo(
      id: id,
      title: title,
      artist: artist,
      artistId: artistId,
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      views: views ?? this.views,
      uploadDate: uploadDate,
      likedByUser: likedByUser ?? this.likedByUser,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      dislikedByUser: dislikedByUser ?? this.dislikedByUser,
      releaseDate: releaseDate ?? this.releaseDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artist_id': artistId,
      'thumbnail_url': thumbnailUrl,
      'video_url': videoUrl,
      'likes': likes,
      'comments': comments,
      'views': views,
      'upload_date': uploadDate.toIso8601String(),
      'release_date': releaseDate?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'MusicVideo(id: $id, title: $title, artist: $artist, views: $views, likes: $likes)';
  }
}
