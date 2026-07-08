# Song Card Interaction Guide

## Visual States Reference

### 🎯 Default State (No Hover)
```
┌─────────────────────┐
│                     │
│   [Album Art]       │  ← Clean, uncluttered
│   170x170px         │
│   20px radius       │
│                     │
└─────────────────────┘
  Song Title (2 lines)
  Artist Name
```

**Elements Visible:**
- Album artwork with subtle gradient
- Subtle border (white, 5% opacity)
- Song title (2 lines max)
- Artist name

**Elements Hidden:**
- Like button (unless already liked)
- Play button
- Stats bar (likes/plays)

---

### ✨ Hover State
```
┌─────────────────────┐
│ 🎵 Playing    ❤️   │  ← Now Playing badge + Like button
│                     │
│                     │
│       ▶️ 64px       │  ← Elastic play button (gold gradient)
│                     │
│ ❤️ 1.2K  │  ▶️ 5.4K│  ← Stats slide up from bottom
└─────────────────────┘
  Song Title (bold)
  Artist Name
```

**Changes on Hover:**
1. **Card scales to 1.03x** (subtle lift)
2. **Dual shadows appear** (gold + black)
3. **Play button bounces in** (elastic animation, 400ms)
4. **Stats bar slides up** from bottom (300ms)
5. **Like button fades in** (200ms, if not already liked)
6. **Dark overlay appears** on album art (40% black)

---

### 🎵 Now Playing State
```
┌─────────────────────┐
│ 🎵 Playing         │  ← Gold badge with glow
│                     │
│                     │  ← Gold border (50% opacity, 2px)
│   [Album Art]       │
│                     │
└─────────────────────┘
  Song Title
  Artist Name
```

**Unique Elements:**
- **"Playing" badge** (top-left)
  - Gold gradient background
  - Graphic equalizer icon
  - Pulsing glow shadow
- **Gold border** around entire card (2px, 50% opacity)

---

### ❤️ Liked Song State
```
┌─────────────────────┐
│                ❤️   │  ← Like button ALWAYS visible
│                     │
│   [Album Art]       │
│                     │
│                     │
└─────────────────────┘
  Song Title
  Artist Name
```

