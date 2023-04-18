// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Scaffold.of].

void main() => runApp(const OfExampleApp());

class OfExampleApp extends StatelessWidget {
  const OfExampleApp({super.key});

  @override
  Widget build(final BuildContext context) {
    return const MaterialApp(
      home: OfExample(),
    );
  }
}

class OfExample extends StatelessWidget {
  const OfExample({super.key});

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo')),
      body: Builder(
        // Create an inner BuildContext so that the onPressed methods
        // can refer to the Scaffold with Scaffold.of().
        builder: (final BuildContext context) {
          return Center(
            child: ElevatedButton(
              child: const Text('SHOW BOTTOM SHEET'),
              onPressed: () {
                Scaffold.of(context).showBottomSheet<void>(
                  (final BuildContext context) {
                    return Container(
                      alignment: Alignment.center,
                      height: 200,
                      color: Colors.amber,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text('BottomSheet'),
                            ElevatedButton(
                              child: const Text('Close BottomSheet'),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
