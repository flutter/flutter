// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [PositionedTransition].

void main() => runApp(const PositionedTransitionExampleApp());

class PositionedTransitionExampleApp extends StatelessWidget {
  const PositionedTransitionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: PositionedTransitionExample());
  }
}

class PositionedTransitionExample extends StatefulWidget {
  const PositionedTransitionExample({super.key});

  @override
  State<PositionedTransitionExample> createState() => _PositionedTransitionExampleState();
}

class _PositionedTransitionExampleState extends State<PositionedTransitionExample>
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
        final Animation<RelativeRect> rectAnimation =
            RelativeRectTween(
                  begin: RelativeRect.fromSize(
                    const Rect.fromLTWH(0, 0, smallLogo, smallLogo),
                    biggest,
                  ),
                  end: RelativeRect.fromSize(
                    Rect.fromLTWH(
                      biggest.width - bigLogo,
                      biggest.height - bigLogo,
                      bigLogo,
                      bigLogo,
                    ),
                    biggest,
                  ),
                ).animate(_curve)
                as Animation<RelativeRect>;

        return Stack(
          children: <Widget>[
            PositionedTransition(
              rect: rectAnimation,
              child: const Padding(padding: EdgeInsets.all(8), child: FlutterLogo()),
            ),
          ],
        );
      },
    );
  }
}
