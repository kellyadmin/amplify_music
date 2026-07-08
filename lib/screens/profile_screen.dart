import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants.dart';
import '../widgets/gradient_text.dart';
import 'auth_screen.dart';
import 'settings_screen.dart';
import 'playlists_screen.dart';
import 'artist_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  // Premium Color Scheme
  static const Color darkBg = Color(0xFF0A0A0B);
  static const Color gold = Color(0xFFF2B84B);
  static const Color premiumGold = Color(0xFFB8860B);
  static const Color cardBg = Color(0xFF171514);
  static const Color cardBorder = Color(0xFF2A2A2A);
  static const Color textDisabled = Colors.white54;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  User? user;
  String? avatarUrl;
  String? username;
  String role = 'user';
  bool isVerified = false;
  bool isPremium = false;

  // New: admin check fields
  bool _isAdminUser = false;
  String? _adminRole; // e.g. 'super_admin' or 'admin'
  List<String>? _adminPermissions;

  int followers = 0;
  int following = 0;
  int playlistCount = 0;

  bool _isUploadingImage = false;

  // NEW: latest application (to show rejection reason & allow reapply)
  Map<String, dynamic>? _latestApplication;

  @override
  void initState() {
    super.initState();
    // Ensure profile loads first, then playlist count and admin check.
    _initProfileAndAdmin();
  }

  Future<void> _initProfileAndAdmin() async {
    debugPrint('--- _initProfileAndAdmin() CALLED ---');
    await _loadUser(); // loads profile fields and latest application
    await _loadPlaylistCount(); // loads playlist count
    await _checkAdminStatus(); // run admin check after user/profile is available
  }

  // --- THIS FUNCTION HAS BEEN CORRECTED ---
  Future<void> _loadUser() async {
    user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint('[DEBUG] _loadUser: User is null, bailing.');
      return;
    }
    debugPrint('[DEBUG] _loadUser: Fetching data for user ${user!.id}');

    try {
      // --- 1. FETCH ALL DATA FIRST ---

      // Load profile
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user!.id)
          .maybeSingle();

      // Load the latest artist application
      final appResp = await supabase
          .from('artist_applications')
          .select()
          .eq('user_id', user!.id)
          .order('applied_at', ascending: false)
          .limit(1)
          .maybeSingle();

      debugPrint('--- _loadUser() FETCH COMPLETE ---');
      debugPrint('[DEBUG] Fetched profile response: $response');
      debugPrint('[DEBUG] Fetched latest app response: $appResp');

      // --- 2. NOW, UPDATE STATE ONCE ---
      if (mounted) {
        // Prepare new state values
        String newRole = 'user';
        String? newAvatarUrl;
        String? newUsername;
        bool newIsVerified = false;
        bool newIsPremium = false;
        int newFollowers = 0;
        int newFollowing = 0;
        Map<String, dynamic>? newLatestApp;

        if (response != null && response is Map) {
          newAvatarUrl = response['avatar_url'];
          newUsername = response['username'];
          newRole = (response['role'] ?? 'user').toString();
          newIsVerified = response['is_verified'] ?? false;
          newIsPremium = response['is_premium'] ?? false;
          newFollowers = response['followers'] ?? 0;
          newFollowing = response['following'] ?? 0;
        }

        if (appResp != null && appResp is Map) {
          newLatestApp = Map<String, dynamic>.from(appResp);
        } else {
          newLatestApp = null;
        }

        debugPrint('[DEBUG] Preparing setState: newRole = $newRole');
        debugPrint('[DEBUG] Preparing setState: newLatestApp status = ${newLatestApp?['status']}');

        // Call setState ONCE with all new data
        setState(() {
          avatarUrl = newAvatarUrl;
          username = newUsername;
          role = newRole;
          isVerified = newIsVerified;
          isPremium = newIsPremium;
          followers = newFollowers;
          following = newFollowing;
          _latestApplication = newLatestApp;
        });
        debugPrint('--- setState() CALLED ---');
      }
    } catch (e, st) {
      debugPrint('[profile] Error loading user profile or application: $e');
      debugPrint(st.toString());
    }
  }
  // --- END OF CORRECTED FUNCTION ---

  // New: check admin_users table to decide whether to show admin UI
  Future<void> _checkAdminStatus() async {
    final current = supabase.auth.currentUser;
    debugPrint('[admin check] client current user id: ${current?.id} email: ${current?.email}');
    if (current == null) {
      if (mounted) {
        setState(() {
          _isAdminUser = false;
          _adminRole = null;
          _adminPermissions = null;
        });
      }
      return;
    }

    try {
      // Query admin_users for this user_id. maybeSingle returns null if not found.
      final response = await supabase
          .from('admin_users')
          .select('id, user_id, role, permissions')
          .eq('user_id', current.id)
          .maybeSingle();

      debugPrint('[admin check] admin_users response: $response');

      if (response == null) {
        // fallback for debugging: if profile.role == super_admin, allow (remove in production)
        debugPrint('[admin check] response null; profile.role=$role');
        if (role.toLowerCase() == 'super_admin') {
          if (mounted) {
            setState(() {
              _isAdminUser = true;
              _adminRole = 'super_admin';
              _adminPermissions = ['manage_users', 'manage_artists', 'manage_content'];
            });
          }
          debugPrint('[admin check] fallback used: profile.role == super_admin');
          return;
        }

        if (mounted) {
          setState(() {
            _isAdminUser = false;
            _adminRole = null;
            _adminPermissions = null;
          });
        }
        return;
      }

      // Normalize response shape and permissions
      String? roleFromAdminTable;
      List<String>? perms;
      if (response is Map) {
        roleFromAdminTable = response['role']?.toString();
        final permsRaw = response['permissions'];
        if (permsRaw is List) {
          perms = permsRaw.map((p) => p?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        } else if (permsRaw is String) {
          perms = permsRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        }
      } else if (response is List && response.isNotEmpty && response.first is Map) {
        final m = response.first as Map;
        roleFromAdminTable = m['role']?.toString();
        final permsRaw = m['permissions'];
        if (permsRaw is List) {
          perms = permsRaw.map((p) => p?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        } else if (permsRaw is String) {
          perms = permsRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        }
      }

      if (mounted) {
        setState(() {
          _isAdminUser = true;
          _adminRole = roleFromAdminTable ?? _adminRole;
          _adminPermissions = perms ?? _adminPermissions;
        });
      }
    } catch (e) {
      debugPrint('[admin check] error: $e');
      if (mounted) {
        setState(() {
          _isAdminUser = false;
          _adminRole = null;
          _adminPermissions = null;
        });
      }
    }
  }

  Future<void> _loadPlaylistCount() async {
    if (user == null) return;

    try {
      final response = await supabase
          .from('playlists')
          .select('id')
          .eq('user_id', user!.id);

      if (mounted) {
        setState(() {
          playlistCount = response.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading playlist count: $e');
    }
  }

  /// Shows instructions *before* picking an image.
  Future<void> _showImageUploadInstructions() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProfileScreen.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Upload Profile Photo',
            style: TextStyle(
                color: ProfileScreen.textPrimary,
                fontWeight: FontWeight.w600)),
        content: const Text(
          'For the best look, use a high-quality square image (1:1 ratio), at least 500x500px.\n\nMax file size: 5MB.',
          style: TextStyle(color: ProfileScreen.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfileScreen.premiumGold,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.of(ctx).pop(); // Close the dialog
              _selectAndUploadImage(); // Proceed to upload
            },
            child: const Text('Choose from Gallery',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// The actual logic to pick and upload the image.
  Future<void> _selectAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final bytes = await pickedFile.readAsBytes();
      final fileName =
          '${user!.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.png';

      await supabase.storage.from('avatars').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      await supabase.from('profiles').update({
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user!.id);

      if (mounted) {
        setState(() {
          avatarUrl = publicUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile image updated successfully!'),
            backgroundColor: ProfileScreen.premiumGold.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: const Color(0xFFE63950),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Widget _buildRoleBadge() {
    Color bgColor;
    IconData iconData;
    String label;

    switch (role.toLowerCase()) {
      case 'super_admin':
        bgColor = Colors.deepOrange;
        iconData = Icons.security;
        label = 'Super Admin';
        break;
      case 'admin':
        bgColor = const Color(0xFFE63950);
        iconData = Icons.admin_panel_settings;
        label = 'Admin';
        break;
      case 'artist':
        bgColor = Colors.purple;
        iconData = Icons.music_note;
        label = 'Artist';
        break;
      case 'artist_pending':
        bgColor = Colors.orange;
        iconData = Icons.pending;
        label = 'Pending Artist';
        break;
      case 'user':
        bgColor = Colors.blue;
        iconData = Icons.person;
        label = 'User';
        break;
      default:
        bgColor = Colors.grey;
        iconData = Icons.person_outline;
        label = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPremiumBadge() {
    if (!isPremium) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ProfileScreen.premiumGold, ProfileScreen.gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ProfileScreen.premiumGold.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.black, size: 16),
          const SizedBox(width: 6),
          Text(
            'Premium',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDashboardButton() {
    // Only show this button for users that exist in admin_users table
    if (!_isAdminUser) return const SizedBox.shrink();

    // Show different label for super_admin vs other admins if desired
    final String title = (_adminRole != null && _adminRole!.toLowerCase() == 'super_admin')
        ? 'Super Admin Dashboard'
        : 'Admin Dashboard';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.2),
                Colors.red.withOpacity(0.1),
                ProfileScreen.cardBg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFE63950), const Color(0xFFE63950)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ProfileScreen.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Approve songs, artists, and manage platform content',
                      style: const TextStyle(
                          color: ProfileScreen.textSecondary, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.red.shade200, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Amplify for Artists button - updated to support showing rejection reason and reapply
  Widget _buildAmplifyForArtistsButton(BuildContext context) {
    debugPrint('--- _buildAmplifyForArtistsButton() CALLED ---');
    debugPrint('[DEBUG] Current state role: $role');
    debugPrint('[DEBUG] Current state _latestApplication: $_latestApplication');

    final bool isArtist = role.toLowerCase() == 'artist';
    final bool isArtistPending = role.toLowerCase() == 'artist_pending';
    final bool isLoggedIn = supabase.auth.currentUser != null;

    debugPrint('[DEBUG] UI Logic: isArtist = $isArtist');
    debugPrint('[DEBUG] UI Logic: isArtistPending = $isArtistPending');

    // Check for rejection
    final bool isRejected = _latestApplication != null && (_latestApplication!['status']?.toString().toLowerCase() == 'rejected');
    debugPrint('[DEBUG] UI Logic: isRejected = $isRejected');


    // If latest application was rejected show reason + reapply
    if (isRejected) {
      debugPrint('[DEBUG] UI Decision: Showing REJECTED');
      final reason = (_latestApplication!['review_message'] ?? '').toString();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withOpacity(0.08),
                Colors.orange.withOpacity(0.05),
                ProfileScreen.cardBg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.3), shape: BoxShape.circle), child: const Icon(Icons.report_gmailerrorred, color: Colors.orange, size: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Application Rejected', style: TextStyle(color: ProfileScreen.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Reason: ${reason.isNotEmpty ? reason : "No reason provided."}', style: TextStyle(color: ProfileScreen.textSecondary)),
                ])),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () {
                    // Re-open application dialog to reapply
                    _showBecomeArtistDialog();
                  },
                  child: const Text('Reapply'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () async {
                    // Allow user to remove the rejected application and reset role to 'user'
                    if (_latestApplication == null) return;
                    try {
                      await supabase.from('artist_applications').delete().eq('id', _latestApplication!['id']);
                      await supabase.from('profiles').update({'role': 'user', 'updated_at': DateTime.now().toIso8601String()}).eq('id', user!.id);
                      await _loadUser();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application removed. You can reapply now.'), backgroundColor: Colors.green));
                    } catch (e) {
                      debugPrint('[profile] error removing application: $e');
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error removing application: $e'), backgroundColor: const Color(0xFFE63950)));
                    }
                  },
                  child: const Text('Remove Application', style: TextStyle(color: Colors.white70)),
                ),
              ]),
            ],
          ),
        ),
      );
    }

    if (isArtistPending) {
      debugPrint('[DEBUG] UI Decision: Showing PENDING');
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withOpacity(0.2),
                Colors.orange.withOpacity(0.1),
                ProfileScreen.cardBg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1),
          ),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.3), shape: BoxShape.circle), child: const Icon(Icons.pending, color: Colors.orange, size: 28)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Application Under Review', style: TextStyle(color: ProfileScreen.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Your artist application is being reviewed. We\'ll notify you soon!', style: TextStyle(color: ProfileScreen.textSecondary)),
              ])),
            ],
          ),
        ),
      );
    }

    if (isArtist) {
      debugPrint('[DEBUG] UI Decision: Showing ARTIST DASHBOARD');
      // Show Artist Dashboard button for existing artists
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 24),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtistDashboardScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.2),
                  Colors.deepPurple.withOpacity(0.3),
                  ProfileScreen.cardBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.purple.withOpacity(0.5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_external_on,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Artist Dashboard',
                        style: const TextStyle(
                          color: ProfileScreen.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage your releases, analytics, and followers',
                        style: const TextStyle(
                            color: ProfileScreen.textSecondary, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.purple.shade200, size: 18),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      debugPrint('[DEBUG] UI Decision: Showing SIGNUP');
      // Show Amplify for Artists signup for non-artists
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 24),
        child: InkWell(
          onTap: () {
            _showArtistSignupOptions();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ProfileScreen.cardBg,
                  ProfileScreen.cardBg,
                  Colors.purple.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: ProfileScreen.premiumGold.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_external_on,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amplify for Artists',
                        style: const TextStyle(
                          color: ProfileScreen.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isLoggedIn
                            ? 'Get verified, upload music, and track your success'
                            : 'Sign up as an artist to share your music with the world',
                        style: const TextStyle(
                            color: ProfileScreen.textSecondary, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ProfileScreen.premiumGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      color: ProfileScreen.premiumGold, size: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _showArtistSignupOptions() {
    final isLoggedIn = supabase.auth.currentUser != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProfileScreen.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.music_note, color: Colors.purple.shade300),
            const SizedBox(width: 12),
            const Text('Become an Artist',
                style: TextStyle(
                    color: ProfileScreen.textPrimary,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLoggedIn
                  ? 'Upgrade your account to access artist features:'
                  : 'Join as an artist to share your music:',
              style: const TextStyle(color: ProfileScreen.textSecondary),
            ),
            const SizedBox(height: 16),
            _featureItem('Upload your music and albums'),
            _featureItem('Get detailed analytics and insights'),
            _featureItem('Build your artist profile and brand'),
            _featureItem('Connect with your listeners'),
            const SizedBox(height: 8),
            Text(
              isLoggedIn
                  ? 'Your existing account will be upgraded to artist status.'
                  : 'Create a new artist account to get started.',
              style: const TextStyle(
                color: ProfileScreen.textDisabled,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (isLoggedIn) {
                _showBecomeArtistDialog();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
            },
            child: Text(
              isLoggedIn ? 'Upgrade Now' : 'Sign Up as Artist',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.purple.shade300, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: ProfileScreen.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reused Artist Application dialog: on successful submission we refresh user & latest app
  void _showBecomeArtistDialog() {
    final _stageNameController = TextEditingController();
    final _bioController = TextEditingController();
    final _websiteController = TextEditingController();
    final _socialMediaController = TextEditingController();

    String _selectedGenre = 'Pop';
    final List<String> _genres = [
      'Pop', 'Rock', 'Hip Hop', 'R&B', 'Electronic', 'Jazz',
      'Classical', 'Country', 'Reggae', 'Metal', 'Folk', 'Other'
    ];

    bool _hasOriginalMusic = false;
    bool _agreeToTerms = false;
    bool _isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: ProfileScreen.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.music_note, color: Colors.purple),
                SizedBox(width: 12),
                Text('Artist Application',
                    style: TextStyle(
                        color: ProfileScreen.textPrimary,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tell us about your music career',
                    style: TextStyle(color: ProfileScreen.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _stageNameController,
                    style: const TextStyle(color: ProfileScreen.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Stage Name *',
                      labelStyle: const TextStyle(color: ProfileScreen.textSecondary),
                      hintText: 'Your artist name',
                      hintStyle: const TextStyle(color: ProfileScreen.textDisabled),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ProfileScreen.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.purple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedGenre,
                    dropdownColor: ProfileScreen.cardBg,
                    style: const TextStyle(color: ProfileScreen.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Primary Genre *',
                      labelStyle: const TextStyle(color: ProfileScreen.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ProfileScreen.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.purple),
                      ),
                    ),
                    items: _genres.map((String genre) {
                      return DropdownMenuItem<String>(
                        value: genre,
                        child: Text(genre, style: const TextStyle(color: ProfileScreen.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGenre = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    style: const TextStyle(color: ProfileScreen.textPrimary),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Artist Bio',
                      labelStyle: const TextStyle(color: ProfileScreen.textSecondary),
                      hintText: 'Tell us about your music and career...',
                      hintStyle: const TextStyle(color: ProfileScreen.textDisabled),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ProfileScreen.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.purple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _websiteController,
                    style: const TextStyle(color: ProfileScreen.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Website (Optional)',
                      labelStyle: const TextStyle(color: ProfileScreen.textSecondary),
                      hintText: 'https://yourwebsite.com',
                      hintStyle: const TextStyle(color: ProfileScreen.textDisabled),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ProfileScreen.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.purple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _socialMediaController,
                    style: const TextStyle(color: ProfileScreen.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Social Media (Optional)',
                      labelStyle: const TextStyle(color: ProfileScreen.textSecondary),
                      hintText: '@yourusername',
                      hintStyle: const TextStyle(color: ProfileScreen.textDisabled),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ProfileScreen.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.purple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: ProfileScreen.cardBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ProfileScreen.cardBorder),
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        'I have original music to upload',
                        style: TextStyle(color: ProfileScreen.textPrimary),
                      ),
                      subtitle: const Text(
                        'You must own the rights to the music you upload',
                        style: TextStyle(color: ProfileScreen.textDisabled, fontSize: 12),
                      ),
                      value: _hasOriginalMusic,
                      onChanged: (value) {
                        setState(() {
                          _hasOriginalMusic = value!;
                        });
                      },
                      activeColor: Colors.purple,
                      checkColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: ProfileScreen.cardBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ProfileScreen.cardBorder),
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        'I agree to the Artist Terms and Conditions',
                        style: TextStyle(color: ProfileScreen.textPrimary),
                      ),
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value!;
                        });
                      },
                      activeColor: Colors.purple,
                      checkColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '* Required fields',
                    style: TextStyle(
                      color: ProfileScreen.textDisabled,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSubmitting ? null : () async {
                  if (_stageNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Please enter your stage name'),
                        backgroundColor: const Color(0xFFE63950),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  if (!_agreeToTerms) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Please agree to the terms and conditions'),
                        backgroundColor: const Color(0xFFE63950),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _isSubmitting = true;
                  });

                  try {
                    // Submit artist application
                    await supabase.from('artist_applications').insert({
                      'user_id': user!.id,
                      'stage_name': _stageNameController.text.trim(),
                      'genre': _selectedGenre,
                      'bio': _bioController.text.trim(),
                      'website': _websiteController.text.trim(),
                      'social_media': _socialMediaController.text.trim(),
                      'has_original_music': _hasOriginalMusic,
                      'status': 'pending',
                      'applied_at': DateTime.now().toIso8601String(),
                    });

                    // Update user role to artist_pending
                    await supabase.from('profiles').update({
                      'role': 'artist_pending',
                      'updated_at': DateTime.now().toIso8601String(),
                    }).eq('id', user!.id);

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Artist application submitted successfully! We\'ll review it within 48 hours.'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                      await _loadUser(); // Refresh user data and latest application
                    }
                  } catch (e) {
                    debugPrint('Error submitting artist application: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error submitting application: $e'),
                          backgroundColor: const Color(0xFFE63950),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isSubmitting = false;
                      });
                    }
                  }
                },
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Submit Application', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showVerificationOptions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProfileScreen.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: Colors.blue),
            SizedBox(width: 12),
            Text('Get Verified',
                style: TextStyle(
                    color: ProfileScreen.textPrimary,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get the official verification badge to establish your authentic presence on Amplify.',
              style: TextStyle(color: ProfileScreen.textSecondary),
            ),
            const SizedBox(height: 20),

            // Verification Benefits
            _verificationBenefit('Blue verification badge on your profile'),
            _verificationBenefit('Increased credibility and trust'),
            _verificationBenefit('Priority in search results'),
            _verificationBenefit('Enhanced visibility to listeners'),
            _verificationBenefit('Dedicated support team'),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '\$4.99',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/month',
                        style: TextStyle(
                          color: ProfileScreen.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Cancel anytime • 30-day money back guarantee',
                    style: TextStyle(
                      color: ProfileScreen.textDisabled,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showVerificationPayment();
            },
            child: const Text('Get Verified', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _verificationBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.blue.shade300, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: ProfileScreen.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerificationPayment() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProfileScreen.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.credit_card, color: Colors.blue),
            SizedBox(width: 12),
            Text('Complete Verification',
                style: TextStyle(
                    color: ProfileScreen.textPrimary,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete your verification payment to get the blue badge.',
              style: TextStyle(color: ProfileScreen.textSecondary),
            ),
            SizedBox(height: 16),
            Text(
              'Payment Method:',
              style: TextStyle(
                color: ProfileScreen.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Stripe Payment Integration\n(Simulated for demo)',
              style: TextStyle(
                color: ProfileScreen.textDisabled,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // Simulate payment processing
              await Future.delayed(const Duration(seconds: 2));

              if (mounted) {
                Navigator.pop(ctx);
                // Update user verification status
                try {
                  await supabase.from('profiles').update({
                    'is_verified': true,
                    'verified_at': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                  }).eq('id', user!.id);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('🎉 Congratulations! You are now verified on Amplify.'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                  _loadUser(); // Refresh user data
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating verification status: $e'),
                      backgroundColor: const Color(0xFFE63950),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Pay \$4.99', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final _usernameController = TextEditingController(text: username);
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();

    bool _showPasswordSection = false;
    bool _isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: ProfileScreen.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Edit Profile',
                style: TextStyle(
                  color: ProfileScreen.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: ProfileScreen.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: const TextStyle(color: ProfileScreen.textSecondary),
                        hintText: 'Enter your username',
                        hintStyle: const TextStyle(color: ProfileScreen.textDisabled),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ProfileScreen.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: ProfileScreen.gold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Change Section
                    Container(
                      decoration: BoxDecoration(
                        color: ProfileScreen.cardBg.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ProfileScreen.cardBorder),
                      ),
                      child: Column(
                        children: [
                          // Toggle button for password section
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            leading: Icon(
                              Icons.lock,
                              color: ProfileScreen.gold,
                            ),
                            title: const Text(
                              'Change Password',
                              style: TextStyle(
                                color: ProfileScreen.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Switch(
                              value: _showPasswordSection,
                              onChanged: _isSaving ? null : (value) {
                                setState(() {
                                  _showPasswordSection = value;
                                  if (!value) {
                                    _currentPasswordController.clear();
                                    _newPasswordController.clear();
                                    _confirmPasswordController.clear();
                                  }
                                });
                              },
                              activeColor: ProfileScreen.gold,
                            ),
                            onTap: _isSaving ? null : () {
                              setState(() {
                                _showPasswordSection = !_showPasswordSection;
                              });
                            },
                          ),

                          if (_showPasswordSection) ...[
                            const Divider(color: ProfileScreen.cardBorder, height: 1),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // Current Password
                                  TextFormField(
                                    controller: _currentPasswordController,
                                    obscureText: true,
                                    style: const TextStyle(color: ProfileScreen.textPrimary),
                                    decoration: InputDecoration(
                                      labelText: 'Current Password',
                                      labelStyle: const TextStyle(color: ProfileScreen.textSecondary),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: ProfileScreen.cardBorder),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: ProfileScreen.gold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // New Password
                                  TextFormField(
                                    controller: _newPasswordController,
                                    obscureText: true,
                                    style: const TextStyle(color: ProfileScreen.textPrimary),
                                    decoration: InputDecoration(
                                      labelText: 'New Password',
                                      labelStyle: const TextStyle(color: ProfileScreen.textSecondary),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: ProfileScreen.cardBorder),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: ProfileScreen.gold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Confirm New Password
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: true,
                                    style: const TextStyle(color: ProfileScreen.textPrimary),
                                    decoration: InputDecoration(
                                      labelText: 'Confirm New Password',
                                      labelStyle: const TextStyle(color: ProfileScreen.textSecondary),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: ProfileScreen.cardBorder),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: ProfileScreen.gold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Leave password fields empty if you don\'t want to change your password.',
                                    style: TextStyle(
                                      color: ProfileScreen.textDisabled,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProfileScreen.premiumGold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _isSaving ? null : () async {
                    setState(() {
                      _isSaving = true;
                    });

                    try {
                      final user = supabase.auth.currentUser;
                      if (user == null) throw Exception('User not logged in');

                      // Update username
                      await supabase.from('profiles').update({
                        'username': _usernameController.text.trim(),
                        'updated_at': DateTime.now().toIso8601String(),
                      }).eq('id', user.id);

                      // Change password if all password fields are filled
                      if (_currentPasswordController.text.isNotEmpty &&
                          _newPasswordController.text.isNotEmpty &&
                          _confirmPasswordController.text.isNotEmpty) {

                        if (_newPasswordController.text != _confirmPasswordController.text) {
                          throw Exception('New passwords do not match');
                        }

                        // Update password
                        await supabase.auth.updateUser(
                          UserAttributes(
                            password: _newPasswordController.text,
                          ),
                        );
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Profile updated successfully!'),
                            backgroundColor: ProfileScreen.premiumGold.withOpacity(0.9),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                        Navigator.pop(context);
                        _loadUser(); // Refresh profile data
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating profile: $e'),
                            backgroundColor: const Color(0xFFE63950),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isSaving = false;
                        });
                      }
                    }
                  },
                  child: _isSaving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = supabase.auth.currentUser != null;

    return Scaffold(
      backgroundColor: ProfileScreen.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(
                color: ProfileScreen.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 24)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          const Positioned(top: -90, right: -70, child: GlowOrb(size: 300, color: primaryColor, opacity: 0.16)),
          const Positioned(bottom: -120, left: -90, child: GlowOrb(size: 320, color: accentColor, opacity: 0.12)),
          isLoggedIn ? _buildProfileBody() : _buildGuestUI(context),
        ],
      ),
    );
  }

  Widget _buildGuestUI(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enhanced guest avatar
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade800,
                    Colors.grey.shade600,
                    Colors.grey.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.account_circle,
                  size: 120, color: Colors.white30),
            ),
            const SizedBox(height: 32),
            const Text(
              'Join the Amplify Community',
              style: TextStyle(
                  color: ProfileScreen.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sign in to access personalized recommendations,\ncreate playlists, and discover new music',
              style: TextStyle(color: ProfileScreen.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Column(
              children: [
                Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF7CE68), Color(0xFFC8901F)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: ProfileScreen.gold.withOpacity(0.5),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()));
                    },
                    child: const Text(
                      'Sign In / Sign Up',
                      style:
                      TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ProfileScreen.gold,
                    side: BorderSide(color: ProfileScreen.gold),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()));
                  },
                  child: const Text(
                    'Sign Up as Artist',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBody() {
    final bool isArtist = role.toLowerCase() == 'artist';
    final bool isArtistPending = role.toLowerCase() == 'artist_pending';

    return RefreshIndicator(
      onRefresh: () async {
        await _loadUser();
        await _loadPlaylistCount();
        await _checkAdminStatus();
      },
      color: primaryColor,
      backgroundColor: ProfileScreen.darkBg,
      displacement: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // 1. Enhanced Profile Header
          _buildProfileHeader(),
          const SizedBox(height: 8),

          // 2. Stats Row
          _buildStatsSection(isArtist),
          const SizedBox(height: 8),

          // 3. Admin Dashboard Button (only for users in admin_users table)
          _buildAdminDashboardButton(),

          // 4. Amplify for Artists Button
          _buildAmplifyForArtistsButton(context),

          // 5. Get Verified Button (for non-verified users)
          if (!isVerified && !isArtistPending) _buildGetVerifiedButton(),

          // 6. Playlist Section
          _buildPlaylistSection(),

          // 7. Account & Settings
          _buildAccountSection(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGetVerifiedButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _showVerificationOptions,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.blue.withOpacity(0.05),
                ProfileScreen.cardBg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified,
                    color: Colors.blue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get Verified',
                      style: const TextStyle(
                        color: ProfileScreen.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Get the blue verification badge and stand out',
                      style: const TextStyle(
                          color: ProfileScreen.textSecondary, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.blue.shade300, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ProfileScreen.cardBg,
            ProfileScreen.cardBg,
            Colors.black.withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ProfileScreen.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with enhanced styling
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: ProfileScreen.premiumGold, width: 3),
                  gradient: isPremium
                      ? LinearGradient(
                    colors: [ProfileScreen.premiumGold, ProfileScreen.gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : LinearGradient(
                    colors: [Colors.grey.shade700, Colors.grey.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 58,
                  backgroundColor: ProfileScreen.cardBg,
                  backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person,
                      color: ProfileScreen.textDisabled, size: 60)
                      : null,
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _showImageUploadInstructions,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ProfileScreen.premiumGold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ProfileScreen.premiumGold.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isUploadingImage
                        ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 3),
                    )
                        : const Icon(Icons.camera_alt,
                        color: Colors.black, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Username and badges
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      username ?? 'No Username',
                      style: const TextStyle(
                          color: ProfileScreen.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isVerified)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.verified,
                          color: Colors.blueAccent, size: 28),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(user?.email ?? '',
                  style: const TextStyle(
                      color: ProfileScreen.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildRoleBadge(),
                  _buildPremiumBadge(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isArtist) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ProfileScreen.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileScreen.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: isArtist
            ? [
          _statItem('Followers', followers, Icons.people),
          _statItem('Following', following, Icons.person_add),
          _statItem('Playlists', playlistCount, Icons.queue_music),
        ]
            : [
          _statItem('Following', following, Icons.person_add),
          _statItem('Playlists', playlistCount, Icons.queue_music),
          _statItem('Likes', 0, Icons.favorite),
        ],
      ),
    );
  }

  Widget _statItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: ProfileScreen.cardBg.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(color: ProfileScreen.cardBorder, width: 1),
          ),
          child: Icon(icon, color: ProfileScreen.premiumGold, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
              color: ProfileScreen.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
              color: ProfileScreen.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPlaylistSection() {
    return _buildMenuCard(
      title: "My Playlists",
      icon: Icons.library_music,
      children: [
        _menuItem(
            Icons.queue_music,
            'Browse My Playlists',
                () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlaylistsScreen()))),
        _menuItem(
          Icons.add_circle_outline,
          'Create New Playlist',
          _createNewPlaylist,
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: ProfileScreen.textSecondary, size: 24),
      title: Text(title,
          style: const TextStyle(color: ProfileScreen.textPrimary)),
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          color: ProfileScreen.textDisabled, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  void _createNewPlaylist() {
    final _playlistNameController = TextEditingController();
    final _playlistDescriptionController = TextEditingController();
    bool _isPublic = false;
    bool _isCreating = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: ProfileScreen.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Create Playlist',
                  style: TextStyle(
                      color: ProfileScreen.textPrimary,
                      fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _playlistNameController,
                      style: const TextStyle(color: ProfileScreen.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Playlist Name',
                        labelStyle: const TextStyle(color: ProfileScreen.textSecondary),
                        hintText: 'Enter playlist name',
                        hintStyle: const TextStyle(color: ProfileScreen.textDisabled),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ProfileScreen.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ProfileScreen.premiumGold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _playlistDescriptionController,
                      style: const TextStyle(color: ProfileScreen.textPrimary),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        labelStyle: const TextStyle(color: ProfileScreen.textSecondary),
                        hintText: 'Describe your playlist...',
                        hintStyle: const TextStyle(color: ProfileScreen.textDisabled),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ProfileScreen.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ProfileScreen.premiumGold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: ProfileScreen.cardBg.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ProfileScreen.cardBorder),
                      ),
                      child: ListTile(
                        leading: Icon(
                          _isPublic ? Icons.public : Icons.lock,
                          color: ProfileScreen.premiumGold,
                        ),
                        title: const Text(
                          'Public Playlist',
                          style: TextStyle(color: ProfileScreen.textPrimary),
                        ),
                        subtitle: const Text(
                          'Anyone can discover and listen to this playlist',
                          style: TextStyle(color: ProfileScreen.textSecondary, fontSize: 12),
                        ),
                        trailing: Switch(
                          value: _isPublic,
                          onChanged: (value) {
                            setState(() {
                              _isPublic = value;
                            });
                          },
                          activeColor: ProfileScreen.premiumGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isCreating ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProfileScreen.premiumGold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _isCreating ? null : () async {
                    final name = _playlistNameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please enter a playlist name'),
                          backgroundColor: const Color(0xFFE63950),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _isCreating = true;
                    });

                    try {
                      final user = supabase.auth.currentUser;
                      if (user == null) throw Exception('User not logged in');

                      // Insert playlist into database
                      await supabase
                          .from('playlists')
                          .insert({
                        'name': name,
                        'description': _playlistDescriptionController.text.trim(),
                        'is_public': _isPublic,
                        'user_id': user.id,
                        'created_at': DateTime.now().toIso8601String(),
                        'updated_at': DateTime.now().toIso8601String(),
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Playlist "$name" created successfully!'),
                            backgroundColor: ProfileScreen.premiumGold.withOpacity(0.9),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );

                        // Refresh playlist count
                        _loadPlaylistCount();
                      }
                    } catch (e) {
                      debugPrint('Error creating playlist: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error creating playlist: $e'),
                            backgroundColor: const Color(0xFFE63950),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isCreating = false;
                        });
                      }
                    }
                  },
                  child: _isCreating
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAccountSection() {
    return _buildMenuCard(
      title: "Account & Settings",
      icon: Icons.settings,
      children: [
        _menuItem(Icons.person_outline, 'Edit Profile & Password', _showEditProfileDialog),
        _menuItem(
            Icons.settings,
            'Settings & Privacy',
                () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        const Divider(
            color: Colors.white12, height: 16, indent: 16, endIndent: 16),
        _buildLogoutTile(),
      ],
    );
  }

  // ADDED: The missing _buildMenuCard method
  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ProfileScreen.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileScreen.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: ProfileScreen.premiumGold, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: ProfileScreen.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: ProfileScreen.cardBorder, height: 1, thickness: 1),
          // Use Column for the children
          Column(
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutTile() {
    return ListTile(
      leading: const Icon(Icons.logout, color: const Color(0xFFE63950), size: 24),
      title: const Text('Logout',
          style: TextStyle(color: const Color(0xFFE63950), fontWeight: FontWeight.w500)),
      onTap: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: ProfileScreen.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Logout',
                style: TextStyle(
                    color: ProfileScreen.textPrimary,
                    fontWeight: FontWeight.bold)),
            content: const Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: ProfileScreen.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE63950),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (shouldLogout == true) {
          await supabase.auth.signOut();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            );
          }
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
