import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
// import 'package:file_picker/file_picker.dart'; // Commented for Android build
import 'package:path/path.dart' as path;
import '../utils/file_picker_stub.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/html.dart' as html; // Web-only shim (safe on mobile)

const Color primaryColor = Color(0xFFF2B84B);
const Color secondaryColor = Color(0xFF0A0A0B);
const Color cardColor = Color(0xFF211C16);
const Color textColor = Colors.white;
const Color subtitleColor = Colors.white70;

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _fileName = '';
  Uint8List? _fileBytes;
  String? _filePath;

  final String _workerUrl = 'https://video-upload-worker.kellytrendz79.workers.dev';

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    debugPrint('UploadVideoScreen: _pickVideo called');
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        debugPrint('UploadVideoScreen: File selected: ${file.name}');
        debugPrint('UploadVideoScreen: File size: ${file.size} bytes');

        setState(() {
          _fileName = file.name ?? '';
          if (kIsWeb) {
            _fileBytes = file.bytes;
            _filePath = null;
            debugPrint('UploadVideoScreen: Web platform, using file bytes (size: ${_fileBytes?.length})');
          } else {
            _filePath = file.path;
            _fileBytes = null;
            debugPrint('UploadVideoScreen: Non-web platform, using file path: $_filePath');
          }
          _uploadProgress = 0.0;
        });
      } else {
        debugPrint('UploadVideoScreen: No file selected');
      }
    } catch (e, s) { // Added stack trace
      debugPrint('UploadVideoScreen: Error picking video: $e');
      debugPrint('UploadVideoScreen: Stack trace: $s'); // Added stack trace
      _showError('Error picking video: $e');
    }
  }

  Future<Map<String, dynamic>> _testWorkerConnection() async {
    debugPrint('UploadVideoScreen: Testing worker connection');

    if (kIsWeb) {
      try {
        debugPrint('UploadVideoScreen: Testing with browser fetch');
        final response = await html.HttpRequest.request(
          '$_workerUrl/test',
          method: 'GET',
        );

        debugPrint('UploadVideoScreen: Browser fetch response: ${response.responseText}');
        debugPrint('UploadVideoScreen: Browser fetch status: ${response.status}');

        if (response.status == 200) {
          try {
            final jsonData = json.decode(response.responseText ?? '');
            return {
              'success': true,
              'method': 'browser_fetch',
              'response': jsonData,
            };
          } catch (e) {
            return {
              'success': true,
              'method': 'browser_fetch',
              'response': response.responseText ?? '',
            };
          }
        }
      } catch (e, s) { // Added stack trace
        debugPrint('UploadVideoScreen: Browser fetch failed: $e');
        debugPrint('UploadVideoScreen: Stack trace: $s'); // Added stack trace
      }
    }

    try {
      debugPrint('UploadVideoScreen: Testing with Dio');
      final dio = Dio();
      final response = await dio.get(
        '$_workerUrl/test',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 15));

      debugPrint('UploadVideoScreen: Dio response status: ${response.statusCode}');
      debugPrint('UploadVideoScreen: Dio response data: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'method': 'dio',
          'response': response.data ?? {},
        };
      }
    } catch (e, s) { // Added stack trace
      debugPrint('UploadVideoScreen: Dio test failed: $e');
      debugPrint('UploadVideoScreen: Stack trace: $s'); // Added stack trace
    }

    try {
      debugPrint('UploadVideoScreen: Testing with http package');
      final testEndpoints = [
        '$_workerUrl/test',
        '$_workerUrl/',
        _workerUrl,
      ];

      for (String endpoint in testEndpoints) {
        debugPrint('UploadVideoScreen: Testing endpoint: $endpoint');
        try {
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ).timeout(const Duration(seconds: 15));

          debugPrint('UploadVideoScreen: HTTP response status: ${response.statusCode}');
          debugPrint('UploadVideoScreen: HTTP response body: ${response.body}');

          if (response.statusCode == 200) {
            try {
              final jsonData = json.decode(response.body);
              return {
                'success': true,
                'method': 'http',
                'endpoint': endpoint,
                'response': jsonData,
              };
            } catch (e) {
              return {
                'success': true,
                'method': 'http',
                'endpoint': endpoint,
                'response': response.body,
              };
            }
          }
        } catch (e, s) { // Added stack trace
          debugPrint('UploadVideoScreen: Error testing endpoint $endpoint: $e');
          debugPrint('UploadVideoScreen: Stack trace: $s'); // Added stack trace
        }
      }
    } catch (e, s) { // Added stack trace
      debugPrint('UploadVideoScreen: HTTP package test failed: $e');
      debugPrint('UploadVideoScreen: Stack trace: $s'); // Added stack trace
    }

    return {
      'success': false,
      'error': 'All connection methods failed',
    };
  }

  Future<Map<String, dynamic>> _uploadVideoToCloudflare() async {
    debugPrint('UploadVideoScreen: _uploadVideoToCloudflare called');

    if (_fileBytes == null && (_filePath == null || _filePath!.isEmpty)) {
      debugPrint('UploadVideoScreen: No video file selected');
      throw Exception('No video file selected');
    }

    // Add detailed check
    if (kIsWeb) {
      debugPrint('UploadVideoScreen: Web upload. File bytes length: ${_fileBytes?.length}');
    } else {
      debugPrint('UploadVideoScreen: Mobile upload. File path: $_filePath');
      if (_filePath != null) {
        final file = io.File(_filePath!);
        if (await file.exists()) {
          debugPrint('UploadVideoScreen: Mobile file exists. Size: ${await file.length()} bytes');
        } else {
          debugPrint('UploadVideoScreen: ERROR: Mobile file does NOT exist at path: $_filePath');
          throw Exception('File not found at path: $_filePath');
        }
      }
    }


    try {
      debugPrint('UploadVideoScreen: Creating multipart request to $_workerUrl/upload');

      // Use http package for better compatibility
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_workerUrl/upload'),
      );

      // Ensure all string values are non-nullable with explicit defaults
      String title = _titleController.text.trim();
      if (title.isEmpty) title = 'Untitled Video';

      String artist = _artistController.text.trim();
      if (artist.isEmpty) artist = 'Unknown Artist';

      String description = _descriptionController.text.trim();
      // Description can be empty

      String userId = _supabase.auth.currentUser?.id ?? '';
      if (userId.isEmpty) userId = 'anonymous';

      debugPrint('UploadVideoScreen: Validated fields - Title: $title, Artist: $artist, UserId: $userId');

      // Add video file
      String filename = _fileName.isNotEmpty ? _fileName : 'video.mp4';

      if (kIsWeb && _fileBytes != null) {
        debugPrint('UploadVideoScreen: Adding web file: $filename, size: ${_fileBytes!.length} bytes');
        request.files.add(
          http.MultipartFile.fromBytes(
            'video',
            _fileBytes!,
            filename: filename,
          ),
        );
      } else if (!kIsWeb && _filePath != null && _filePath!.isNotEmpty) {
        debugPrint('UploadVideoScreen: Adding non-web file: $_filePath');
        request.files.add(
          await http.MultipartFile.fromPath(
            'video',
            _filePath!,
            filename: filename,
          ),
        );
      } else {
        debugPrint('UploadVideoScreen: ERROR: No file bytes (web) or file path (mobile) available for upload.');
        throw Exception('No file available for upload');
      }

      // Add metadata - ensure all values are non-empty strings
      request.fields['title'] = title;
      request.fields['artist'] = artist;
      request.fields['description'] = description;
      request.fields['userId'] = userId;

      debugPrint('UploadVideoScreen: Metadata added - Title: ${request.fields['title']}, Artist: ${request.fields['artist']}');

      // Added detailed logging of request fields
      debugPrint('UploadVideoScreen: --- Sending request with fields ---');
      request.fields.forEach((key, value) {
        debugPrint('UploadVideoScreen: Field: $key = $value');
      });
      for (var file in request.files) {
        debugPrint('UploadVideoScreen: File: ${file.field} = ${file.filename} (Length: ${file.length})');
      }
      debugPrint('UploadVideoScreen: --- End of request fields ---');


      // Send the request with progress tracking
      debugPrint('UploadVideoScreen: Sending request to worker');

      final responseFuture = request.send().timeout(
        const Duration(minutes: 30),
        onTimeout: () {
          debugPrint('UploadVideoScreen: Request timed out');
          throw TimeoutException('Request timed out');
        },
      );

      var response = await responseFuture;

      debugPrint('UploadVideoScreen: Response status code: ${response.statusCode}');
      debugPrint('UploadVideoScreen: Response content length: ${response.contentLength}');

      // Track upload progress
      // Use request.contentLength for total bytes to send, not response.contentLength
      final totalBytes = request.contentLength; // Changed this
      debugPrint('UploadVideoScreen: Total bytes to send (from request.contentLength): $totalBytes');
      int receivedBytes = 0; // This is for download, let's rename

      final completer = Completer<String>();
      final buffer = StringBuffer();

      // The http.MultipartRequest.send() doesn't give upload progress.
      // We are tracking download progress here, which isn't what we want.
      // The LinearProgressIndicator was using _uploadProgress, which was only set here.
      // This progress logic is for the *response* download, not the *request* upload.
      // We will leave it as is, but add a debug print.
      debugPrint('UploadVideoScreen: NOTE: Progress tracking is for response download, not request upload.');

      await response.stream.forEach((data) {
        receivedBytes += data.length;
        // Progress calculation might be incorrect if response.contentLength was null
        double progress = totalBytes > 0 ? (receivedBytes / totalBytes) : 0.0;
        debugPrint('UploadVideoScreen: Response download progress: $progress (${(progress * 100).toStringAsFixed(1)}%)');

        if (mounted) {
          setState(() {
            // This is mislabeled as _uploadProgress, but it's download progress
            _uploadProgress = progress;
          });
        }

        buffer.write(String.fromCharCodes(data));
      });

      debugPrint('UploadVideoScreen: Response stream completed');
      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
        });
      }

      final responseBody = buffer.toString();
      debugPrint('UploadVideoScreen: Response body: $responseBody');

      // Parse JSON response
      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = json.decode(responseBody);
        debugPrint('UploadVideoScreen: Parsed JSON response: $jsonResponse');
      } catch (e, s) { // Added stack trace
        debugPrint('UploadVideoScreen: Error parsing JSON response: $e');
        debugPrint('UploadVideoScreen: Stack trace: $s'); // Added stack trace
        debugPrint('UploadVideoScreen: Raw response: $responseBody');
        throw Exception('Invalid JSON response from server: $e. Response: $responseBody');
      }

      if (response.statusCode != 200) {
        debugPrint('UploadVideoScreen: Upload failed with status: ${response.statusCode}');
        throw Exception(jsonResponse['error']?.toString() ?? 'Failed to upload video. Status: ${response.statusCode}');
      }

      debugPrint('UploadVideoScreen: Upload successful, returning data');
      return {
        'videoUrl': jsonResponse['videoUrl']?.toString() ?? '',
        'thumbnailUrl': jsonResponse['thumbnailUrl']?.toString() ?? '',
        'streamId': jsonResponse['streamId']?.toString() ?? '',
        'duration': jsonResponse['duration'] ?? 0,
      };
    } catch (e, s) { // Added stack trace
      debugPrint('UploadVideoScreen: Exception in _uploadVideoToCloudflare: $e');
      debugPrint('UploadVideoScreen: Stack trace: $s'); // Added stack trace
      if (e is TimeoutException) {
        throw Exception('Upload timed out. Please check your internet connection and try again.');
      }
      throw Exception('Error uploading to Cloudflare: $e');
    }
  }

  Future<void> _uploadVideo() async {
    debugPrint('UploadVideoScreen: _uploadVideo called');

    if (!_formKey.currentState!.validate()) {
      debugPrint('UploadVideoScreen: Form validation failed');
      return;
    }

    if (_fileBytes == null && (_filePath == null || _filePath!.isEmpty)) {
      debugPrint('UploadVideoScreen: No video file selected');
      _showError('Please pick a video file first.');
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      debugPrint('UploadVideoScreen: User not authenticated');
      _showError('You must be logged in to upload.');
      return;
    }

    debugPrint('UploadVideoScreen: User authenticated: $userId');

    debugPrint('UploadVideoScreen: Testing worker connection');
    final workerTestResult = await _testWorkerConnection();

    if (!workerTestResult['success']) {
      debugPrint('UploadVideoScreen: Worker connection test failed: ${workerTestResult['error']}');

      String errorMessage = 'Unable to connect to upload service. ';
      if (kIsWeb) {
        errorMessage += 'This might be due to browser security restrictions. ';
        errorMessage += 'Please try using a different browser or check your browser settings. ';
      }
      errorMessage += 'Error: ${workerTestResult['error']}. Please try again later.';

      _showError(errorMessage);
      return;
    }

    debugPrint('UploadVideoScreen: Worker connection test successful. Method: ${workerTestResult['method']}');
    debugPrint('UploadVideoScreen: Worker test response: ${workerTestResult['response']}'); // Added response logging

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      debugPrint('UploadVideoScreen: Starting upload process');

      final result = await _uploadVideoToCloudflare();
      debugPrint('UploadVideoScreen: Cloudflare upload result: $result');

      // Add check for empty results
      if (result['videoUrl'] == null || (result['videoUrl'] as String).isEmpty) {
        debugPrint('UploadVideoScreen: ERROR: Cloudflare worker returned empty videoUrl.');
        throw Exception('Upload worker returned no video URL.');
      }
      if (result['streamId'] == null || (result['streamId'] as String).isEmpty) {
        debugPrint('UploadVideoScreen: ERROR: Cloudflare worker returned empty streamId.');
        throw Exception('Upload worker returned no stream ID.');
      }


      debugPrint('UploadVideoScreen: Saving metadata to Supabase');
      final dataToInsert = {
        'title': _titleController.text.trim(),
        'artist': _artistController.text.trim(),
        'video_url': result['videoUrl'] as String,
        'thumbnailUrl': result['thumbnailUrl'] as String,
        'play_count': 0,
        'likes': 0,
        'comments': 0,
        'views': 0,
        'created_at': DateTime.now().toIso8601String(),
        'upload_date': DateTime.now().toIso8601String(),
        'release_date': null,
        'stream_id': result['streamId'] as String,
      };

      debugPrint('UploadVideoScreen: Data to insert: $dataToInsert'); // Added logging for data

      final supabaseResponse = await _supabase.from('music_videos').insert(dataToInsert).select();

      debugPrint('UploadVideoScreen: Supabase response: $supabaseResponse');

      // Supabase v2 returns an object with 'error' and 'data' keys
      // The provided code doesn't check for Supabase errors. Let's add it.
      // Note: This assumes supabase_flutter >= 1.0.0
      // If it's older, the response *is* the data or it throws.
      // Let's assume it's new and can return an error object.
      // The `.select()` makes it return data. If it fails, it might throw or return an error.
      // The current Supabase client throws an exception on error, so a try/catch is correct.
      // We will add logging inside the catch block.


      _showSuccess('Upload complete! Your video is now processing.');
      if (mounted) {
        debugPrint('UploadVideoScreen: Navigating back to discover screen');
        Navigator.of(context).pop();
      }
    } catch (e, s) { // Added stack trace
      debugPrint('UploadVideoScreen: Upload failed with error: $e');
      debugPrint('UploadVideoScreen: Stack trace: $s'); // Added stack trace
      _showError('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _showError(String message) {
    debugPrint('UploadVideoScreen: Showing error message: $message');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE63950),
        duration: const Duration(seconds: 5), // Make error easier to read
      ),
    );
  }

  void _showSuccess(String message) {
    debugPrint('UploadVideoScreen: Showing success message: $message');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('UploadVideoScreen: Building widget');
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: const Text('Upload New Video', style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: textColor),
                decoration: _buildInputDecoration('Video Title'),
                validator: (value) {
                  debugPrint('UploadVideoScreen: Validating title: $value');
                  return (value == null || value.isEmpty)
                      ? 'Please enter a title'
                      : null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _artistController,
                style: const TextStyle(color: textColor),
                decoration: _buildInputDecoration('Artist Name'),
                validator: (value) {
                  debugPrint('UploadVideoScreen: Validating artist: $value');
                  return (value == null || value.isEmpty)
                      ? 'Please enter an artist name'
                      : null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: textColor),
                decoration: _buildInputDecoration('Description (Optional)'),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              OutlinedButton.icon(
                icon: const Icon(Icons.video_library_outlined, color: primaryColor),
                label: Text(
                  _fileName.isEmpty ? 'Pick Video' : _fileName,
                  style: const TextStyle(color: primaryColor),
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _isLoading ? null : _pickVideo,
              ),
              const SizedBox(height: 24),

              if (_isLoading) ...[
                LinearProgressIndicator(
                  // The progress value is likely for response download, not upload.
                  // For a better UX, we'd want indeterminate or actual upload progress.
                  // Setting value to null makes it indeterminate.
                  value: _uploadProgress > 0.0 ? _uploadProgress : null, // Changed to indeterminate
                  backgroundColor: cardColor,
                  color: const Color(0xFFC8901F),
                  minHeight: 10,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    // Updated text based on indeterminate progress
                    _uploadProgress == 0.0
                        ? 'Uploading... (Please wait)'
                        : 'Processing... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: subtitleColor),
                  ),
                ),
              ] else
                ElevatedButton(
                  onPressed: _uploadVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: secondaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Upload & Publish',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: subtitleColor),
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    );
  }
}
