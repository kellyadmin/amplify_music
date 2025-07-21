import 'package:flutter/material.dart';

class RecentlyPlayedScreen extends StatelessWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Recently Played"),
        backgroundColor: const Color(0xFF121212),
      ),
      body: const Center(
        child: Text(
          "Recently played songs will show up here.",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
