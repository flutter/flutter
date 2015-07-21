// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See http://www.google.com/design/spec/style/typography.html

import 'dart:sky';

import 'package:sky/painting/text_style.dart';

// TODO(eseidel): Font weights are supposed to be language relative!
// TODO(jackson): Baseline should be language relative!
// These values are for English-like text.
class TextTheme {

  // The two colours used here are 54% and 87%, respectively, of the base color (black or white)

  const TextTheme._black()
    : display4 = const TextStyle(fontSize: 112.0, fontWeight: FontWeight.w100, color: const Color(0xFF757575), textBaseline: TextBaseline.alphabetic),
      display3 = const TextStyle(fontSize:  56.0, fontWeight: FontWeight.w400, color: const Color(0xFF757575), textBaseline: TextBaseline.alphabetic),
      display2 = const TextStyle(fontSize:  45.0, fontWeight: FontWeight.w400, color: const Color(0xFF757575), height: 48.0 / 45.0, textBaseline: TextBaseline.alphabetic),
      display1 = const TextStyle(fontSize:  34.0, fontWeight: FontWeight.w400, color: const Color(0xFF757575), height: 40.0 / 34.0, textBaseline: TextBaseline.alphabetic),
      headline = const TextStyle(fontSize:  24.0, fontWeight: FontWeight.w400, color: const Color(0xFF212121), height: 32.0 / 24.0, textBaseline: TextBaseline.alphabetic),
      title    = const TextStyle(fontSize:  20.0, fontWeight: FontWeight.w500, color: const Color(0xFF212121), height: 28.0 / 20.0, textBaseline: TextBaseline.alphabetic),
      subhead  = const TextStyle(fontSize:  16.0, fontWeight: FontWeight.w400, color: const Color(0xFF212121), height: 24.0 / 16.0, textBaseline: TextBaseline.alphabetic),
      body2    = const TextStyle(fontSize:  14.0, fontWeight: FontWeight.w500, color: const Color(0xFF212121), height: 24.0 / 14.0, textBaseline: TextBaseline.alphabetic),
      body1    = const TextStyle(fontSize:  14.0, fontWeight: FontWeight.w400, color: const Color(0xFF212121), height: 20.0 / 14.0, textBaseline: TextBaseline.alphabetic),
      caption  = const TextStyle(fontSize:  12.0, fontWeight: FontWeight.w400, color: const Color(0xFF757575), textBaseline: TextBaseline.alphabetic),
      button   = const TextStyle(fontSize:  14.0, fontWeight: FontWeight.w500, color: const Color(0xFF212121), textBaseline: TextBaseline.alphabetic);

  const TextTheme._white()
    : display4 = const TextStyle(fontSize: 112.0, fontWeight: FontWeight.w100, color: const Color(0xFF8A8A8A), textBaseline: TextBaseline.alphabetic),
      display3 = const TextStyle(fontSize:  56.0, fontWeight: FontWeight.w400, color: const Color(0xFF8A8A8A), textBaseline: TextBaseline.alphabetic),
      display2 = const TextStyle(fontSize:  45.0, fontWeight: FontWeight.w400, color: const Color(0xFF8A8A8A), height: 48.0 / 45.0, textBaseline: TextBaseline.alphabetic),
      display1 = const TextStyle(fontSize:  34.0, fontWeight: FontWeight.w400, color: const Color(0xFF8A8A8A), height: 40.0 / 34.0, textBaseline: TextBaseline.alphabetic),
      headline = const TextStyle(fontSize:  24.0, fontWeight: FontWeight.w400, color: const Color(0xFFDEDEDE), height: 32.0 / 24.0, textBaseline: TextBaseline.alphabetic),
      title    = const TextStyle(fontSize:  20.0, fontWeight: FontWeight.w500, color: const Color(0xFFDEDEDE), height: 28.0 / 20.0, textBaseline: TextBaseline.alphabetic),
      subhead  = const TextStyle(fontSize:  16.0, fontWeight: FontWeight.w400, color: const Color(0xFFDEDEDE), height: 24.0 / 16.0, textBaseline: TextBaseline.alphabetic),
      body2    = const TextStyle(fontSize:  14.0, fontWeight: FontWeight.w500, color: const Color(0xFFDEDEDE), height: 24.0 / 14.0, textBaseline: TextBaseline.alphabetic),
      body1    = const TextStyle(fontSize:  14.0, fontWeight: FontWeight.w400, color: const Color(0xFFDEDEDE), height: 20.0 / 14.0, textBaseline: TextBaseline.alphabetic),
      caption  = const TextStyle(fontSize:  12.0, fontWeight: FontWeight.w400, color: const Color(0xFF8A8A8A), textBaseline: TextBaseline.alphabetic),
      button   = const TextStyle(fontSize:  14.0, fontWeight: FontWeight.w500, color: const Color(0xFFDEDEDE), textBaseline: TextBaseline.alphabetic);

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


const TextTheme black = const TextTheme._black();
const TextTheme white = const TextTheme._white();

// TODO(abarth): Maybe this should be hard-coded in Scaffold?
const String typeface = 'font-family: sans-serif';

const TextStyle error = const TextStyle(
  color: const Color(0xD0FF0000),
  fontFamily: 'monospace',
  fontSize: 48.0,
  fontWeight: FontWeight.w900,
  textAlign: TextAlign.right,
  decoration: underline,
  decorationColor: const Color(0xFFFF00),
  decorationStyle: TextDecorationStyle.double
);
