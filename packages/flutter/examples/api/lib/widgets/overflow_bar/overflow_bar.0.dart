// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [OverflowBar].

void main() => runApp(const OverflowBarExampleApp());

class OverflowBarExampleApp extends StatelessWidget {
  const OverflowBarExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('OverflowBar Sample')),
        body: const Center(child: OverflowBarExample()),
      ),
    );
  }
}

class OverflowBarExample extends StatelessWidget {
  const OverflowBarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: .center,
      padding: const .all(16),
      color: Colors.black.withValues(alpha: 0.15),
      child: Material(
        color: Colors.white,
        elevation: 24,
        shape: const RoundedRectangleBorder(
          borderRadius: .all(Radius.circular(4)),
        ),
        child: Padding(
          padding: const .all(8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              children: <Widget>[
                const SizedBox(height: 128, child: Placeholder()),
                Align(
                  alignment: .centerEnd,
                  child: OverflowBar(
                    spacing: 8,
                    overflowAlignment: .end,
                    children: <Widget>[
                      TextButton(child: const Text('Cancel'), onPressed: () {}),
                      TextButton(
                        child: const Text('Really Really Cancel'),
                        onPressed: () {},
                      ),
                      OutlinedButton(child: const Text('OK'), onPressed: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
