// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

/// Flutter code sample for [State.dispose].

void main() {
  runApp(const StateDisposeExampleApp());
}

class StateDisposeExampleApp extends StatelessWidget {
  const StateDisposeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: CountDisplayControls())),
    );
  }
}

/// Shows a [CountDisplay] along with buttons that give it a new stream or
/// remove it from the tree.
class CountDisplayControls extends StatefulWidget {
  const CountDisplayControls({super.key});

  @override
  State<CountDisplayControls> createState() => _CountDisplayControlsState();
}

class _CountDisplayControlsState extends State<CountDisplayControls> {
  Stream<int> _counts = _createCounts();
  bool _showCount = true;

  static Stream<int> _createCounts() {
    return Stream<int>.periodic(const Duration(seconds: 1), (int i) => i + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: <Widget>[
        if (_showCount)
          CountDisplay(counts: _counts)
        else
          const Text('Counter removed'),
        ElevatedButton(
          onPressed: _showCount
              ? () {
                  // Passes a new stream to CountDisplay, which calls
                  // didUpdateWidget on its State.
                  setState(() {
                    _counts = _createCounts();
                  });
                }
              : null,
          child: const Text('Restart'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              // Removing CountDisplay calls dispose on its State. A stream
              // created by Stream.periodic can only be listened to once, so
              // a new one is created for when it is shown again.
              _showCount = !_showCount;
              _counts = _createCounts();
            });
          },
          child: Text(_showCount ? 'Remove counter' : 'Show counter'),
        ),
      ],
    );
  }
}

/// Displays the latest value emitted by [counts].
class CountDisplay extends StatefulWidget {
  const CountDisplay({super.key, required this.counts});

  final Stream<int> counts;

  @override
  State<CountDisplay> createState() => _CountDisplayState();
}

class _CountDisplayState extends State<CountDisplay> {
  late StreamSubscription<int> _subscription;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(CountDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.counts != oldWidget.counts) {
      unawaited(_subscription.cancel());
      _count = 0;
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = widget.counts.listen((int count) {
      if (mounted) {
        setState(() {
          _count = count;
        });
      }
    });
  }

  @override
  void dispose() {
    // Starts the cancellation without waiting for it to complete.
    unawaited(_subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('Count: $_count');
  }
}
