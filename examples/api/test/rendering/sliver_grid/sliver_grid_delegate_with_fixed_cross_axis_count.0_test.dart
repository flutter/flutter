// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/rendering/sliver_grid/sliver_grid_delegate_with_fixed_cross_axis_count.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Example app has ScrollDirection represented', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SliverGridDelegateWithFixedCrossAxisCountExampleApp(),
    );

    for (int i = 0; i < 4; i++) {
      expect(find.text('$i'), findsOne);
      final Element element = tester.element(find.text('0'));

      expect(element.size, const Size(200, 400));
    }
  });
}
