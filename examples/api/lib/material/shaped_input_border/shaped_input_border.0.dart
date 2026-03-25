// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [ShapedInputBorder].

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ShapedInputBorder Sample')),
        body: const ShapedInputBorderExample(),
      ),
    );
  }
}

class ShapedInputBorderExample extends StatelessWidget {
  const ShapedInputBorderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Superellipse border (iOS-style)
            TextField(
              decoration: InputDecoration(
                labelText: 'Superellipse Border',
                hintText: 'iOS-style smooth border',
                border: ShapedInputBorder(
                  shape: const RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                  ),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.0,
                  ),
                ),
                enabledBorder: ShapedInputBorder(
                  shape: const RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                  ),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                focusedBorder: ShapedInputBorder(
                  shape: const RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                  ),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Stadium border
            TextField(
              decoration: InputDecoration(
                labelText: 'Stadium Border',
                hintText: 'Pill-shaped border',
                border: ShapedInputBorder(
                  shape: const StadiumBorder(),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Beveled border
            const TextField(
              decoration: InputDecoration(
                labelText: 'Beveled Border',
                hintText: 'Angular beveled corners',
                border: ShapedInputBorder(
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Filled with custom shape
            TextField(
              decoration: InputDecoration(
                labelText: 'Filled with Superellipse',
                hintText: 'Filled background',
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                border: const ShapedInputBorder(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
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
