// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Flutter code sample for [RepeatingTweenAnimationBuilder].

void main() => runApp(const RepeatingTweenAnimationBuilderExampleApp());

class RepeatingTweenAnimationBuilderExampleApp extends StatelessWidget {
  const RepeatingTweenAnimationBuilderExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: RepeatingTweenAnimationBuilderExample());
  }
}

class RepeatingTweenAnimationBuilderExample extends StatefulWidget {
  const RepeatingTweenAnimationBuilderExample({super.key});

  @override
  State<RepeatingTweenAnimationBuilderExample> createState() =>
      _RepeatingTweenAnimationBuilderExampleState();
}

class _RepeatingTweenAnimationBuilderExampleState
    extends State<RepeatingTweenAnimationBuilderExample> {
  bool _isPaused = false;
  bool _isReversed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RepeatingTweenAnimationBuilder Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RepeatingTweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              paused: _isPaused,
              reverse: _isReversed,
              builder: (BuildContext context, Animation<double> animation, Widget? child) {
                return Transform.rotate(angle: math.pi * animation.value * 2, child: child);
              },
              child: Container(width: 100, height: 100, color: Colors.green),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isPaused = !_isPaused;
                    });
                  },
                  child: Text(_isPaused ? 'Resume' : 'Pause'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isReversed = !_isReversed;
                    });
                  },
                  child: Text(_isReversed ? 'Forward Only' : 'Reverse'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
