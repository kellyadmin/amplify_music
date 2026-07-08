import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────────────
// Viba Music — "Midnight Luxe" palette
// A vibrant, premium dark theme with warm gold gradients + multi-accent
// energy. Distinct from Spotify (green), Boomplay (lime/red), Audiomack
// (orange), Apple Music (pink). The deep zinc-black backgrounds pair
// with sunset-gold gradients for luxury, while hot-pink, vivid-purple,
// and mint-green accents inject life and vibrancy across the UI.
// ──────────────────────────────────────────────────────────────────────

// ── Brand Primary (sunset gold gradient) ─────────────────────────────
const Color primaryColor = Color(0xFFFFB347); // Warm Gold
const Color primaryGradientStart = Color(0xFFFFB347); // Warm Gold
const Color primaryGradientEnd = Color(0xFFFF6B35); // Vibrant Orange
const Color premiumGold = Color(0xFFD4A017); // Rich Gold — VIP badges

// ── Vibrant Accents (Enhanced Saturation) ────────────────────────────
const Color accentColor = Color(0xFFFF1493); // Vivid Hot Pink — likes/CTA/energy
const Color accentPurple = Color(0xFF9333EA); // Electric Purple — premium/AI
const Color accentMint = Color(0xFF00E5B8); // Neon Mint — success/play
const Color accentYellow = Color(0xFFFFE500); // Bright Electric Yellow — progress
const Color neonBlue = Color(0xFF00D9FF); // Cyan Neon — notifications/info
const Color neonCoral = Color(0xFFFF6B9D); // Neon Coral — secondary accent
const Color electricLime = Color(0xFFCCFF00); // Electric Lime — energy boost

// ── Surfaces (zinc-based, clear hierarchy) ───────────────────────────
const Color backgroundColor = Color(0xFF09090B); // Zinc-950 — deepest bg
const Color secondaryColor = backgroundColor;
const Color cardColor = Color(0xFF18181B); // Zinc-900 — card level 1
const Color surfaceElevated = Color(0xFF27272A); // Zinc-800 — card level 2
const Color surfaceGlass = Color.fromRGBO(255, 255, 255, 0.06); // Frosted tint
const Color surfaceGlassSolid = Color(0xFF3F3F46); // Zinc-700 — solid glass
const Color cardBorderColor = Color(0xFF3F3F46); // Zinc-700 — card borders

// ── Text ─────────────────────────────────────────────────────────────
const Color textColor = Color(0xFFFAFAFA); // Zinc-50 — primary text
const Color subtitleColor = Color(0xFFA1A1AA); // Zinc-400 — secondary text
const Color textDisabledColor = Color(0xFF71717A); // Zinc-500 — disabled

// ── Semantic ─────────────────────────────────────────────────────────
const Color errorColor = Color(0xFFFF2D55); // Error/danger red
const Color successColor = Color(0xFF06D6A0); // Mint success
const Color warningColor = Color(0xFFFFDD00); // Electric warning

// ── Action Sheet / Icon Accents ──────────────────────────────────────
const Color actionBlue = Color(0xFF60A5FA);
const Color actionGreen = Color(0xFF34D399);
const Color actionAmber = Color(0xFFF59E0B);
const Color actionPurple = Color(0xFFA78BFA);
const Color actionCoral = Color(0xFFFF6B6B);

// ── Social Brand Colors ──────────────────────────────────────────────
const Color googleBlue = Color(0xFF4285F4);
const Color whatsappGreen = Color(0xFF25D366);
const Color facebookBlue = Color(0xFF1877F2);

