// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';

/// Flutter code sample for [MatrixTransition].

void main() => runApp(const MatrixTransitionExampleApp());

class MatrixTransitionExampleApp extends StatelessWidget {
  const MatrixTransitionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MatrixTransitionExample());
  }
}

class MatrixTransitionExample extends StatefulWidget {
  const MatrixTransitionExample({super.key});

  @override
  State<MatrixTransitionExample> createState() => _MatrixTransitionExampleState();
}

class _MatrixTransitionExampleState extends State<MatrixTransitionExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _turns;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
    _turns = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: MatrixTransition(
          animation: _turns,
          onTransform: (double value) {
            return Matrix4.identity()
              ..setEntry(3, 2, 0.004)
              ..rotateY(pi * 2.0 * value);
          },
          child: const Padding(padding: EdgeInsets.all(8.0), child: FlutterLogo(size: 150.0)),
        ),
      ),
    );
  }
}
