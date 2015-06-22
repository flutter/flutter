// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See http://www.google.com/design/spec/style/typography.html

import 'dart:sky';

import '../painting/text_style.dart';

// TODO(eseidel): Font weights are supposed to be language relative!
// These values are for English-like text.
class TextTheme {
  TextTheme._(Color color54, Color color87)
    : display4 = new TextStyle(fontSize: 112.0, fontWeight: FontWeight.w100, color: color54),
      display3 = new TextStyle(fontSize:  56.0, fontWeight: FontWeight.w400, color: color54),
      display2 = new TextStyle(fontSize:  45.0, fontWeight: FontWeight.w400, color: color54),
      display1 = new TextStyle(fontSize:  34.0, fontWeight: FontWeight.w400, color: color54),
      headline = new TextStyle(fontSize:  24.0, fontWeight: FontWeight.w400, color: color87),
      title    = new TextStyle(fontSize:  20.0, fontWeight: FontWeight.w500, color: color87),
      subhead  = new TextStyle(fontSize:  16.0, fontWeight: FontWeight.w400, color: color87),
      body2    = new TextStyle(fontSize:  14.0, fontWeight: FontWeight.w500, color: color87),
      body1    = new TextStyle(fontSize:  14.0, fontWeight: FontWeight.w400, color: color87),
      caption  = new TextStyle(fontSize:  12.0, fontWeight: FontWeight.w400, color: color54),
      button   = new TextStyle(fontSize:  14.0, fontWeight: FontWeight.w500, color: color87);

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


final TextTheme black = new TextTheme._(
  const Color(0xFF757575),
  const Color(0xFF212121)
);


final TextTheme white = new TextTheme._(
  const Color(0xFF8A8A8A),
  const Color(0xFFDEDEDE)
);

// TODO(abarth): Maybe this should be hard-coded in Scaffold?
const String typeface = 'font-family: sans-serif';
