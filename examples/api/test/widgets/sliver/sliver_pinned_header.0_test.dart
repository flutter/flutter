// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/sliver/sliver_pinned_header.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SliverPinnedHeader example', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SliverPinnedHeaderApp(),
    );

    expect(find.text('SliverPinnedHeader'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Alternative Title\nWith Two Lines'), findsOneWidget);
  });
}
