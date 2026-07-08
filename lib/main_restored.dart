import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uni_links/uni_links.dart';
// Use a small stub on non-web platforms to avoid importing web-only library
import 'utils/web_plugins_stub.dart'
    if (dart.library.html) 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:provider/provider.dart' as p;

import 'models.dart';
import 'screens/loading_screen.dart';
import 'screens/amplify_main_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/song_detail_screen.dart';
import 'screens/artist_detail_screen.dart';
import 'screens/album_detail_screen.dart';
import 'screens/playlist_detail_screen.dart';
import 'screens/auth_screen.dart';
import 'services/music_service.dart';
import 'services/download_notifier_service.dart';
import 'services/recent_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set URL Strategy for clean URLs on the web (removes the '#' from the URL)
  setUrlStrategy(PathUrlStrategy());

  await Supabase.initialize(
    url: 'https://conhbihmsgdujpwhperh.supabase.co',
    // G¡Én+Å ACTION REQUIRED: Replace 'YOUR_SUPABASE_ANON_KEY' with your actual key.
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvbmhiaWhtc2dkdWpwd2hwZXJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI4MTY3NjMsImV4cCI6MjA2ODM5Mjc2M30.wic-hToCZl9CNXvqyXcxAyjY7YtKVfp70fe0As77XnQ',
    authFlowType: AuthFlowType.pkce,
  );
  runApp(
    p.MultiProvider(
      providers: [
        p.ChangeNotifierProvider(create: (_) => DownloadNotifierService()),
        p.ChangeNotifierProvider(create: (_) => RecentService()),
        p.ChangeNotifierProvider<MusicService>(
          create: (context) {
            final recentService = p.Provider.of<RecentService>(context, listen: false);
            return MusicService(recentService);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
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

    if (uri == null) return; // No deep link to handle

    // Handle Supabase Auth/Password Reset links
    if (uri.queryParameters['access_token'] != null) {
      // Navigate to the password reset screen
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            token: uri.queryParameters['access_token']!,
          ),
        ),
      );
      return;
    }

    // Filter out any empty segments caused by leading/trailing slashes on the web.
    final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    // --- DEBUG CONFIRMATION START ---
    if (pathSegments.isNotEmpty) {
      print('Deep Link segments found: $pathSegments');
    }
    // --- DEBUG CONFIRMATION END ---

    // We only care if we have at least a route type (e.g., 'song') and an ID
    if (pathSegments.length >= 2) {
      final routeName = '/${pathSegments.first}'; // Correctly gets '/song'
      final id = pathSegments[1]; // Correctly gets the ID

      // --- DEBUG CONFIRMATION START ---
      print('Attempting deep link navigation to: $routeName with ID: $id');
      // --- DEBUG CONFIRMATION END ---

      // Check if the route is one of our detail screens
      if (['/song', '/artist', '/album', '/playlist'].contains(routeName)) {
        // Use the global key to navigate to the specific route, passing the ID directly
        // The rest of the URL slug is now correctly ignored but the navigation works.
        navigatorKey.currentState?.push(
            MaterialPageRoute(
                builder: (context) {
                  // --- DEBUG CONFIRMATION START ---
                  print('SUCCESS: Pushing $routeName screen with ID $id');
                  // --- DEBUG CONFIRMATION END ---
                  switch (routeName) {
                    case '/song':
                      return SongDetailScreen(songId: id);
                    case '/artist':
                      return ArtistDetailScreen(artistId: id);
                    case '/album':
                      return AlbumDetailScreen(albumId: id);
                    case '/playlist':
                      return UnifiedPlaylistDetailScreen(playlistId: id);
                    default:
                    // Fallback: Should not be reached
                      return const SongsLoaderScreen();
                  }
                }
            )
        );
        return; // Stop processing and prevent loading the home screen immediately
      }
    }

    // If we reach here, no deep link was found or handled, and the app proceeds
    // to load the 'home' widget (SongsLoaderScreen) as intended.
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Your existing MaterialApp setup
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Viba Music',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellow,
          brightness: Brightness.dark,
        ),
      ),
      // If a deep link is handled in initState, it will push over this home screen.
      home: const SongsLoaderScreen(),

      // Your routes remain here for IN-APP navigation (e.g., Navigator.pushNamed)
      // They are not used for the initial deep link loading with this fix.
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
          return UnifiedPlaylistDetailScreen(playlistId: id);
        },
        '/auth': (ctx) => const AuthScreen(),
      },
    );
  }
}
