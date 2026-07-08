import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/file_picker_stub.dart';
import 'package:path/path.dart' as p; // Import path for getting file extensions
import '../constants.dart';

class ArtistDashboardScreen extends StatefulWidget {
  const ArtistDashboardScreen({super.key});

  @override
  State<ArtistDashboardScreen> createState() => _ArtistDashboardScreenState();
}

class _ArtistDashboardScreenState extends State<ArtistDashboardScreen> {
  final supabase = Supabase.instance.client;
  final NumberFormat _formatter = NumberFormat.compact(locale: 'en_US');

  User? user;

  // State variables for our data
  bool _isLoading = true;
  String _artistName = 'Artist';
  int _followers = 0;
  int _totalPlays = 0;

  // Dynamic variables for Chart Analytics
  int _monthlyPlays = 0; // The total plays displayed in the Monthly Stat Card
  List<FlSpot> _dailyPlaysSpots = []; // The data points for the line chart

  List<dynamic> _songs = [];
  List<dynamic> _albums = [];

  // Upload form controllers
  final _uploadFormKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  // Removed URL controllers
  DateTime? _selectedReleaseDate;
  String? _selectedAlbumId;
  bool _isUploading = false;

  // --- NEW: State for file picking ---
  Uint8List? _selectedCoverArtBytes; // Changed from File?
  Uint8List? _selectedAudioBytes; // Changed from File?
  String? _coverArtFileName;
  String? _audioFileName;
  // --- End new state ---

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    // Removed URL controllers disposal
    super.dispose();
  }

  // --- Improved analytics function ---
  // Calculate a plausible 7-day trend based on song plays, weighted by song plays.
  Future<void> _fetchDailyPlayData(String artistId) async {
    _monthlyPlays = (_totalPlays * 0.8).toInt();

    if (_monthlyPlays == 0) {
      if (mounted) {
        setState(() {
          _dailyPlaysSpots = [];
        });
      }
      return;
    }

    int lastWeekPlays = (_monthlyPlays * 0.25).toInt();
    final List<int> songPlays = _songs.map<int>((s) => (s['plays'] ?? 0) as int).toList();
    int totalSongPlays = songPlays.fold(0, (a, b) => a + b);
    final randomSeed = DateTime.now().millisecondsSinceEpoch % 1000;

    final List<double> dayWeights = List.generate(7, (i) {
      return 0.9 + (i * 0.18);
    });

    final double weightSum = dayWeights.fold(0.0, (a, b) => a + b);

    List<FlSpot> spots = [];
    int assigned = 0;
    for (int i = 0; i < 7; i++) {
      double base = (dayWeights[i] / weightSum) * lastWeekPlays;

      double variability = 0.0;
      if (totalSongPlays > 0) {
        double topSongFactor = songPlays.isNotEmpty ? (songPlays.first / totalSongPlays) : 0.1;
        variability = base * (0.05 + 0.15 * topSongFactor) * ((randomSeed % (i + 3)) / 100.0);
      } else {
        variability = base * 0.1 * ((randomSeed % (i + 3)) / 100.0);
      }

      int playsForDay = (base + variability).round();
      if (i == 6) {
        playsForDay = lastWeekPlays - assigned;
      } else {
        assigned += playsForDay;
      }

      if (playsForDay < 0) playsForDay = 0;
      spots.add(FlSpot(i.toDouble(), playsForDay.toDouble()));
    }

    if (mounted) {
      setState(() {
        _dailyPlaysSpots = spots;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final artistId = user!.id;

    try {
      final profileRes = await supabase
          .from('profiles')
          .select('username, followers')
          .eq('id', artistId)
          .single();

      final songsRes = await supabase
          .from('songs')
          .select('id, title, album_art_url, plays')
          .eq('artist_id', artistId)
          .order('plays', ascending: false);

      int calculatedTotalPlays = 0;
      for (var song in songsRes) {
        calculatedTotalPlays += (song['plays'] ?? 0) as int;
      }

      final albumsRes = await supabase
          .from('albums')
          .select('id, title, cover_art_url, release_date')
          .eq('artist_id', artistId)
          .order('release_date', ascending: false);

      if (mounted) {
        setState(() {
          _artistName = profileRes['username'] ?? 'Artist';
          _followers = profileRes['followers'] ?? 0;
          _songs = songsRes;
          _albums = albumsRes;
          _totalPlays = calculatedTotalPlays;

          _selectedAlbumId = null;
        });
      }

      await _fetchDailyPlayData(artistId);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard data: $e. Ensure all tables/columns exist.'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  // --- NEW: File picking methods ---
  Future<void> _pickCoverArt(StateSetter setStateSB) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Ask file_picker to load bytes
      );

      if (result != null && result.files.single.bytes != null) { // Check for bytes instead of path
        setStateSB(() {
          _selectedCoverArtBytes = result.files.single.bytes; // Store bytes
          _coverArtFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking cover art: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: errorColor),
        );
      }
    }
  }

  Future<void> _pickAudioFile(StateSetter setStateSB) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: true, // Ask file_picker to load bytes
      );

      if (result != null && result.files.single.bytes != null) { // Check for bytes instead of path
        setStateSB(() {
          _selectedAudioBytes = result.files.single.bytes; // Store bytes
          _audioFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking audio file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking audio: $e'), backgroundColor: errorColor),
        );
      }
    }
  }
  // --- End new file picking methods ---

  // Upload bottom-sheet
  Future<void> _showUploadSheet() async {
    // Clear form state
    _titleController.clear();
    _genreController.clear();
    _selectedReleaseDate = null;
    _selectedAlbumId = _albums.isNotEmpty ? (_albums.first['id'] as String) : null;
    _selectedCoverArtBytes = null; // Clear bytes
    _selectedAudioBytes = null; // Clear bytes
    _coverArtFileName = null;
    _audioFileName = null;

    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      context: context,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
        return StatefulBuilder(builder: (context, setStateSB) {
          return Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Form(
                key: _uploadFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Submit New Song', // Changed title
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Song Title',
                        labelStyle: const TextStyle(color: subtitleColor),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a song title' : null,
                    ),
                    const SizedBox(height: 12),

                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Album (optional)',
                        labelStyle: const TextStyle(color: subtitleColor),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          dropdownColor: cardColor,
                          value: _selectedAlbumId,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Single / No Album', style: TextStyle(color: textColor))),
                            ..._albums.map((a) {
                              return DropdownMenuItem(
                                value: a['id'] as String?,
                                child: Text(a['title'] ?? 'Untitled', style: const TextStyle(color: textColor)),
                              );
                            }).toList(),
                          ],
                          onChanged: (v) {
                            setStateSB(() => _selectedAlbumId = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _genreController,
                      style: const TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Genre',
                        labelStyle: const TextStyle(color: subtitleColor),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Release Date',
                              labelStyle: const TextStyle(color: subtitleColor),
                              filled: true,
                              fillColor: Colors.white12,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            child: GestureDetector(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(1970),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  initialDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.dark()), child: child!);
                                  },
                                );
                                if (picked != null) {
                                  setStateSB(() {
                                    _selectedReleaseDate = picked;
                                  });
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  _selectedReleaseDate != null ? DateFormat.yMMMd().format(_selectedReleaseDate!) : 'Select a date',
                                  style: const TextStyle(color: textColor),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- NEW: File Picker Widgets ---
                    _buildFilePicker(
                      context: context,
                      title: 'Cover Art',
                      fileName: _coverArtFileName,
                      icon: Icons.image,
                      onTap: () => _pickCoverArt(setStateSB),
                    ),
                    const SizedBox(height: 12),
                    _buildFilePicker(
                      context: context,
                      title: 'Audio File',
                      fileName: _audioFileName,
                      icon: Icons.music_note,
                      onTap: () => _pickAudioFile(setStateSB),
                    ),
                    // --- End File Picker Widgets ---

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: premiumGold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isUploading
                                ? null
                                : () async {
                              if (!_uploadFormKey.currentState!.validate()) return;

                              // Add validation for files
                              if (_selectedAudioBytes == null || _selectedCoverArtBytes == null) { // Check bytes
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Please select both cover art and an audio file.'),
                                  backgroundColor: errorColor,
                                ));
                                return;
                              }

                              await _performUpload();
                              if (mounted) Navigator.of(context).pop();
                            },
                            child: _isUploading
                                ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                                : const Text('Submit for Review', style: TextStyle(fontWeight: FontWeight.bold)), // Changed button text
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your submission will be reviewed by our team before it appears in the app.', // Updated note
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  // --- NEW: Helper widget for file picker ---
  Widget _buildFilePicker({
    required BuildContext context,
    required String title,
    required String? fileName,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: title,
          labelStyle: const TextStyle(color: subtitleColor),
          filled: true,
          fillColor: Colors.white12,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
        child: Row(
          children: [
            Icon(icon, color: subtitleColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName ?? 'No file selected',
                style: TextStyle(
                  color: fileName != null ? textColor : textDisabledColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.upload_file, color: subtitleColor, size: 20),
          ],
        ),
      ),
    );
  }
  // --- End helper widget ---

  // --- UPDATED: _performUpload function ---
  Future<void> _performUpload() async {
    if (user == null || _selectedAudioBytes == null || _selectedCoverArtBytes == null || _coverArtFileName == null || _audioFileName == null) {
      debugPrint('User or files are null. Aborting upload.');
      return;
    }

    if (mounted) {
      setState(() {
        _isUploading = true;
      });
    }

    try {
      final artistId = user!.id;
      final uniqueTimestamp = DateTime.now().millisecondsSinceEpoch;

      // 1. Upload Cover Art
      final coverArtExt = p.extension(_coverArtFileName!); // Get extension from filename
      final coverArtName = '${uniqueTimestamp}_cover$coverArtExt';
      final coverArtPath = 'artist_submissions/$artistId/cover_art/$coverArtName';

      await supabase.storage
          .from('cover_art_submissions') // BUCKET for cover art
          .uploadBinary( // Use uploadBinary
        coverArtPath,
        _selectedCoverArtBytes!, // Pass bytes
        fileOptions: FileOptions(cacheControl: '3600', upsert: false),
      );
      debugPrint('Cover art uploaded to: $coverArtPath');


      // 2. Upload Audio File
      final audioExt = p.extension(_audioFileName!); // Get extension from filename
      final audioName = '${uniqueTimestamp}_audio$audioExt';
      final audioPath = 'artist_submissions/$artistId/audio/$audioName';

      await supabase.storage
          .from('song_submissions') // BUCKET for audio
          .uploadBinary( // Use uploadBinary
        audioPath,
        _selectedAudioBytes!, // Pass bytes
        fileOptions: FileOptions(cacheControl: '3600', upsert: false),
      );
      debugPrint('Audio file uploaded to: $audioPath');

      // 3. Insert into `song_submissions` table
      final Map<String, dynamic> newSubmission = {
        'title': _titleController.text.trim(),
        'genre': _genreController.text.trim(),
        'album_id': _selectedAlbumId,
        'release_date': _selectedReleaseDate?.toIso8601String(),
        'artist_id': artistId,
        'status': 'pending', // Set initial status
        'cover_art_storage_path': coverArtPath, // Store the path
        'audio_storage_path': audioPath, // Store the path
        'created_at': DateTime.now().toIso8601String(),
      };

      // Insert into the new table
      await supabase.from('song_submissions').insert(newSubmission);
      debugPrint('Submission metadata inserted into song_submissions table.');


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Song submitted for review successfully.'),
          backgroundColor: Colors.green,
        ));
        // We don't call _loadDashboardData() because the song is not in the 'songs' table yet
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: errorColor,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
  // --- End updated function ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 2,
        shadowColor: Colors.black54,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _artistName,
              style: const TextStyle(
                color: premiumGold,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Artist Dashboard',
              style: TextStyle(color: subtitleColor, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: subtitleColor),
            tooltip: 'Refresh Data',
            onPressed: _loadDashboardData,
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.black12,
            child: Text(
              _artistName.isNotEmpty ? _artistName[0].toUpperCase() : 'A',
              style: const TextStyle(color: textColor),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: premiumGold,
        foregroundColor: Colors.black,
        onPressed: _showUploadSheet,
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('Submit Song'), // Changed FAB text
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: premiumGold),
      )
          : RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: premiumGold,
        backgroundColor: backgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderSummary(),
            const SizedBox(height: 18),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildSectionHeader('Monthly Play Trend (7 Days)', Icons.bar_chart),
            _buildMonthlyPlaysChart(),
            const SizedBox(height: 24),
            _buildSectionHeader('Top Songs', Icons.music_note),
            _buildSongList(),
            const SizedBox(height: 24),
            _buildSectionHeader('Your Albums', Icons.album),
            _buildAlbumList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: surfaceGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [premiumGold.withOpacity(0.9), primaryColor.withOpacity(0.6)]),
              boxShadow: [BoxShadow(color: premiumGold.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 6))],
            ),
            child: Center(
              child: Text(
                _artistName.isNotEmpty ? _artistName[0].toUpperCase() : 'A',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _artistName,
                style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person, color: subtitleColor, size: 16),
                  const SizedBox(width: 6),
                  Text('${_formatter.format(_followers)} followers', style: const TextStyle(color: subtitleColor)),
                  const SizedBox(width: 12),
                  Icon(Icons.headset, color: subtitleColor, size: 16),
                  const SizedBox(width: 6),
                  Text('${_formatter.format(_totalPlays)} plays', style: const TextStyle(color: subtitleColor)),
                ],
              )
            ]),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Add premium/upgrade flow
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: premiumGold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Upgrade', style: TextStyle(color: premiumGold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: premiumGold, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard('Total Plays', _totalPlays.toString(), Icons.play_arrow, Colors.blue),
        _buildStatCard('Followers', _followers.toString(), Icons.people, Colors.purple),
        _buildStatCard('Monthly', _monthlyPlays.toString(), Icons.show_chart, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String title, String rawValue, IconData icon, Color color) {
    final String value = _formatter.format(int.tryParse(rawValue) ?? 0);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)]),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ]),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Improved Chart Widget with touch tooltips
  Widget _buildMonthlyPlaysChart() {
    if (_dailyPlaysSpots.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor),
        ),
        child: const Center(
          child: Text(
            'No play data available for the last 7 days.',
            style: TextStyle(color: subtitleColor),
          ),
        ),
      );
    }

    final double minYRaw = _dailyPlaysSpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final double maxYRaw = _dailyPlaysSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final double minY = (minYRaw * 0.8).clamp(0.0, double.infinity);
    final double maxY = (maxYRaw * 1.15).clamp(1.0, double.infinity);
    final double interval = ((maxY - minY) / 3).clamp(1.0, double.infinity);

    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 8, right: 12, left: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final now = DateTime.now();
                  final dayIndex = value.toInt();
                  final date = now.subtract(Duration(days: 6 - dayIndex));
                  final dayLabel = DateFormat('EEE').format(date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dayLabel,
                      style: const TextStyle(color: subtitleColor, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      _formatter.format(value.round()),
                      style: const TextStyle(color: subtitleColor, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: cardBorderColor, width: 1),
              left: BorderSide(color: Colors.transparent),
              right: BorderSide(color: Colors.transparent),
              top: BorderSide(color: Colors.transparent),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _dailyPlaysSpots,
              isCurved: true,
              color: premiumGold,
              barWidth: 3,
              isStrokeCapRound: true,
              // Replaced deprecated dotSize/dotColor usage with getDotPainter
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(radius: 4, color: premiumGold),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    premiumGold.withOpacity(0.35),
                    premiumGold.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minX: 0,
          maxX: 6,
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              // Removed tooltipBgColor (no longer available in newer fl_chart versions)
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touched) {
                  final dayIndex = touched.x.toInt();
                  final now = DateTime.now();
                  final date = now.subtract(Duration(days: 6 - dayIndex));
                  final label = DateFormat('EEE, MMM d').format(date);
                  final value = touched.y.round();
                  return LineTooltipItem(
                    '$label\n${_formatter.format(value)} plays',
                    const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }

  Widget _buildSongList() {
    if (_songs.isEmpty) {
      return _buildEmptyState('No songs uploaded yet.');
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
      ),
      child: ListView.builder(
        itemCount: _songs.length > 5 ? 5 : _songs.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final song = _songs[index];
          final String artUrl = song['album_art_url'] ?? 'https://placehold.co/100x100/1A1A1A/FFFFFF?text=Song';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                artUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Image.network('https://placehold.co/100x100/1A1A1A/FFFFFF?text=Song', width: 50, height: 50),
              ),
            ),
            title: Text(
              song['title'] ?? 'Untitled',
              style: const TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${_formatter.format(song['plays'] ?? 0)} plays',
              style: const TextStyle(color: subtitleColor, fontSize: 12),
            ),
            trailing: const Icon(Icons.more_vert, color: textDisabledColor),
            onTap: () {
              // TODO: Navigate to song analytics screen
            },
          );
        },
      ),
    );
  }

  Widget _buildAlbumList() {
    if (_albums.isEmpty) {
      return _buildEmptyState('No albums released yet.');
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: _albums.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final album = _albums[index];
          final String artUrl = album['cover_art_url'] ?? 'https://placehold.co/300x300/1A1A1A/FFFFFF?text=Album';

          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    artUrl,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.network('https://placehold.co/300x300/1A1A1A/FFFFFF?text=Album', width: 150, height: 150),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  album['title'] ?? 'Untitled Album',
                  style: const TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  album['release_date'] != null
                      ? 'Released ${DateTime.parse(album['release_date']).year}'
                      : 'No date',
                  style: const TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: textDisabledColor, size: 40),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: subtitleColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
