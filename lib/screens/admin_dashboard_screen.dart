import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _pendingArtistApps = [];
  List<Map<String, dynamic>> _reviewedArtistApps = [];

  bool _isLoading = true;
  bool _isAdmin = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    debugPrint('[admin dashboard] initState');
    _tabController = TabController(length: 2, vsync: this);
    _checkAdminStatusAndLoad();
  }

  Future<void> _checkAdminStatusAndLoad() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _isAdmin = false;
      });
      return;
    }

    try {
      final response = await supabase
          .from('admin_users')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      debugPrint('[admin dashboard] admin_users check response: $response');

      setState(() {
        _isAdmin = response != null;
      });

      if (_isAdmin) {
        await Future.wait([_loadPendingArtistApplications(), _loadReviewedArtistApplications()]);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrint('[admin dashboard] error checking admin: $e');
      debugPrint(st.toString());
      setState(() {
        _isLoading = false;
        _isAdmin = false;
      });
    }
  }

  Future<void> _loadPendingArtistApplications() async {
    debugPrint('[admin dashboard] loadPendingArtistApplications START');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from('artist_applications')
          .select('*, profiles:user_id (username, avatar_url)')
          .eq('status', 'pending')
          .order('applied_at', ascending: true);

      debugPrint('[admin dashboard] raw pending apps response: $response');

      List<Map<String, dynamic>> apps = [];
      if (response is List) apps = List<Map<String, dynamic>>.from(response);
      else if (response is Map) apps = [Map<String, dynamic>.from(response)];

      setState(() {
        _pendingArtistApps = apps;
        _isLoading = false;
      });
      debugPrint('[admin dashboard] pending count=${apps.length}');
    } catch (e, st) {
      debugPrint('[admin dashboard] error loading pending: $e');
      debugPrint(st.toString());
      setState(() {
        _pendingArtistApps = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReviewedArtistApplications() async {
    debugPrint('[admin dashboard] loadReviewedArtistApplications START');
    try {
      final response = await supabase
          .from('artist_applications')
          .select('*, profiles:user_id (username, avatar_url)')
          .in_('status', ['approved', 'rejected'])
          .order('reviewed_at', ascending: false);

      debugPrint('[admin dashboard] raw reviewed response: $response');

      List<Map<String, dynamic>> apps = [];
      if (response is List) apps = List<Map<String, dynamic>>.from(response);
      else if (response is Map) apps = [Map<String, dynamic>.from(response)];

      setState(() {
        _reviewedArtistApps = apps;
      });

      debugPrint('[admin dashboard] reviewed count=${apps.length}');
    } catch (e, st) {
      debugPrint('[admin dashboard] error loading reviewed: $e');
      debugPrint(st.toString());
      setState(() {
        _reviewedArtistApps = [];
      });
    }
  }

  // APPROVE: set application -> approved, set profile.role='artist', notify user
  Future<void> _approveApplication(String applicationId, String userId, {String? message}) async {
    debugPrint('[admin dashboard] approve called id=$applicationId user=$userId messagePresent=${(message ?? '').isNotEmpty}');
    try {
      final adminId = supabase.auth.currentUser?.id;
      final updateData = {
        'status': 'approved',
        'reviewed_at': DateTime.now().toIso8601String(),
        if (message != null && message.isNotEmpty) 'review_message': message,
        if (adminId != null) 'reviewed_by': adminId,
      };

      final appResp = await supabase
          .from('artist_applications')
          .update(updateData)
          .eq('id', applicationId)
          .select()
          .maybeSingle();
      debugPrint('[admin dashboard] artist_applications.update resp: $appResp');

      // update profile role -> artist
      final profileResp = await supabase
          .from('profiles')
          .update({'role': 'artist', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId)
          .select()
          .maybeSingle();
      debugPrint('[admin dashboard] profiles.update resp: $profileResp');

      // insert notification (optional table) - log failures
      try {
        final notifResp = await supabase
            .from('notifications')
            .insert({
          'user_id': userId,
          'title': 'Artist application approved',
          'body': message ?? 'Congratulations — your application has been approved!',
          'read': false,
          'created_at': DateTime.now().toIso8601String(),
        })
            .select()
            .maybeSingle();
        debugPrint('[admin dashboard] notifications.insert resp: $notifResp');
      } catch (nerr, nst) {
        debugPrint('[admin dashboard] notifications.insert ERROR: $nerr');
        debugPrint(nst.toString());
      }

      // Move locally from pending -> reviewed
      setState(() {
        final idx = _pendingArtistApps.indexWhere((a) => a['id'] == applicationId);
        Map<String, dynamic>? moved;
        if (idx != -1) {
          moved = Map<String, dynamic>.from(_pendingArtistApps[idx]);
          _pendingArtistApps.removeAt(idx);
        }
        if (appResp != null && appResp is Map) {
          _reviewedArtistApps.insert(0, Map<String, dynamic>.from(appResp));
        } else if (moved != null) {
          moved['status'] = 'approved';
          moved['review_message'] = message;
          moved['reviewed_at'] = DateTime.now().toIso8601String();
          moved['reviewed_by'] = adminId;
          _reviewedArtistApps.insert(0, moved);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Application approved'), backgroundColor: Colors.green));
      }
    } catch (e, st) {
      debugPrint('[admin dashboard] error approving: $e');
      debugPrint(st.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error approving: $e'), backgroundColor: const Color(0xFFE63950)));
    }
  }

  // REJECT: set application -> rejected, set profile.role='user' so they may reapply, notify user
  Future<void> _rejectApplication(String applicationId, String userId, {required String reason}) async {
    debugPrint('[admin dashboard] reject called id=$applicationId user=$userId reasonPresent=${reason.isNotEmpty}');
    try {
      final adminId = supabase.auth.currentUser?.id;
      final updateData = {
        'status': 'rejected',
        'reviewed_at': DateTime.now().toIso8601String(),
        if (reason.isNotEmpty) 'review_message': reason,
        if (adminId != null) 'reviewed_by': adminId,
      };

      final appResp = await supabase
          .from('artist_applications')
          .update(updateData)
          .eq('id', applicationId)
          .select()
          .maybeSingle();
      debugPrint('[admin dashboard] artist_applications.update resp: $appResp');

      // revert profile role so user can reapply
      final profileResp = await supabase
          .from('profiles')
          .update({'role': 'user', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId)
          .select()
          .maybeSingle();
      debugPrint('[admin dashboard] profiles.update resp: $profileResp');

      // insert notification
      try {
        final notifResp = await supabase
            .from('notifications')
            .insert({
          'user_id': userId,
          'title': 'Artist application update',
          'body': reason.isNotEmpty ? reason : 'Your application was rejected. You may reapply.',
          'read': false,
          'created_at': DateTime.now().toIso8601String(),
        })
            .select()
            .maybeSingle();
        debugPrint('[admin dashboard] notifications.insert resp: $notifResp');
      } catch (nerr, nst) {
        debugPrint('[admin dashboard] notifications.insert ERROR: $nerr');
        debugPrint(nst.toString());
      }

      // Move locally from pending -> reviewed
      setState(() {
        final idx = _pendingArtistApps.indexWhere((a) => a['id'] == applicationId);
        Map<String, dynamic>? moved;
        if (idx != -1) {
          moved = Map<String, dynamic>.from(_pendingArtistApps[idx]);
          _pendingArtistApps.removeAt(idx);
        }
        if (appResp != null && appResp is Map) {
          _reviewedArtistApps.insert(0, Map<String, dynamic>.from(appResp));
        } else if (moved != null) {
          moved['status'] = 'rejected';
          moved['review_message'] = reason;
          moved['reviewed_at'] = DateTime.now().toIso8601String();
          moved['reviewed_by'] = adminId;
          _reviewedArtistApps.insert(0, moved);
        }
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application rejected'), backgroundColor: Colors.orange));
    } catch (e, st) {
      debugPrint('[admin dashboard] error rejecting: $e');
      debugPrint(st.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error rejecting: $e'), backgroundColor: const Color(0xFFE63950)));
    }
  }

  // Dialogs
  Future<void> _showApproveDialog(String applicationId, String userId) async {
    String message = '';
    bool submitting = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171514),
          title: const Text('Approve Application', style: TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Optionally include a welcome message to send to the artist.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(onChanged: (v) => setState(() => message = v), maxLines: 4, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Welcome message (optional)', hintStyle: TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF0E0E0E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
          ]),
          actions: [
            TextButton(onPressed: submitting ? null : () => Navigator.of(ctx).pop(), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
            ElevatedButton(onPressed: submitting ? null : () async { setState(() => submitting = true); Navigator.of(ctx).pop(); await _approveApplication(applicationId, userId, message: message.trim()); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Approve')),
          ],
        );
      }),
    );
  }

  Future<void> _showRejectDialog(String applicationId, String userId) async {
    String reason = '';
    bool submitting = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171514),
          title: const Text('Reject Application', style: TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Provide a reason for rejection (optional). This will be sent to the applicant.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(onChanged: (v) => setState(() => reason = v), maxLines: 4, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Reason', hintStyle: TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF0E0E0E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
          ]),
          actions: [
            TextButton(onPressed: submitting ? null : () => Navigator.of(ctx).pop(), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE63950)), onPressed: submitting ? null : () async { setState(() => submitting = true); Navigator.of(ctx).pop(); await _rejectApplication(applicationId, userId, reason: reason.trim()); }, child: submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Reject')),
          ],
        );
      }),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> app) {
    final profile = app['profiles'] as Map<String, dynamic>? ?? {};
    final appliedAt = app['applied_at']?.toString() ?? '';
    final email = (profile['email'] as String?) ?? (app['email'] as String?) ?? 'No email';

    return Card(
      color: const Color(0xFF171514),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: Colors.grey[800], backgroundImage: profile['avatar_url'] != null ? NetworkImage(profile['avatar_url']) : null, child: profile['avatar_url'] == null ? const Icon(Icons.person, color: Colors.white54) : null),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(profile['username'] ?? 'No username', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(email, style: const TextStyle(color: Colors.white70))])),
          ]),
          const SizedBox(height: 12),
          _detailRow('🎤 Stage Name:', app['stage_name'] ?? ''),
          _detailRow('🎵 Genre:', app['genre'] ?? ''),
          _detailRow('📀 Original Music:', (app['has_original_music'] ?? false) ? 'Yes' : 'No'),
          if ((app['bio'] ?? '').toString().isNotEmpty) _detailRow('📝 Bio:', app['bio'] ?? ''),
          _detailRow('📅 Applied:', _formatDate(appliedAt)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _showRejectDialog(app['id'].toString(), app['user_id'].toString()), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE63950), side: const BorderSide(color: const Color(0xFFE63950))), child: const Text('Reject'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: () => _showApproveDialog(app['id'].toString(), app['user_id'].toString()), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Approve'))),
          ]),
        ]),
      ),
    );
  }

  Widget _buildReviewedCard(Map<String, dynamic> app) {
    final profile = app['profiles'] as Map<String, dynamic>? ?? {};
    final appliedAt = app['applied_at']?.toString() ?? '';
    final reviewedAt = app['reviewed_at']?.toString() ?? '';
    final status = (app['status'] ?? '').toString();
    final reviewMessage = (app['review_message'] ?? '').toString();
    final reviewedBy = (app['reviewed_by'] ?? '').toString();

    Color statusColor = Colors.white70;
    if (status.toLowerCase() == 'approved') statusColor = Colors.green;
    if (status.toLowerCase() == 'rejected') statusColor = Colors.orange;

    return Card(
      color: const Color(0xFF161616),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: Colors.grey[800], backgroundImage: profile['avatar_url'] != null ? NetworkImage(profile['avatar_url']) : null, child: profile['avatar_url'] == null ? const Icon(Icons.person, color: Colors.white54) : null),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(profile['username'] ?? 'No username', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(_formatDate(appliedAt), style: const TextStyle(color: Colors.white70))])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 12),
          _detailRow('🎤 Stage Name:', app['stage_name'] ?? ''),
          _detailRow('🎵 Genre:', app['genre'] ?? ''),
          if (reviewMessage.isNotEmpty) _detailRow('📝 Review Message:', reviewMessage),
          _detailRow('📅 Reviewed:', _formatDate(reviewedAt)),
          if (reviewedBy.isNotEmpty) _detailRow('👤 Reviewed By:', reviewedBy),
        ]),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500))), const SizedBox(width: 8), Expanded(child: Text(value ?? '', style: const TextStyle(color: Colors.white)))]));
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0B),
        appBar: AppBar(title: const Text('Admin Dashboard'), backgroundColor: Colors.transparent),
        body: const Center(child: Text('Access Denied', style: TextStyle(color: Colors.white70))),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0B),
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.transparent,
          bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Pending'), Tab(text: 'Reviewed')]),
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () async { setState(() { _isLoading = true; }); await _loadPendingArtistApplications(); await _loadReviewedArtistApplications(); })],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(controller: _tabController, children: [
          _pendingArtistApps.isEmpty ? const Center(child: Text('No pending applications', style: TextStyle(color: Colors.white70))) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _pendingArtistApps.length, itemBuilder: (context, i) => _buildPendingCard(_pendingArtistApps[i])),
          _reviewedArtistApps.isEmpty ? const Center(child: Text('No reviewed applications yet', style: TextStyle(color: Colors.white70))) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _reviewedArtistApps.length, itemBuilder: (context, i) => _buildReviewedCard(_reviewedArtistApps[i])),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
