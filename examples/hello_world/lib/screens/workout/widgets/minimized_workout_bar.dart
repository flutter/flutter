import 'dart:async';

import 'package:flutter/material.dart';

class MinimizedWorkoutBar extends StatefulWidget {
  const MinimizedWorkoutBar({
    required this.startedAt,
    required this.exerciseCount,
    required this.onOpen,
    required this.onFinish,
    super.key,
  });

  final DateTime startedAt;
  final int exerciseCount;
  final VoidCallback onOpen;
  final VoidCallback onFinish;

  @override
  State<MinimizedWorkoutBar> createState() => _MinimizedWorkoutBarState();
}

class _MinimizedWorkoutBarState extends State<MinimizedWorkoutBar> {
  Timer? _ticker;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _syncElapsed();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _syncElapsed());
  }

  @override
  void didUpdateWidget(covariant MinimizedWorkoutBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt) {
      _syncElapsed();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncElapsed() {
    if (!mounted) {
      return;
    }
    setState(() {
      _elapsedSeconds = DateTime.now().difference(widget.startedAt).inSeconds;
    });
  }

  String _formatElapsed() {
    final int minutes = _elapsedSeconds ~/ 60;
    final int seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: widget.onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              const Icon(Icons.fitness_center),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Workout i gang • ${_formatElapsed()}', style: Theme.of(context).textTheme.labelLarge),
                    Text('${widget.exerciseCount} øvelser', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              TextButton(onPressed: widget.onFinish, child: const Text('Afslut')),
            ],
          ),
        ),
      ),
    );
  }
}
