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

class PositionedTransitionExample extends StatelessWidget {
  const PositionedTransitionExample({super.key});

  @override
  Widget build(BuildContext context) {
    const double smallLogo = 100;
    const double bigLogo = 200;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size biggest = constraints.biggest;
        return RepeatingTweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          reverse: true,
          builder: (BuildContext context, Animation<double> animation, Widget? child) {
            return Stack(
              children: <Widget>[
                PositionedTransition(
                  rect: RelativeRectTween(
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
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.elasticInOut)),
                  child: child!,
                ),
              ],
            );
          },
          child: const Padding(padding: EdgeInsets.all(8), child: FlutterLogo()),
        );
      },
    );
  }
}
