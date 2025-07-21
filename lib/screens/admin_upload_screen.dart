import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isUploading = false;

  String _title = '';
  String _artist = '';
  String? _genre;
  String? _category;

  Uint8List? _audioBytes;
  Uint8List? _imageBytes;
  String? _audioFileName;
  String? _imageFileName;

  final _genres = [
    'Afrobeat', 'Pop', 'RnB', 'Hip Hop', 'Dancehall', 'Reggae', 'Trap', 'Other'
  ];
  final _categories = [
    'Single', 'Album', 'Freestyle', 'EP', 'Collab'
  ];

  Future<void> _pickFile({required bool isImage}) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: isImage
          ? ['jpg', 'jpeg', 'png']
          : ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
      withData: true,
    );
    if (res?.files.isEmpty ?? true) return;
    final f = res!.files.first;
    setState(() {
      if (isImage) {
        _imageBytes = f.bytes;
        _imageFileName = f.name;
      } else {
        _audioBytes = f.bytes;
        _audioFileName = f.name;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isImage ? '✅ Image selected' : '✅ Audio selected')),
    );
  }

  Future<void> _uploadSong() async {
    if (!_formKey.currentState!.validate() ||
        _audioBytes == null ||
        _imageBytes == null ||
        _genre == null ||
        _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Fill all fields & select files')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isUploading = true);

    final supabase = Supabase.instance.client;
    final ts = DateTime.now().millisecondsSinceEpoch;

    try {
      var aext = p.extension(_audioFileName ?? '').replaceFirst('.', '');
      if (aext.isEmpty) aext = 'mp3';

      var iext = p.extension(_imageFileName ?? '').replaceFirst('.', '');
      if (iext.isEmpty) iext = 'jpg';

      final audioPath = 'songs/$ts.$aext';
      final imagePath = 'images/$ts.$iext';

      // Upload files to correct buckets
      await supabase.storage.from('songs').uploadBinary(audioPath, _audioBytes!);
      await supabase.storage.from('images').uploadBinary(imagePath, _imageBytes!);

      // Get public URLs
      final audioUrl = supabase.storage.from('songs').getPublicUrl(audioPath);
      final imageUrl = supabase.storage.from('images').getPublicUrl(imagePath);

      // Insert metadata into Supabase table
      await supabase.from('songs').insert({
        'title': _title,
        'artist': _artist,
        'audio_url': audioUrl,
        'album_art_url': imageUrl,
        'genre': _genre,
        'category': _category,
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Uploaded successfully')),
      );

      _formKey.currentState!.reset();
      setState(() {
        _audioBytes = null;
        _imageBytes = null;
        _audioFileName = null;
        _imageFileName = null;
        _genre = null;
        _category = null;
      });
    } catch (e) {
      debugPrint('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Upload failed: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Widget _previewImage() {
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, height: 100, fit: BoxFit.cover);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload New Song')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Song Title'),
                onSaved: (v) => _title = v!.trim(),
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Artist Name'),
                onSaved: (v) => _artist = v!.trim(),
                validator: (v) => v == null || v.isEmpty ? 'Enter artist' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Genre'),
                value: _genre,
                items: _genres
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _genre = v),
                validator: (v) => v == null ? 'Select genre' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                value: _category,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Select category' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : () => _pickFile(isImage: false),
                icon: const Icon(Icons.music_note),
                label: Text(
                    _audioBytes != null ? '✅ Audio Selected' : 'Pick Audio'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : () => _pickFile(isImage: true),
                icon: const Icon(Icons.image),
                label: Text(
                    _imageBytes != null ? '✅ Image Selected' : 'Pick Image'),
              ),
              const SizedBox(height: 10),
              _previewImage(),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadSong,
                style:
                ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : const Text('🚀 Upload Song'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
