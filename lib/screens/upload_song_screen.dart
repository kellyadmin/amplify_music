import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadSongScreen extends StatefulWidget {
  const UploadSongScreen({super.key});

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();

  File? _albumArt;
  File? _audioFile;
  bool _isUploading = false;

  Future<void> _pickAlbumArt() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _albumArt = File(picked.path);
      });
    }
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioFile = File(result.files.single.path!);
      });
    }
  }

  Future<String> _uploadFile(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _uploadSong() async {
    if (_isUploading) return;

    if (!_formKey.currentState!.validate()) return;

    if (_audioFile == null) {
      _showError('Please select an audio file');
      return;
    }

    setState(() => _isUploading = true);

    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();

    try {
      // Upload audio file
      final audioUrl = await _uploadFile(
          _audioFile!, 'songs/${DateTime.now().millisecondsSinceEpoch}_audio');

      // Upload album art (optional)
      String albumArtUrl = '';
      if (_albumArt != null) {
        albumArtUrl = await _uploadFile(
            _albumArt!, 'songs/${DateTime.now().millisecondsSinceEpoch}_art');
      }

      // Save song document in Firestore
      final songDoc = FirebaseFirestore.instance.collection('songs').doc();
      await songDoc.set({
        'id': songDoc.id,
        'title': title,
        'artist': artist,
        'url': audioUrl,
        'albumArtUrl': albumArtUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Song "$title" uploaded successfully!')),
      );

      // Clear form and selections
      setState(() {
        _titleController.clear();
        _artistController.clear();
        _albumArt = null;
        _audioFile = null;
      });

      Navigator.pop(context);
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD700);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload New Song'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Song Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Please enter a song title' : null,
                enabled: !_isUploading,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _artistController,
                decoration: const InputDecoration(
                  labelText: 'Artist Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Please enter artist name' : null,
                enabled: !_isUploading,
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                icon: const Icon(Icons.audiotrack),
                label: Text(_audioFile == null ? 'Pick Audio File' : 'Change Audio File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isUploading ? null : _pickAudioFile,
              ),
              if (_audioFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Selected Audio: ${_audioFile!.path.split('/').last}',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: _isUploading ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _isUploading ? null : _pickAlbumArt,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _albumArt == null
                      ? const Center(child: Text('Tap to select album art (optional)'))
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_albumArt!, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: _isUploading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
                    : const Icon(Icons.upload_file),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Song'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isUploading ? null : _uploadSong,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
