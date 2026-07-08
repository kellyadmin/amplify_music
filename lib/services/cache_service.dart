// lib/services/cache_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Import your models. Make sure their toMap() methods are implemented!
import '../models.dart';
import '../widgets/home/home_banners_section.dart';

/// A service class to handle all local file-based caching for the application.
class CacheService {
  /// The duration after which cached data is considered stale and should be refreshed.
  static const Duration cacheDuration = Duration(hours: 1);

  /// A helper function to get the local application directory for storing files.
  ///
  /// For mobile platforms, this returns the directory for storing persistent data.
  /// For web, it returns `null` as file system access is not standard.
  Future<String?> _getCacheDirectory() async {
    if (kIsWeb) {
      return null;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } catch (e) {
      debugPrint('Error getting cache directory: $e');
      return null;
    }
  }

  /// Saves a list of items to a file in the local cache.
  ///
  /// The `items` list must contain objects that have a `toMap()` method
  /// (e.g., `Song`, `Artist`, `BannerItem`). The method serializes the list
  /// to JSON and stores it with a timestamp.
  Future<void> saveToCache<T>(List<T> items, String fileName) async {
    final dirPath = await _getCacheDirectory();
    if (dirPath == null) {
      return;
    }

    final file = File('$dirPath/$fileName');

    try {
      final List<Map<String, dynamic>> jsonList = [];
      for (var item in items) {
        if (item is Song) {
          jsonList.add(item.toMap());
        } else if (item is Artist) {
          jsonList.add(item.toMap());
        } else if (item is BannerItem) {
          jsonList.add(item.toMap());
        }
        // You can add other model types here if you need to cache them
      }

      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': jsonList,
      };

      await file.writeAsString(jsonEncode(data));
      debugPrint('✅ Data saved to cache: $fileName');
    } catch (e) {
      debugPrint('❌ Error saving to cache: $e');
    }
  }

  /// Loads a list of items from a file in the local cache.
  ///
  /// This method retrieves cached data, checks its timestamp for freshness,
  /// and deserializes it back into a list of objects using the provided `fromMap`
  /// factory. Returns `null` if the cache is stale or an error occurs.
  Future<List<T>?> loadFromCache<T>(String fileName, T Function(Map<String, dynamic>) fromMap) async {
    final dirPath = await _getCacheDirectory();
    if (dirPath == null) {
      return null;
    }

    final file = File('$dirPath/$fileName');

    if (await file.exists()) {
      try {
        final String contents = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(contents);

        final DateTime timestamp = DateTime.parse(data['timestamp']);

        // Check if cache has expired
        if (DateTime.now().difference(timestamp) > cacheDuration) {
          debugPrint('⚠️ Cache for $fileName is stale, refreshing...');
          return null;
        }

        final List<dynamic> jsonList = data['data'];
        final List<T> items = jsonList.map((item) => fromMap(item as Map<String, dynamic>)).toList();
        debugPrint('📦 Data loaded from cache: $fileName');
        return items;
      } catch (e) {
        debugPrint('❌ Error loading from cache: $e');
        return null;
      }
    }
    return null;
  }
}
