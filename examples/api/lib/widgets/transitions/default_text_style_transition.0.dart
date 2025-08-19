// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [DefaultTextStyleTransition].

void main() => runApp(const DefaultTextStyleTransitionExampleApp());

class DefaultTextStyleTransitionExampleApp extends StatelessWidget {
  const DefaultTextStyleTransitionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: DefaultTextStyleTransitionExample());
  }
}

class DefaultTextStyleTransitionExample extends StatelessWidget {
  const DefaultTextStyleTransitionExample({super.key});

  @override
  Widget build(BuildContext context) {
    final styleTween = TextStyleTween(
      begin: const TextStyle(fontSize: 50, color: Colors.blue, fontWeight: FontWeight.w900),
      end: const TextStyle(fontSize: 50, color: Colors.red, fontWeight: FontWeight.w100),
    );

    return Center(
      child: TweenAnimationBuilder<double>.repeat(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 2),
        reverse: true,
        builder: (context, value, child) {
          final curvedValue = Curves.elasticInOut.transform(value);
          return DefaultTextStyleTransition(
            style: styleTween.animate(AlwaysStoppedAnimation<double>(curvedValue)),
            child: const Text('Flutter'),
          );
        },
      ),
    );
  }
}
