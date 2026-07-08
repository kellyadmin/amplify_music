import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../services/chat_service.dart';
import '../constants.dart';

// Chat-premium-specific color (not in centralized constants)
const Color chatAccentBlue = Color(0xFF2196F3);

class ChatScreenPremium extends StatefulWidget {
  const ChatScreenPremium({super.key});

  @override
  State<ChatScreenPremium> createState() => _ChatScreenPremiumState();
}

class _ChatScreenPremiumState extends State<ChatScreenPremium>
    with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  late StreamSubscription<Map<String, dynamic>> _messageSubscription;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<User> _searchResults = [];
  List<FriendRequest> _pendingRequests = [];
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  bool _isAuthenticated = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );
    _fabController.forward();
  }

  void _checkAuthentication() {
    // Check if user is signed in via Supabase directly
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user == null) {
      setState(() {
        _isAuthenticated = false;
      });
      return;
    }

    setState(() {
      _isAuthenticated = true;
    });

    // Try to initialize chat service
    _initializeChatService();
  }

  void _initializeChatService() {
    try {
      _messageSubscription = _chatService.messages.listen(_handleIncomingMessage);
      _chatService.requestFriendsList();
      _loadPendingRequests();
    } catch (e) {
      debugPrint('Error initializing chat service: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Chat feature is not available yet';
      });
    }
  }

  void _loadPendingRequests() async {
    try {
      final requests = await _chatService.getPendingFriendRequests();
      if (mounted) {
        setState(() {
          _pendingRequests = requests;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending requests: $e');
      // Silently fail - chat tables might not exist yet
    }
  }

  @override
  void dispose() {
    if (_isAuthenticated) {
      _messageSubscription.cancel();
    }
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      switch (data['type']) {
        case 'friends_list':
          if (mounted) setState(() {});
          break;
        case 'database_setup_required':
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Chat database needs setup.\nPlease see SUPABASE_CHAT_SETUP.md for instructions.';
            });
          }
          break;
        case 'friend_request':
          _showPremiumNotification(
            'Friend Request',
            'From ${data['fromUserName']}',
            Icons.person_add,
            chatAccentBlue,
          );
          _loadPendingRequests();
          break;
        case 'friend_request_accepted':
          _showPremiumNotification(
            'Request Accepted',
            '${data['fromUserName']} is now your friend!',
            Icons.check_circle,
            accentMint,
          );
          _chatService.requestFriendsList();
          break;
      }
    } catch (e) {
      debugPrint('Error handling incoming message: $e');
    }
  }

  void _showPremiumNotification(
      String title, String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show sign-in prompt if not authenticated
    if (!_isAuthenticated) {
      return _buildSignInPrompt();
    }

    // Show error state if chat feature is not available
    if (_hasError) {
      return _buildErrorState();
    }

    final friends = _chatService.friends.values.toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildPremiumAppBar(),
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(),
          
          // Content
          SafeArea(
            child: _isSearching
                ? _buildSearchResults()
                : _buildChatList(friends),
          ),
        ],
      ),
      floatingActionButton: _buildPremiumFAB(),
    );
  }

  Widget _buildSignInPrompt() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.3),
                          primaryColor.withOpacity(0.3),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 60,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [primaryColor, primaryColor],
                    ).createShader(bounds),
                    child: const Text(
                      'Sign In Required',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please sign in to access chat features\nand connect with friends',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryColor, primaryColor],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          Navigator.pop(context);
                          // Navigate to auth screen
                          Navigator.pushNamed(context, '/auth');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.login, color: Colors.black87),
                              SizedBox(width: 12),
                              Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.3),
                          Colors.red.withOpacity(0.3),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.construction,
                      size: 60,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [accentColor, errorColor],
                    ).createShader(bounds),
                    child: const Text(
                      'Setup Required',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage.isNotEmpty
                        ? _errorMessage
                        : 'Chat feature requires database setup.\nCheck back soon!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: chatAccentBlue,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Setup Instructions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'See SUPABASE_CHAT_SETUP.md\nin your project root for\ndetailed setup instructions',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            cardColor,
            backgroundColor,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _GradientCirclesPainter(),
        size: Size.infinite,
      ),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cardColor.withOpacity(0.8),
                  cardColor.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),
      ),
      title: _isSearching
          ? _buildSearchField()
          : ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [primaryColor, primaryColor],
              ).createShader(bounds),
              child: const Text(
                'Messages',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
      leading: _isSearching
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searchResults.clear();
                });
              },
            )
          : null,
      actions: [
        if (!_isSearching) ...[
          _buildPremiumIconButton(
            Icons.search,
            () => setState(() => _isSearching = true),
          ),
          _buildFriendRequestBadge(),
        ],
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search conversations...',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        border: InputBorder.none,
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildPremiumIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.3),
            primaryColor.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildFriendRequestBadge() {
    return Stack(
      children: [
        _buildPremiumIconButton(
          Icons.person_add,
          () {
            // Navigate to friend requests
          },
        ),
        if (_pendingRequests.isNotEmpty)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [accentColor, errorColor],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
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

  Widget _buildChatList(List<Friend> friends) {
    if (friends.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        return _PremiumChatTile(
          friend: friends[index],
          color: _getColorForIndex(index),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _PremiumUserTile(
          user: _searchResults[index],
          color: _getColorForIndex(index),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.3),
                  primaryColor.withOpacity(0.3),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [primaryColor, primaryColor],
            ).createShader(bounds),
            child: const Text(
              'No Conversations Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start chatting with your friends!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFAB() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton.extended(
        onPressed: () {
          // Show new chat dialog
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryColor, primaryColor],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: const [
              Icon(Icons.add, color: Colors.black87),
              SizedBox(width: 8),
              Text(
                'New Chat',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [chatAccentBlue, accentPurple, accentMint, accentColor];
    return colors[index % colors.length];
  }
}

class _PremiumChatTile extends StatelessWidget {
  final Friend friend;
  final Color color;

  const _PremiumChatTile({required this.friend, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor.withOpacity(0.8),
            cardColor.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to conversation
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.5), color],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          friend.profileImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                    if (friend.isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: accentMint,
                            shape: BoxShape.circle,
                            border: Border.all(color: cardColor, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: accentMint.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        friend.lastMessage.isNotEmpty
                            ? friend.lastMessage
                            : 'Start a conversation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (friend.lastMessageTime.isNotEmpty)
                  Text(
                    friend.lastMessageTime,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumUserTile extends StatelessWidget {
  final User user;
  final Color color;

  const _PremiumUserTile({required this.user, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor.withOpacity(0.8),
            cardColor.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage(user.profileImageUrl),
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '@${user.username}',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Add',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientCirclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw gradient circles
    paint.shader = RadialGradient(
      colors: [
        primaryColor.withOpacity(0.1),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.2, size.height * 0.3),
      radius: 150,
    ));
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      150,
      paint,
    );

    paint.shader = RadialGradient(
      colors: [
        accentPurple.withOpacity(0.1),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.8, size.height * 0.7),
      radius: 180,
    ));
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      180,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
