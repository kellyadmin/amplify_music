import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final VoidCallback? onShareCurrentSong;
  final bool canShareSong;

  const ChatInput({
    Key? key,
    required this.onSendMessage,
    this.onShareCurrentSong,
    this.canShareSong = false,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _showReactions = false;
  late AnimationController _reactionController;
  late Animation<double> _reactionAnimation;

  final List<String> _quickReactions = ['🎵', '🔥', '💯', '👏', '❤️', '😍', '🎉', '💃'];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    
    _reactionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _reactionAnimation = CurvedAnimation(
      parent: _reactionController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _reactionController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });
    }
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  void _toggleReactions() {
    setState(() {
      _showReactions = !_showReactions;
    });
    
    if (_showReactions) {
      _reactionController.forward();
    } else {
      _reactionController.reverse();
    }
  }

  void _sendReaction(String emoji) {
    widget.onSendMessage(emoji);
    _toggleReactions();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Quick reactions panel
        AnimatedBuilder(
          animation: _reactionAnimation,
          builder: (context, child) {
            return SizeTransition(
              sizeFactor: _reactionAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border(
                    top: BorderSide(color: Colors.grey[700]!),
                  ),
                ),
                child: Wrap(
                  spacing: 12,
                  children: _quickReactions.map((emoji) {
                    return GestureDetector(
                      onTap: () => _sendReaction(emoji),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
        
        // Main input area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(
              top: BorderSide(color: Colors.grey[700]!),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Reaction button
                GestureDetector(
                  onTap: _toggleReactions,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _showReactions ? const Color(0xFFF2B84B) : Colors.grey[800],
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.emoji_emotions_outlined,
                      color: _showReactions ? Colors.black87 : Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Text input
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 36,
                      maxHeight: 100,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Share song button (if available)
                if (widget.canShareSong) ...[
                  GestureDetector(
                    onTap: widget.onShareCurrentSong,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Color(0xFFF2B84B),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Send button
                GestureDetector(
                  onTap: _isTyping ? _sendMessage : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _isTyping ? const Color(0xFFF2B84B) : Colors.grey[800],
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: _isTyping ? Colors.black87 : Colors.white54,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
