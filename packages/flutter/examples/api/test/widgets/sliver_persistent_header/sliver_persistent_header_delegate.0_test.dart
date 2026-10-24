// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/sliver_persistent_header/sliver_persistent_header_delegate.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Header shrinks to its minExtent and stays pinned while scrolling',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const example.SliverPersistentHeaderDelegateExampleApp(),
      );

      // The innermost Material is the one the delegate builds, so its size is the
      // header's current extent.
      Size headerSize() => tester.getSize(
        find
            .ancestor(of: find.text('Header'), matching: find.byType(Material))
            .first,
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(headerSize().height, 160.0);

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0.0, -400.0),
      );
      await tester.pumpAndSettle();

      // The header is pinned, so it survives scrolling the list past it, shrunk
      // to its minExtent.
      expect(find.text('Item 0'), findsNothing);
      expect(find.text('Header'), findsOneWidget);
      expect(headerSize().height, 60.0);
    },
  );
}
