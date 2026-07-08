# Visual Guide - All New Features

## 1. ENHANCED SEARCH BAR

### Default State (Inactive)
```
┌─────────────────────────────────────────┐
│  🔍  Search songs, artists...           │ ✕
└─────────────────────────────────────────┘
```

### Focused State (Active)
```
╔═════════════════════════════════════════╗  ← Gradient border appears
║  🔍  Search songs, artists...           │ ✕ ← Clear button shows
╚═════════════════════════════════════════╝  ← Shadow effect
```

### With Suggestions
```
╔═════════════════════════════════════════╗
║  🔍  bohemian                           │ ✕
╚═════════════════════════════════════════╝
┌─────────────────────────────────────────┐
│ [img] Bohemian Rhapsody                 │→
│       Queen                             │
├─────────────────────────────────────────┤
│ [img] Bohemian Soul                     │→
│       Stevie Wonder                     │
├─────────────────────────────────────────┤
│ [img] Go Bohemian                       │→
│       Moby                              │
└─────────────────────────────────────────┘
```

### Features:
- ✅ Smooth focus animation
- ✅ Gradient background on focus
- ✅ Primary color border highlight
- ✅ Live suggestions dropdown
- ✅ Album art preview (36x36px)
- ✅ One-tap playback
- ✅ Clear button for quick reset

---

## 2. SECTION DIVIDERS WITH BADGES

### Visual Layout
```
━━━━━━━ (gradient divider line)
▶ Your Daily Recommendations  [Based on your taste]  [See All →]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ Song Card ][ Song Card ][ Song Card ]...
```

### Section Examples

#### 1. Daily Recommendations
```
━━━━━━━
▶ Your Daily Recommendations  [Based on your taste]  [See All →]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### 2. Mood & Activity
```
━━━━━━━
▶ Mood & Activity            [Curated for you]      [See All →]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### 3. Featured Playlists
```
━━━━━━━
▶ Featured Playlists         [Editor's picks]       [See All →]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### 4. Top Charts
```
━━━━━━━
▶ Top Charts                 [Trending globally]    [See All →]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### 5. Emerging Artists
```
━━━━━━━
▶ Emerging Artists           [New talent]           [See All →]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### 6. Featured Artists
```
━━━━━━━
▶ Featured Artists           [Handpicked]           [See All →]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Colors & Styling:
- **Divider:** Gradient from Yellow to Transparent
- **Title:** White, 18px, Bold (800)
- **Badge:** Yellow background, 15% opacity, rounded
- **Badge Text:** Yellow, 11px, Bold (600)
- **Button:** Yellow border, 10% opacity, rounded

---

## 3. SHIMMER LOADING PLACEHOLDERS

### Loading State
```
Row of shimmer cards while loading:

[shimmer] [shimmer] [shimmer]
  ▀▀▀▀▀     ▀▀▀▀▀     ▀▀▀▀▀
 animation animation animation
   ↓↓↓      ↓↓↓       ↓↓↓

Smooth wave effect moving through cards
```

### Transition
```
Before:
[shimmer] [shimmer] [shimmer]

After (content loaded):
[song 1]  [song 2]  [song 3]
```

### Card Appearance:
- **Width:** 170px
- **Height:** 220px
- **Border Radius:** 20px
- **Shimmer Colors:** Dark gray → Lighter gray → Dark gray
- **Animation Speed:** Smooth, continuous loop

---

## 4. EMPTY STATE ILLUSTRATIONS

### No Content Example 1
```
         ╔════════════════╗
         ║      💡       ║
         ║                ║
         ║  No Recs Yet   ║
         ║                ║
         ║ Start exploring║
         ║ songs to get   ║
         ║ personalized   ║
         ║ recommendations║
         ╚════════════════╝
```

### No Content Example 2
```
         ╔════════════════╗
         ║      🔍       ║
         ║                ║
         ║  No Results    ║
         ║                ║
         ║ Try searching  ║
         ║ for songs,     ║
         ║ artists, or    ║
         ║ playlists      ║
         ╚════════════════╝
```

### Component Breakdown:
```
   [Circular container with icon]  ← Primary color background
              ↓
         [Bold Title]
              ↓
      [Subtitle text]
```

- **Icon Container:** 80x80px, centered
- **Icon:** 40px size, primary color
- **Title:** 18px, bold, white
- **Subtitle:** 14px, 80% opacity white
- **Vertical Spacing:** 20px between elements

---

## 5. QUICK ACTIONS FAB MENU

### FAB Button (Normal)
```
                              ⊕
                              ↑
                         (Primary Color)
                         (Bottom Right)
```

### FAB Button (Hover)
```
                              ⊕  ← Enlarged, shadow grows
```

### FAB Menu (Open)
```
Content scrolls up...

                        ┌──────────────────┐
                        │      ⋯⋯⋯         │  ← Handle indicator
                        ├──────────────────┤
                        │  Quick Actions   │  ← Title
                        ├──────────────────┤
                        │ [💖] My Liked    │
                        │     Songs        │  ← Quick action 1
                        ├──────────────────┤
                        │ [📋] Create      │
                        │     Playlist     │  ← Quick action 2
                        ├──────────────────┤
                        │ [⭐] Go Premium  │
                        │                  │  ← Quick action 3
                        ├──────────────────┤
                        │ [📤] Upload Song │
                        │                  │  ← Quick action 4
                        └──────────────────┘
```

