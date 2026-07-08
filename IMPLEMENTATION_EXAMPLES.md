# 🚀 Vibrant UI Implementation Examples

Step-by-step examples showing how to upgrade your existing screens with the new vibrant components.

---

## 📱 Example 1: Enhance Home Screen Hero Section

### **Current Code** (Basic)
```dart
// Old basic container
Container(
  padding: EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: backgroundColor,
  ),
  child: Column(
    children: [
      Text('Discover New Music'),
      ElevatedButton(
        onPressed: () {},
        child: Text('Explore'),
      ),
    ],
  ),
)
```

### **New Code** (Vibrant!)
```dart
// Import the new widgets at the top of your file
import '../widgets/animated_gradient_background.dart';
import '../widgets/vibrant_card.dart';

// Enhanced version with animated background
AnimatedGradientBackground(
  colors: [accentPurple, accentColor, neonBlue, accentMint],
  opacity: 0.12,
  duration: Duration(seconds: 8),
  child: Container(
    padding: EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gradient text for heading
        ShaderMask(
          shaderCallback: (bounds) => brandGradient.createShader(bounds),
          child: Text(
            'Discover New Music',
            style: homeFont(
              size: 32,
              weight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Personalized for you',
          style: homeFont(size: 16, color: subtitleColor),
        ),
        SizedBox(height: 20),
        // Vibrant button instead of basic ElevatedButton
        VibrantButton(
          text: 'Explore Now',
          icon: Icons.explore_rounded,
          gradient: brandGradient,
          width: double.infinity,
          onPressed: () {
            // Your explore action
          },
        ),
      ],
    ),
  ),
)
```

**Result**: Animated gradient orbs moving in background + glowing gradient button!

---

## 🎵 Example 2: Upgrade Song Cards

### **Current Code**
```dart
// Old basic card
Container(
  width: songCardWidth,
  decoration: BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(imageUrl: song.imageUrl),
      ),
      Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Text(song.title),
            Text(song.artist),
          ],
        ),
      ),
    ],
  ),
)
```

### **New Code** (With Glow!)
```dart
VibrantCard(
  width: songCardWidth,
  gradient: neonGradient,
  enableGlow: true,
  enableAnimation: true,
  padding: EdgeInsets.zero,
  onTap: () {
    // Play song or navigate to detail
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongDetailScreen(song: song),
      ),
    );
  },
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Album art with play button overlay
      Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: song.imageUrl,
              width: songCardWidth,
              height: songCardWidth,
              fit: BoxFit.cover,
            ),
          ),
          // Hover play button
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: PulsingGlow(
                  color: accentMint,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: mintGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: textColor,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              song.title,
              style: homeFont(size: 14, weight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              song.artist,
              style: homeFont(size: 12, color: subtitleColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  ),
)
```

**Result**: Gradient border, pulsing glow, animated play button!

---

## 🎸 Example 3: Artist Cards with Glassmorphism

### **Current Code**
```dart
Container(
  width: artistCardWidth,
  decoration: BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: [
      CircleAvatar(
        radius: 40,
        backgroundImage: CachedNetworkImageProvider(artist.imageUrl),
      ),
      SizedBox(height: 8),
      Text(artist.name),
    ],
  ),
)
```

### **New Code** (Glassmorphic!)
```dart
GlassmorphicCard(
  width: artistCardWidth,
  padding: EdgeInsets.all(16),
  borderColor: accentPurple.withOpacity(0.4),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtistDetailScreen(artist: artist),
      ),
    );
  },
  child: Column(
    children: [
      // Artist avatar with gradient border
      Container(
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: premiumGradient,
        ),
        child: Container(
          padding: EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cardColor,
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundImage: CachedNetworkImageProvider(artist.imageUrl),
          ),
        ),
      ),
      SizedBox(height: 12),
      Text(
        artist.name,
        style: homeFont(size: 14, weight: FontWeight.w700),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      SizedBox(height: 4),
      // Follower count with icon
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_rounded,
            size: 12,
            color: subtitleColor,
          ),
          SizedBox(width: 4),
          Text(
            '${artist.followers}K',
            style: homeFont(size: 11, color: subtitleColor),
          ),
        ],
      ),
    ],
  ),
)
```

**Result**: Frosted glass effect with colorful border and gradient avatar ring!

---

## ▶️ Example 4: Enhanced Play Button

### **Current Code**
```dart
IconButton(
  icon: Icon(Icons.play_arrow),
  onPressed: () {
    // Play music
  },
)
```

