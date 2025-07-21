import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Upload sample artist and songs to Firestore
  Future<void> uploadSampleData() async {
    final sampleSongs = [
      Song(
        id: 'song1',
        title: 'Dream Life',
        artist: 'Kelly Trendz',
        url: 'https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT.appspot.com/o/dreamlife.mp3?alt=media',
        albumArtUrl: 'https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT.appspot.com/o/dreamlife.jpg?alt=media',
      ),
      Song(
        id: 'song2',
        title: 'Bad Love',
        artist: 'Kelly Trendz',
        url: 'https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT.appspot.com/o/badlove.mp3?alt=media',
        albumArtUrl: 'https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT.appspot.com/o/badlove.jpg?alt=media',
      ),
    ];

    final sampleArtist = Artist(
      id: 'kellytrendz',
      name: 'Kelly Trendz',
      imageUrl: 'https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT.appspot.com/o/kelly.jpg?alt=media',
      bio: 'Yo favorite vocal artist',
      followers: 5000,
      songs: sampleSongs,
    );

    await _db.collection('artists').doc(sampleArtist.id).set(sampleArtist.toMap());
  }

  // Load all songs from Firestore
  Future<List<Song>> getAllSongs() async {
    final snapshot = await _db.collection('artists').get();
    List<Song> allSongs = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final artist = Artist.fromMap(data);
      allSongs.addAll(artist.songs);
    }

    return allSongs;
  }
}
