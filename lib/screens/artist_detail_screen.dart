import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import '../services/music_service.dart';
import 'package:provider/provider.dart' as p;
import 'music_player_screen.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/auth_dialogs.dart';

import '../constants.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String artistId;

  const ArtistDetailScreen({Key? key, required this.artistId}) : super(key: key);

  @override
  _ArtistDetailScreenState createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  Future<Map<String, dynamic>>? _detailsFuture;
  bool _isFollowed = false;
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _cachedData;
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -2),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    ));

    _loadArtistData();
  }

  Future<void> _loadArtistData() {
    // Invalidate cache and refetch when the artistId changes.
    if (_cachedData != null &&
        (_cachedData!['artist'] as Artist).id != widget.artistId) {
      _cachedData = null;
    }

    if (_cachedData != null) {
      setState(() {
        _isLoading = false;
      });
      return Future.value();
    }

    setState(() {
      _isLoading = true;
      _detailsFuture = _fetchArtistAndSongsDetails();
    });
    return _detailsFuture!;
  }

  @override
  void didUpdateWidget(covariant ArtistDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.artistId != oldWidget.artistId) {
      _loadArtistData();
    }
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFollowed() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isFollowed = false);
      return;
    }
    try {
      final response = await _supabase
          .from('user_follows_artist')
          .select()
          .eq('user_id', userId)
          .eq('artist_id', widget.artistId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isFollowed = response != null;
        });
      }
    } catch (e) {
      debugPrint("Error checking follow status: $e");
    }
  }

  Future<Map<String, dynamic>> _fetchArtistAndSongsDetails() async {
    try {
      // Fetch artist data
      final artistResponse = await _supabase
          .from('artists')
          .select()
          .eq('id', widget.artistId)
          .single();

      final artist = Artist.fromMap(artistResponse);

      // Check follow status in parallel
      await _checkIfFollowedAsync();

      // Fetch songs with limit for faster initial load
      final allSongsResponse = await _supabase
          .from('songs')
          .select()
          .ilike('artist', '%${artist.name}%')
          .order('release_date', ascending: false)
          .limit(50); // Limit for faster loading

      final allSongs = (allSongsResponse as List)
          .map((data) => Song.fromMap(data))
          .toList();

      // Calculate total streams
      final totalStreams = allSongs.fold<int>(0, (sum, song) => sum + song.playCount);

      // Fetch related artists in parallel (don't wait for it)
      _getRelatedArtists(artist).then((relatedArtistsResponse) {
        final relatedArtists = (relatedArtistsResponse as List)
            .map((data) => Artist.fromMap(data))
            .toList();

        if (mounted && _cachedData != null) {
          setState(() {
            _cachedData = {
              ..._cachedData!,
              'relatedArtists': relatedArtists,
            };
          });
        }
      });

      // Cache the data
      final data = {
        'artist': artist,
        'songs': allSongs,
        'totalStreams': totalStreams,
        'relatedArtists': <Artist>[], // Will be populated async
      };

      if (mounted) {
        setState(() {
          _cachedData = data;
          _isLoading = false;
        });
      }

      return data;
    } catch (e) {
      debugPrint('Error fetching artist details: $e');
      rethrow;
    }
  }

  Future<bool> _checkIfFollowedAsync() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isFollowed = false);
      return false;
    }
    try {
      final response = await _supabase
          .from('user_follows_artist')
          .select()
          .eq('user_id', userId)
          .eq('artist_id', widget.artistId)
          .maybeSingle();

      final followed = response != null;
      if (mounted) {
        setState(() {
          _isFollowed = followed;
        });
      }
      return followed;
    } catch (e) {
      debugPrint("Error checking follow status: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _getRelatedArtists(Artist artist) async {
    try {
      // Get popular artists
      final popularResponse = await _supabase
          .from('artists')
          .select()
          .neq('id', artist.id)
          .order('followers', ascending: false)
          .limit(30); // Get more artists to have variety

      List<Map<String, dynamic>> relatedArtists = List<Map<String, dynamic>>.from(popularResponse);

      // Shuffle to get different artists each time
      relatedArtists.shuffle();

      // Take only 10 for the display
      return relatedArtists.take(10).toList();
    } catch (e) {
      debugPrint('Error fetching related artists: $e');
      // Fallback to random artists if there's an error
      final fallbackResponse = await _supabase
          .from('artists')
          .select()
          .neq('id', artist.id)
          .limit(15);

      return List<Map<String, dynamic>>.from(fallbackResponse);
    }
  }

  void _showAnimatedMessage(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 20,
        left: 20,
        right: 20,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login_rounded, color: backgroundColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: backgroundColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    _animationController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _animationController.reverse().then((_) => overlayEntry.remove());
      }
    });
  }

  Future<void> _toggleFollow(Artist artist) async {
    String? userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      final didLogin = await AuthDialogs.showLoginRequired(
        context,
        title: 'Sign in to follow artists',
        message:
            'Follow your favorite artists, stay updated on their latest releases, and personalize your music journey by signing in.',
        actionLabel: 'Sign In',
      );
      if (!didLogin) return;
      userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
    }

    final currentlyFollowed = _isFollowed;
    setState(() {
      _isFollowed = !currentlyFollowed;
    });

    try {
      if (currentlyFollowed) {
        await _supabase
            .from('user_follows_artist')
            .delete()
            .match({'user_id': userId, 'artist_id': artist.id});
      } else {
        await _supabase
            .from('user_follows_artist')
            .insert({'user_id': userId, 'artist_id': artist.id});
      }
    } catch (e) {
      setState(() {
        _isFollowed = currentlyFollowed;
      });
      debugPrint('Error toggling follow for ${artist.name}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')));
    }
  }

  void _showPromotionDialog(Artist artist) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: primaryColor),
              const SizedBox(width: 10),
              Text(
                'Support ${artist.name}',
                style: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Thank you for your interest in supporting this artist! The feature to send funds is coming soon.',
            style: TextStyle(color: subtitleColor),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Close',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? _buildLoadingShimmer()
          : (_cachedData != null
          ? _buildContent(_cachedData!)
          : FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingShimmer();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildErrorWidget(snapshot.error);
          }

          final data = snapshot.data!;
          return _buildContent(data);
        },
      )),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final artist = data['artist'] as Artist;
    final songs = data['songs'] as List<Song>;
    final totalStreams = data['totalStreams'] as int;
    final relatedArtists = data['relatedArtists'] as List<Artist>;

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(artist, totalStreams),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActionButtons(context, artist, songs),
                const SizedBox(height: 40),
                _buildSectionTitle('Latest Releases'),
                const SizedBox(height: 15),
                if (songs.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: songs.length, // Show all songs
                    itemBuilder: (context, index) {
                      return _buildSongTile(context, songs[index], index + 1, songs);
                    },
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('No songs found for this artist.',
                        style: TextStyle(color: subtitleColor, fontSize: 16)),
                  ),

                const SizedBox(height: 40),

                if (relatedArtists.isNotEmpty)
                  _buildRelatedArtistsSection(relatedArtists),
                const SizedBox(height: 40),
                _buildSectionTitle('About'),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        artist.bio,
                        style: const TextStyle(
                            color: subtitleColor, fontSize: 15, height: 1.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(Artist artist, int totalStreams) {
    return SliverAppBar(
      expandedHeight: 400.0,
      pinned: true,
      stretch: true,
      backgroundColor: backgroundColor,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.4),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image with parallax effect
            Hero(
              tag: 'artist_profile_image_${artist.id}',
              child: CachedNetworkImage(
                imageUrl: artist.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withOpacity(0.3),
                        backgroundColor,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withOpacity(0.3),
                        backgroundColor,
                      ],
                    ),
                  ),
                  child: const Icon(Icons.person, size: 80, color: subtitleColor),
                ),
              ),
            ),
            // Glassmorphic overlay
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        backgroundColor.withOpacity(0.7),
                        backgroundColor,
                      ],
                      stops: const [0.0, 0.3, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Premium gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      primaryColor.withOpacity(0.1),
                      Colors.transparent,
                      primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (artist.isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryColor, primaryColor],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified, color: backgroundColor, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Verified Artist',
                            style: TextStyle(
                              color: backgroundColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Artist name with premium styling
                  Text(
                    artist.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 52,
                      letterSpacing: -1,
                      shadows: [
                        Shadow(
                          blurRadius: 20.0,
                          color: primaryColor.withOpacity(0.3),
                          offset: const Offset(0, 4),
                        ),
                        const Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stats with premium design
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPremiumStatChip(
                        Icons.play_circle_filled,
                        '${_formatNumber(totalStreams)} plays',
                      ),
                      const SizedBox(width: 12),
                      _buildPremiumStatChip(
                        Icons.people,
                        '${_formatNumber(artist.followers)} followers',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, Artist artist, List<Song> songs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor.withOpacity(0.8),
            cardColor.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12.0,
        runSpacing: 12.0,
        children: [
          _buildPremiumButton(
            icon: Icons.shuffle_rounded,
            label: 'Shuffle Play',
            gradient: const LinearGradient(
              colors: [primaryColor, primaryColor],
            ),
            textColor: backgroundColor,
            onPressed: () {
              if (songs.isNotEmpty) {
                final musicService = p.Provider.of<MusicService>(context, listen: false);
                List<Song> shuffledSongs = List.from(songs)..shuffle();
                musicService.playSong(shuffledSongs.first, shuffledSongs);
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const MusicPlayerScreen()));
              }
            },
          ),
          _buildPremiumButton(
            icon: _isFollowed ? Icons.check_circle : Icons.person_add_alt_1_rounded,
            label: _isFollowed ? 'Following' : 'Follow',
            gradient: _isFollowed
                ? const LinearGradient(
                    colors: [primaryColor, primaryColor],
                  )
                : null,
            borderColor: _isFollowed ? null : subtitleColor,
            textColor: _isFollowed ? backgroundColor : textColor,
            onPressed: () => _toggleFollow(artist),
          ),
          _buildPremiumButton(
            icon: Icons.card_giftcard_rounded,
            label: 'Promote',
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.8),
                primaryColor.withOpacity(0.6),
              ],
            ),
            textColor: backgroundColor,
            onPressed: () => _showPromotionDialog(artist),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumButton({
    required IconData icon,
    required String label,
    Gradient? gradient,
    Color? borderColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? Colors.transparent : null,
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1.5)
                : null,
            borderRadius: BorderRadius.circular(30),
            boxShadow: gradient != null
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: textColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongTile(
      BuildContext context, Song song, int trackNumber, List<Song> songQueue) {
    final musicService = p.Provider.of<MusicService>(context, listen: false);
    // Check if the song was released in the last 30 days based on releaseDate
    final bool isNew = song.releaseDate != null && DateTime.now().difference(song.releaseDate!).inDays <= 30;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      onTap: () {
        musicService.playSong(song, songQueue, initialIndex: trackNumber - 1);
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MusicPlayerScreen()));
      },
      leading: SizedBox(
        width: 80,
        child: Row(
          children: [
            Text(
              trackNumber.toString(),
              style: const TextStyle(
                  color: subtitleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: song.albumArtUrl,
                width: 45,
                height: 45,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: cardColor,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          if (isNew)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: backgroundColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      trailing: Text(
        _formatNumber(song.playCount),
        style: const TextStyle(color: subtitleColor, fontSize: 14),
      ),
    );
  }

  Widget _buildRelatedArtistsSection(List<Artist> artists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Fans Also Like'),
        const SizedBox(height: 15),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: artists.length > 10 ? 10 : artists.length,
            itemBuilder: (context, index) {
              return _buildArtistCard(artists[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArtistCard(Artist artist) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ArtistDetailScreen(artistId: artist.id)),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: CachedNetworkImageProvider(artist.imageUrl),
              onBackgroundImageError: (exception, stackTrace) {
                // Handle image loading error
              },
              child: artist.imageUrl.isEmpty
                  ? const Icon(Icons.person, size: 40, color: subtitleColor)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: textColor, fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: subtitleColor, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: subtitleColor, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            backgroundColor: backgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: backgroundColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: 120,
                          height: 48,
                          decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(30))),
                      const SizedBox(width: 16),
                      Container(
                          width: 120,
                          height: 48,
                          decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(30))),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Container(width: 150, height: 24, color: Colors.black),
                  const SizedBox(height: 15),
                  ...List.generate(5, (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(width: 45, height: 45, color: Colors.black),
                        const SizedBox(width: 16),
                        Expanded(child: Container(height: 20, color: Colors.black)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: errorColor, size: 60),
            const SizedBox(height: 20),
            const Text(
              'Failed to Load Artist',
              style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'An unexpected error occurred. Please try again later.\n($error)',
              style: const TextStyle(color: subtitleColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _cachedData = null;
                _loadArtistData();
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: backgroundColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}
