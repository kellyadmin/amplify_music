import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uni_links/uni_links.dart';

import 'models.dart';
import 'screens/amplify_main_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/song_detail_screen.dart';
import 'screens/artist_detail_screen.dart';
import 'screens/album_detail_screen.dart';
import 'screens/playlist_detail_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ This is the correct way now (with authFlowType required)
  await Supabase.initialize(
    url: 'https://conhbihmsgdujpwhperh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvbmhiaWhtc2dkdWpwd2hwZXJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI4MTY3NjMsImV4cCI6MjA2ODM5Mjc2M30.wic-hToCZl9CNXvqyXcxAyjY7YtKVfp70fe0As77XnQ',
    authFlowType: AuthFlowType.pkce, // ✅ required for web auth sessions
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
    _handleDeepLinks();
  }

  void _handleDeepLinks() {
    if (kIsWeb) {
      _processDeepLink(Uri.base);
    } else {
      getInitialUri().then((uri) {
        if (uri != null) _processDeepLink(uri);
      });
      _sub = uriLinkStream.listen((uri) {
        if (uri != null) _processDeepLink(uri);
      });
    }
  }

  void _processDeepLink(Uri uri) {
    final token = uri.queryParameters['access_token'];

    final isMobileReset =
        uri.scheme == 'io.supabase.amplify' && uri.host == 'reset-password';
    final isWebReset = kIsWeb && uri.queryParameters['type'] == 'recovery';

    if ((isMobileReset || isWebReset) && token != null && token.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(token: token),
          ),
        );
      });
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
      home: const AmplifyMainScreen(),
      routes: {
        '/song': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as String;
          return SongDetailScreen(songId: id);
        },
        '/artist': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as String;
          return ArtistDetailScreen(artistId: id);
        },
        '/album': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as String;
          return AlbumDetailScreen(albumId: id);
        },
        '/playlist': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as String;
          return PlaylistDetailScreen(playlistId: id);
        },
      },
    );
  }
}
