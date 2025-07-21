import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uni_links/uni_links.dart';

import 'screens/amplify_main_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/reset_password_screen.dart'; // Make sure this file exists
import 'models.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://conhbihmsgdujpwhperh.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvbmhiaWhtc2dkdWpwd2hwZXJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI4MTY3NjMsImV4cCI6MjA2ODM5Mjc2M30.wic-hToCZl9CNXvqyXcxAyjY7YtKVfp70fe0As77XnQ',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();

    // Listen to deep links (uni_links)
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() {
    // Initial link when app starts
    getInitialUri().then((uri) {
      if (uri != null) {
        _processDeepLink(uri);
      }
    });

    // Listen to link changes while app is running
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _processDeepLink(uri);
      }
    }, onError: (err) {
      // Handle error if needed
    });
  }

  void _processDeepLink(Uri uri) {
    // Check if this is the password reset link
    // Adjust this check to match your deep link scheme
    if (uri.scheme == 'io.supabase.amplify' && uri.host == 'reset-password') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Amplify Music',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellow,
          brightness: Brightness.dark,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
