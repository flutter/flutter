// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestSliverChildDelegate extends SliverChildDelegate {
  TestSliverChildDelegate({
    super.addAutomaticKeepAlives,
    super.addRepaintBoundaries,
  });

  @override
  Widget? build(BuildContext context, int index) {
    if (index == 0) {
      return wrapChildForIndex(const SizedBox.square(dimension: 50), 0);
    }
    return null;
  }

  @override
  bool shouldRebuild(covariant SliverChildDelegate oldDelegate) => true;
}

void main() {
  testWidgets('SliverChildDelegate.wrapChildForIndex wraps child as configured', (WidgetTester tester) async {
    final TestSliverChildDelegate defaultDelegate = TestSliverChildDelegate();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.custom(childrenDelegate: defaultDelegate),
      ),
    );
    expect(find.byType(RepaintBoundary), findsNWidgets(3));
    expect(find.byType(AutomaticKeepAlive), findsOneWidget);
    expect(find.byType(KeyedSubtree), findsOneWidget);

    final TestSliverChildDelegate customDelegate = TestSliverChildDelegate(
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.custom(childrenDelegate: customDelegate),
      ),
    );

    expect(find.byType(RepaintBoundary), findsNWidgets(2));
    expect(find.byType(AutomaticKeepAlive), findsNothing);
    expect(find.byType(KeyedSubtree), findsOneWidget);
  });
}
