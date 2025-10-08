// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [CircularProgressIndicator].

void main() => runApp(const ProgressIndicatorExampleApp());

class ProgressIndicatorExampleApp extends StatelessWidget {
  const ProgressIndicatorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color(0xff6750a4)),
      home: const ProgressIndicatorExample(),
    );
  }
}

class ProgressIndicatorExample extends StatefulWidget {
  const ProgressIndicatorExample({super.key});

  @override
  State<ProgressIndicatorExample> createState() => _ProgressIndicatorExampleState();
}

class _ProgressIndicatorExampleState extends State<ProgressIndicatorExample> {
  bool determinate = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          spacing: 16.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Circular progress indicator', style: Theme.of(context).textTheme.titleLarge),
            RepeatingTweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              reverse: true,
              paused: determinate,
              builder: (BuildContext context, double value, Widget? child) {
                return CircularProgressIndicator(
                  value: determinate ? value : null,
                  semanticsLabel: 'Circular progress indicator',
                );
              },
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('determinate Mode', style: Theme.of(context).textTheme.titleSmall),
                ),
                Switch(
                  value: determinate,
                  onChanged: (bool value) {
                    setState(() {
                      determinate = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
