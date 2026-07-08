# ✅ Testing Checklist - UI/UX Improvements

## Quick Start
Run these commands first:
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

---

## 1. Recently Played Section

### Basic Functionality
- [ ] Open app - No recently played section visible (first time)
- [ ] Play any song from home/discover/library
- [ ] Navigate back to home screen
- [ ] **VERIFY**: "Recently Played" section appears
- [ ] **VERIFY**: Song you just played is visible
- [ ] **VERIFY**: Album art, title, and artist display correctly
- [ ] **VERIFY**: Section subtitle shows "Pick up where you left off"

### Multiple Songs
- [ ] Play a second different song
- [ ] Go back to home
- [ ] **VERIFY**: Second song appears FIRST in list
- [ ] **VERIFY**: First song is still visible (second position)
- [ ] Play 5 more songs
- [ ] **VERIFY**: Most recent song always appears first
- [ ] **VERIFY**: All songs display with correct data

### Persistence
- [ ] Play several songs
- [ ] Close app completely
- [ ] Reopen app
- [ ] Navigate to home
- [ ] **VERIFY**: Recently played songs still visible
- [ ] **VERIFY**: Order is preserved (newest first)

### Interaction
- [ ] Tap on any song in recently played
- [ ] **VERIFY**: Song starts playing
- [ ] **VERIFY**: Mini player appears
- [ ] Tap heart icon on a recently played song
- [ ] **VERIFY**: Heart fills/unfills
- [ ] **VERIFY**: Like status persists

### Edge Cases
- [ ] Clear app data (if possible)
- [ ] Open app
- [ ] **VERIFY**: No recently played section visible (clean state)
- [ ] Play exactly 1 song
- [ ] **VERIFY**: Section shows with just 1 song
- [ ] Play 25 songs (more than limit)
- [ ] **VERIFY**: Only last 20 songs show

---

## 2. Shimmer Loaders

### Initial Load
- [ ] Clear app cache (Settings → Clear Cache if available)
- [ ] Restart app
- [ ] **VERIFY**: Shimmer animations appear on load
- [ ] **VERIFY**: Shimmer has smooth wave animation
- [ ] **VERIFY**: Cards have proper shape (rounded corners)
- [ ] **VERIFY**: Shimmer eventually replaces with real content

### Song Card Shimmers
- [ ] Observe loading song cards
- [ ] **VERIFY**: Album art placeholder shimmers
- [ ] **VERIFY**: Title text placeholder shimmers
- [ ] **VERIFY**: Artist text placeholder shimmers
- [ ] **VERIFY**: Sizing matches real cards
- [ ] **VERIFY**: Spacing between cards is correct

### Artist Card Shimmers
- [ ] Observe loading artist cards
- [ ] **VERIFY**: Circular avatar placeholder shimmers
- [ ] **VERIFY**: Name placeholder shimmers
- [ ] **VERIFY**: Circle shape is perfect (not oval)

### Playlist Card Shimmers
- [ ] Observe loading playlist cards
- [ ] **VERIFY**: Cover image placeholder shimmers
- [ ] **VERIFY**: Title placeholder shimmers
- [ ] **VERIFY**: Description placeholder shimmers
- [ ] **VERIFY**: Card height matches real playlists

### News Card Shimmers
- [ ] Scroll to News section
- [ ] **VERIFY**: Banner placeholder shimmers
- [ ] **VERIFY**: Title lines shimmer
- [ ] **VERIFY**: Card maintains aspect ratio

### Animation Quality
- [ ] Watch shimmer animations
- [ ] **VERIFY**: No janky/stuttering animation
- [ ] **VERIFY**: Smooth wave from left to right
- [ ] **VERIFY**: Consistent timing across all loaders
- [ ] **VERIFY**: No flickering or glitches

---

## 3. Scroll Fade Indicators

