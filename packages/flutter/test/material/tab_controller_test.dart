// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  testWidgets('$TabController dispatches creation in constructor.', (
    WidgetTester widgetTester,
  ) async {
    await expectLater(
      await memoryEvents(
        () async => TabController(length: 1, vsync: const TestVSync()).dispose(),
        TabController,
      ),
      areCreateAndDispose,
    );
  });
  testWidgets('DefaultTabController uncontrolled uses initialIndex only once', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTabController(
          length: 3,
          initialIndex: 1,
          child: TabBarView(children: <Widget>[Text('A'), Text('B'), Text('C')]),
        ),
      ),
    );

    TabController controller = DefaultTabController.of(tester.element(find.text('B')));

    expect(controller.index, 1);

    // Rebuild with different initialIndex — should be ignored.
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTabController(
          length: 3,
          initialIndex: 2,
          child: TabBarView(children: <Widget>[Text('A'), Text('B'), Text('C')]),
        ),
      ),
    );

    controller = DefaultTabController.of(tester.element(find.text('B')));

    expect(controller.index, 1);
  });

  testWidgets('DefaultTabController uncontrolled updates index on animateTo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 3,
          child: Builder(
            builder: (BuildContext context) {
              return Column(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      DefaultTabController.of(context).animateTo(2);
                    },
                    child: const Text('go'),
                  ),
                  const Expanded(
                    child: TabBarView(children: <Widget>[Text('A'), Text('B'), Text('C')]),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    final TabController controller = DefaultTabController.of(tester.element(find.text('C')));

    expect(controller.index, 2);
  });
  testWidgets('DefaultTabController controlled animates when index changes', (
    WidgetTester tester,
  ) async {

    Widget build({int index=0}) {
      return MaterialApp(
        home: DefaultTabController.controlled(
          length: 3,
          index: index,
          child: const TabBarView(children: <Widget>[Text('A'), Text('B'), Text('C')]),
        ),
      );
    }

    await tester.pumpWidget(build(index: 0));

    TabController controller = DefaultTabController.of(tester.element(find.text('A')));
    expect(controller.index, 0);

    await tester.pumpWidget(build(index:2));

    // Animation started
    expect(controller.indexIsChanging, true);

    await tester.pumpAndSettle();

    controller = DefaultTabController.of(tester.element(find.text('C')));
    expect(controller.index, 2);
  });
}
