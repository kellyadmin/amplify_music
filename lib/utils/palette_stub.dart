import 'package:flutter/material.dart';

// Minimal stub for palette_generator.PaletteGenerator used in song_detail_screen.
class PaletteColor {
  final Color color;
  PaletteColor(this.color);
}

class PaletteGenerator {
  final PaletteColor? dominantColor;
  PaletteGenerator({this.dominantColor});

  static Future<PaletteGenerator> fromImageProvider(ImageProvider provider, {Size? size}) async {
	// Return a default palette generator with null dominantColor to fall back to defaults
	return PaletteGenerator(dominantColor: null);
  }
}
