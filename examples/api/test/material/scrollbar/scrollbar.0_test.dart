// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/scrollbar/scrollbar.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Scrollbar.0 works well on all platforms', (WidgetTester tester) async {

    await tester.pumpWidget(
      const example.ScrollbarExampleApp(),
    );

    final Finder buttonFinder = find.byType(Scrollbar);
    await tester.drag(buttonFinder.last, const Offset(0, 100.0));

    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.all());
}
