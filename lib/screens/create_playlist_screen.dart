import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async' show Timer; // Import Timer
import '../constants.dart';

// For this example, we'll use Map<String, dynamic> to represent a song
// A typical song map might look like:
// { 'id': 'uuid', 'title': 'Song Title', 'artist_name': 'Artist Name', 'song_url': '...', 'cover_art_url': '...' }

class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({super.key});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isPublic = false;
  bool _isSaving = false;
  bool _isSearching = false;

  // List of songs found via search
  List<Map<String, dynamic>> _searchResults = [];

  // List of songs the user has added to this new playlist
  final List<Map<String, dynamic>> _addedSongs = [];

  // Debouncer for search
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }

    try {
      // We assume your songs table is named 'songs' and has a 'title' column.
      // We also select 'artist_name' for display. Adjust as needed.
      final response = await supabase
          .from('songs')
          .select('id, title, artist_name, cover_art_url')
          .ilike('title', '%$query%')
          .limit(20); // Limit results for performance

      if (mounted) {
        setState(() {
          // Supabase returns a List<dynamic> which we cast
          _searchResults = List<Map<String, dynamic>>.from(response);
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching songs: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching songs: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  void _addSongToPlaylist(Map<String, dynamic> song) {
    // Check if song is already added
    if (_addedSongs.any((s) => s['id'] == song['id'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${song['title']}" is already in the playlist.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _addedSongs.add(song);
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _removeSongFromPlaylist(String songId) {
    setState(() {
      _addedSongs.removeWhere((s) => s['id'] == songId);
    });
  }

  Future<void> _publishPlaylist() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Form is not valid
    }

    if (_addedSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one song to the playlist.'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get the list of song IDs
      // IMPORTANT: We assume your 'playlists' table has a column named 'song_ids'
      // This column should be of type 'jsonb' or 'uuid[]' (array of uuids)
      // to store the list of song IDs.
      final songIds = _addedSongs.map((song) => song['id'] as String).toList();

      // Insert the new playlist
      await supabase.from('playlists').insert({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'is_public': _isPublic,
        'user_id': user.id,
        'created_at': DateTime.now().toIso8fcmTimer01String(),
        'updated_at': DateTime.now().toIso8601String(),
        'song_ids': songIds, // <-- Here is where we save the songs
      });

      if (mounted) {
        final newPlaylistName = _nameController.text.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playlist "$newPlaylistName" created successfully!'),
            backgroundColor: premiumGold.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pop(context, true); // Pop and signal success
      }
    } catch (e) {
      debugPrint('Error creating playlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating playlist: $e'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Create New Playlist',
            style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor), // Ensure back button is white
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _publishPlaylist,
              style: ElevatedButton.styleFrom(
                backgroundColor: premiumGold,
                foregroundColor: Colors.black,
              ),
              child: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
                  : const Text('Publish',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 1. Playlist Details ---
            _buildDetailsCard(),
            const SizedBox(height: 24),

            // --- 2. Add Songs ---
            _buildAddSongsSection(),
            const SizedBox(height: 24),

            // --- 3. Added Songs List ---
            _buildAddedSongsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: textColor),
              decoration: _inputDecoration(
                  'Playlist Name *', 'My Awesome Mix Vol. 1'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a playlist name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: textColor),
              maxLines: 3,
              decoration:
              _inputDecoration('Description', 'A short description...'),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorderColor),
              ),
              child: SwitchListTile(
                title: const Text('Public Playlist',
                    style: TextStyle(color: textColor)),
                subtitle: const Text(
                  'Anyone can discover and listen',
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
                activeColor: premiumGold,
                secondary:
                Icon(_isPublic ? Icons.public : Icons.lock, color: primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSongsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Songs',
          style: TextStyle(
              color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          style: const TextStyle(color: textColor),
          decoration: _inputDecoration('Search for a song...', 'Song title...')
              .copyWith(
            prefixIcon: const Icon(Icons.search, color: subtitleColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close, color: subtitleColor),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults = [];
                  _isSearching = false;
                });
              },
            )
                : null,
          ),
          onChanged: (query) {
            // Use debouncer to avoid spamming the API
            _debouncer.run(() {
              _searchSongs(query);
            });
          },
        ),
        const SizedBox(height: 12),

        // --- Search Results ---
        if (_isSearching)
          const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: premiumGold),
              )),
        if (!_isSearching &&
            _searchResults.isEmpty &&
            _searchController.text.isNotEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No songs found.',
                  style: TextStyle(color: subtitleColor)),
            ),
          ),
        if (!_isSearching && _searchResults.isNotEmpty)
          Container(
            height: 200, // Constrain the height
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorderColor),
            ),
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final song = _searchResults[index];
                return _buildSongTile(song,
                    isSearchResult: true,
                    onTap: () => _addSongToPlaylist(song));
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAddedSongsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Playlist (${_addedSongs.length})',
          style: const TextStyle(
              color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_addedSongs.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Search for songs to add them to your playlist.',
                style: TextStyle(color: subtitleColor, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (_addedSongs.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              shrinkWrap: true, // Use shrinkWrap inside SingleChildScrollView
              physics:
              const NeverScrollableScrollPhysics(), // Disable scrolling
              itemCount: _addedSongs.length,
              itemBuilder: (context, index) {
                final song = _addedSongs[index];
                return _buildSongTile(
                  song,
                  isSearchResult: false,
                  onTap: () {
                    // Maybe play the song? (Future functionality)
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: errorColor),
                    onPressed: () => _removeSongFromPlaylist(song['id']),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSongTile(
      Map<String, dynamic> song, {
        required bool isSearchResult,
        required VoidCallback onTap,
        Widget? trailing,
      }) {
    final coverArtUrl = song['cover_art_url'] as String?;
    final title = song['title'] ?? 'Unknown Title';
    final artist = song['artist_name'] ?? 'Unknown Artist';

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: coverArtUrl != null
            ? Image.network(
          coverArtUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 40,
            height: 40,
            color: cardBorderColor,
            child: const Icon(Icons.music_note,
                color: textDisabledColor, size: 20),
          ),
        )
            : Container(
          width: 40,
          height: 40,
          color: cardBorderColor,
          child: const Icon(Icons.music_note,
              color: textDisabledColor, size: 20),
        ),
      ),
      title: Text(title,
          style: const TextStyle(color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(artist,
          style: const TextStyle(color: subtitleColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: trailing ??
          (isSearchResult
              ? IconButton(
            icon: const Icon(Icons.add_circle_outline, color: primaryColor),
            onPressed: onTap,
          )
              : null),
      onTap: isSearchResult ? null : onTap, // Only allow adding from search
    );
  }

// Helper for consistent text field styling
  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: subtitleColor),
      hintText: hint,
      hintStyle: const TextStyle(color: textDisabledColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cardBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: premiumGold),
      ),
      filled: true,
      fillColor: backgroundColor.withOpacity(0.7),
    );
  }
}

extension on DateTime {
  toIso8fcmTimer01String() {}
}

// Simple debouncer class to prevent API spam on search
class Debouncer {
  final int milliseconds;
  VoidCallback? _callback;
  Timer? _timer; // Use Timer

  Debouncer({required this.milliseconds});

  run(VoidCallback callback) {
    _callback = callback;
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), () {
      _callback?.call();
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
