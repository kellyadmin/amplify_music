import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Models for music-focused chat
class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String message;
  final DateTime createdAt;
  final String? sharedSongId;
  final String? sharedSongTitle;
  final String? sharedSongArtist;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.message,
    required this.createdAt,
    this.sharedSongId,
    this.sharedSongTitle,
    this.sharedSongArtist,
    this.type = MessageType.text,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      userAvatar: map['user_avatar'] as String? ?? '',
      message: map['message'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      sharedSongId: map['shared_song_id'] as String?,
      sharedSongTitle: map['shared_song_title'] as String?,
      sharedSongArtist: map['shared_song_artist'] as String?,
      type: MessageType.values.firstWhere(
        (t) => t.name == (map['type'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'shared_song_id': sharedSongId,
      'shared_song_title': sharedSongTitle,
      'shared_song_artist': sharedSongArtist,
      'type': type.name,
    };
  }
}

enum MessageType {
  text,
  songShare,
  reaction,
  joinedRoom,
  leftRoom,
}

enum ChatRoomType {
  song,
  artist,
  genre,
  playlist,
  liveEvent,
}

class ChatRoom {
  final String id;
  final String name;
  final String description;
  final ChatRoomType type;
  final String? imageUrl;
  final int activeUsers;
  final DateTime lastActivity;
  final Map<String, dynamic>? metadata;

  ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.imageUrl,
    this.activeUsers = 0,
    required this.lastActivity,
    this.metadata,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      type: ChatRoomType.values.firstWhere(
        (t) => t.name == (map['type'] as String),
        orElse: () => ChatRoomType.song,
      ),
      imageUrl: map['image_url'] as String?,
      activeUsers: map['active_users'] as int? ?? 0,
      lastActivity: DateTime.parse(map['last_activity'] as String),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}

class MusicChatService {
  static final MusicChatService _instance = MusicChatService._internal();
  factory MusicChatService() => _instance;
  MusicChatService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final StreamController<List<ChatMessage>> _messagesController = 
      StreamController<List<ChatMessage>>.broadcast();
  final StreamController<List<ChatRoom>> _roomsController = 
      StreamController<List<ChatRoom>>.broadcast();
  
  RealtimeChannel? _currentChannel;
  String? _currentRoomId;
  Timer? _presenceTimer;

  // Getters
  Stream<List<ChatMessage>> get messagesStream => _messagesController.stream;
  Stream<List<ChatRoom>> get roomsStream => _roomsController.stream;
  bool get isConnected => _currentChannel != null;
  String? get currentUserId => _supabase.auth.currentUser?.id;
  String? get currentUserName => _supabase.auth.currentUser?.userMetadata?['display_name'] ?? 
                                _supabase.auth.currentUser?.email?.split('@')[0];

  /// Initialize the service
  void initialize() {
    debugPrint('MusicChatService initialized');
  }

  /// Get or create a chat room for a song
  Future<ChatRoom> getSongChatRoom(String songId, String songTitle, String artistName) async {
    try {
      final roomId = 'song_$songId';
      
      // Try to get existing room
      final existingRoom = await _supabase
          .from('chat_rooms')
          .select()
          .eq('id', roomId)
          .maybeSingle();

      if (existingRoom != null) {
        return ChatRoom.fromMap(existingRoom);
      }

      // Create new room
      final newRoom = {
        'id': roomId,
        'name': songTitle,
        'description': 'Discussion about "$songTitle" by $artistName',
        'type': 'song',
        'metadata': {
          'song_id': songId,
          'song_title': songTitle,
          'artist_name': artistName,
        },
        'last_activity': DateTime.now().toIso8601String(),
      };

      await _supabase.from('chat_rooms').insert(newRoom);
      return ChatRoom.fromMap(newRoom);
    } catch (e) {
      debugPrint('Error getting/creating song chat room: $e');
      rethrow;
    }
  }

  /// Get or create a chat room for an artist
  Future<ChatRoom> getArtistChatRoom(String artistId, String artistName) async {
    try {
      final roomId = 'artist_$artistId';
      
      final existingRoom = await _supabase
          .from('chat_rooms')
          .select()
          .eq('id', roomId)
          .maybeSingle();

      if (existingRoom != null) {
        return ChatRoom.fromMap(existingRoom);
      }

      final newRoom = {
        'id': roomId,
        'name': '$artistName Fan Room',
        'description': 'Chat with other $artistName fans',
        'type': 'artist',
        'metadata': {
          'artist_id': artistId,
          'artist_name': artistName,
        },
        'last_activity': DateTime.now().toIso8601String(),
      };

      await _supabase.from('chat_rooms').insert(newRoom);
      return ChatRoom.fromMap(newRoom);
    } catch (e) {
      debugPrint('Error getting/creating artist chat room: $e');
      rethrow;
    }
  }

  /// Join a chat room and start listening to messages
  Future<void> joinRoom(String roomId) async {
    try {
      // Leave current room first
      if (_currentRoomId != null) {
        await leaveRoom();
      }

      _currentRoomId = roomId;

      // Create realtime channel for this room
      _currentChannel = _supabase.channel('chat_room_$roomId');
      
      // Listen for new messages using the correct Supabase realtime API
      _currentChannel!
          .on(
            RealtimeListenTypes.postgresChanges,
            ChannelFilter(
              event: 'INSERT',
              schema: 'public',
              table: 'chat_messages',
              filter: 'room_id=eq.$roomId',
            ),
            (payload, [ref]) {
              _handleNewMessage(payload);
            },
          )
          .subscribe();

      // Load existing messages
      await _loadRoomMessages(roomId);

      // Update user presence
      await _updatePresence(roomId, true);

      debugPrint('Joined chat room: $roomId');
    } catch (e) {
      debugPrint('Error joining chat room: $e');
      rethrow;
    }
  }

  /// Leave the current chat room
  Future<void> leaveRoom() async {
    if (_currentRoomId != null && _currentChannel != null) {
      // Update presence
      await _updatePresence(_currentRoomId!, false);
      
      // Unsubscribe from channel
      await _supabase.removeChannel(_currentChannel!);
      _currentChannel = null;
      _currentRoomId = null;
      
      debugPrint('Left chat room');
    }
  }

  /// Send a text message to the current room
  Future<void> sendMessage(String message) async {
    if (_currentRoomId == null || currentUserId == null) {
      throw Exception('Not connected to a chat room or user not authenticated');
    }

    try {
      final messageData = {
        'room_id': _currentRoomId!,
        'user_id': currentUserId!,
        'user_name': currentUserName ?? 'Anonymous',
        'user_avatar': _supabase.auth.currentUser?.userMetadata?['avatar_url'] ?? '',
        'message': message,
        'type': 'text',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('chat_messages').insert(messageData);
      
      // Update room's last activity
      await _supabase
          .from('chat_rooms')
          .update({'last_activity': DateTime.now().toIso8601String()})
          .eq('id', _currentRoomId!);

    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Share a song in the current chat room
  Future<void> shareSong(String songId, String songTitle, String artistName, {String? message}) async {
    if (_currentRoomId == null || currentUserId == null) {
      throw Exception('Not connected to a chat room or user not authenticated');
    }

    try {
      final shareMessage = message ?? 'Check out this song! 🎵';
      
      final messageData = {
        'room_id': _currentRoomId!,
        'user_id': currentUserId!,
        'user_name': currentUserName ?? 'Anonymous',
        'user_avatar': _supabase.auth.currentUser?.userMetadata?['avatar_url'] ?? '',
        'message': shareMessage,
        'type': 'songShare',
        'shared_song_id': songId,
        'shared_song_title': songTitle,
        'shared_song_artist': artistName,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('chat_messages').insert(messageData);
      
      // Update room's last activity
      await _supabase
          .from('chat_rooms')
          .update({'last_activity': DateTime.now().toIso8601String()})
          .eq('id', _currentRoomId!);

    } catch (e) {
      debugPrint('Error sharing song: $e');
      rethrow;
    }
  }

  /// Send a quick reaction (emoji)
  Future<void> sendReaction(String emoji) async {
    if (_currentRoomId == null || currentUserId == null) {
      throw Exception('Not connected to a chat room or user not authenticated');
    }

    try {
      final messageData = {
        'room_id': _currentRoomId!,
        'user_id': currentUserId!,
        'user_name': currentUserName ?? 'Anonymous',
        'user_avatar': _supabase.auth.currentUser?.userMetadata?['avatar_url'] ?? '',
        'message': emoji,
        'type': 'reaction',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('chat_messages').insert(messageData);
    } catch (e) {
      debugPrint('Error sending reaction: $e');
      rethrow;
    }
  }

  /// Get popular/active chat rooms
  Future<List<ChatRoom>> getActiveRooms() async {
    try {
      final response = await _supabase
          .from('chat_rooms')
          .select()
          .order('active_users', ascending: false)
          .order('last_activity', ascending: false)
          .limit(20);

      return (response as List).map((data) => ChatRoom.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting active rooms: $e');
      return [];
    }
  }

  /// Load messages for a specific room
  Future<void> _loadRoomMessages(String roomId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .limit(50);

      final messages = (response as List)
          .map((data) => ChatMessage.fromMap(data))
          .toList()
          .reversed
          .toList();

      _messagesController.add(messages);
    } catch (e) {
      debugPrint('Error loading room messages: $e');
      _messagesController.add([]);
    }
  }

  /// Handle new message from realtime subscription
  void _handleNewMessage(Map<String, dynamic> payload) {
    try {
      // Extract the new record from payload
      final newRecord = payload['new'] as Map<String, dynamic>?;
      if (newRecord == null) return;
      
      final newMessage = ChatMessage.fromMap(newRecord);
      
      // Add to current messages stream
      final currentMessages = <ChatMessage>[];
      if (_messagesController.hasListener) {
        // Get current messages and add new one
        currentMessages.add(newMessage);
        _messagesController.add(currentMessages);
      }
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }

  /// Update user presence in a room
  Future<void> _updatePresence(String roomId, bool isJoining) async {
    if (currentUserId == null) return;

    try {
      if (isJoining) {
        // Add user to room presence
        await _supabase.from('chat_presence').upsert({
          'room_id': roomId,
          'user_id': currentUserId!,
          'user_name': currentUserName ?? 'Anonymous',
          'joined_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Remove user from room presence
        await _supabase
            .from('chat_presence')
            .delete()
            .eq('room_id', roomId)
            .eq('user_id', currentUserId!);
      }

      // Update active user count in room
      final activeCount = await _supabase
          .from('chat_presence')
          .select('user_id')
          .eq('room_id', roomId);

      await _supabase
          .from('chat_rooms')
          .update({'active_users': (activeCount as List).length})
          .eq('id', roomId);

    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    leaveRoom();
    _messagesController.close();
    _roomsController.close();
    _presenceTimer?.cancel();
  }
}