### **New Code** (Pulsing Glow!)
```dart
GestureDetector(
  onTap: () {
    // Play music
    _musicService.playSong(song);
  },
  child: PulsingGlow(
    color: accentMint,
    minOpacity: 0.3,
    maxOpacity: 0.7,
    duration: Duration(milliseconds: 1500),
    child: Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: mintGradient,
        shape: BoxShape.circle,
        boxShadow: mintGlow(opacity: 0.5, blur: 20),
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: textColor,
        size: 32,
      ),
    ),
  ),
)
```

**Result**: Glowing, pulsing play button that draws attention!

---

## 💎 Example 5: Premium Badge

### **Current Code**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text('PREMIUM'),
)
```

### **New Code** (Gradient Border!)
```dart
GradientBorderContainer(
  gradient: premiumGradient,
  borderWidth: 2,
  borderRadius: BorderRadius.circular(20),
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.star_rounded,
        color: premiumGold,
        size: 16,
      ),
      SizedBox(width: 4),
      // Shimmer text effect
      MultiColorShimmer(
        colors: [accentYellow, primaryColor, accentColor],
        child: Text(
          'PREMIUM',
          style: homeFont(
            size: 11,
            weight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ),
    ],
  ),
)
```

**Result**: Animated shimmer text with gradient border - super premium look!

---

## ❤️ Example 6: Action Buttons Row

### **Current Code**
```dart
Row(
  children: [
    IconButton(
      icon: Icon(Icons.favorite_border),
      onPressed: () {},
    ),
    IconButton(
      icon: Icon(Icons.share),
      onPressed: () {},
    ),
    IconButton(
      icon: Icon(Icons.add),
      onPressed: () {},
    ),
  ],
)
```

### **New Code** (Vibrant Buttons!)
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    // Like button
    VibrantButton(
      text: 'Like',
      icon: Icons.favorite_rounded,
      gradient: actionGradient,
      width: 100,
      height: 44,
      onPressed: () {
        // Like action
      },
    ),
    
    // Share button
    VibrantButton(
      text: 'Share',
      icon: Icons.share_rounded,
      gradient: neonGradient,
      width: 100,
      height: 44,
      onPressed: () {
        // Share action
      },
    ),
    
    // Add to playlist button
    VibrantButton(
      text: 'Add',
      icon: Icons.add_rounded,
      gradient: mintGradient,
      width: 100,
      height: 44,
      onPressed: () {
        // Add to playlist
      },
    ),
  ],
)
```

**Result**: Three colorful gradient buttons with glow effects!

---

## 📊 Example 7: Stats Card

