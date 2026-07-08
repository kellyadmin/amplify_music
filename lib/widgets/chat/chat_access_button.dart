import 'package:flutter/material.dart';
import '../../services/music_chat_service.dart';
import '../../screens/music_chat_screen.dart';
import '../../models.dart';

class ChatAccessButton extends StatefulWidget {
  final Song? song;
  final Artist? artist;
  final String? customRoomId;
  final String? customRoomName;
  final ChatRoomType roomType;
  final Widget? customIcon;
  final String? tooltip;

  const ChatAccessButton({
    Key? key,
    this.song,
    this.artist,
    this.customRoomId,
    this.customRoomName,
    this.roomType = ChatRoomType.song,
    this.customIcon,
    this.tooltip,
  }) : super(key: key);

  // Constructor for song chat
  const ChatAccessButton.song({
    Key? key,
    required Song song,
    Widget? customIcon,
    String? tooltip,
  }) : this(
    key: key,
    song: song,
    roomType: ChatRoomType.song,
    customIcon: customIcon,
    tooltip: tooltip,
  );

  // Constructor for artist chat
  const ChatAccessButton.artist({
    Key? key,
    required Artist artist,
    Widget? customIcon,
    String? tooltip,
  }) : this(
    key: key,
    artist: artist,
    roomType: ChatRoomType.artist,
    customIcon: customIcon,
    tooltip: tooltip,
  );

  @override
  State<ChatAccessButton> createState() => _ChatAccessButtonState();
}

class _ChatAccessButtonState extends State<ChatAccessButton> 
    with SingleTickerProviderStateMixin {
  final MusicChatService _chatService = MusicChatService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openChat() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    
    try {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });

      ChatRoom chatRoom;
      
      switch (widget.roomType) {
        case ChatRoomType.song:
          if (widget.song == null) {
            throw Exception('Song is required for song chat');
          }
          chatRoom = await _chatService.getSongChatRoom(
            widget.song!.id,
            widget.song!.title,
            widget.song!.artist,
          );
          break;
        
        case ChatRoomType.artist:
          if (widget.artist == null) {
            throw Exception('Artist is required for artist chat');
          }
          chatRoom = await _chatService.getArtistChatRoom(
            widget.artist!.id,
            widget.artist!.name,
          );
          break;
        
        default:
          throw Exception('Unsupported room type');
      }

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MusicChatScreen(
            chatRoom: chatRoom,
            currentSong: widget.song,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open chat: $e'),
          backgroundColor: const Color(0xFFE63950),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _openChat,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[800]?.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFF2B84B),
                          ),
                        ),
                      )
                    : widget.customIcon ??
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Color(0xFFF2B84B),
                        size: 20,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Compact version for use in song/artist cards
class CompactChatButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const CompactChatButton({
    Key? key,
    required this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFFF2B84B),
                  ),
                ),
              )
            : const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFFF2B84B),
                size: 16,
              ),
      ),
    );
  }
}

// Chat indicator showing active users count
class ChatIndicator extends StatelessWidget {
  final int activeUsers;
  final VoidCallback onTap;
  final bool showCount;

  const ChatIndicator({
    Key? key,
    required this.activeUsers,
    required this.onTap,
    this.showCount = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: activeUsers > 0 
              ? const Color(0xFFF2B84B).withOpacity(0.2)
              : Colors.grey[800]?.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activeUsers > 0 
                ? const Color(0xFFF2B84B).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_rounded,
              color: activeUsers > 0 
                  ? const Color(0xFFF2B84B)
                  : Colors.grey[400],
              size: 14,
            ),
            if (showCount && activeUsers > 0) ...[
              const SizedBox(width: 4),
              Text(
                activeUsers.toString(),
                style: TextStyle(
                  color: activeUsers > 0 
                      ? const Color(0xFFF2B84B)
                      : Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