### Recently Played Section
- [ ] Navigate to Recently Played section
- [ ] **VERIFY**: Right side has subtle fade gradient
- [ ] **VERIFY**: Left side has NO fade (at start position)
- [ ] Scroll right slowly
- [ ] **VERIFY**: Left fade appears gradually
- [ ] **VERIFY**: Right fade still visible
- [ ] Scroll to middle
- [ ] **VERIFY**: Both fades visible
- [ ] Scroll to end
- [ ] **VERIFY**: Only left fade visible
- [ ] **VERIFY**: Right fade gone

### Fade Visual Quality
- [ ] Observe fade gradients closely
- [ ] **VERIFY**: Smooth gradient (no harsh lines)
- [ ] **VERIFY**: Fade width is ~40px
- [ ] **VERIFY**: Matches background color
- [ ] **VERIFY**: Doesn't block content visibility

### Touch Interaction
- [ ] Tap on a card near fade area
- [ ] **VERIFY**: Card responds (fade doesn't block touches)
- [ ] Swipe from fade area
- [ ] **VERIFY**: Scrolling works normally
- [ ] **VERIFY**: No interaction issues

---

## 4. Section Subtitles

### Recently Played
- [ ] View Recently Played section title
- [ ] **VERIFY**: Main title shows "Recently Played" with icon
- [ ] **VERIFY**: Subtitle shows "Pick up where you left off"
- [ ] **VERIFY**: Subtitle is gray/muted color
- [ ] **VERIFY**: Subtitle is left-aligned with title
- [ ] **VERIFY**: Proper spacing between title and subtitle (4px)

### Text Styling
- [ ] Check subtitle text appearance
- [ ] **VERIFY**: Font size smaller than title (~14px)
- [ ] **VERIFY**: Font weight is regular (not bold)
- [ ] **VERIFY**: Color is subtitleColor (white70)
- [ ] **VERIFY**: Readable and not too faint

---

## 5. Integration Testing

### With Music Service
- [ ] Play a song
- [ ] **VERIFY**: Song appears in recently played
- [ ] Pause song
- [ ] Play different song
- [ ] **VERIFY**: Both songs in recently played (newest first)
- [ ] **VERIFY**: Currently playing song has special indicator

### With Like System
- [ ] Go to recently played
- [ ] Like a song (heart icon)
- [ ] **VERIFY**: Heart fills immediately
- [ ] Navigate away and back
- [ ] **VERIFY**: Heart still filled
- [ ] Unlike the song
- [ ] **VERIFY**: Heart empties immediately

### With Navigation
- [ ] Play a song from Recently Played
- [ ] **VERIFY**: Player screen opens
- [ ] Go back
- [ ] **VERIFY**: Still on home screen
- [ ] Navigate to Discover tab
- [ ] Play a song
- [ ] Go to Home tab
- [ ] **VERIFY**: New song in Recently Played

---

## 6. Performance Testing

### Scrolling Performance
- [ ] Scroll through home feed rapidly
- [ ] **VERIFY**: No lag or stuttering
- [ ] **VERIFY**: Smooth 60fps scrolling
- [ ] Scroll recently played horizontally
- [ ] **VERIFY**: Smooth scrolling
- [ ] **VERIFY**: No frame drops

### Memory Usage
- [ ] Play 20 songs to fill recently played
- [ ] **VERIFY**: App doesn't slow down
- [ ] **VERIFY**: No memory warnings in console
- [ ] Close and reopen app
- [ ] **VERIFY**: Fast startup time

### Loading Times
- [ ] Cold start app
- [ ] **VERIFY**: Home loads within 2 seconds
- [ ] **VERIFY**: Shimmers show immediately
- [ ] **VERIFY**: Content appears smoothly

---

## 7. Visual Polish

### Consistency
- [ ] Compare shimmer colors across sections
- [ ] **VERIFY**: All use same baseColor and highlightColor
- [ ] Compare card sizes
- [ ] **VERIFY**: Song cards are consistent size
- [ ] Compare spacing
- [ ] **VERIFY**: Uniform margins and padding

### Alignment
- [ ] Check section titles
- [ ] **VERIFY**: All titles align to left edge (20px padding)
- [ ] **VERIFY**: All subtitles align with titles
- [ ] **VERIFY**: Icons align with text properly

### Colors
- [ ] Verify color scheme
- [ ] **VERIFY**: Primary color used for highlights (#FFD600)
- [ ] **VERIFY**: Background color consistent (#121212)
- [ ] **VERIFY**: Card color consistent (#1A1A1A)
- [ ] **VERIFY**: Text colors readable

---

## 8. Edge Cases

### Empty States
- [ ] Fresh install (no data)
- [ ] **VERIFY**: No recently played section (hidden)
- [ ] **VERIFY**: No "0 songs" message
- [ ] **VERIFY**: Other sections still visible

### Network Issues
- [ ] Enable airplane mode
- [ ] Open app
- [ ] **VERIFY**: Cached recently played still shows
- [ ] **VERIFY**: Shimmer shows for network content
- [ ] **VERIFY**: App doesn't crash

### Rapid Actions
- [ ] Rapidly play/pause multiple songs
- [ ] **VERIFY**: Recently played updates correctly
- [ ] **VERIFY**: No duplicate entries
- [ ] **VERIFY**: No UI glitches

### Long Content
- [ ] Play song with very long title (30+ chars)
- [ ] **VERIFY**: Title truncates with ellipsis
- [ ] **VERIFY**: Card doesn't overflow
- [ ] Play song with long artist name
- [ ] **VERIFY**: Artist name handles properly

---

## 9. Cross-Browser Testing (Web)

### Chrome
- [ ] Test all features in Chrome
- [ ] **VERIFY**: Everything works
- [ ] **VERIFY**: Smooth animations

### Firefox
- [ ] Test all features in Firefox
- [ ] **VERIFY**: Everything works
- [ ] **VERIFY**: Shimmers animate correctly

### Safari
- [ ] Test all features in Safari
- [ ] **VERIFY**: Everything works
- [ ] **VERIFY**: Fade gradients render correctly

---

## 10. Accessibility

### Screen Reader (Optional)
- [ ] Enable screen reader
- [ ] Navigate to Recently Played
- [ ] **VERIFY**: Section title announced
- [ ] **VERIFY**: Songs can be selected
- [ ] **VERIFY**: Actions are accessible

### Keyboard Navigation (Optional)
- [ ] Try tabbing through interface
- [ ] **VERIFY**: Focus indicators visible
- [ ] **VERIFY**: Can activate songs with Enter

---

## ✅ Pass Criteria

**All Checkboxes Above Should Be Checked**

Minimum for approval:
- ✅ Recently Played shows and updates correctly
- ✅ Shimmers animate smoothly
- ✅ Fade indicators visible and work
- ✅ No crashes or major bugs
- ✅ Performance is acceptable (no lag)

---

## 🐛 Reporting Issues

If you find a bug, note:
1. **What you did** (steps to reproduce)
2. **What happened** (actual result)
3. **What you expected** (expected result)
4. **Console errors** (if any)
5. **Browser/device** (environment)

Example:
```
ISSUE: Recently played doesn't update

Steps:
1. Played song "Test Song"
2. Went to Home tab
3. No recently played section visible

Expected: Section should show with "Test Song"
Actual: Section not visible at all
Console: "Provider.of() called with a context that does not contain a RecentService"
Browser: Chrome 120, Windows 11
```

---

## 📊 Testing Results Template

```
Date: _______________
Tester: _______________
Environment: _______________

Recently Played: ☐ PASS  ☐ FAIL
Shimmer Loaders: ☐ PASS  ☐ FAIL
Scroll Indicators: ☐ PASS  ☐ FAIL
Section Subtitles: ☐ PASS  ☐ FAIL
Integration: ☐ PASS  ☐ FAIL
Performance: ☐ PASS  ☐ FAIL
Visual Polish: ☐ PASS  ☐ FAIL
Edge Cases: ☐ PASS  ☐ FAIL

Overall: ☐ APPROVED  ☐ NEEDS WORK

Notes:
_________________________________
_________________________________
_________________________________
```

---

**Good luck testing! 🚀**
