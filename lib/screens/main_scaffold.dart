import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models.dart';
import '../screens/home_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/library_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/music_player_screen.dart';
import '../widgets/mini_player.dart';

class MainScaffold extends StatefulWidget {
  final List<Song> allSongs;

  const MainScaffold({super.key, required this.allSongs});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  Song? currentSong;
  bool isPlaying = false;
  final AudioPlayer _player = AudioPlayer();

  void _onSongTap(Song song) async {
    await _player.stop();
    await _player.play(AssetSource(song.url));
    setState(() {
      currentSong = song;
      isPlaying = true;
    });
  }

  void _togglePlayPause() async {
    if (_player.state == PlayerState.playing) {
      await _player.pause();
      setState(() => isPlaying = false);
    } else {
      await _player.resume();
      setState(() => isPlaying = true);
    }
  }

  void _openPlayer() {
    if (currentSong != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MusicPlayerScreen(
            song: currentSong!,
            playlist: widget.allSongs,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onSongTap: _onSongTap),
      DiscoverScreen(onSongTap: _onSongTap),
      LibraryScreen(onSongTap: _onSongTap),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          screens[_selectedIndex],
          if (currentSong != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 56,
              child: MiniPlayer(
                song: currentSong!,
                isPlaying: isPlaying,
                onTap: _openPlayer,
                onPlayPause: _togglePlayPause,
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white60,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
