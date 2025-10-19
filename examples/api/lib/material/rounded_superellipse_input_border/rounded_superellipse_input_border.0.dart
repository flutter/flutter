// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [RoundedSuperellipseInputBorder].

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('RoundedSuperellipseInputBorder Sample')),
        body: const RoundedSuperellipseInputBorderExample(),
      ),
    );
  }
}

class RoundedSuperellipseInputBorderExample extends StatelessWidget {
  const RoundedSuperellipseInputBorderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                labelText: 'Rounded Superellipse Border',
                hintText: 'Enter text',
                border: RoundedSuperellipseInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                ),
                enabledBorder: RoundedSuperellipseInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                focusedBorder: RoundedSuperellipseInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                labelText: 'Filled with Superellipse Border',
                hintText: 'Enter text',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: const RoundedSuperellipseInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Custom Radius',
                hintText: 'Different corner radii',
                border: RoundedSuperellipseInputBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(24.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
