import 'dart:async';
import '../constants.dart';

import 'package:flutter/material.dart';
import '../services/chat_service.dart';

// --- Chat-specific UI Constants (not in centralized constants) ---
const Color chatSecondaryColor = Color(0xFFF0F2F5); // Light Grey Background (chat-specific)
const Color appBarColor = Colors.white;
const Color chatTextColor = Colors.black; // Chat uses black text on light bg
const Color sentMessageColor = primaryColor; // Use centralized gold
const Color receivedMessageColor = Color(0xFFE4E6EB);
const Color sentMessageTextColor = Colors.white;
const Color receivedMessageTextColor = Colors.black;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  late StreamSubscription<Map<String, dynamic>> _messageSubscription;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<User> _searchResults = [];
  List<FriendRequest> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    // Listen for real-time updates from ChatService
    _messageSubscription = _chatService.messages.listen(_handleIncomingMessage);

    // Request friends list when screen loads
    _chatService.requestFriendsList();
    _loadPendingRequests();
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    // Handle different types of real-time updates
    switch (data['type']) {
      case 'friends_list':
        setState(() {}); // Refresh UI when friends list updates
        break;
      case 'message':
      // Messages are handled in individual conversation screens
        break;
      case 'friend_request':
        _showFriendRequestNotification(data);
        _loadPendingRequests();
        break;
      case 'friend_request_accepted':
        _showFriendRequestAcceptedNotification(data);
        _chatService.requestFriendsList(); // Refresh friends list
        break;
    }
  }

  void _loadPendingRequests() async {
    final requests = await _chatService.getPendingFriendRequests();
    setState(() {
      _pendingRequests = requests;
    });
  }

  void _showFriendRequestNotification(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Friend request from ${data['fromUserName']}'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            _showFriendRequestsScreen();
          },
        ),
      ),
    );
  }

  void _showFriendRequestAcceptedNotification(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${data['fromUserName']} accepted your friend request!'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    final results = await _chatService.searchUsers(query);
    setState(() {
      _searchResults = results;
    });
  }

  void _showFriendRequestsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendRequestsScreen(
          pendingRequests: _pendingRequests,
          onRequestsUpdated: _loadPendingRequests,
        ),
      ),
    );
  }

  void _showNewChatScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => NewChatScreen(
        onUserSelected: (user) {
          // Check if user is already a friend
          final isFriend = _chatService.friends.values
              .any((friend) => friend.id == user.id);

          if (isFriend) {
            // Navigate to existing chat
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConversationScreen(friend: Friend(
                  id: user.id,
                  name: user.name,
                  profileImageUrl: user.profileImageUrl,
                  isOnline: user.isOnline,
                  lastMessage: '',
                  lastMessageTime: '',
                )),
              ),
            );
          } else {
            // Show option to send friend request
            _showSendRequestDialog(user);
          }
        },
      ),
    );
  }

  void _showSendRequestDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Friend Request'),
        content: Text('Send friend request to ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _chatService.sendFriendRequest(user.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Friend request sent to ${user.name}'),
                ),
              );
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friends = _chatService.friends.values.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: _isSearching ? _buildSearchResults() : _buildChatList(friends),
    );
  }

  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text(
          'Chats',
          style: TextStyle(color: chatTextColor, fontWeight: FontWeight.bold, fontSize: 24)
      ),
      backgroundColor: appBarColor,
      elevation: 0,
      actions: [
        _buildAppBarIcon(Icons.search, onTap: () {
          setState(() {
            _isSearching = true;
          });
        }),
        _buildAppBarIcon(Icons.add_comment, onTap: _showNewChatScreen),
        _buildFriendRequestIcon(),
      ],
    );
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      backgroundColor: appBarColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: chatTextColor),
        onPressed: () {
          setState(() {
            _isSearching = false;
            _searchController.clear();
            _searchResults.clear();
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search users...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey),
        ),
        style: const TextStyle(color: chatTextColor),
        onChanged: _performSearch,
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, color: chatTextColor),
            onPressed: () {
              _searchController.clear();
              _performSearch('');
            },
          ),
      ],
    );
  }

  Widget _buildChatList(List<Friend> friends) {
    return friends.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return _FriendListItem(friend: friend);
      },
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _UserListItem(
          user: user,
          onTap: () {
            // Check if user is already a friend
            final isFriend = _chatService.friends.values
                .any((friend) => friend.id == user.id);

            if (isFriend) {
              // Navigate to chat
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _searchResults.clear();
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConversationScreen(friend: Friend(
                    id: user.id,
                    name: user.name,
                    profileImageUrl: user.profileImageUrl,
                    isOnline: user.isOnline,
                    lastMessage: '',
                    lastMessageTime: '',
                  )),
                ),
              );
            } else {
              // Show option to send friend request
              _showSendRequestDialog(user);
            }
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your friends!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showNewChatScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Find People',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarIcon(IconData icon, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: CircleAvatar(
          backgroundColor: chatSecondaryColor,
          child: Icon(icon, color: chatTextColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildFriendRequestIcon() {
    return Stack(
      children: [
        _buildAppBarIcon(Icons.person_add, onTap: _showFriendRequestsScreen),
        if (_pendingRequests.isNotEmpty)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: errorColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _pendingRequests.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _FriendListItem extends StatelessWidget {
  final Friend friend;

  const _FriendListItem({required this.friend});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(friend.profileImageUrl),
          ),
          if (friend.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                height: 16,
                width: 16,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
          friend.name,
          style: const TextStyle(fontWeight: FontWeight.bold)
      ),
      subtitle: Text(
        friend.lastMessage.isNotEmpty ? friend.lastMessage : 'Start a conversation',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: friend.lastMessage.isEmpty ? Colors.grey : null,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (friend.lastMessageTime.isNotEmpty)
            Text(
              friend.lastMessageTime,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(friend: friend),
          ),
        );
      },
    );
  }
}

