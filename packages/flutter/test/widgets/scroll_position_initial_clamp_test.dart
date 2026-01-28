
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ScrollPosition clamps restored offset on first layout', (WidgetTester tester) async {
    final PageStorageBucket bucket = PageStorageBucket();
    final Key key = const PageStorageKey<String>('list');

    // 1. Build list with content and scroll it to 1000.0.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PageStorage(
          bucket: bucket,
          child: ListView.builder(
            key: key,
            itemCount: 100,
            itemExtent: 50.0,
            physics: const ClampingScrollPhysics(), // Enforce clamping.
            itemBuilder: (BuildContext context, int index) => Text('Item $index'),
          ),
        ),
      ),
    );

    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    scrollable.position.jumpTo(1000.0);
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, 1000.0);

    // 2. Rebuild with empty list, reusing PageStorage.
    // The ScrollState is disposed and recreated, triggering state restoration.
    // The restored offset (1000.0) is invalid for the new empty list.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PageStorage(
          bucket: bucket,
          child: ListView.builder(
            key: key,
            itemCount: 0, // Empty list.
            physics: const ClampingScrollPhysics(),
            itemBuilder: (BuildContext context, int index) => Text('Item $index'),
          ),
        ),
      ),
    );

    // The scroll position should be restored but then clamped to 0.0 during layout.
    final ScrollableState newScrollable = tester.state(find.byType(Scrollable));

    expect(newScrollable.position.pixels, 0.0);
    expect(newScrollable.position.maxScrollExtent, 0.0);
  });
}
