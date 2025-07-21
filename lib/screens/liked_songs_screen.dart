import 'package:flutter/material.dart';

class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Liked Songs"),
        backgroundColor: const Color(0xFF121212),
      ),
      body: const Center(
        child: Text(
          "Your liked songs will appear here.",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
