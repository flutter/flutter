// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ColorTestingDemo extends StatelessWidget {
  const ColorTestingDemo({ Key key }) : super(key: key);

  static const String routeName = '/color_demo';

  @override
  Widget build(BuildContext context) => new ColorDemoHome();
}

const double _kPageMaxWidth = 500.0;

class ColorDemoHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: const Text('Color Demo')),
      body: new ListView(
        padding: const EdgeInsets.all(5.0),
        children: <Widget>[
          new Image.network('https://flutter.github.io/assets-for-api-docs/tests/colors/gbr.png'),
          new Image.network('https://flutter.github.io/assets-for-api-docs/tests/colors/tf.png'),
          new Image.network('https://flutter.github.io/assets-for-api-docs/tests/colors/wide-gamut.png'),
          const GradientRow(leftColor: const Color(0xFFFF0000), rightColor: const Color(0xFF00FF00)),
          const GradientRow(leftColor: const Color(0xFF0000FF), rightColor: const Color(0xFFFFFF00)),
          const GradientRow(leftColor: const Color(0xFFFF0000), rightColor: const Color(0xFF0000FF)),
          const GradientRow(leftColor: const Color(0xFF00FF00), rightColor: const Color(0xFFFFFF00)),
          const GradientRow(leftColor: const Color(0xFF0000FF), rightColor: const Color(0xFF00FF00)),
          const GradientRow(leftColor: const Color(0xFFFF0000), rightColor: const Color(0xFFFFFF00)),

          // For the following pairs, the blend result should match the opaque color.
          const ColorRow(color: const Color(0xFFBCBCBC)),
          const ColorRow(color: const Color(0x80000000)),

          const ColorRow(color: const Color(0xFFFFBCBC)),
          const ColorRow(color: const Color(0x80FF0000)),

          const ColorRow(color: const Color(0xFFBCFFBC)),
          const ColorRow(color: const Color(0x8000FF00)),

          const ColorRow(color: const Color(0xFFBCBCFF)),
          const ColorRow(color: const Color(0x800000FF)),
        ],
      ),
    );
  }
}

class GradientRow extends StatelessWidget {
  const GradientRow({ Key key, this.rightColor, this.leftColor }) : super(key: key);

  final Color leftColor;
  final Color rightColor;

  @override
  Widget build(BuildContext context) {
    return new Container(
      height: 100.0,
      decoration: new BoxDecoration(
        gradient: new LinearGradient(
          begin: FractionalOffset.topLeft,
          end: FractionalOffset.bottomRight,
          colors: <Color>[ leftColor, rightColor ],
        ),
      ),
    );
  }
}

class ColorRow extends StatelessWidget {
  const ColorRow({ Key key, this.color }) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return new Container(
      height: 100.0,
      color: color,
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'Color Testing Demo',
    home: new ColorDemoHome(),
  ));
}