class _UserListItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _UserListItem({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(user.profileImageUrl),
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        user.username,
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Add',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}

class NewChatScreen extends StatefulWidget {
  final Function(User) onUserSelected;

  const NewChatScreen({super.key, required this.onUserSelected});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  List<User> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    final users = await _chatService.getAllUsers();
    setState(() {
      _users = users;
      _filteredUsers = users;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) =>
        user.name.toLowerCase().contains(query.toLowerCase()) ||
            user.username.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'New Chat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: _filterUsers,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
              child: Text(
                'No users found',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
              ),
            )
                : ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.profileImageUrl),
                  ),
                  title: Text(user.name),
                  subtitle: Text('@${user.username}'),
                  onTap: () => widget.onUserSelected(user),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FriendRequestsScreen extends StatefulWidget {
  final List<FriendRequest> pendingRequests;
  final VoidCallback onRequestsUpdated;

  const FriendRequestsScreen({
    super.key,
    required this.pendingRequests,
    required this.onRequestsUpdated,
  });

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final ChatService _chatService = ChatService();

  void _acceptRequest(FriendRequest request) async {
    await _chatService.acceptFriendRequest(request.id);
    widget.onRequestsUpdated();
    setState(() {});
  }

  void _rejectRequest(FriendRequest request) async {
    await _chatService.rejectFriendRequest(request.id);
    widget.onRequestsUpdated();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        backgroundColor: appBarColor,
        elevation: 0,
      ),
      body: widget.pendingRequests.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_disabled,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No pending requests',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 18,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: widget.pendingRequests.length,
        itemBuilder: (context, index) {
          final request = widget.pendingRequests[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(request.fromUserProfileImage),
            ),
            title: Text(request.fromUserName),
            subtitle: Text('@${request.fromUserUsername}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _acceptRequest(request),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: errorColor),
                  onPressed: () => _rejectRequest(request),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Keep the existing ConversationScreen and _MessageBubble classes
class ConversationScreen extends StatefulWidget {
  final Friend friend;

  const ConversationScreen({super.key, required this.friend});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  late StreamSubscription<Map<String, dynamic>> _messageSubscription;

  @override
  void initState() {
    super.initState();

    // Load existing messages from ChatService
    _loadMessages();

    // Listen for new real-time messages
    _messageSubscription = _chatService.messages.listen((data) {
      if (data['type'] == 'message' &&
          (data['fromUserId'] == widget.friend.id || data['toUserId'] == widget.friend.id)) {
        setState(() {});
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() async {
    await _chatService.fetchMessagesFromSupabase(widget.friend.id);
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_controller.text.trim().isNotEmpty) {
      final message = _controller.text.trim();
      _controller.clear();

      // Send message via ChatService
      await _chatService.sendMessageToSupabase(message, widget.friend.id);

      // The real-time listener will update the UI when the message is actually sent
      // and stored in the database
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = _chatService.getMessagesForFriend(widget.friend.id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 1,
        leadingWidth: 70,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.friend.profileImageUrl),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friend.name,
                  style: const TextStyle(
                    color: chatTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.friend.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: widget.friend.isOnline ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: primaryColor),
            onPressed: () {
              // Call action
              _showComingSoonSnackbar('Voice call');
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: primaryColor),
            onPressed: () {
              // Video call action
              _showComingSoonSnackbar('Video call');
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: primaryColor),
            onSelected: (value) {
              switch (value) {
                case 'view_profile':
                  _showComingSoonSnackbar('View profile');
                  break;
                case 'clear_chat':
                  _showClearChatDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'view_profile',
                child: Text('View Profile'),
              ),
              const PopupMenuItem<String>(
                value: 'clear_chat',
                child: Text('Clear Chat'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyChatState()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(message: messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(widget.friend.profileImageUrl),
          ),
          const SizedBox(height: 16),
          Text(
            widget.friend.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.friend.isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: widget.friend.isOnline ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Send your first message to start the conversation!',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.add, color: primaryColor),
              onPressed: () => _showComingSoonSnackbar('Add attachment')
          ),
          IconButton(
              icon: const Icon(Icons.camera_alt, color: primaryColor),
              onPressed: () => _showComingSoonSnackbar('Camera')
          ),
          IconButton(
              icon: const Icon(Icons.image, color: primaryColor),
              onPressed: () => _showComingSoonSnackbar('Gallery')
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: chatSecondaryColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: primaryColor),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Chat'),
          content: const Text('Are you sure you want to clear this chat? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showComingSoonSnackbar('Clear chat');
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: errorColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isSentByMe ? sentMessageColor : receivedMessageColor,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isSentByMe ? sentMessageTextColor : receivedMessageTextColor,
          ),
        ),
      ),
    );
  }
}
