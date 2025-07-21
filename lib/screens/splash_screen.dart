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
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    final user = supabase.auth.currentUser;

    if (user != null) {
      if (user.emailConfirmedAt == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen(showResend: true)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AmplifyMainScreen(allSongs: allSongs, isArtist: true)),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
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
