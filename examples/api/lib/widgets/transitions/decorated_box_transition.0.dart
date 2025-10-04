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

class DecoratedBoxTransitionExample extends StatelessWidget {
  const DecoratedBoxTransitionExample({super.key});

  @override
  Widget build(BuildContext context) {
    final DecorationTween decorationTween = DecorationTween(
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
        // No shadow.
      ),
    );

    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: RepeatingTweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 3),
          reverse: true,
          builder: (BuildContext context, Animation<double> animation, Widget? child) {
            return DecoratedBoxTransition(
              decoration: decorationTween.animate(AlwaysStoppedAnimation<double>(animation.value)),
              child: child!,
            );
          },
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
