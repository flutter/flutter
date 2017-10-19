// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hourFormat', () {
    testWidgets('respects alwaysUse24HourFormat option', (WidgetTester tester) async {
      expect(hourFormat(of: TimeOfDayFormat.a_space_h_colon_mm), HourFormat.h);
      expect(hourFormat(of: TimeOfDayFormat.a_space_h_colon_mm, alwaysUse24HourFormat: true), HourFormat.HH);
    });
  });
}
