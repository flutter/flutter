// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

import 'typography.dart';

class ThemeData {
  const ThemeData({ this.text, this.color });
  final TextTheme text;
  final Map<int, Color> color;
}
