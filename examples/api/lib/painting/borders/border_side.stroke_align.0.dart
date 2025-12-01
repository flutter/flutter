// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [BorderSide.strokeAlign].

void main() => runApp(const StrokeAlignApp());

class StrokeAlignApp extends StatelessWidget {
  const StrokeAlignApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: StrokeAlignExample());
  }
}

class StrokeAlignExample extends StatelessWidget {
  const StrokeAlignExample({super.key});

  static const double borderWidth = 10;
  static const double cornerRadius = 10;
  static const Color borderColor = Color(0x8000b4fc);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: RepeatingAnimationBuilder<double>(
          animatable: Tween<double>(begin: -1.0, end: 1.0),
          duration: const Duration(seconds: 1),
          repeatMode: RepeatMode.reverse,
          builder: (BuildContext context, double strokeAlign, Widget? child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                BorderedBox(
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: borderColor,
                      width: borderWidth,
                      strokeAlign: strokeAlign,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    BorderedBox(
                      shape: CircleBorder(
                        side: BorderSide(
                          color: borderColor,
                          width: borderWidth,
                          strokeAlign: strokeAlign,
                        ),
                      ),
                    ),
                    BorderedBox(
                      shape: OvalBorder(
                        side: BorderSide(
                          color: borderColor,
                          width: borderWidth,
                          strokeAlign: strokeAlign,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    BorderedBox(
                      shape: BeveledRectangleBorder(
                        side: BorderSide(
                          color: borderColor,
                          width: borderWidth,
                          strokeAlign: strokeAlign,
                        ),
                      ),
                    ),
                    BorderedBox(
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(cornerRadius),
                        side: BorderSide(
                          color: borderColor,
                          width: borderWidth,
                          strokeAlign: strokeAlign,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    BorderedBox(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: borderColor,
                          width: borderWidth,
                          strokeAlign: strokeAlign,
                        ),
                      ),
                    ),
                    BorderedBox(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(cornerRadius),
                        side: BorderSide(
                          color: borderColor,
                          width: borderWidth,
                          strokeAlign: strokeAlign,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    BorderedBox(
                      shape: StarBorder(
                        side: BorderSide(
                          color: borderColor,
                          width: borderWidth,
                          strokeAlign: strokeAlign,
                        ),
                      ),
                    ),
                    BorderedBox(
                      shape: StarBorder(
                        pointRounding: 1,
                        innerRadiusRatio: 0.5,
                        points: 8,
                        side: BorderSide(
                          color: borderColor,
                          width: borderWidth,
                          strokeAlign: strokeAlign,
                        ),
                      ),
                    ),
                    BorderedBox(
                      shape: StarBorder.polygon(
                        sides: 6,
                        pointRounding: 0.5,
                        side: BorderSide(
                          color: borderColor,
                          width: borderWidth,
                          strokeAlign: strokeAlign,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class BorderedBox extends StatelessWidget {
  const BorderedBox({super.key, required this.shape});

  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 50,
      decoration: ShapeDecoration(color: const Color(0xff012677), shape: shape),
    );
  }
}
