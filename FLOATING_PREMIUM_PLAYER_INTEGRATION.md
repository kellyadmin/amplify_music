# Floating Premium Player Integration Guide

## Overview
The new floating premium player provides a modern, glassmorphic design with smooth animations and enhanced user experience. It comes in two variants:
1. **FloatingPremiumPlayer** - For audio playback
2. **FloatingPremiumVideoPlayer** - For video playback

## Features

### Visual Design
- ✨ Glassmorphism effect with backdrop blur
- 🎨 Golden gradient accents (premium look)
- 💫 Smooth animations and transitions
- 🌟 Pulsing indicator when playing
- 📱 Responsive sizing (compact/expanded modes)

### Functionality
- 🎯 Draggable and snaps to screen edges
- 🔄 Expandable/collapsible interface
- ⏯️ Play/pause controls
- ⏭️ Next/previous track support (audio)
- 📊 Progress indicator
- 🖱️ Mouse hover effects
- ❌ Close button

## Integration Examples

### 1. Audio Player Integration (amplify_main_screen.dart)

Replace the bottom mini player with a floating one:

```dart
import '../widgets/floating_premium_player.dart';

class _AmplifyMainScreenState extends State<AmplifyMainScreen> {
  Offset _playerPosition = const Offset(10, 100);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Your main content
          PageView(
            controller: _pageController,
            children: _screens,
          ),
          
          // Floating Premium Player
          p.Consumer<MusicService>(
            builder: (context, musicService, child) {
              final song = musicService.currentSong;
              if (song == null) return const SizedBox.shrink();
              
              return FloatingPremiumPlayer(
                song: song,
                isPlaying: musicService.isPlaying,
                progress: musicService.position.inMilliseconds / 
                         (musicService.duration?.inMilliseconds ?? 1),
                onPlayPause: () => musicService.togglePlayPause(),
                onTap: () => _navigateToMusicPlayer(musicService),
                onNext: () => musicService.playNext(),
                onPrevious: () => musicService.playPrevious(),
                onClose: () => musicService.stop(),
                initialPosition: _playerPosition,
                onPositionChanged: (newPos) {
                  setState(() => _playerPosition = newPos);
                },
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        // Your navigation bar
      ),
    );
  }
}
```

### 2. Video Player Integration (Already Implemented in discover_screen.dart)

The video player is already integrated in the discover screen:

```dart
Widget _buildMiniVideoPlayer() {
  final video = _selectedVideoForPlayback;
  if (video == null || _videoPlayerController == null) {
    return const SizedBox.shrink();
  }

  return FloatingPremiumVideoPlayer(
    video: video,
    videoController: _videoPlayerController!,
    isPlaying: _videoPlayerController!.value.isPlaying,
    onPlayPause: () {
      setState(() {
        _videoPlayerController!.value.isPlaying
            ? _videoPlayerController!.pause()
            : _videoPlayerController!.play();
      });
    },
    onFullScreen: () {
      setState(() {
        _isFullScreenVideo = true;
      });
    },
    onClose: () {
      _disposeVideoPlayer();
      setState(() {
        _selectedVideoForPlayback = null;
      });
    },
    initialPosition: _miniPlayerPosition,
    onPositionChanged: (newPosition) {
      setState(() {
        _miniPlayerPosition = newPosition;
      });
    },
  );
}
```

## Customization Options

### FloatingPremiumPlayer Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `song` | `Song?` | Yes | Current song to display |
| `isPlaying` | `bool` | Yes | Playing state |
| `onPlayPause` | `VoidCallback` | Yes | Play/pause handler |
| `onTap` | `VoidCallback` | Yes | Tap handler (open full player) |
| `onNext` | `VoidCallback?` | No | Next track handler |
| `onPrevious` | `VoidCallback?` | No | Previous track handler |
| `onClose` | `VoidCallback?` | No | Close player handler |
| `progress` | `double` | No | Progress (0.0 to 1.0) |
| `initialPosition` | `Offset` | No | Starting position |
| `onPositionChanged` | `Function(Offset)?` | No | Position change callback |

### FloatingPremiumVideoPlayer Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `video` | `MusicVideo` | Yes | Video to display |
| `videoController` | `VideoPlayerController` | Yes | Video controller |
| `isPlaying` | `bool` | Yes | Playing state |
| `onPlayPause` | `VoidCallback` | Yes | Play/pause handler |
| `onFullScreen` | `VoidCallback` | Yes | Fullscreen handler |
| `onClose` | `VoidCallback` | Yes | Close handler |
| `initialPosition` | `Offset` | No | Starting position |
| `onPositionChanged` | `Function(Offset)?` | No | Position change callback |

## Behavior

### Dragging
- Drag the player anywhere on screen
- Automatically snaps to left or right edge when released
- Respects screen boundaries

### Expanding/Collapsing
- Click the expand/collapse button (top right)
- **Compact mode**: Shows album art, title, artist, and play button
- **Expanded mode**: Shows larger album art and full controls

### Auto-hide Controls
- Controls fade out after 3 seconds of inactivity
- Mouse hover or tap shows controls again
- Playing indicator always visible

## Styling

The player uses these color schemes:
- **Background**: Glassmorphic white with blur
- **Accent**: Golden gradient (#FFD700 to #FFA500)
- **Border**: Semi-transparent white
- **Shadow**: Black with golden glow

## Migration from Old Mini Player

### Before (Bottom Bar)
```dart
bottomNavigationBar: Column(
  children: [
    MiniPlayerWidget(...),
    BottomNavigationBar(...),
  ],
)
```

### After (Floating)
```dart
body: Stack(
  children: [
    // Main content
    PageView(...),
    // Floating player
    FloatingPremiumPlayer(...),
  ],
)
```

## Tips

1. **Save Position**: Store `_playerPosition` in shared preferences to remember user's preferred location
2. **Z-Index**: The floating player appears above all content - ensure important UI isn't obscured
3. **Performance**: The player uses `SingleTickerProviderStateMixin` for smooth animations
4. **Accessibility**: All buttons have proper tap targets (minimum 32x32)

## Next Steps

To complete the integration:
1. Update `amplify_main_screen.dart` to use `FloatingPremiumPlayer`
2. Remove the old `MiniPlayerWidget` from bottom bar
3. Add position persistence (optional)
4. Test on different screen sizes
5. Adjust initial position if needed

## Example: Complete Integration

See `lib/screens/discover_screen.dart` for a complete working example of the video player integration.
