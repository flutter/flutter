// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [BorderSide].

import 'package:flutter/material.dart';

void main() => runApp(const BorderSideApp());

class BorderSideApp extends StatelessWidget {
  const BorderSideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: BorderSideExample());
  }
}

class BorderSideExample extends StatefulWidget {
  const BorderSideExample({super.key});

  @override
  State<BorderSideExample> createState() => _BorderSideExampleState();
}

class _BorderSideExampleState extends State<BorderSideExample>
    with TickerProviderStateMixin {
  late final AnimationController animation;

  @override
  void initState() {
    super.initState();
    animation =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    animation.repeat(reverse: true);
    animation.addListener(_markDirty);
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  void _markDirty() {
    setState(() {});
  }

  static const double borderWidth = 10;
  static const double cornerRadius = 10;
  static const Color borderColor = Color(0x8000b4fc);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            TestBox(
              shape: StadiumBorder(
                side: BorderSide(
                  color: borderColor,
                  width: borderWidth,
                  strokeAlign: (animation.value * 2) - 1,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                TestBox(
                  shape: CircleBorder(
                    side: BorderSide(
                      color: borderColor,
                      width: borderWidth,
                      strokeAlign: (animation.value * 2) - 1,
                    ),
                  ),
                ),
                TestBox(
                  shape: OvalBorder(
                    side: BorderSide(
                      color: borderColor,
                      width: borderWidth,
                      strokeAlign: (animation.value * 2) - 1,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                TestBox(
                  shape: BeveledRectangleBorder(
                    side: BorderSide(
                      color: borderColor,
                      width: borderWidth,
                      strokeAlign: (animation.value * 2) - 1,
                    ),
                  ),
                ),
                TestBox(
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    side: BorderSide(
                      color: borderColor,
                      width: borderWidth,
                      strokeAlign: (animation.value * 2) - 1,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                TestBox(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: borderColor,
                      width: borderWidth,
                      strokeAlign: (animation.value * 2) - 1,
                    ),
                  ),
                ),
                TestBox(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    side: BorderSide(
                      color: borderColor,
                      width: borderWidth,
                      strokeAlign: (animation.value * 2) - 1,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                TestBox(
                  shape: StarBorder(
                    side: BorderSide(
                      color: borderColor,
                      width: borderWidth,
                      strokeAlign: (animation.value * 2) - 1,
                    ),
                  ),
                ),
                TestBox(
                  shape: StarBorder(
                    pointRounding: 1,
                    innerRadiusRatio: 0.5,
                    points: 8,
                    side: BorderSide(
                      color: borderColor,
                      width: borderWidth,
                      strokeAlign: (animation.value * 2) - 1,
                    ),
                  ),
                ),
                TestBox(
                  shape: StarBorder.polygon(
                    sides: 6,
                    pointRounding: 0.5,
                    side: BorderSide(
                      color: borderColor,
                      width: borderWidth,
                      strokeAlign: (animation.value * 2) - 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TestBox extends StatelessWidget {
  const TestBox({
    super.key,
    required this.shape,
  });

  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 50,
      decoration: ShapeDecoration(
        color: const Color(0xff012677),
        shape: shape,
      ),
    );
  }
}