### Quick Action Tile (Normal)
```
┌──────────────────────────────────┐
│ [💖] My Liked Songs        [→]   │
│     View your collection          │
└──────────────────────────────────┘
```

### Quick Action Tile (Pressed/Hover)
```
┌──────────────────────────────────┐
│ [💖] My Liked Songs        [→]   │ ← Background color changes
│     View your collection          │ ← Ripple effect shows
└──────────────────────────────────┘
```

### Tile Components:
- **Icon Container:** 48x48px, colored background, rounded
- **Icon:** 24px, primary color
- **Title:** 14px, bold, white
- **Subtitle:** 12px, 80% opacity white
- **Arrow:** 16px, primary color, right-aligned

---

## 6. COMPLETE HOME SCREEN LAYOUT

### Full Screen View
```
┌────────────────────────────────────────┐
│ Header / Logo                          │
├────────────────────────────────────────┤
│ ╔════════════════════════════════════╗ │
│ ║ 🔍 Search songs, artists...       ║ │  ← Enhanced Search Bar
│ ╚════════════════════════════════════╝ │
├────────────────────────────────────────┤
│ [For You] [Top 20] [Trending]...      │  ← Tabs
├────────────────────────────────────────┤
│                                        │
│ ━━━━━ Your Daily Recommendations      │
│ [Badge] [See All →]                   │
│ [ 🎵 ][ 🎵 ][ 🎵 ][ 🎵 ]              │  ← Song Cards
│                                        │
│ ━━━━━ Mood & Activity                 │
│ [Badge] [See All →]                   │
│ [ 🎵 ][ 🎵 ][ 🎵 ][ 🎵 ]              │
│                                        │
│ ━━━━━ Featured Playlists              │
│ [Badge] [See All →]                   │
│ [ 🎵 ][ 🎵 ][ 🎵 ][ 🎵 ]              │
│                                        │
│ ━━━━━ Top Charts                      │
│ [Badge] [See All →]                   │
│ [ 🎵 ][ 🎵 ][ 🎵 ][ 🎵 ]              │
│                                        │
│ ... (scroll to see more)              │
│                                        │
└────────────────────────────────────────┘
                          ⊕ ← Quick Actions FAB
```

---

## 7. USER INTERACTION FLOWS

### Search Flow
```
User taps search bar
        ↓
    [Focus effect]
    [Animation: bar expands]
        ↓
User starts typing "bohemian"
        ↓
    [Suggestions appear below]
    [Shows matching songs]
        ↓
User taps a suggestion
        ↓
    [Song plays]
    [Navigates to player]
    [Search clears]
```

### Section Flow
```
User sees section with divider
        ↓
User taps "See All" button
        ↓
    [Navigation/expand happens]
    [Shows all items in section]
        ↓
User scrolls through content
        ↓
User taps a song to play
```

### FAB Flow
```
User sees yellow FAB button (bottom-right)
        ↓
User taps FAB
        ↓
    [Bottom sheet menu animates up]
    [Shows 4 quick actions]
        ↓
User taps an action
        ↓
    [Sheet closes]
    [Action executes]
```

---

## 8. COLOR REFERENCE

| Element | Color | Use Case |
|---------|-------|----------|
| Primary | #FFD600 | Search bar border, badges, buttons, icons |
| Secondary | #121212 | Background, FAB text |
| Card | #1A1A1A | Card backgrounds, section backgrounds |
| Text | #FFFFFF | Main text |
| Subtitle | #FFFFFF70 | Secondary text, hints |

### Opacity Variations:
- Full: 100% (`Color(0xFFFFD600)`)
- High: 70-80% (`withOpacity(0.7)`)
- Medium: 30-50% (`withOpacity(0.3)`)
- Low: 10-20% (`withOpacity(0.1)`)

---

## 9. RESPONSIVE DESIGN

### Mobile (< 600px width)
```
Full width search bar
Stacked quick actions
Single column layout
```

### Tablet (600-1200px width)
```
Padded search bar (20px)
Side-by-side quick actions
Two-column card layout
```

### Desktop (> 1200px width)
```
Centered search (max-width 600px)
Grid layout for actions
Multi-column card layout
```

### All Platforms:
- **Minimum tap target:** 48px
- **Padding:** 20px horizontal
- **Spacing:** 12-20px vertical

---

## 10. ANIMATION TIMINGS

| Animation | Duration | Curve |
|-----------|----------|-------|
| Search focus | 300ms | ease-out |
| Divider appear | 600ms | ease-out cubic |
| FAB open | 400ms | ease-out |
| Suggestion dropdown | 200ms | linear |
| Shimmer | 1000ms | linear loop |
| Scroll physics | natural | ease |

---

## Summary

All new features work together to create:
- ✅ Better content discovery (search)
- ✅ Clearer organization (dividers)
- ✅ Smoother experience (loaders)
- ✅ Professional appearance (empty states)
- ✅ Quick access (FAB menu)
- ✅ Overall improved UX

---

Last Updated: June 12, 2026
Version: 1.0
