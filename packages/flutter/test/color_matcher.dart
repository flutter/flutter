// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color;
import 'package:flutter/src/foundation/colors.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher isEquivalentColor(Color color) => IsEquivalentColorMatcher(color);

class IsEquivalentColorMatcher extends Matcher {
  IsEquivalentColorMatcher(this.target);

  final Color target;

  @override
  Description describe(Description description) =>
    description.add('A color that matches $target');

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is Color) {
      return item.isEquivalentTo(target);
    } else {
      return false;
    }
  }
}
