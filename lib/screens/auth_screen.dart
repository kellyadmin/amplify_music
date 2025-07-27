import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  final bool showResend;

  const AuthScreen({super.key, this.showResend = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool showResend = false;
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
    showResend = widget.showResend;
  }

  void _showSnack(String message, {Color color = Colors.orange}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _createUserProfile(String userId, String email, String username) async {
    try {
      await supabase.from('users').insert({
        'id': userId,
        'email': email,
        'username': username,
        'user_type': 'normal', // You can make this dynamic later
        'is_verified': true,
      });
      print("✅ User profile created");
    } catch (e) {
      print("❌ Error creating profile: $e");
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!isLogin && username.isEmpty)) {
      _showSnack('Fill all required fields.', color: Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
      showResend = false;
    });

    try {
      if (isLogin) {
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final user = response.user;
        final isConfirmed = user?.emailConfirmedAt != null;

        if (!isConfirmed) {
          _showSnack("Please verify your email first.", color: Colors.red);
          setState(() => showResend = true);
        } else {
          _showSnack("Login successful!");
          Navigator.pop(context, true);
        }
      } else {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: 'https://conhbihmsgdujpwhperh.supabase.co/auth/callback',
        );

        final userId = response.user?.id;
        if (userId != null) {
          await _createUserProfile(userId, email, username);
        }

        _showSnack("Account created! Check your email for verification.");
        setState(() => isLogin = true);
      }
    } on AuthException catch (e) {
      _showSnack(e.message, color: Colors.red);
    } catch (e) {
      _showSnack("Unexpected error: ${e.toString()}", color: Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Enter your email and password to resend verification.', color: Colors.red);
      return;
    }

    try {
      await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://conhbihmsgdujpwhperh.supabase.co/auth/callback',
      );
      _showSnack("Verification email resent!");
    } catch (e) {
      _showSnack("Error resending email: ${e.toString()}", color: Colors.red);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnack('Enter your email to receive reset link.', color: Colors.red);
      return;
    }

    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.amplify://reset-password',
      );
      _showSnack("Password reset email sent!");
    } catch (e) {
      _showSnack("Error sending reset email: ${e.toString()}", color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(isLogin ? 'Login' : 'Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isLogin)
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: !showPassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.white70),
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white54,
                  ),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (isLogin)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: const Text('Forgot Password?', style: TextStyle(color: Colors.orange)),
                ),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(isLogin ? 'Login' : 'Sign Up', style: const TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(
                isLogin ? 'Create an account' : 'Already have an account?',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            if (showResend)
              TextButton(
                onPressed: isLoading ? null : _resendVerificationEmail,
                child: const Text('Resend verification email', style: TextStyle(color: Colors.orange)),
              ),
          ],
        ),
      ),
    );
  }
}
