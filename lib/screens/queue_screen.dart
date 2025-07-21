import 'package:flutter/material.dart';
import '../models.dart';

class QueueScreen extends StatefulWidget {
  final List<Song> queue;
  final Function(List<Song>) onReorder;

  const QueueScreen({
    Key? key,
    required this.queue,
    required this.onReorder,
  }) : super(key: key);

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  late List<Song> _queue;

  @override
  void initState() {
    super.initState();
    _queue = List.from(widget.queue);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final song = _queue.removeAt(oldIndex);
      _queue.insert(newIndex, song);
      widget.onReorder(_queue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Up Next'),
        backgroundColor: const Color(0xFF121212),
      ),
      backgroundColor: const Color(0xFF121212),
      body: ReorderableListView.builder(
        itemCount: _queue.length,
        onReorder: _onReorder,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final song = _queue[index];
          return Dismissible(
            key: ValueKey(song.url),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              setState(() {
                _queue.removeAt(index);
                widget.onReorder(_queue);
              });
            },
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: song.albumArtUrl != null
                    ? Image.asset(song.albumArtUrl!, width: 50, height: 50, fit: BoxFit.cover)
                    : const SizedBox(width: 50, height: 50),
              ),
              title: Text(song.title, style: const TextStyle(color: Colors.white)),
              subtitle: Text(song.artist, style: const TextStyle(color: Colors.white70)),
              trailing: const Icon(Icons.drag_handle, color: Colors.white54),
            ),
          );
        },
      ),
    );
  }
}
