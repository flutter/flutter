// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [ValueUpdater].

void main() => runApp(const ToggleValueWithNotifierExampleApp());

class ToggleValueWithNotifierExampleApp extends StatelessWidget {
  const ToggleValueWithNotifierExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ToggleValueWithNotifierExample(),
    );
  }
}

class ToggleValueWithNotifierExample extends StatelessWidget {
  ToggleValueWithNotifierExample({super.key});

  final ValueNotifier<AlignmentGeometry> _notifier = ValueNotifier<AlignmentGeometry>(Alignment.bottomLeft);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: ColoredBox(
            color: Colors.white,
            child: ValueUpdater<AlignmentGeometry>(
              initialValue: Alignment.center,
              valueNotifier: _notifier,
              builder: (BuildContext context, AlignmentGeometry value) {
                return AnimatedAlign(
                  alignment: value,
                  duration: const Duration(seconds: 1),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: FlutterLogo(size: 100.0),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              _notifier.value = switch(_notifier.value) {
                Alignment.topLeft=> Alignment.topRight,
                Alignment.topRight=> Alignment.bottomRight,
                Alignment.bottomRight=> Alignment.bottomLeft,
                Alignment.bottomLeft=> Alignment.topLeft,
                _ => Alignment.topRight,
              };
            },
            child: const Text('Change'),
          ),
        ),
      ],
    );
  }
}
