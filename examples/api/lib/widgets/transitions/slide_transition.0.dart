// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [SlideTransition].

void main() => runApp(const SlideTransitionExampleApp());

class SlideTransitionExampleApp extends StatelessWidget {
  const SlideTransitionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('SlideTransition Sample')),
        body: const Center(child: SlideTransitionExample()),
      ),
    );
  }
}

class SlideTransitionExample extends StatefulWidget {
  const SlideTransitionExample({super.key});

  @override
  State<SlideTransitionExample> createState() => _SlideTransitionExampleState();
}

class _SlideTransitionExampleState extends State<SlideTransitionExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat(reverse: true);
  final _positionTween = Tween<Offset>(
    begin: .zero,
    end: const Offset(1.5, 0.0),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _positionTween
          .chain(CurveTween(curve: Curves.elasticIn))
          .animate(_controller),
      child: const Padding(padding: .all(8.0), child: FlutterLogo(size: 150.0)),
    );
  }
}
