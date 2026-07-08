# Premium Design Quick Reference

## 🎨 Color Palette

```
PRIMARY COLORS:
├─ Gold:        #FFD700 (Primary accent)
├─ Dark BG:     #0A0E27 (Main background)
└─ Card BG:     #1A1A1A (Card background)

ACCENT COLORS:
├─ Purple:      #6366F1 (Secondary accent)
├─ Pink:        #EC4899 (Tertiary accent)
└─ Green:       #10B981 (Success/positive)

TEXT COLORS:
├─ Primary:     #FFFFFF (Main text)
├─ Secondary:   #B0B0B0 (Secondary text)
└─ Tertiary:    #808080 (Tertiary text)
```

## 📐 Spacing Scale

```
xs:   4px   (minimal spacing)
sm:   8px   (small spacing)
md:   12px  (medium spacing)
lg:   16px  (standard spacing)
xl:   24px  (large spacing)
xxl:  32px  (extra large spacing)
```

## 🔤 Typography

```
HEADINGS (Poppins):
├─ H1: 32px, Bold (700),    Letter-spacing: 0.5px
├─ H2: 24px, Bold (700),    Letter-spacing: 0.3px
└─ H3: 20px, Semi-bold (600), Letter-spacing: 0.2px

BODY (Inter):
├─ Large:  16px, Medium (500), Line-height: 1.5
├─ Normal: 14px, Regular (400), Line-height: 1.4
└─ Small:  12px, Regular (400), Line-height: 1.3

SPECIAL:
├─ Button: 16px, Semi-bold (600), Letter-spacing: 0.5px
└─ Caption: 12px, Regular (400), Color: white70
```

## ⏱️ Animation Timings

```
QUICK:      150ms  (feedback, hover)
STANDARD:   300ms  (transitions, opens)
SLOW:       500ms  (complex animations)
VERY SLOW:  800ms  (entrance animations)

CURVES:
├─ easeOut:      Quick start, slow end
├─ easeInOut:    Smooth both ways
├─ fastOutSlowIn: Material standard
└─ bouncy:       Playful feel
```

## 🎯 Component Sizes

```
BUTTONS:
├─ Small:   32px height, 12px padding
├─ Medium:  44px height, 16px padding
└─ Large:   56px height, 20px padding

CARDS:
├─ Small:   160x160px
├─ Medium:  200x200px
└─ Large:   280x280px

IMAGES:
├─ Thumbnail: 56x56px
├─ Small:     100x100px
├─ Medium:    160x160px
└─ Large:     280x280px
```

## 🌟 Glassmorphism Recipe

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.08),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withOpacity(0.15),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 20,
        spreadRadius: 5,
      ),
    ],
  ),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: YourContent(),
  ),
)
```

## 🎬 Animation Recipes

### Fade In
```dart
FadeTransition(
  opacity: Tween<double>(begin: 0, end: 1).animate(controller),
  child: YourWidget(),
)
```

### Slide In
```dart
SlideTransition(
  position: Tween<Offset>(
    begin: Offset(0, 0.3),
    end: Offset.zero,
  ).animate(controller),
  child: YourWidget(),
)
```

### Scale
```dart
ScaleTransition(
  scale: Tween<double>(begin: 0.8, end: 1).animate(controller),
  child: YourWidget(),
)
```

### Rotate
```dart
RotationTransition(
  turns: Tween<double>(begin: 0, end: 1).animate(controller),
  child: YourWidget(),
)
```

## 🖼️ Image Overlay Gradient

```dart
Stack(
  children: [
    Image(),
    Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black54,
            Colors.black87,
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
    ),
  ],
)
```

## 🎨 Gradient Backgrounds

### Dark Gradient
```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF0A0E27),
    Color(0xFF1A1F3A),
    Color(0xFF0A0E27),
  ],
)
```

### Gold Accent
```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFFD700),
    Color(0xFFFFA500),
  ],
)
```

### Purple Accent
```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ],
)
```

## 🔘 Button Styles

### Primary Button
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFFFD700),
    foregroundColor: Color(0xFF0A0E27),
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  ),
  child: Text('Button', style: PremiumTextStyles.button),
)
```

