// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

/// Flutter code sample for [State.dispose].

void main() {
  runApp(const StateDisposeExampleApp());
}

class StateDisposeExampleApp extends StatelessWidget {
  const StateDisposeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFFFFFFF),
      // WidgetsApp does not install a [DefaultTextStyle], so without this the
      // labels below fall back to a style with no color and are invisible
      // against the white background.
      textStyle: const TextStyle(color: Color(0xFF000000), fontSize: 14.0),
      builder: (BuildContext context, Widget? child) {
        return const ColoredBox(
          color: Color(0xFFFFFFFF),
          child: Center(child: CountDisplayControls()),
        );
      },
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
        _Button(
          onPressed: _showCount
              ? () {
                  // Passes a new stream to CountDisplay, which calls
                  // didUpdateWidget on its State.
                  setState(() {
                    _counts = _createCounts();
                  });
                }
              : null,
          label: 'Restart',
        ),
        _Button(
          onPressed: () {
            setState(() {
              // Removing CountDisplay calls dispose on its State.
              _showCount = !_showCount;
              if (_showCount) {
                // A stream created by Stream.periodic can only be listened
                // to once, so a new one is needed when CountDisplay is shown
                // again.
                _counts = _createCounts();
              }
            });
          },
          label: _showCount ? 'Remove counter' : 'Show counter',
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
      setState(() {
        _count = count;
      });
    });
  }

  @override
  void dispose() {
    // Starts the cancellation without waiting for it to complete. The
    // subscription stops delivering events as soon as cancel() is called, so
    // setState is never called after this State is unmounted.
    unawaited(_subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('Count: $_count');
  }
}

/// A simple button built from widgets in the widgets library.
///
/// The button is disabled when [onPressed] is null.
class _Button extends StatelessWidget {
  const _Button({required this.onPressed, required this.label});

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFF2196F3) : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: enabled
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFF9E9E9E),
            ),
          ),
        ),
      ),
    );
  }
}
