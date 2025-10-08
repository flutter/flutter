// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [RelativePositionedTransition].

void main() => runApp(const RelativePositionedTransitionExampleApp());

class RelativePositionedTransitionExampleApp extends StatelessWidget {
  const RelativePositionedTransitionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: RelativePositionedTransitionExample());
  }
}

class RelativePositionedTransitionExample extends StatefulWidget {
  const RelativePositionedTransitionExample({super.key});

  @override
  State<RelativePositionedTransitionExample> createState() =>
      _RelativePositionedTransitionExampleState();
}

class _RelativePositionedTransitionExampleState extends State<RelativePositionedTransitionExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)
      ..repeat(reverse: true);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.elasticInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double smallLogo = 100;
    const double bigLogo = 200;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size biggest = constraints.biggest;
        final Animation<Rect?> rectAnimation = RectTween(
          begin: const Rect.fromLTWH(0, 0, bigLogo, bigLogo),
          end: Rect.fromLTWH(
            biggest.width - smallLogo,
            biggest.height - smallLogo,
            smallLogo,
            smallLogo,
          ),
        ).animate(_curve);

        return Stack(
          children: <Widget>[
            RelativePositionedTransition(
              size: biggest,
              rect: rectAnimation,
              child: const Padding(padding: EdgeInsets.all(8), child: FlutterLogo()),
            ),
          ],
        );
      },
    );
  }
}
