// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [DecoratedBoxTransition].

void main() => runApp(const DecoratedBoxTransitionExampleApp());

class DecoratedBoxTransitionExampleApp extends StatelessWidget {
  const DecoratedBoxTransitionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: DecoratedBoxTransitionExample());
  }
}

class DecoratedBoxTransitionExample extends StatefulWidget {
  const DecoratedBoxTransitionExample({super.key});

  @override
  State<DecoratedBoxTransitionExample> createState() => _DecoratedBoxTransitionExampleState();
}

class _DecoratedBoxTransitionExampleState extends State<DecoratedBoxTransitionExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Decoration> _decoration;

  static final DecorationTween _decorationTween = DecorationTween(
    begin: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      border: Border.all(style: BorderStyle.none),
      borderRadius: BorderRadius.circular(60.0),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x66666666),
          blurRadius: 10.0,
          spreadRadius: 3.0,
          offset: Offset(0, 6.0),
        ),
      ],
    ),
    end: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      border: Border.all(style: BorderStyle.none),
      borderRadius: BorderRadius.zero,
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 3), vsync: this)
      ..repeat(reverse: true);
    _decoration = _decorationTween.animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: DecoratedBoxTransition(
          decoration: _decoration,
          child: Container(
            width: 200,
            height: 200,
            padding: const EdgeInsets.all(10),
            child: const FlutterLogo(),
          ),
        ),
      ),
    );
  }
}
