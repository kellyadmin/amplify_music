// Updated auth_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reset_password_screen.dart'; // Optional if creating a new screen

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
  bool isLogin = true;
  bool isLoading = false;
  bool showResend = false;
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
    showResend = widget.showResend;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password.');
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

        final confirmedAt = response.user?.emailConfirmedAt;
        final isConfirmed = confirmedAt != null;

        if (!isConfirmed) {
          _showError("Please verify your email first.");
          setState(() => showResend = true);
        } else {
          _showError("Login successful!");
        }
      } else {
        await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: 'https://conhbihmsgdujpwhperh.supabase.co/auth/callback',
        );
        _showError("Account created! Check your email for verification.");
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("Unexpected error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Enter your email and password to resend verification.');
      return;
    }

    try {
      await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://conhbihmsgdujpwhperh.supabase.co/auth/callback',
      );
      _showError("Verification email resent!");
    } catch (e) {
      _showError("Error resending email: ${e.toString()}");
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Enter your email to receive reset link.');
      return;
    }

    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.amplify://reset-password',
      );
      _showError("Password reset email sent!");
    } catch (e) {
      _showError("Error sending reset email: ${e.toString()}");
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
