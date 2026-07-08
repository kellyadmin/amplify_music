import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Song.dart';

class SongService {
  static Future<List<Song>> fetchSongs() async {
    final snapshot = await FirebaseFirestore.instance.collection('songs').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Song.fromMap(data);
    }).toList();
  }
}
