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

class SlideTransitionExample extends StatelessWidget {
  const SlideTransitionExample({super.key});

  @override
  Widget build(BuildContext context) {
    return RepeatingTweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      reverse: true,
      curve: Curves.elasticIn,
      builder: (BuildContext context, Animation<double> animation, Widget? child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(1.5, 0.0),
          ).animate(animation),
          child: child,
        );
      },
      child: const Padding(padding: EdgeInsets.all(8.0), child: FlutterLogo(size: 150.0)),
    );
  }
}
