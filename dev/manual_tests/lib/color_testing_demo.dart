// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ColorTestingDemo extends StatelessWidget {
  const ColorTestingDemo({ Key? key }) : super(key: key);

  static const String routeName = '/color_demo';

  @override
  Widget build(BuildContext context) => const ColorDemoHome();
}

class ColorDemoHome extends StatelessWidget {
  const ColorDemoHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Color Demo')),
      body: ListView(
        padding: const EdgeInsets.all(5.0),
        children: <Widget>[
          Image.network('https://flutter.github.io/assets-for-api-docs/assets/tests/colors/gbr.png'),
          Image.network('https://flutter.github.io/assets-for-api-docs/assets/tests/colors/tf.png'),
          Image.network('https://flutter.github.io/assets-for-api-docs/assets/tests/colors/wide-gamut.png'),
          const GradientRow(leftColor: Color(0xFFFF0000), rightColor: Color(0xFF00FF00)),
          const GradientRow(leftColor: Color(0xFF0000FF), rightColor: Color(0xFFFFFF00)),
          const GradientRow(leftColor: Color(0xFFFF0000), rightColor: Color(0xFF0000FF)),
          const GradientRow(leftColor: Color(0xFF00FF00), rightColor: Color(0xFFFFFF00)),
          const GradientRow(leftColor: Color(0xFF0000FF), rightColor: Color(0xFF00FF00)),
          const GradientRow(leftColor: Color(0xFFFF0000), rightColor: Color(0xFFFFFF00)),

          // For the following pairs, the blend result should match the opaque color.
          const ColorRow(color: Color(0xFFBCBCBC)),
          const ColorRow(color: Color(0x80000000)),

          const ColorRow(color: Color(0xFFFFBCBC)),
          const ColorRow(color: Color(0x80FF0000)),

          const ColorRow(color: Color(0xFFBCFFBC)),
          const ColorRow(color: Color(0x8000FF00)),

          const ColorRow(color: Color(0xFFBCBCFF)),
          const ColorRow(color: Color(0x800000FF)),
        ],
      ),
    );
  }
}

class GradientRow extends StatelessWidget {
  const GradientRow({ Key? key, required this.rightColor, required this.leftColor }) : super(key: key);

  final Color leftColor;
  final Color rightColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[ leftColor, rightColor ],
        ),
      ),
    );
  }
}

class ColorRow extends StatelessWidget {
  const ColorRow({ Key? key, required this.color }) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.0,
      color: color,
    );
  }
}

void main() {
  runApp(const MaterialApp(
    title: 'Color Testing Demo',
    home: ColorDemoHome(),
  ));
}
