import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  bool _isConnected = false;
  String? _currentUserId;
  RealtimeChannel? _channel;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Store friends and messages
  final Map<String, Friend> _friends = {};
  final Map<String, List<Message>> _messages = {};

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _isConnected;
  Map<String, Friend> get friends => _friends;
  List<Message> getMessagesForFriend(String friendId) => _messages[friendId] ?? [];

  // ADDED: Initialize method that replaces saveAuthDetails
  void initialize() {
    _currentUserId = _supabase.auth.currentUser?.id;
    debugPrint('ChatService initialized. User ID: $_currentUserId');
    connectIfRequired();
  }

  void connectIfRequired() {
    if (_isConnected && _channel != null) {
      debugPrint('ChatService is already connected.');
      return;
    }

    if (_currentUserId == null || _currentUserId!.isEmpty) {
      debugPrint('Cannot connect: User is not logged in.');
      return;
    }

    try {
      // Create a realtime channel for this user
      _channel = _supabase.channel('user_${_currentUserId!}');

      // Subscribe to message inserts
      _channel!.on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
        ),
            (payload, [ref]) {
          _handleRealtimeMessage(payload);
        },
      ).on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'friends',
        ),
            (payload, [ref]) {
          _handleRealtimeFriendUpdate(payload);
        },
      ).on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'UPDATE',
          schema: 'public',
          table: 'friends',
        ),
            (payload, [ref]) {
          _handleRealtimeFriendUpdate(payload);
        },
      ).subscribe();

      _isConnected = true;
      _reconnectAttempts = 0;
      debugPrint('Connected to Supabase Realtime');

      // Fetch initial data
      fetchFriendsFromSupabase();
      requestFriendsList();

    } catch (e) {
      _isConnected = false;
      debugPrint('Failed to connect to Supabase Realtime: $e');
      _messageController.add({
        'type': 'error',
        'message': 'Failed to connect: $e',
      });
      _attemptReconnect();
    }
  }

  void _handleRealtimeMessage(Map<String, dynamic> payload) {
    debugPrint('Realtime message received: $payload');

    final Map<String, dynamic> newRecord = payload['new'] ?? {};
    final String eventType = payload['eventType'] ?? '';

    if (eventType == 'INSERT') {
      final String senderId = newRecord['sender_id']?.toString() ?? '';
      final String receiverId = newRecord['receiver_id']?.toString() ?? '';
      final String content = newRecord['content']?.toString() ?? '';
      final String createdAt = newRecord['created_at']?.toString() ?? '';

      // Only handle messages where current user is either sender or receiver
      if (senderId == _currentUserId || receiverId == _currentUserId) {
        final String friendId = senderId == _currentUserId ? receiverId : senderId;

        if (!_messages.containsKey(friendId)) {
          _messages[friendId] = [];
        }

        _messages[friendId]!.add(
          Message(
            text: content,
            isSentByMe: senderId == _currentUserId,
            timestamp: DateTime.parse(createdAt).millisecondsSinceEpoch,
          ),
        );

        // Update friend's last message
        if (_friends.containsKey(friendId)) {
          _friends[friendId] = _friends[friendId]!.copyWith(
            lastMessage: content,
            lastMessageTime: _formatTimestamp(DateTime.parse(createdAt).millisecondsSinceEpoch),
          );
        }

        _messageController.add({
          'type': 'message',
          'fromUserId': senderId,
          'toUserId': receiverId,
          'message': content,
          'timestamp': DateTime.parse(createdAt).millisecondsSinceEpoch,
        });
      }
    }
  }

  void _handleRealtimeFriendUpdate(Map<String, dynamic> payload) {
    debugPrint('Realtime friend update received: $payload');

    final Map<String, dynamic> newRecord = payload['new'] ?? {};
    final String eventType = payload['eventType'] ?? '';

    if (eventType == 'INSERT') {
      final String userId = newRecord['user_id']?.toString() ?? '';
      final String friendId = newRecord['friend_id']?.toString() ?? '';
      final String status = newRecord['status']?.toString() ?? 'pending';

      // If the friend request is for current user and is accepted
      if (userId == _currentUserId && status == 'accepted') {
        // Fetch the friend's details
        _fetchFriendDetails(friendId);
      } else if (friendId == _currentUserId && status == 'pending') {
        // Notify about incoming friend request
        _fetchRequesterDetails(userId);
      }
    } else if (eventType == 'UPDATE') {
      final String userId = newRecord['user_id']?.toString() ?? '';
      final String friendId = newRecord['friend_id']?.toString() ?? '';
      final String status = newRecord['status']?.toString() ?? 'pending';

      // Handle friend request acceptance
      if (friendId == _currentUserId && status == 'accepted') {
        _fetchFriendDetails(userId);

        // Notify about friend request acceptance
        _messageController.add({
          'type': 'friend_request_accepted',
          'fromUserId': userId,
          'fromUserName': _friends[userId]?.name ?? 'Unknown User',
        });
      }
    }
  }

  Future<void> _fetchRequesterDetails(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('name, profile_url, username')
          .eq('id', userId)
          .single();

      _messageController.add({
        'type': 'friend_request',
        'fromUserId': userId,
        'fromUserName': response['name'] ?? 'Unknown User',
        'fromUserUsername': response['username'] ?? 'unknown',
        'profileImageUrl': response['profile_url'],
      });

      debugPrint('Friend request received from: ${response['name']} ($userId)');
    } catch (e) {
      debugPrint('Error fetching requester details: $e');
    }
  }

  Future<void> _fetchFriendDetails(String friendId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('name, profile_url, username')
          .eq('id', friendId)
          .single();

      _friends[friendId] = Friend(
        id: friendId,
        name: response['name'] ?? 'Unknown',
        profileImageUrl: response['profile_url'] ?? 'https://placehold.co/100x100/EBF5FF/808080?text=${response['name']?[0] ?? 'U'}',
        isOnline: false,
      );

      _messageController.add({
        'type': 'friend_accepted',
        'friendId': friendId,
        'friendName': response['name'] ?? 'Unknown',
        'profileImageUrl': response['profile_url'],
      });

      debugPrint('Friend added: ${response['name']} ($friendId)');

      // Refresh friends list
      fetchFriendsFromSupabase();
    } catch (e) {
      debugPrint('Error fetching friend details: $e');
    }
  }

  String _formatTimestamp(int timestamp) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateTime now = DateTime.now();

    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached.');
      _reconnectTimer?.cancel();
      return;
    }

    _reconnectAttempts++;
    debugPrint('Attempting to reconnect... ($_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(_reconnectDelay, () {
      connectIfRequired();
    });
  }

  Future<void> fetchFriendsFromSupabase() async {
    try {
      final response = await _supabase
          .from('friends')
          .select('friend_id, users!friends_friend_id_fkey(name, profile_url)')
          .eq('user_id', _currentUserId)
          .eq('status', 'accepted');

      final List<dynamic> friendsData = response;
      _friends.clear();

      for (var friendData in friendsData) {
        final friendInfo = friendData['users'];
        final friendId = friendData['friend_id'];

        _friends[friendId] = Friend(
          id: friendId,
          name: friendInfo['name'] ?? 'Unknown',
          profileImageUrl: friendInfo['profile_url'] ?? 'https://placehold.co/100x100/EBF5FF/808080?text=${friendInfo['name']?[0] ?? 'U'}',
          isOnline: false,
        );
      }

      debugPrint('Fetched ${_friends.length} friends from Supabase');

      // Notify about friends list update
      _messageController.add({
        'type': 'friends_list',
        'friends': _friends.values.map((friend) => friend.toMap()).toList(),
      });

    } catch (e) {
      debugPrint('Error fetching friends: $e');
      // Check if it's a database relationship error
      if (e.toString().contains('PGRST200') || e.toString().contains('relationship')) {
        _messageController.add({
          'type': 'database_setup_required',
          'message': 'Chat database tables need to be set up. Please see SUPABASE_CHAT_SETUP.md',
        });
      }
    }
  }

  Future<void> fetchMessagesFromSupabase(String friendId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*')
          .or('and(sender_id.eq.$_currentUserId,receiver_id.eq.$friendId),and(sender_id.eq.$friendId,receiver_id.eq.$_currentUserId)')
          .order('created_at', ascending: true);

      final List<dynamic> messagesData = response;
      _messages[friendId] = [];

      for (var messageData in messagesData) {
        _messages[friendId]!.add(
          Message(
            text: messageData['content'],
            isSentByMe: messageData['sender_id'] == _currentUserId,
            timestamp: DateTime.parse(messageData['created_at']).millisecondsSinceEpoch,
          ),
        );
      }

      debugPrint('Fetched ${_messages[friendId]!.length} messages with friend $friendId');
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  Future<void> sendMessageToSupabase(String message, String toUserId) async {
    try {
      await _supabase.from('messages').insert({
        'sender_id': _currentUserId,
        'receiver_id': toUserId,
        'content': message,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Message sent to Supabase');
    } catch (e) {
      debugPrint('Error sending message: $e');
      _messageController.add({
        'type': 'error',
        'message': 'Failed to send message: $e',
      });
    }
  }

  // ADDED: Search users by username or name
  Future<List<User>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('users')
          .select('id, name, username, profile_url, last_seen')
          .or('name.ilike.%$query%,username.ilike.%$query%')
          .neq('id', _currentUserId) // Exclude current user
          .limit(20);

      final List<User> users = [];
      for (var userData in response) {
        users.add(User(
          id: userData['id'],
          name: userData['name'] ?? 'Unknown',
          username: userData['username'] ?? 'unknown',
          profileImageUrl: userData['profile_url'] ?? 'https://placehold.co/100x100/EBF5FF/808080?text=${userData['name']?[0] ?? 'U'}',
          isOnline: _isUserOnline(userData['last_seen']),
        ));
      }

      debugPrint('Found ${users.length} users for query: $query');
      return users;
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // ADDED: Get all users for the "New Chat" screen
  Future<List<User>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, name, username, profile_url, last_seen')
          .neq('id', _currentUserId) // Exclude current user
          .limit(50);

      final List<User> users = [];
      for (var userData in response) {
        users.add(User(
          id: userData['id'],
          name: userData['name'] ?? 'Unknown',
          username: userData['username'] ?? 'unknown',
          profileImageUrl: userData['profile_url'] ?? 'https://placehold.co/100x100/EBF5FF/808080?text=${userData['name']?[0] ?? 'U'}',
          isOnline: _isUserOnline(userData['last_seen']),
        ));
      }

      debugPrint('Fetched ${users.length} users from Supabase');
      return users;
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return [];
    }
  }

  // ADDED: Check if user is online based on last_seen timestamp
  bool _isUserOnline(String? lastSeen) {
    if (lastSeen == null) return false;

    try {
      final lastSeenTime = DateTime.parse(lastSeen);
      final now = DateTime.now();
      final difference = now.difference(lastSeenTime);

      // Consider user online if they were active in the last 5 minutes
      return difference.inMinutes < 5;
    } catch (e) {
      return false;
    }
  }

  // ADDED: Send friend request
  Future<void> sendFriendRequest(String toUserId) async {
    try {
      // Check if friend request already exists
      final existingRequest = await _supabase
          .from('friends')
          .select('id, status')
          .eq('user_id', _currentUserId)
          .eq('friend_id', toUserId)
          .maybeSingle();

      if (existingRequest != null) {
        debugPrint('Friend request already exists with status: ${existingRequest['status']}');
        _messageController.add({
          'type': 'error',
          'message': 'Friend request already sent',
        });
        return;
      }

      await _supabase.from('friends').insert({
        'user_id': _currentUserId,
        'friend_id': toUserId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Friend request sent to user $toUserId');

      _messageController.add({
        'type': 'friend_request_sent',
        'toUserId': toUserId,
      });

    } catch (e) {
      debugPrint('Error sending friend request: $e');
      _messageController.add({
        'type': 'error',
        'message': 'Failed to send friend request: $e',
      });
    }
  }

  // ADDED: Get pending friend requests
  Future<List<FriendRequest>> getPendingFriendRequests() async {
    try {
      final response = await _supabase
          .from('friends')
          .select('id, user_id, users!friends_user_id_fkey(name, username, profile_url)')
          .eq('friend_id', _currentUserId)
          .eq('status', 'pending');

      final List<FriendRequest> requests = [];
      for (var request in response) {
        final userInfo = request['users'];
        requests.add(FriendRequest(
          id: request['id'],
          fromUserId: request['user_id'],
          fromUserName: userInfo['name'] ?? 'Unknown User',
          fromUserUsername: userInfo['username'] ?? 'unknown',
          fromUserProfileImage: userInfo['profile_url'] ?? 'https://placehold.co/100x100/EBF5FF/808080?text=${userInfo['name']?[0] ?? 'U'}',
        ));
      }

      debugPrint('Fetched ${requests.length} pending friend requests');
      return requests;
    } catch (e) {
      debugPrint('Error fetching pending friend requests: $e');
      // Return empty list if database is not set up yet
      return [];
    }
  }

  // ADDED: Accept friend request
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      // First get the request details
      final request = await _supabase
          .from('friends')
          .select('user_id, friend_id')
          .eq('id', requestId)
          .single();

      final String fromUserId = request['user_id'];
      final String toUserId = request['friend_id'];

      // Update the friend request status to accepted
      await _supabase
          .from('friends')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      // Also create the reverse relationship
      await _supabase.from('friends').insert({
        'user_id': toUserId, // current user
        'friend_id': fromUserId, // the user who sent the request
        'status': 'accepted',
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Friend request from $fromUserId accepted');

      _messageController.add({
        'type': 'friend_request_accepted',
        'fromUserId': fromUserId,
      });

      // Fetch the updated friends list
      fetchFriendsFromSupabase();

    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      _messageController.add({
        'type': 'error',
        'message': 'Failed to accept friend request: $e',
      });
    }
  }

  // ADDED: Reject friend request
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _supabase
          .from('friends')
          .delete()
          .eq('id', requestId);

      debugPrint('Friend request $requestId rejected');

      _messageController.add({
        'type': 'friend_request_rejected',
        'requestId': requestId,
      });

    } catch (e) {
      debugPrint('Error rejecting friend request: $e');
      _messageController.add({
        'type': 'error',
        'message': 'Failed to reject friend request: $e',
      });
    }
  }

  void requestFriendsList() {
    fetchFriendsFromSupabase();
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    if (_channel != null) {
      _supabase.removeChannel(_channel!);
      _channel = null;
    }

    _isConnected = false;
    debugPrint('Disconnected from Supabase Realtime');
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}

// Data models
class Friend {
  final String id;
  final String name;
  final String profileImageUrl;
  final String lastMessage;
  final String lastMessageTime;
  final bool isOnline;

  const Friend({
    required this.id,
    required this.name,
    required this.profileImageUrl,
    this.lastMessage = '',
    this.lastMessageTime = '',
    this.isOnline = false,
  });

  Friend copyWith({
    String? lastMessage,
    String? lastMessageTime,
    bool? isOnline,
  }) {
    return Friend(
      id: id,
      name: name,
      profileImageUrl: profileImageUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'isOnline': isOnline,
    };
  }
}

class Message {
  final String text;
  final bool isSentByMe;
  final int timestamp;

  const Message({
    required this.text,
    required this.isSentByMe,
    required this.timestamp,
  });
}

// ADDED: User model for search results
class User {
  final String id;
  final String name;
  final String username;
  final String profileImageUrl;
  final bool isOnline;

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.profileImageUrl,
    required this.isOnline,
  });
}

// ADDED: FriendRequest model
class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String fromUserUsername;
  final String fromUserProfileImage;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserUsername,
    required this.fromUserProfileImage,
  });
}
