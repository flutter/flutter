// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SliverReorderableList restores a reparented item after a drag', (
    WidgetTester tester,
  ) async {
    final GlobalKey listKey = GlobalKey();
    late StateSetter setParentState;
    var wrapped = false;
    var generation = 0;
    var reorderCount = 0;

    await tester.pumpWidget(
      TestWidgetsApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            setParentState = setState;
            final Widget list = KeyedSubtree(
              key: listKey,
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverReorderableList(
                    itemCount: 3,
                    onReorderItem: (int oldIndex, int newIndex) => reorderCount += 1,
                    itemBuilder: (BuildContext context, int index) => SizedBox(
                      key: ValueKey<int>(index),
                      height: 80,
                      child: ReorderableDragStartListener(
                        index: index,
                        child: Text('item $index $generation'),
                      ),
                    ),
                  ),
                ],
              ),
            );
            return wrapped ? Padding(padding: EdgeInsets.zero, child: list) : list;
          },
        ),
      ),
    );

    final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 1 0')));
    await tester.pump(kPressTimeout);
    await drag.moveBy(const Offset(0, 100));
    await tester.pump();

    setParentState(() => wrapped = true);
    await tester.pump();

    await drag.moveBy(const Offset(0, -100));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(reorderCount, 0);
    setParentState(() => generation += 1);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('item 1 1'), findsOneWidget);
  });
}
