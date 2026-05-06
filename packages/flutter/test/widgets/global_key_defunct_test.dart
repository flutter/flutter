// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GlobalKey reuse after defunct does not assert (different widget type)', (
    WidgetTester tester,
  ) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Container(key: key),
      ),
    );
    expect(find.byKey(key), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Text('Reused', key: key),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Reused'), findsOneWidget);
  });

  testWidgets('GlobalKey reuse after defunct does not assert (same widget type)', (
    WidgetTester tester,
  ) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Container(key: key),
      ),
    );
    expect(find.byKey(key), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Container(key: key),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(key), findsOneWidget);
  });
}
