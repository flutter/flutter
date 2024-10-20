// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProgressIndicatorThemeData copyWith, ==, hashCode, basics', () {
    expect(const ProgressIndicatorThemeData(), const ProgressIndicatorThemeData().copyWith());
    expect(const ProgressIndicatorThemeData().hashCode, const ProgressIndicatorThemeData().copyWith().hashCode);
  });

  test('ProgressIndicatorThemeData lerp special cases', () {
    expect(ProgressIndicatorThemeData.lerp(null, null, 0), null);
    const ProgressIndicatorThemeData data = ProgressIndicatorThemeData();
    expect(identical(ProgressIndicatorThemeData.lerp(data, data, 0.5), data), true);
  });
}