**Changes When Liked:**
- **Like button always visible** (doesn't hide on hover out)
- **Gold border on like button** (2px)
- **Gold tint background** (20% opacity)
- **Shadow glow** around like button

---

## 🎬 Animation Timeline

### Hover Enter (Total: ~400ms)
```
0ms    → Card starts scaling (250ms duration)
0ms    → Stats begin sliding up (300ms duration)
0ms    → Like button fades in (200ms duration)
0ms    → Play button begins elastic bounce (400ms duration)
0ms    → Shadows transition (200ms)
200ms  → Like button fully visible ✓
250ms  → Card fully scaled ✓
300ms  → Stats fully visible ✓
400ms  → Play button bounce complete ✓
```

### Hover Exit (Total: ~300ms)
```
0ms    → Card scales back to 1.0 (250ms)
0ms    → Stats slide down (300ms)
0ms    → Play button disappears (immediate)
0ms    → Like button fades out (200ms, if not liked)
0ms    → Shadows fade (200ms)
200ms  → Like button hidden ✓ (unless liked)
250ms  → Card back to normal scale ✓
300ms  → Stats fully hidden ✓
```

---

## 🎨 Design Specifications

### Colors
- **Primary Color**: Gold (`#FFD700` or theme primary)
- **Secondary Color**: Dark background (`#1A1A1A` or theme secondary)
- **Text Color**: White (`#FFFFFF`)
- **Subtitle Color**: White 90% opacity (`#E6E6E6`)
- **Border (default)**: White 5% opacity
- **Border (playing)**: Gold 50% opacity
- **Shadow (hover)**: Gold 25% opacity + Black 30% opacity

### Typography
- **Song Title**: 14px, Weight 700, 0.2 letter spacing, 1.35 line height
- **Artist Name**: 12px, Weight 500, 0.3 letter spacing
- **Badge Text**: 11px, Weight 700, 0.5 letter spacing
- **Stats Text**: 11px, Weight 600, 0.3 letter spacing

### Spacing
- **Card width**: 170px
- **Card margin-right**: 16px
- **Border radius**: 20px
- **Title padding**: 6px horizontal
- **Badge padding**: 10px horizontal, 5px vertical
- **Stats padding**: 10px horizontal, 8px vertical

### Shadows
**Default State:**
```css
box-shadow: 0px 2px 8px -2px rgba(0,0,0,0.2)
```

**Hover State:**
```css
box-shadow: 
  0px 8px 24px 0px rgba(255,215,0,0.25),  /* Gold glow */
  0px 4px 16px -2px rgba(0,0,0,0.3)       /* Depth */
```

---

## 📱 Interaction Feedback

### Haptic Feedback Map
| Action | Haptic Type | Intensity |
|--------|-------------|-----------|
| Tap card | `lightImpact()` | Light |
| Tap play button | `mediumImpact()` | Medium |
| Tap like button | `selectionClick()` | Selection |

### Visual Feedback
- **Card tap**: Navigates to player screen with Hero animation
- **Play button tap**: Same as card tap (redundant action)
- **Like button tap**: 
  - Immediate visual change (filled heart)
  - Border color change
  - Shadow glow appears

---

## 🔧 Technical Notes

### Performance Optimizations
- Only hovered card rebuilds (efficient `setState`)
- GPU-accelerated animations (Transform, Opacity)
- Image caching via `CachedNetworkImage`
- Hero animation for smooth transitions

### Responsive Behavior
- Cards maintain 170x170px size (not responsive by width)
- Horizontal scroll on all screen sizes
- Touch devices: Tap to reveal hover state

### Accessibility
- All interactive elements have tap targets
- Icon buttons have semantic labels
- Color contrast meets WCAG AA standards
- Haptic feedback provides non-visual confirmation

---

## 💡 Design Principles Applied

1. **Progressive Disclosure**: Info shown only when needed
2. **Micro-interactions**: Delightful details (elastic bounce)
3. **Depth & Hierarchy**: Shadows create elevation
4. **Consistency**: Same pattern across all cards
5. **Feedback Loop**: Visual + haptic + state changes
6. **Performance First**: Smooth 60fps animations
7. **Premium Aesthetic**: Gradients, blur, glow effects

---

## 🎯 Key Differentiators

What makes these cards special:

✨ **Elastic play button** - Not just fade, but bouncy entrance  
✨ **Sliding stats** - Not just opacity, animated position  
✨ **Smart like button** - Context-aware visibility  
✨ **Glassmorphism** - Modern blur effect on stats  
✨ **Multi-layer shadows** - Proper depth perception  
✨ **Haptic feedback** - Tactile experience  
✨ **Gradient buttons** - Premium gold-to-orange  
✨ **Dual animation curves** - Cubic + elastic mixing  

---

## 📊 Comparison Matrix

| Feature | Before | After |
|---------|--------|-------|
| Card Size | 160x160 | 170x170 |
| Border Radius | 16px | 20px |
| Stats Visibility | Always | On hover |
| Like Button | Always | Smart (hover/liked) |
| Play Button | Fade in | Elastic bounce |
| Animation Curves | Linear | Cubic + Elastic |
| Shadow Layers | 1 | 2 (gold + black) |
| Haptic Feedback | None | 3 types |
| Glassmorphism | No | Yes (stats bar) |
| Now Playing | Badge only | Badge + border |
| Typography | Basic | Enhanced spacing |

---

## 🚀 Usage Example

```dart
// Card automatically handles all states
_buildSongCard(song, index, songQueue)

// States managed internally:
// - isHovered (via MouseRegion)
// - isLiked (via musicService)
// - isCurrentSong (via musicService)

// No additional props needed!
```

---

## ✅ Checklist for Testing

When testing, verify:

- [ ] Card scales smoothly on hover
- [ ] Stats slide up from bottom (not fade in place)
- [ ] Play button bounces with elastic effect
- [ ] Like button hides when not hovered (unless liked)
- [ ] Like button always visible on liked songs
- [ ] Haptic feedback on all taps (mobile)
- [ ] Now Playing badge shows on current song
- [ ] Gold border appears on playing song
- [ ] Shadows enhance on hover
- [ ] Hero animation works to player screen
- [ ] Stats show correct formatted numbers
- [ ] All animations are smooth (60fps)
- [ ] No visual glitches or jank

---

## 🎨 Color Theme Integration

The design uses theme colors:
- `primaryColor` - Gold accents, gradients, glows
- `secondaryColor` - Dark backgrounds, badges
- `textColor` - White text, titles
- `subtitleColor` - Gray text, artists
- `cardColor` - Fallback backgrounds

All colors auto-adapt if theme changes!
