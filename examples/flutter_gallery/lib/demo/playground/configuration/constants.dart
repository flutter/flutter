// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'choices.dart';

typedef IndexedValueCallback<T> = Function(int index, T value);

const double kPickerSelectedElevation = 3.0;
const double kPickerRowHeight = 44.0;
const double kPickerRowPadding = 10.0;

const List<BorderChoice> kBorderChoices = <BorderChoice>[
  BorderChoice(type: 'square', code: '''
RoundedRectangleBorder(
  borderRadius: BorderRadius.zero
)'''),
  BorderChoice(type: 'rounded', code: '''
RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(10.0)'
)'''),
  BorderChoice(type: 'beveled', code: '''
BeveledRectangleBorder(
  borderRadius: BorderRadius.circular(10.0)
)'''),
  BorderChoice(type: 'stadium', code: '''
StadiumBorder()
'''),
];

const List<ColorChoice> kColorChoices = <ColorChoice>[
  ColorChoice(color: Colors.white, code: 'Colors.white'),
  ColorChoice(color: Colors.orange, code: 'Colors.orange'),
  ColorChoice(color: Color(0xff80deea), code: 'Color(0xff80deea)'),
  ColorChoice(color: Color(0xff4fc3f7), code: 'Color(0xff4fc3f7)'),
  ColorChoice(color: Colors.blue, code: 'Colors.blue'),
  ColorChoice(color: Color(0xff1565c0), code: 'Color(0xff1565c0)'),
];

const List<IconChoice> kIconChoices = <IconChoice>[
  IconChoice(icon: Icons.thumb_up, code: 'Icons.thumb_up'),
  IconChoice(icon: Icons.android, code: 'Icons.android'),
  IconChoice(icon: Icons.alarm, code: 'Icons.alarm'),
  IconChoice(icon: Icons.accessibility, code: 'Icons.accessibility'),
  IconChoice(icon: Icons.call, code: 'Icons.call'),
  IconChoice(icon: Icons.camera, code: 'Icons.camera'),
];
