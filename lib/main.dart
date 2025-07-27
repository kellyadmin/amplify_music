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

  await Supabase.initialize(
    url: 'https://conhbihmsgdujpwhperh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvbmhiaWhtc2dkdWpwd2hwZXJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI4MTY3NjMsImV4cCI6MjA2ODM5Mjc2M30.wic-hToCZl9CNXvqyXcxAyjY7YtKVfp70fe0As77XnQ',
    authFlowType: AuthFlowType.pkce,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    handleInitialDeepLinks();
  }

  void handleInitialDeepLinks() async {
    final uri = await getInitialUri();
    if (uri != null && uri.queryParameters['access_token'] != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(token: uri.queryParameters['access_token']!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Amplify Music',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow, brightness: Brightness.dark),
      ),
      home: const AmplifyMainScreen(), // ✅ load directly here
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
