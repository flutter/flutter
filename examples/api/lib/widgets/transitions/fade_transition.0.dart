// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [FadeTransition].

void main() => runApp(const FadeTransitionExampleApp());

class FadeTransitionExampleApp extends StatelessWidget {
  const FadeTransitionExampleApp({super.key});

  static const Duration duration = Duration(seconds: 2);
  static const Curve curve = Curves.easeIn;

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FadeTransitionExample(duration: duration, curve: curve),
    );
  }
}

class FadeTransitionExample extends StatelessWidget {
  const FadeTransitionExample({required this.duration, required this.curve, super.key});

  final Duration duration;

  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: RepeatingTweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: duration,
        reverse: true,
        builder: (BuildContext context, Animation<double> animation, Widget? child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: AlwaysStoppedAnimation<double>(animation.value),
              curve: curve,
            ),
            child: child,
          );
        },
        child: const Padding(padding: EdgeInsets.all(8), child: FlutterLogo()),
      ),
    );
  }
}
