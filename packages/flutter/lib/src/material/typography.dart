// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See http://www.google.com/design/spec/style/typography.html

import 'dart:ui' show Color;

import 'package:flutter/painting.dart';

import 'colors.dart';

// TODO(eseidel): Font weights are supposed to be language relative!
// TODO(jackson): Baseline should be language relative!
// These values are for English-like text.
class TextTheme {

  const TextTheme._black()
    : display4 = const TextStyle(inherit: false, fontSize: 112.0, fontWeight: FontWeight.w100, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      display3 = const TextStyle(inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      display2 = const TextStyle(inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, color: Colors.black54, height: 48.0 / 45.0, textBaseline: TextBaseline.alphabetic),
      display1 = const TextStyle(inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, color: Colors.black54, height: 40.0 / 34.0, textBaseline: TextBaseline.alphabetic),
      headline = const TextStyle(inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, color: Colors.black87, height: 32.0 / 24.0, textBaseline: TextBaseline.alphabetic),
      title    = const TextStyle(inherit: false, fontSize:  20.0, fontWeight: FontWeight.w500, color: Colors.black87, height: 28.0 / 20.0, textBaseline: TextBaseline.alphabetic),
      subhead  = const TextStyle(inherit: false, fontSize:  16.0, fontWeight: FontWeight.w400, color: Colors.black87, height: 24.0 / 16.0, textBaseline: TextBaseline.alphabetic),
      body2    = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.black87, height: 24.0 / 14.0, textBaseline: TextBaseline.alphabetic),
      body1    = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w400, color: Colors.black87, height: 20.0 / 14.0, textBaseline: TextBaseline.alphabetic),
      caption  = const TextStyle(inherit: false, fontSize:  12.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      button   = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.black87, textBaseline: TextBaseline.alphabetic);

  const TextTheme._white()
    : display4 = const TextStyle(inherit: false, fontSize: 112.0, fontWeight: FontWeight.w100, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      display3 = const TextStyle(inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      display2 = const TextStyle(inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, color: Colors.white70, height: 48.0 / 45.0, textBaseline: TextBaseline.alphabetic),
      display1 = const TextStyle(inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, color: Colors.white70, height: 40.0 / 34.0, textBaseline: TextBaseline.alphabetic),
      headline = const TextStyle(inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, color: Colors.white, height: 32.0 / 24.0, textBaseline: TextBaseline.alphabetic),
      title    = const TextStyle(inherit: false, fontSize:  20.0, fontWeight: FontWeight.w500, color: Colors.white, height: 28.0 / 20.0, textBaseline: TextBaseline.alphabetic),
      subhead  = const TextStyle(inherit: false, fontSize:  16.0, fontWeight: FontWeight.w400, color: Colors.white, height: 24.0 / 16.0, textBaseline: TextBaseline.alphabetic),
      body2    = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.white, height: 24.0 / 14.0, textBaseline: TextBaseline.alphabetic),
      body1    = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w400, color: Colors.white, height: 20.0 / 14.0, textBaseline: TextBaseline.alphabetic),
      caption  = const TextStyle(inherit: false, fontSize:  12.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      button   = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.white, textBaseline: TextBaseline.alphabetic);

  final TextStyle display4;
  final TextStyle display3;
  final TextStyle display2;
  final TextStyle display1;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle subhead;
  final TextStyle body2;
  final TextStyle body1;
  final TextStyle caption;
  final TextStyle button;

}

class Typography {
  Typography._();

  static const TextTheme black = const TextTheme._black();
  static const TextTheme white = const TextTheme._white();

  // TODO(abarth): Maybe this should be hard-coded in Scaffold?
  static const String typeface = 'font-family: sans-serif';

  // TODO(ianh): Remove this when we remove fn2, now that it's hard-coded in App.
  static const TextStyle error = const TextStyle(
    color: const Color(0xD0FF0000),
    fontFamily: 'monospace',
    fontSize: 48.0,
    fontWeight: FontWeight.w900,
    textAlign: TextAlign.right,
    decoration: TextDecoration.underline,
    decorationColor: const Color(0xFFFF00),
    decorationStyle: TextDecorationStyle.double
  );
}
