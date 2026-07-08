import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// CORRECTED PATH: Assumes 'auth_screen.dart' is in a 'screens' folder
// and 'chat_service.dart' is in a sibling 'services' folder.
import '../services/chat_service.dart';
import '../constants.dart';

// Replace with your actual home screen
import 'amplify_main_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool showResend;

  const AuthScreen({super.key, this.showResend = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _showResend = false;
  bool _showPassword = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _showResend = widget.showResend;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
              color: isError ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? errorColor : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Terms & Conditions',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: Text(
              '''
Last Updated: October 14, 2025

Please read these Terms and Conditions ("Terms") carefully before using the Amplify mobile application (the "Service").

Your access to and use of the Service is conditioned upon your acceptance of and compliance with these Terms. These Terms apply to all visitors, users, and others who wish to access or use the Service.

1. Accounts
When you create an account with us, you guarantee that you are above the age of 13, and that the information you provide us is accurate, complete, and current at all times.

2. Content
Our Service allows you to post, link, store, share and otherwise make available certain information, text, graphics, videos, or other material ("Content"). You are responsible for the Content that you post on or through the Service, including its legality, reliability, and appropriateness.

By posting Content on or through the Service, You represent and warrant that: (i) the Content is yours (you own it) and/or you have the right to use it and the right to grant us the rights and license as provided in these Terms, and (ii) that the posting of your Content on or through the Service does not violate the privacy rights, publicity rights, copyrights, contract rights or any other rights of any person or entity. We reserve the right to terminate the account of anyone found to be infringing on a copyright.

Amplify takes no responsibility and assumes no liability for Content posted by you or any third party. All content on the app is uploaded by artists or music service providers, not Amplify. The copyright and ownership of the content remain with the respective artists and/or service providers.

3. Limitation Of Liability
In no event shall Amplify, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your access to or use of or inability to access or use the Service.

Amplify is not responsible for any illegal activity conducted by users on the platform. We reserve the right to cooperate with law enforcement in the case of any investigation.

4. Changes
We reserve the right, at our sole discretion, to modify or replace these Terms at any time.

5.You should not upload videos that you do not own the copyright

By continuing to access or use our Service after any revisions become effective, you agree to be bound by the revised terms. If you do not agree to the new terms, you are no longer authorized to use the Service.
              ''',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Close',
                style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createUserProfile(String userId, String email, String username) async {
    try {
      // NOTE: Assuming 'users' table exists and accepts this schema
      await supabase.from('users').insert({
        'id': userId,
        'email': email,
        'username': username,
        'user_type': 'listener', // Default role is listener
        'is_verified': false,
      });
      debugPrint("✅ User profile created");
    } catch (e) {
      debugPrint("❌ Error creating profile: $e");
      _showSnack("Couldn't create user profile. Please try again.", isError: true);
    }
  }

  // Add Google Sign In method
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // UPDATED: Using a cleaner, app-specific deep link scheme
      const redirectUrl = 'amplifymusic://login-callback';

      final response = await supabase.auth.signInWithOAuth(
        Provider.google,
        redirectTo: redirectUrl,
      );

      // Note: The OAuth flow will handle the rest through deep linking
      // The auth state listener in your main app should handle the navigation

    } on AuthException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (e) {
      _showSnack("An unexpected error occurred: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isLogin && !_agreedToTerms) {
      _showSnack("Please accept the Terms & Conditions to sign up.", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _showResend = false;
    });

    try {
      if (_isLogin) {
        final response = await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = response.user;
        final sessionToken = response.session?.accessToken; // Extracted the token

        if (user?.emailConfirmedAt == null) {
          _showSnack("Please verify your email first.", isError: true);
          setState(() => _showResend = true);
        } else if (sessionToken != null && mounted) {
          // --- CHAT SERVICE INTEGRATION (FIXED) ---
          // 1. Initialize the ChatService with the current user
          ChatService().initialize();

          // 2. Navigate to AmplifyMainScreen as requested.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AmplifyMainScreen(),
            ),
          );
        } else {
          _showSnack("Login successful but session data is missing. Please try again.", isError: true);
        }
      } else {
        // UPDATED: Using a cleaner, app-specific deep link scheme
        const emailRedirectTo = 'amplifymusic://login-callback';
        final response = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          emailRedirectTo: emailRedirectTo,
        );

        final userId = response.user?.id;
        if (userId != null) {
          await _createUserProfile(userId, _emailController.text.trim(), _usernameController.text.trim());
        }

        _showSnack("Account created! Check your email for a verification link.");
        setState(() => _isLogin = true);
      }
    } on AuthException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (e) {
      _showSnack("An unexpected error occurred: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_emailController.text.isEmpty) {
      _showSnack('Please enter your email to resend verification.', isError: true);
      return;
    }
    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: _emailController.text.trim(),
      );
      _showSnack("Verification email resent!");
    } catch (e) {
      _showSnack("Error resending email: ${e.toString()}", isError: true);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Enter your email to receive a password reset link.', isError: true);
      return;
    }
    try {
      // UPDATED: Using a cleaner, app-specific deep link scheme
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'amplifymusic://reset-password',
      );
      _showSnack("Password reset email sent! Check your inbox.");
    } catch (e) {
      _showSnack("Error sending reset email: ${e.toString()}", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    final inputDecoration = InputDecoration(
      labelStyle: textTheme.bodyMedium?.copyWith(color: Colors.white70),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Placeholder for Image.asset('assets/images/logo.png')
                  Center(
                    child: Text(
                      'AMPLIFY',
                      style: GoogleFonts.inter(
                        color: primaryColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _isLogin ? 'Welcome Back' : 'Create Account',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // Google Sign In Button - UPDATED STYLING
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: googleBlue, // Official Google Blue
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon color is now white for contrast
                        Icon(
                          Icons.g_mobiledata,
                          size: 30,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Continue with Google',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Text color is now white
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // OR divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey[700],
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'OR',
                          style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey[700],
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _usernameController,
                      style: textTheme.bodyLarge,
                      decoration: inputDecoration.copyWith(labelText: 'Username'),
                      validator: (value) => value!.isEmpty ? 'Please enter a username' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    style: textTheme.bodyLarge,
                    keyboardType: TextInputType.emailAddress,
                    decoration: inputDecoration.copyWith(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter an email';
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    style: textTheme.bodyLarge,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54,
                        ),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter a password';
                      if (value.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            textStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        child: const Text('Forgot Password?'),
                      ),
                    ),

                  if (!_isLogin)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (bool? value) {
                              setState(() {
                                _agreedToTerms = value ?? false;
                              });
                            },
                            checkColor: Colors.black,
                            activeColor: primaryColor,
                            side: const BorderSide(color: Colors.white70),
                          ),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                style: textTheme.bodySmall,
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = _showTermsDialog,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryGradientStart, primaryGradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 3,
                        ),
                      )
                          : Text(
                        _isLogin ? 'Log In' : 'Sign Up',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? "Don't have an account?" : "Already have an account?",
                        style: textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          if (_isLoading) return;
                          setState(() {
                            _isLogin = !_isLogin;
                            _formKey.currentState?.reset();
                          });
                        },
                        style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                            textStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        child: Text(_isLogin ? 'Sign Up' : 'Log In'),
                      ),
                    ],
                  ),
                  if (_showResend)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: TextButton(
                        onPressed: _isLoading ? null : _resendVerificationEmail,
                        style: TextButton.styleFrom(foregroundColor: primaryColor),
                        child: const Text('Resend verification email'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
