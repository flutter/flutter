// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file defines basic widgets for use in tests for Widgets in `flutter/widgets`.

import 'package:flutter/widgets.dart';

/// Get a color for use in a widget test.
///
/// The returned color will be fully opaque,
/// but the [Color.r], [Color.g], and [Color.b] channels
/// will vary sequentially based on index, cycling every sixth integer.
Color getTestColor(int index) {
  const colors = [
    Color(0xFFFF0000),
    Color(0xFF00FF00),
    Color(0xFF0000FF),
    Color(0xFFFFFF00),
    Color(0xFFFF00FF),
    Color(0xFF00FFFF),
  ];

  return colors[index % colors.length];
}