### Secondary Button
```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: Color(0xFFFFD700), width: 2),
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  ),
  child: Text('Button'),
)
```

## 📱 Responsive Breakpoints

```
MOBILE:    < 600px
TABLET:    600px - 1200px
DESKTOP:   > 1200px

PADDING:
├─ Mobile:  16px
├─ Tablet:  24px
└─ Desktop: 32px
```

## 🎯 Shadow System

### Elevation 1 (Subtle)
```dart
BoxShadow(
  color: Colors.black.withOpacity(0.1),
  blurRadius: 4,
  offset: Offset(0, 2),
)
```

### Elevation 2 (Medium)
```dart
BoxShadow(
  color: Colors.black.withOpacity(0.15),
  blurRadius: 12,
  offset: Offset(0, 4),
)
```

### Elevation 3 (Strong)
```dart
BoxShadow(
  color: Colors.black.withOpacity(0.2),
  blurRadius: 20,
  offset: Offset(0, 8),
)
```

## 🎪 Border Radius

```
SMALL:    8px   (buttons, small cards)
MEDIUM:   12px  (cards, inputs)
LARGE:    16px  (large cards)
XLARGE:   20px  (glassmorphic cards)
CIRCLE:   50%   (avatars, badges)
```

## 🔍 Hover States

```dart
MouseRegion(
  onEnter: (_) => setState(() => _isHovering = true),
  onExit: (_) => setState(() => _isHovering = false),
  child: AnimatedContainer(
    duration: Duration(milliseconds: 200),
    color: _isHovering ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.08),
    child: YourContent(),
  ),
)
```

## 📊 Opacity Scale

```
FULL:       1.0   (100% opaque)
HIGH:       0.87  (87% opaque)
MEDIUM:     0.6   (60% opaque)
LOW:        0.38  (38% opaque)
VERY LOW:   0.12  (12% opaque)
DISABLED:   0.5   (50% opaque)
```

## 🎬 Stagger Animation

```dart
for (int i = 0; i < items.length; i++) {
  Future.delayed(
    Duration(milliseconds: i * 100),
    () => controllers[i].forward(),
  );
}
```

## 🌈 Color Combinations

### Gold + Purple
```
Primary:   #FFD700 (Gold)
Secondary: #6366F1 (Purple)
Accent:    #EC4899 (Pink)
```

### Gold + Green
```
Primary:   #FFD700 (Gold)
Secondary: #10B981 (Green)
Accent:    #6366F1 (Purple)
```

### Gold + Pink
```
Primary:   #FFD700 (Gold)
Secondary: #EC4899 (Pink)
Accent:    #6366F1 (Purple)
```

## ✅ Quality Checklist

- [ ] 60fps animations
- [ ] Consistent spacing
- [ ] Proper typography hierarchy
- [ ] Accessible colors (WCAG AA)
- [ ] Responsive design
- [ ] Touch-friendly (min 44px)
- [ ] Proper error states
- [ ] Loading states
- [ ] Empty states
- [ ] Hover states (web)

## 🚀 Performance Tips

1. Use `const` constructors
2. Use `RepaintBoundary` for complex widgets
3. Lazy load images
4. Profile with DevTools
5. Test on low-end devices
6. Use `shouldRebuild` wisely
7. Avoid rebuilding entire trees
8. Use `SingleChildScrollView` sparingly

## 📚 File Structure

```
lib/
├─ utils/
│  ├─ gradients.dart
│  ├─ text_styles.dart
│  └─ constants.dart
├─ widgets/
│  ├─ premium_card.dart
│  ├─ staggered_list.dart
│  ├─ animated_scroll_view.dart
│  └─ shimmer_loading.dart
└─ screens/
   └─ home_screen.dart
```

---

## 🎯 Implementation Priority

1. **Glasmorphic Cards** - Highest visual impact
2. **Spacing System** - Foundation for everything
3. **Typography** - Improves readability
4. **Gradients** - Adds depth
5. **Animations** - Brings it to life

---

**Print this page for quick reference while implementing!** 📋
