// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [PageView.shrinkWrapCrossAxis].

void main() => runApp(const ShrinkWrapCrossAxisExampleApp());

class ShrinkWrapCrossAxisExampleApp extends StatelessWidget {
  const ShrinkWrapCrossAxisExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('PageView shrinkWrapCrossAxis')),
        body: const ShrinkWrapCrossAxisExample(),
      ),
    );
  }
}

class ShrinkWrapCrossAxisExample extends StatelessWidget {
  const ShrinkWrapCrossAxisExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'The PageView below adapts its height to the current page.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          PageView(
            shrinkWrapCrossAxis: true,
            children: const <Widget>[
              _PageContent(
                color: Colors.blue,
                height: 100,
                label: 'Page 1 — Short (100)',
              ),
              _PageContent(
                color: Colors.orange,
                height: 250,
                label: 'Page 2 — Medium (250)',
              ),
              _PageContent(
                color: Colors.green,
                height: 400,
                label: 'Page 3 — Tall (400)',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('← Swipe to see the height change →'),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.color,
    required this.height,
    required this.label,
  });

  final Color color;
  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Card(
        color: color.withValues(alpha: 0.2),
        child: Center(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    );
  }
}
