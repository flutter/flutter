// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [AnimatedSwitcher].

void main() => runApp(const AnimatedSwitcherExampleApp());

class AnimatedSwitcherExampleApp extends StatelessWidget {
  const AnimatedSwitcherExampleApp({super.key});

  static const Duration duration = Duration(microseconds: 500);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AnimatedSwitcherExample(duration: duration),
    );
  }
}

class AnimatedSwitcherExample extends StatefulWidget {
  const AnimatedSwitcherExample({
    super.key,
    required this.duration,
  });

  final Duration duration;

  @override
  State<AnimatedSwitcherExample> createState() =>
      _AnimatedSwitcherExampleState();
}

class _AnimatedSwitcherExampleState extends State<AnimatedSwitcherExample> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedSwitcher(
            duration: widget.duration,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Text(
              '$_count',
              // This key causes the AnimatedSwitcher to interpret this as a "new"
              // child each time the count changes, so that it will begin its animation
              // when the count changes.
              key: ValueKey<int>(_count),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          ElevatedButton(
            child: const Text('Increment'),
            onPressed: () {
              setState(() {
                _count += 1;
              });
            },
          ),
        ],
      ),
    );
  }
}
