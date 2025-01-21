// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/tab_bar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('tab bar view can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, TabBarViewUseCase());
    expect(find.byType(TabBar), findsOneWidget);
  });
}
