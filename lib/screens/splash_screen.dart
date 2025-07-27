import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'amplify_main_screen.dart';
import '../models.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final supabase = Supabase.instance.client;

  final List<Song> allSongs = [
    Song(
      id: '1',
      title: 'Bad Love',
      artist: 'Kelly Trendz',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      albumArtUrl: 'https://i.imgur.com/Zj0rVQK.jpeg',
    ),
    Song(
      id: '2',
      title: 'Bankyaye',
      artist: 'Kelly Trendz',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      albumArtUrl: 'https://i.imgur.com/tXgkb7c.jpeg',
    ),
    Song(
      id: '3',
      title: 'Trendz Anthem',
      artist: 'Kelly Trendz',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      albumArtUrl: 'https://i.imgur.com/r2aD8Rs.jpeg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    final user = supabase.auth.currentUser;

    if (!mounted) return;

    if (user == null) {
      _navigateTo(const AuthScreen());
    } else if (user.emailConfirmedAt == null) {
      _navigateTo(const AuthScreen(showResend: true));
    } else {
      final isArtist = _checkIfArtist(user); // Can customize with your DB later
      _navigateTo(AmplifyMainScreen(allSongs: allSongs, isArtist: isArtist));
    }
  }

  bool _checkIfArtist(User user) {
    // Placeholder logic for artist detection
    return user.email?.contains('kelly') ?? false;
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.yellow),
      ),
    );
  }
}
