// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/navigation_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('navigation rail can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, NavigationRailUseCase());

    expect(find.byType(NavigationRail), findsExactly(1));
  });
}
