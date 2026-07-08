import 'package:flutter/material.dart';

// Minimal stubs for on_audio_query API used in the app so non-Android builds compile.

class SongModel {
  final int id;
  final String title;
  final String? artist;
  final int? duration; // milliseconds
  final String? uri;

  SongModel({required this.id, required this.title, this.artist, this.duration, this.uri});
}

class OnAudioQuery {
  Future<List<SongModel>> querySongs({
	dynamic sortType,
	dynamic orderType,
	dynamic uriType,
	bool? ignoreCase,
  }) async {
	// Return empty list on platforms where on_audio_query isn't available.
	return <SongModel>[];
  }
}

// Enums and constants used by original code
class SongSortType {
  static const TITLE = 0;
}

class OrderType {
  static const ASC_OR_SMALLER = 0;
}

class UriType {
  static const EXTERNAL = 0;
}

class ArtworkType {
  static const AUDIO = 0;
}

class QueryArtworkWidget extends StatelessWidget {
  final int id;
  final int type;
  final BorderRadius? artworkBorder;
  final Widget nullArtworkWidget;
  final double size;
  final int quality;
  final BoxFit artworkFit;

  const QueryArtworkWidget({
	Key? key,
	required this.id,
	required this.type,
	this.artworkBorder,
	required this.nullArtworkWidget,
	this.size = 100,
	this.quality = 100,
	this.artworkFit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
	// On non-Android platforms, return the provided nullArtworkWidget
	return SizedBox(
	  width: size,
	  height: size,
	  child: ClipRRect(borderRadius: artworkBorder ?? BorderRadius.zero, child: nullArtworkWidget),
	);
  }
}
