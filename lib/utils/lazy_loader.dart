import 'dart:async';
import 'package:flutter/material.dart';

/// A utility class to handle lazy loading of content sections
/// Loads content only when it becomes visible in the viewport
class LazyLoader {
  final Map<String, bool> _loadedSections = {};
  final Map<String, VoidCallback> _loadCallbacks = {};

  /// Register a section with its load callback
  void registerSection(String sectionId, VoidCallback onLoad) {
    _loadCallbacks[sectionId] = onLoad;
    _loadedSections[sectionId] = false;
  }

  /// Check if a section has been loaded
  bool isLoaded(String sectionId) {
    return _loadedSections[sectionId] ?? false;
  }

  /// Trigger loading for a section
  void loadSection(String sectionId) {
    if (!isLoaded(sectionId)) {
      _loadedSections[sectionId] = true;
      _loadCallbacks[sectionId]?.call();
    }
  }

  /// Reset all sections (useful for refresh)
  void reset() {
    _loadedSections.clear();
  }

  /// Dispose and clear all callbacks
  void dispose() {
    _loadedSections.clear();
    _loadCallbacks.clear();
  }
}

/// A widget that loads its content only when visible in the viewport
class LazyLoadSection extends StatefulWidget {
  final String sectionId;
  final Widget Function(BuildContext) builder;
  final Widget placeholder;
  final double threshold;
  final VoidCallback? onLoad;

  const LazyLoadSection({
    Key? key,
    required this.sectionId,
    required this.builder,
    required this.placeholder,
    this.threshold = 200.0,
    this.onLoad,
  }) : super(key: key);

  @override
  State<LazyLoadSection> createState() => _LazyLoadSectionState();
}

class _LazyLoadSectionState extends State<LazyLoadSection> {
  bool _isVisible = false;
  bool _hasLoaded = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.sectionId),
      threshold: widget.threshold,
      onVisibilityChanged: (visible) {
        if (visible && !_hasLoaded) {
          setState(() {
            _isVisible = true;
            _hasLoaded = true;
          });
          widget.onLoad?.call();
        }
      },
      child: _isVisible ? widget.builder(context) : widget.placeholder,
    );
  }
}

/// A simple visibility detector widget
class VisibilityDetector extends StatefulWidget {
  final Key key;
  final Widget child;
  final double threshold;
  final Function(bool) onVisibilityChanged;

  const VisibilityDetector({
    required this.key,
    required this.child,
    required this.threshold,
    required this.onVisibilityChanged,
  }) : super(key: key);

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;

    // Check if widget is within viewport + threshold
    final isVisible = position.dy < screenHeight + widget.threshold &&
        position.dy + size.height > -widget.threshold;

    widget.onVisibilityChanged(isVisible);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Batch loader for multiple sections
class BatchLoader {
  final List<Future<void> Function()> _tasks = [];
  bool _isLoading = false;

  /// Add a task to the batch
  void addTask(Future<void> Function() task) {
    _tasks.add(task);
  }

  /// Execute all tasks in parallel with a limit
  Future<void> executeBatch({int concurrency = 3}) async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      // Split tasks into batches
      for (var i = 0; i < _tasks.length; i += concurrency) {
        final batch = _tasks.skip(i).take(concurrency);
        await Future.wait(batch.map((task) => task()));
      }
    } finally {
      _isLoading = false;
      _tasks.clear();
    }
  }

  /// Check if currently loading
  bool get isLoading => _isLoading;
}

/// Priority queue for loading tasks
enum LoadPriority { high, medium, low }

class PriorityLoader {
  final Map<LoadPriority, List<Future<void> Function()>> _queues = {
    LoadPriority.high: [],
    LoadPriority.medium: [],
    LoadPriority.low: [],
  };

  bool _isProcessing = false;

  /// Add a task with priority
  void addTask(Future<void> Function() task, LoadPriority priority) {
    _queues[priority]?.add(task);
  }

  /// Process all tasks by priority
  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Process high priority first
      await _processPriority(LoadPriority.high);
      // Then medium
      await _processPriority(LoadPriority.medium);
      // Finally low
      await _processPriority(LoadPriority.low);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processPriority(LoadPriority priority) async {
    final tasks = _queues[priority] ?? [];
    if (tasks.isEmpty) return;

    await Future.wait(tasks.map((task) => task()));
    tasks.clear();
  }

  /// Clear all queues
  void clear() {
    _queues.values.forEach((queue) => queue.clear());
  }
}

/// Debouncer for load events
class LoadDebouncer {
  final Duration delay;
  Timer? _timer;

  LoadDebouncer({this.delay = const Duration(milliseconds: 300)});

  /// Debounce a callback
  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  /// Cancel pending callback
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose
  void dispose() {
    _timer?.cancel();
  }
}

/// Helper class for managing loading states
class LoadingStateManager extends ChangeNotifier {
  final Map<String, bool> _loadingStates = {};
  final Map<String, dynamic> _errors = {};

  /// Set loading state for a section
  void setLoading(String sectionId, bool isLoading) {
    _loadingStates[sectionId] = isLoading;
    if (isLoading) {
      _errors.remove(sectionId);
    }
    notifyListeners();
  }

  /// Set error for a section
  void setError(String sectionId, dynamic error) {
    _errors[sectionId] = error;
    _loadingStates[sectionId] = false;
    notifyListeners();
  }

  /// Clear error for a section
  void clearError(String sectionId) {
    _errors.remove(sectionId);
    notifyListeners();
  }

  /// Check if section is loading
  bool isLoading(String sectionId) {
    return _loadingStates[sectionId] ?? false;
  }

  /// Get error for section
  dynamic getError(String sectionId) {
    return _errors[sectionId];
  }

  /// Check if section has error
  bool hasError(String sectionId) {
    return _errors.containsKey(sectionId);
  }

  /// Reset all states
  void reset() {
    _loadingStates.clear();
    _errors.clear();
    notifyListeners();
  }
}
