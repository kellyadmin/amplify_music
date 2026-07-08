import 'package:flutter/material.dart';

void main() {
  runApp(const MinimalAmplifyMusic());
}

class MinimalAmplifyMusic extends StatelessWidget {
  const MinimalAmplifyMusic({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viba Music - Minimal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MinimalHomeScreen(),
    );
  }
}

class MinimalHomeScreen extends StatelessWidget {
  const MinimalHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viba Music'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'Amplify Music',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Minimal Android Build Test',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