### **Current Code**
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: [
      Text('1,234'),
      Text('Plays'),
    ],
  ),
)
```

### **New Code** (Vibrant Stats!)
```dart
VibrantCard(
  gradient: electricGradient,
  enableGlow: true,
  padding: EdgeInsets.all(20),
  child: Column(
    children: [
      // Big number with gradient
      ShaderMask(
        shaderCallback: (bounds) => electricGradient.createShader(bounds),
        child: Text(
          '1,234',
          style: homeFont(
            size: 36,
            weight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      SizedBox(height: 8),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_outline_rounded,
            size: 16,
            color: subtitleColor,
          ),
          SizedBox(width: 4),
          Text(
            'Total Plays',
            style: homeFont(size: 13, color: subtitleColor),
          ),
        ],
      ),
      SizedBox(height: 12),
      // Trend indicator
      Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: mintGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.trending_up, size: 14, color: textColor),
            SizedBox(width: 4),
            Text(
              '+12% this week',
              style: homeFont(size: 11, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ],
  ),
)
```

**Result**: Eye-catching stats card with gradient numbers and trend badge!

---

## 🔍 Example 8: Search Bar Enhancement

### **Current Code**
```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Search songs, artists...',
    prefixIcon: Icon(Icons.search),
  ),
)
```

### **New Code** (Glassmorphic!)
```dart
GlassmorphicCard(
  padding: EdgeInsets.zero,
  borderColor: neonBlue.withOpacity(0.3),
  child: TextField(
    style: homeFont(size: 15, color: textColor),
    decoration: InputDecoration(
      hintText: 'Search songs, artists...',
      hintStyle: homeFont(size: 15, color: textDisabledColor),
      prefixIcon: Container(
        margin: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: neonGradient,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.search_rounded,
          color: textColor,
          size: 20,
        ),
      ),
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    ),
    onChanged: (value) {
      // Search logic
    },
  ),
)
```

**Result**: Glassmorphic search bar with gradient icon!

---

## 🎚️ Example 9: Progress Bar/Slider

### **Current Code**
```dart
LinearProgressIndicator(
  value: 0.6,
  backgroundColor: surfaceElevated,
  color: primaryColor,
)
```

### **New Code** (Gradient!)
```dart
Stack(
  children: [
    // Background track
    Container(
      height: 4,
      decoration: BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
    // Gradient progress
    FractionallySizedBox(
      widthFactor: 0.6, // 60% progress
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          gradient: playerGradient,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: accentYellow.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    ),
  ],
)
```

**Result**: Glowing gradient progress bar!

---

## 📱 Example 10: Bottom Sheet / Modal

### **Current Code**
```dart
showModalBottomSheet(
  context: context,
  builder: (context) {
    return Container(
      color: cardColor,
      child: ListView(
        children: [
          ListTile(title: Text('Option 1')),
          ListTile(title: Text('Option 2')),
        ],
      ),
    );
  },
)
```

### **New Code** (Vibrant!)
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (context) {
    return Container(
      decoration: BoxDecoration(
        gradient: surfaceGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            width: 2,
            color: Colors.transparent,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              gradient: brandGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ShaderMask(
              shaderCallback: (bounds) => brandGradient.createShader(bounds),
              child: Text(
                'Song Options',
                style: homeFont(
                  size: 20,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Divider(color: cardBorderColor.withOpacity(0.2)),
          // Options
          _buildSheetOption(
            icon: Icons.favorite_rounded,
            label: 'Add to Favorites',
            gradient: actionGradient,
            onTap: () {},
          ),
          _buildSheetOption(
            icon: Icons.playlist_add_rounded,
            label: 'Add to Playlist',
            gradient: mintGradient,
            onTap: () {},
          ),
          _buildSheetOption(
            icon: Icons.share_rounded,
            label: 'Share Song',
            gradient: neonGradient,
            onTap: () {},
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  },
);

// Helper method for sheet options
Widget _buildSheetOption({
  required IconData icon,
  required String label,
  required LinearGradient gradient,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardBorderColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          SizedBox(width: 16),
          Text(
            label,
            style: homeFont(size: 15, weight: FontWeight.w600),
          ),
          Spacer(),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: subtitleColor,
          ),
        ],
      ),
    ),
  );
}
```

**Result**: Beautiful gradient bottom sheet with colorful option icons!

---

## 🎯 Quick Copy-Paste Templates

### **Template 1: Section Header**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    ShaderMask(
      shaderCallback: (bounds) => brandGradient.createShader(bounds),
      child: Text(
        'Trending Now',
        style: homeFont(size: 20, weight: FontWeight.w800, color: Colors.white),
      ),
    ),
    VibrantButton(
      text: 'See All',
      gradient: actionGradient,
      width: 80,
      height: 36,
      onPressed: () {},
    ),
  ],
)
```

### **Template 2: Empty State**
```dart
AnimatedGradientBackground(
  colors: [accentPurple, accentColor, neonBlue],
  opacity: 0.08,
  child: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MultiColorShimmer(
          child: Icon(Icons.music_note, size: 80, color: Colors.white),
        ),
        SizedBox(height: 20),
        Text(
          'No songs yet',
          style: homeFont(size: 20, weight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text(
          'Start exploring to build your library',
          style: homeFont(size: 14, color: subtitleColor),
        ),
        SizedBox(height: 24),
        VibrantButton(
          text: 'Explore Music',
          icon: Icons.explore_rounded,
          gradient: brandGradient,
          onPressed: () {},
        ),
      ],
    ),
  ),
)
```

### **Template 3: Loading Skeleton**
```dart
VibrantCard(
  gradient: neonGradient,
  enableGlow: false,
  enableAnimation: false,
  child: Column(
    children: [
      MultiColorShimmer(
        child: Container(
          width: double.infinity,
          height: 160,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 12),
      MultiColorShimmer(
        child: Container(
          height: 16,
          width: 120,
          color: Colors.white,
        ),
      ),
    ],
  ),
)
```

---

## ✅ Implementation Checklist

Use this checklist when upgrading each screen:

- [ ] Import new widget files
- [ ] Replace Container with VibrantCard for important elements
- [ ] Add AnimatedGradientBackground to hero sections
- [ ] Replace ElevatedButton with VibrantButton
- [ ] Add PulsingGlow to play/action buttons
- [ ] Use GlassmorphicCard for secondary content
- [ ] Apply GradientBorderContainer for badges/tags
- [ ] Use MultiColorShimmer for loading states
- [ ] Apply gradient to section headers (ShaderMask)
- [ ] Test animations and performance
- [ ] Adjust opacity values if needed
- [ ] Check on different screen sizes

---

## 🎬 Next Steps

1. **Start with Home Screen** - Most visible, highest impact
2. **Then Player Screen** - Where users spend most time
3. **Discover/Search** - High interaction screens
4. **Profile/Settings** - Polish and consistency

**Want me to implement these on any specific screen? Just ask!** 🚀
