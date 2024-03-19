// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [AlignTransition].

void main() => runApp(const ToggleValueExampleApp());

class ToggleValueExampleApp extends StatelessWidget {
  const ToggleValueExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ToggleValueExample(),
    );
  }
}

class ToggleValueExample extends StatelessWidget {
  const ToggleValueExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: ToggleValue<AlignmentGeometry>(
        offValue: Alignment.bottomLeft,
        onValue: Alignment.topRight,
        builder: (BuildContext context, AlignmentGeometry value) {
          return AnimatedAlign(
            alignment: value,
            duration: const Duration(seconds: 1),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: FlutterLogo(size: 150.0),
            ),
          );
        },
      ),
    );
  }
}
