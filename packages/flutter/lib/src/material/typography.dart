// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See http://www.google.com/design/spec/style/typography.html

import 'package:flutter/painting.dart';

import 'colors.dart';

// TODO(eseidel): Font weights are supposed to be language relative!
// TODO(jackson): Baseline should be language relative!
// These values are for English-like text.
// TODO(ianh): There's no font-family specified here.
class TextTheme {

  const TextTheme._(this.display4, this.display3, this.display2, this.display1, this.headline, this.title, this.subhead, this.body2, this.body1, this.caption, this.button);

  const TextTheme._black()
    : display4 = const TextStyle(inherit: false, fontSize: 112.0, fontWeight: FontWeight.w100, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      display3 = const TextStyle(inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      display2 = const TextStyle(inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      display1 = const TextStyle(inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      headline = const TextStyle(inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      title    = const TextStyle(inherit: false, fontSize:  20.0, fontWeight: FontWeight.w500, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      subhead  = const TextStyle(inherit: false, fontSize:  16.0, fontWeight: FontWeight.w400, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      body2    = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      body1    = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w400, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      caption  = const TextStyle(inherit: false, fontSize:  12.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      button   = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.black87, textBaseline: TextBaseline.alphabetic);

  const TextTheme._white()
    : display4 = const TextStyle(inherit: false, fontSize: 112.0, fontWeight: FontWeight.w100, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      display3 = const TextStyle(inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      display2 = const TextStyle(inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      display1 = const TextStyle(inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      headline = const TextStyle(inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      title    = const TextStyle(inherit: false, fontSize:  20.0, fontWeight: FontWeight.w500, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      subhead  = const TextStyle(inherit: false, fontSize:  16.0, fontWeight: FontWeight.w400, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      body2    = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      body1    = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w400, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      caption  = const TextStyle(inherit: false, fontSize:  12.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      button   = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.white,   textBaseline: TextBaseline.alphabetic);

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

  static TextTheme lerp(TextTheme begin, TextTheme end, double t) {
    return new TextTheme._(
      TextStyle.lerp(begin.display4, end.display4, t),
      TextStyle.lerp(begin.display3, end.display3, t),
      TextStyle.lerp(begin.display2, end.display2, t),
      TextStyle.lerp(begin.display1, end.display1, t),
      TextStyle.lerp(begin.headline, end.headline, t),
      TextStyle.lerp(begin.title, end.title, t),
      TextStyle.lerp(begin.subhead, end.subhead, t),
      TextStyle.lerp(begin.body2, end.body2, t),
      TextStyle.lerp(begin.body1, end.body1, t),
      TextStyle.lerp(begin.caption, end.caption, t),
      TextStyle.lerp(begin.button, end.button, t)
    );
  }

}

class Typography {
  Typography._();
  static const TextTheme black = const TextTheme._black();
  static const TextTheme white = const TextTheme._white();
}
