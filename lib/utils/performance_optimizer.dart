import 'package:flutter/material.dart';
import 'dart:async';

/// Performance optimization utilities for the app
class PerformanceOptimizer {
  /// Preload images to cache
  static Future<void> precacheImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    final futures = imageUrls.map((url) {
      return precacheImage(NetworkImage(url), context).catchError((_) {
        // Silently fail for individual images
        return null;
      });
    });

    await Future.wait(futures);
  }

  /// Batch network requests with delay between batches
  static Future<List<T>> batchRequests<T>({
    required List<Future<T> Function()> requests,
    int batchSize = 3,
    Duration delayBetweenBatches = const Duration(milliseconds: 100),
  }) async {
    final results = <T>[];

    for (var i = 0; i < requests.length; i += batchSize) {
      final batch = requests.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        batch.map((request) => request()),
      );
      results.addAll(batchResults);

      // Add delay between batches to avoid overwhelming the network
      if (i + batchSize < requests.length) {
        await Future.delayed(delayBetweenBatches);
      }
    }

    return results;
  }

  /// Throttle function calls
  static VoidCallback throttle(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 500),
  }) {
    Timer? timer;
    bool canExecute = true;

    return () {
      if (canExecute) {
        callback();
        canExecute = false;
        timer = Timer(duration, () {
          canExecute = true;
        });
      }
    };
  }

  /// Debounce function calls
  static VoidCallback debounce(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    Timer? timer;

    return () {
      timer?.cancel();
      timer = Timer(duration, callback);
    };
  }

  /// Measure widget build time
  static Future<Duration> measureBuildTime(
    Widget Function() builder,
  ) async {
    final stopwatch = Stopwatch()..start();
    builder();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Check if device is low-end
  static bool isLowEndDevice() {
    // This is a simplified check
    // In production, you might want to check actual device specs
    return false; // Implement based on your needs
  }

  /// Optimize list rendering with viewport awareness
  static Widget buildOptimizedList({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    double itemExtent = 80.0,
    ScrollController? controller,
  }) {
    return ListView.builder(
      controller: controller,
      itemCount: itemCount,
      itemExtent: itemExtent,
      itemBuilder: itemBuilder,
      // Add physics for better performance
      physics: const BouncingScrollPhysics(),
      // Cache extent for smoother scrolling
      cacheExtent: 500,
    );
  }

  /// Memory-efficient image loading
  static ImageProvider optimizedImageProvider(
    String url, {
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return NetworkImage(url);
    // In production, use cached_network_image with size constraints
  }

  /// Lazy initialization wrapper
  static T lazyInit<T>(T Function() initializer) {
    T? _instance;
    return _instance ??= initializer();
  }
}

/// Widget performance wrapper
class PerformanceWrapper extends StatelessWidget {
  final Widget child;
  final String label;
  final bool enableProfiling;

  const PerformanceWrapper({
    Key? key,
    required this.child,
    required this.label,
    this.enableProfiling = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!enableProfiling) return child;

    return RepaintBoundary(
      child: child,
    );
  }
}

/// Optimized grid builder
class OptimizedGridView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const OptimizedGridView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      physics: const BouncingScrollPhysics(),
      cacheExtent: 500,
    );
  }
}

/// Memory cache for frequently accessed data
class MemoryCache<K, V> {
  final Map<K, _CacheEntry<V>> _cache = {};
  final int maxSize;
  final Duration ttl;

  MemoryCache({
    this.maxSize = 100,
    this.ttl = const Duration(minutes: 5),
  });

  /// Get value from cache
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.timestamp) > ttl) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  /// Put value in cache
  void put(K key, V value) {
    if (_cache.length >= maxSize) {
      // Remove oldest entry
      final oldestKey = _cache.entries
          .reduce((a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b)
          .key;
      _cache.remove(oldestKey);
    }

    _cache[key] = _CacheEntry(value, DateTime.now());
  }

  /// Clear cache
  void clear() {
    _cache.clear();
  }

  /// Remove specific key
  void remove(K key) {
    _cache.remove(key);
  }

  /// Check if key exists and is valid
  bool contains(K key) {
    return get(key) != null;
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}

/// FPS monitor for debugging
class FPSMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const FPSMonitor({
    Key? key,
    required this.child,
    this.enabled = false,
  }) : super(key: key);

  @override
  State<FPSMonitor> createState() => _FPSMonitorState();
}

class _FPSMonitorState extends State<FPSMonitor> {
  int _frameCount = 0;
  double _fps = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _fps = _frameCount.toDouble();
        _frameCount = 0;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    if (!mounted) return;
    _frameCount++;
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'FPS: ${_fps.toStringAsFixed(1)}',
              style: TextStyle(
                color: _fps >= 55 ? Colors.green : const Color(0xFFE63950),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
