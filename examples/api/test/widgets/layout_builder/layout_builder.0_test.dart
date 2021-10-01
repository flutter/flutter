// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/layout_builder/layout_builder.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('layout_builder.0 Golden', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MyApp(),
    );

    await expectLater(
      find.byType(example.MyApp),
      matchesGoldenFile('examples.api.widgets.layout_builder.layout_builder.0.png'),
    );
  });
}
