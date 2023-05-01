// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TwoDimensionalScrollView',() {
    testWidgets('asserts the axis directions do not conflict with one another', (WidgetTester tester) async {
      // Horizontal mismatch

      // Vertical mismatch

    }, variant: TargetPlatformVariant.all());

    testWidgets('ScrollableDetails.controller can set initial scroll positions', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('Properly assigns the PrimaryScrollController to the main axis on the correct platform', (WidgetTester tester) async {
      // Horizontal

      // Vertical

      // Asserts ScrollableDetails.controller has not been provided if primary
      // is explicitly set

    }, variant: TargetPlatformVariant.all());

    testWidgets('Scrollables receive the correct details from TwoDimensionalScrollView', (WidgetTester tester) async {
      // Default

      // Customized

    }, variant: TargetPlatformVariant.all());
  });
}
