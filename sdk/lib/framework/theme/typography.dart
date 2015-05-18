// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See http://www.google.com/design/spec/style/typography.html

const String _display4 = 'font-size: 112px; font-weight: 300';
const String _display3 = 'font-size:  56px; font-weight: 400';
const String _display2 = 'font-size:  45px; font-weight: 400';
const String _display1 = 'font-size:  34px; font-weight: 400';
const String _headline = 'font-size:  24px; font-weight: 400';
const String _title    = 'font-size:  20px; font-weight: 500';
const String _subhead  = 'font-size:  16px; font-weight: 400';
const String _body2    = 'font-size:  14px; font-weight: 500';
const String _body1    = 'font-size:  14px; font-weight: 400';
const String _caption  = 'font-size:  12px; font-weight: 400';
const String _button   = 'font-size:  14px; font-weight: 500';

class _Black {
  final String display4 = 'color: #757575; ${_display4}'; // 54%
  final String display3 = 'color: #757575; ${_display3}'; // 54%
  final String display2 = 'color: #757575; ${_display2}'; // 54%
  final String display1 = 'color: #757575; ${_display1}'; // 54%
  final String headline = 'color: #212121; ${_headline}'; // 87%
  final String title    = 'color: #212121; ${_title}';    // 87%
  final String subhead  = 'color: #212121; ${_subhead}';  // 87%
  final String body2    = 'color: #212121; ${_body2}';    // 87%
  final String body1    = 'color: #212121; ${_body1}';    // 87%
  final String caption  = 'color: #757575; ${_caption}';  // 54%
  final String button   = 'color: #212121; ${_button}';   // 87%

  const _Black();
}

const _Black black = const _Black();

class _White {
  final String display4 = 'color: #8A8A8A; ${_display4}'; // 54%
  final String display3 = 'color: #8A8A8A; ${_display3}'; // 54%
  final String display2 = 'color: #8A8A8A; ${_display2}'; // 54%
  final String display1 = 'color: #8A8A8A; ${_display1}'; // 54%
  final String headline = 'color: #DEDEDE; ${_headline}'; // 87%
  final String title    = 'color: #DEDEDE; ${_title}';    // 87%
  final String subhead  = 'color: #DEDEDE; ${_subhead}';  // 87%
  final String body2    = 'color: #DEDEDE; ${_body2}';    // 87%
  final String body1    = 'color: #DEDEDE; ${_body1}';    // 87%
  final String caption  = 'color: #8A8A8A; ${_caption}';  // 54%
  final String button   = 'color: #DEDEDE; ${_button}';   // 87%

  const _White();
}

const _White white = const _White();

// TODO(abarth): Maybe this should be hard-coded in Scaffold?
const String typeface = 'font-family: sans-serif';
