import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uni_links/uni_links.dart'; // only works on mobile

class ResetPasswordScreen extends StatefulWidget {
  final String? token; // For web

  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _passwordController = TextEditingController();
  bool loading = false;
  bool sessionSet = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _handleWebToken();
    } else {
      _handleMobileLink();
    }
  }

  Future<void> _handleWebToken() async {
    final token = Uri.base.queryParameters['access_token'] ?? widget.token;
    if (token == null) return;
    try {
      await supabase.auth.exchangeCodeForSession(token);
      setState(() => sessionSet = true);
    } catch (e) {
      _showError("Web session error: $e");
    }
  }

  Future<void> _handleMobileLink() async {
    final uri = await getInitialUri();
    if (uri != null) {
      try {
        await supabase.auth.exchangeCodeForSession(uri.toString());
        setState(() => sessionSet = true);
      } catch (e) {
        _showError("Mobile session error: $e");
      }
    }
  }

  Future<void> _updatePassword() async {
    final newPassword = _passwordController.text.trim();

    if (newPassword.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    setState(() => loading = true);

    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));

      _showError("Password updated successfully. Please log in again.");
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      _showError("Error updating password: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter your new password',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (loading || !sessionSet) ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                minimumSize: const Size.fromHeight(50),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                'Update Password',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
