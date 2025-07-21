import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import '../models.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  static const Color gold = Color(0xFFFFD700);
  static const Color darkBg = Color(0xFF121212);
  static const Color inactiveColor = Colors.white70;

  late List<Widget> _pages;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  final List<IconData> _navIcons = const [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.library_music_rounded,
    Icons.person_rounded,
  ];

  final List<String> _navLabels = const [
    'Home',
    'Search',
    'Library',
    'Profile',
  ];

  List<Song> allSongs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _animationControllers = List.generate(
      _navIcons.length,
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
        lowerBound: 1.0,
        upperBound: 1.2,
      ),
    );

    _scaleAnimations = _animationControllers
        .map((controller) => Tween(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    ))
        .toList();

    _animationControllers[_selectedIndex].forward();

    // Fetch songs from Firestore on init
    fetchSongsFromFirestore();
  }

  void fetchSongsFromFirestore() {
    FirebaseFirestore.instance
        .collection('songs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final songs = snapshot.docs.map((doc) {
        final data = doc.data();
        return Song(
          id: doc.id,
          title: data['title'] ?? 'Unknown',
          artist: data['artist'] ?? 'Unknown',
          url: data['url'] ?? '',
          albumArtUrl: data['cover'] ?? '',
        );
      }).toList();

      setState(() {
        allSongs = songs;
        isLoading = false;
        _pages = [
          HomeScreen(allSongs: allSongs),
          SearchScreen(allSongs: allSongs),
          const LibraryScreen(),
          const ProfileScreen(),
        ];
      });
    });
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _animationControllers[_selectedIndex].reverse();
      _selectedIndex = index;
      _animationControllers[_selectedIndex].forward();
    });
  }

  // Test function to upload a sample song to Firestore
  void uploadSampleSong() {
    FirebaseFirestore.instance.collection('songs').add({
      'title': 'Bankyaye',
      'artist': 'Kelly Trendz',
      'url': 'https://example.com/audio/bankyaye.mp3',
      'cover': 'https://example.com/images/bankyaye.jpg',
      'timestamp': FieldValue.serverTimestamp(),
    }).then((value) {
      print('Song uploaded with ID: ${value.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song uploaded successfully!')),
      );
    }).catchError((error) {
      print('Failed to upload song: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload song: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? darkBg : Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: uploadSampleSong,
        backgroundColor: gold,
        child: const Icon(Icons.cloud_upload),
        tooltip: 'Upload test song to Firestore',
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? darkBg : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 10,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_pages.length, (index) {
                final isSelected = index == _selectedIndex;
                final color = isSelected ? gold : inactiveColor;

                return GestureDetector(
                  onTap: () => _onItemTapped(index),
                  behavior: HitTestBehavior.translucent,
                  child: ScaleTransition(
                    scale: _scaleAnimations[index],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_navIcons[index], color: color, size: 26),
                        const SizedBox(height: 4),
                        Text(
                          _navLabels[index],
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
