import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/music_chat_service.dart';
import '../services/music_service.dart';
import '../widgets/chat/chat_bubble.dart';
import '../widgets/chat/chat_input.dart';
import '../models.dart';

class MusicChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final Song? currentSong;

  const MusicChatScreen({
    Key? key,
    required this.chatRoom,
    this.currentSong,
  }) : super(key: key);

  @override
  State<MusicChatScreen> createState() => _MusicChatScreenState();
}

class _MusicChatScreenState extends State<MusicChatScreen>
    with TickerProviderStateMixin {
  final MusicChatService _chatService = MusicChatService();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingController;
  late Animation<double> _typingAnimation;

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _error;
  int _activeUsers = 0;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _typingAnimation = CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    );

    _initializeChat();
  }

  @override
  void dispose() {
    _chatService.leaveRoom();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      await _chatService.joinRoom(widget.chatRoom.id);

      // Listen to messages stream
      _chatService.messagesStream.listen((messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
            _isLoading = false;
          });
          _scrollToBottom();
        }
      });

      setState(() {
        _activeUsers = widget.chatRoom.activeUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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

  Future<void> _sendMessage(String message) async {
    try {
      // Check if it's a reaction (single emoji)
      if (message.length <= 2 && _isEmoji(message)) {
        await _chatService.sendReaction(message);
      } else {
        await _chatService.sendMessage(message);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to send message: $e');
    }
  }

  Future<void> _shareCurrentSong() async {
    final musicService = Provider.of<MusicService>(context, listen: false);
    final currentSong = musicService.currentSong ?? widget.currentSong;

    if (currentSong == null) {
      _showErrorSnackBar('No song is currently playing');
      return;
    }

    try {
      await _chatService.shareSong(
        currentSong.id,
        currentSong.title,
        currentSong.artist,
        message: '🎵 Currently vibing to this!',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share song: $e');
    }
  }

  bool _isEmoji(String text) {
    // Simple emoji detection - checks for common emoji ranges
    final emojiPattern = RegExp(
      r'[\u{1f300}-\u{1f5ff}]|[\u{1f900}-\u{1f9ff}]|[\u{1f600}-\u{1f64f}]|'
      r'[\u{1f680}-\u{1f6ff}]|[\u{2600}-\u{26ff}]|[\u{2700}-\u{27bf}]|'
      r'[\u{1f1e6}-\u{1f1ff}]|[\u{1f191}-\u{1f251}]|'
      r'[\u{1f004}]|[\u{1f0cf}]|[\u{1f170}-\u{1f171}]|'
      r'[\u{1f17e}-\u{1f17f}]|[\u{1f18e}]|[\u{3030}]|[\u{2b50}]|'
      r'[\u{2b55}]|[\u{2934}-\u{2935}]|[\u{2b05}-\u{2b07}]|'
      r'[\u{2b1b}-\u{2b1c}]|[\u{3297}]|[\u{3299}]|[\u{303d}]|'
      r'[\u{00a9}]|[\u{00ae}]|[\u{2122}]|[\u{23f3}]|[\u{24c2}]|'
      r'[\u{23e9}-\u{23ef}]|[\u{25b6}]|[\u{23f8}-\u{23fa}]',
      unicode: true,
    );
    return emojiPattern.hasMatch(text);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE63950),
      ),
    );
  }

  String _getRoomDescription() {
    switch (widget.chatRoom.type) {
      case ChatRoomType.song:
        return 'Discuss this song with other listeners';
      case ChatRoomType.artist:
        return 'Chat with fans of ${widget.chatRoom.metadata?['artist_name'] ?? 'this artist'}';
      case ChatRoomType.genre:
        return 'Talk about ${widget.chatRoom.name} music';
      case ChatRoomType.playlist:
        return 'Discuss this playlist';
      case ChatRoomType.liveEvent:
        return 'Live event chat';
      default:
        return widget.chatRoom.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatRoom.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_activeUsers} active • ${_getRoomDescription()}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white70),
            onPressed: () {
              _showRoomInfo();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: _buildMessagesArea(),
          ),

          // Chat input
          ChatInput(
            onSendMessage: _sendMessage,
            onShareCurrentSong: _shareCurrentSong,
            canShareSong: widget.currentSong != null ||
                         Provider.of<MusicService>(context, listen: false).currentSong != null,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF2B84B),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load chat',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2B84B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Start the conversation!',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your thoughts\nabout ${widget.chatRoom.name}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isCurrentUser = message.userId == _chatService.currentUserId;

        return ChatBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          onSongTap: () => _playSong(message),
        );
      },
    );
  }

  void _playSong(ChatMessage message) {
    if (message.type == MessageType.songShare &&
        message.sharedSongId != null) {
      // TODO: Implement song playback from shared song
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing "${message.sharedSongTitle}" by ${message.sharedSongArtist}'),
          backgroundColor: const Color(0xFFF2B84B),
        ),
      );
    }
  }

  void _showRoomInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getRoomIcon(),
                  color: const Color(0xFFF2B84B),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.chatRoom.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.chatRoom.description,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  color: Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$_activeUsers active users',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Last activity: ${_formatDateTime(widget.chatRoom.lastActivity)}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2B84B),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRoomIcon() {
    switch (widget.chatRoom.type) {
      case ChatRoomType.song:
        return Icons.music_note;
      case ChatRoomType.artist:
        return Icons.person;
      case ChatRoomType.genre:
        return Icons.category;
      case ChatRoomType.playlist:
        return Icons.playlist_play;
      case ChatRoomType.liveEvent:
        return Icons.live_tv;
      default:
        return Icons.chat;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
