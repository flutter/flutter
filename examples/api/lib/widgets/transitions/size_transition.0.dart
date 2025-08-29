// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [SizeTransition].

void main() => runApp(const SizeTransitionExampleApp());

class SizeTransitionExampleApp extends StatelessWidget {
  const SizeTransitionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SizeTransitionExample());
  }
}

class SizeTransitionExample extends StatelessWidget {
  const SizeTransitionExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepeatingTweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(seconds: 3),
        curve: Curves.fastOutSlowIn,
        builder: (BuildContext context, Animation<double> animation, Widget? child) {
          return SizeTransition(
            sizeFactor: animation,
            axis: Axis.horizontal,
            axisAlignment: -1,
            child: child,
          );
        },
        child: const Center(child: FlutterLogo(size: 200.0)),
      ),
    );
  }
}
