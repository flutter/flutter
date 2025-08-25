// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [RotationTransition].

void main() => runApp(const RotationTransitionExampleApp());

class RotationTransitionExampleApp extends StatelessWidget {
  const RotationTransitionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: RotationTransitionExample());
  }
}

class RotationTransitionExample extends StatelessWidget {
  const RotationTransitionExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RepeatingTweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          curve: Curves.elasticOut,
          reverse: true,
          builder: (BuildContext context, Animation<double> animation, Widget? child) {
            return RotationTransition(turns: animation, child: child);
          },
          child: const Padding(padding: EdgeInsets.all(8.0), child: FlutterLogo(size: 150.0)),
        ),
      ),
    );
  }
}