// ── Enhanced Vibrant Gradients ───────────────────────────────────────
const LinearGradient brandGradient = LinearGradient(
  colors: [Color(0xFFFFB347), Color(0xFFFF6B35), Color(0xFFFF1493)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient premiumGradient = LinearGradient(
  colors: [Color(0xFF9333EA), Color(0xFFC026D3), Color(0xFFFF1493)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient playerGradient = LinearGradient(
  colors: [Color(0xFFFFE500), Color(0xFFFFB347), Color(0xFFFF6B35)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient actionGradient = LinearGradient(
  colors: [Color(0xFFFF1493), Color(0xFFFF6B35), Color(0xFFFFB347)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient mintGradient = LinearGradient(
  colors: [Color(0xFF00E5B8), Color(0xFF00D9FF), Color(0xFF9333EA)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient surfaceGradient = LinearGradient(
  colors: [Color(0xFF27272A), Color(0xFF18181B), Color(0xFF09090B)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const LinearGradient navBarGradient = LinearGradient(
  colors: [Color(0xFF18181B), Color(0xFF09090B)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

// ── New Vibrant Gradients ────────────────────────────────────────────
const LinearGradient neonGradient = LinearGradient(
  colors: [Color(0xFF00D9FF), Color(0xFF9333EA), Color(0xFFFF1493)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient sunsetGradient = LinearGradient(
  colors: [Color(0xFFFF6B35), Color(0xFFFFB347), Color(0xFFFFE500)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient electricGradient = LinearGradient(
  colors: [Color(0xFFCCFF00), Color(0xFF00E5B8), Color(0xFF00D9FF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient cosmicGradient = LinearGradient(
  colors: [Color(0xFF9333EA), Color(0xFF00D9FF), Color(0xFF00E5B8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient fireGradient = LinearGradient(
  colors: [Color(0xFFFF1493), Color(0xFFFF6B35), Color(0xFFFFE500)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── Enhanced Glow / Shadow Presets ───────────────────────────────────
List<BoxShadow> primaryGlow({double opacity = 0.5, double blur = 20}) => [
  BoxShadow(
    color: primaryColor.withOpacity(opacity),
    blurRadius: blur,
    spreadRadius: 2,
  ),
  BoxShadow(
    color: primaryColor.withOpacity(opacity * 0.5),
    blurRadius: blur * 1.5,
    spreadRadius: 4,
  ),
];

List<BoxShadow> accentGlow({double opacity = 0.45, double blur = 18}) => [
  BoxShadow(
    color: accentColor.withOpacity(opacity),
    blurRadius: blur,
    spreadRadius: 2,
  ),
  BoxShadow(
    color: accentColor.withOpacity(opacity * 0.5),
    blurRadius: blur * 1.5,
    spreadRadius: 4,
  ),
];

List<BoxShadow> mintGlow({double opacity = 0.45, double blur = 18}) => [
  BoxShadow(
    color: accentMint.withOpacity(opacity),
    blurRadius: blur,
    spreadRadius: 2,
  ),
  BoxShadow(
    color: accentMint.withOpacity(opacity * 0.5),
    blurRadius: blur * 1.5,
    spreadRadius: 4,
  ),
];

List<BoxShadow> purpleGlow({double opacity = 0.45, double blur = 18}) => [
  BoxShadow(
    color: accentPurple.withOpacity(opacity),
    blurRadius: blur,
    spreadRadius: 2,
  ),
  BoxShadow(
    color: accentPurple.withOpacity(opacity * 0.5),
    blurRadius: blur * 1.5,
    spreadRadius: 4,
  ),
];

List<BoxShadow> neonGlow({double opacity = 0.5, double blur = 22}) => [
  BoxShadow(
    color: neonBlue.withOpacity(opacity),
    blurRadius: blur,
    spreadRadius: 2,
  ),
  BoxShadow(
    color: neonBlue.withOpacity(opacity * 0.4),
    blurRadius: blur * 1.8,
    spreadRadius: 5,
  ),
];

List<BoxShadow> multiColorGlow({double opacity = 0.4, double blur = 20}) => [
  BoxShadow(
    color: accentColor.withOpacity(opacity),
    blurRadius: blur,
    spreadRadius: 1,
  ),
  BoxShadow(
    color: accentPurple.withOpacity(opacity * 0.8),
    blurRadius: blur * 1.2,
    spreadRadius: 2,
  ),
  BoxShadow(
    color: accentMint.withOpacity(opacity * 0.6),
    blurRadius: blur * 1.5,
    spreadRadius: 3,
  ),
];

// Spacing system
const double spacingXs = 4;
const double spacingSm = 8;
const double spacingMd = 12;
const double spacingLg = 16;
const double spacingXl = 20;
const double spacingXxl = 24;
const double spacingSection = 30;
const double spacingSectionLg = 35;

// Section bottom margins
const double sectionBottomMargin = 30;

// Typography sizes
const double headingXl = 26;
const double headingLg = 20;
const double headingMd = 18;
const double headingSm = 16;
const double bodyLg = 15;
const double bodyMd = 14;
const double bodySm = 13;
const double caption = 12;
const double captionSm = 11;
const double captionXs = 10;

// Layout
const double songCardWidth = 168;
const double artistCardWidth = 110;
const double newsCardWidth = 250;

TextStyle homeFont({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = textColor,
  double? letterSpacing,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );
}
