// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import '../rendering/mock_canvas.dart';
import 'states.dart';

void main() {
  testWidgets('Empty GridView', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.count(
          crossAxisCount: 4,
          children: const <Widget>[],
        ),
      ),
    );
  });

  testWidgets('GridView.count control test', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.count(
          crossAxisCount: 4,
          children: kStates.map<Widget>((String state) {
            return GestureDetector(
              onTap: () {
                log.add(state);
              },
              child: Container(
                color: const Color(0xFF0000FF),
                child: Text(state),
              ),
            );
          }).toList(),
        ),
      ),
    );

    expect(tester.getSize(find.text('Arkansas')), equals(const Size(200.0, 200.0)));

    for (int i = 0; i < 8; ++i) {
      await tester.tap(find.text(kStates[i]));
      expect(log, equals(<String>[kStates[i]]));
      log.clear();
    }

    expect(find.text(kStates[12]), findsNothing);
    expect(find.text('Nevada'), findsNothing);

    await tester.drag(find.text('Arkansas'), const Offset(0.0, -200.0));
    await tester.pump();

    for (int i = 0; i < 4; ++i)
      expect(find.text(kStates[i]), findsNothing);

    for (int i = 4; i < 12; ++i) {
      await tester.tap(find.text(kStates[i]));
      expect(log, equals(<String>[kStates[i]]));
      log.clear();
    }

    await tester.drag(find.text('Delaware'), const Offset(0.0, -4000.0));
    await tester.pump();

    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Pennsylvania'), findsNothing);

    expect(tester.getCenter(find.text('Tennessee')),
        equals(const Offset(300.0, 100.0)));

    await tester.tap(find.text('Tennessee'));
    expect(log, equals(<String>['Tennessee']));
    log.clear();

    await tester.drag(find.text('Tennessee'), const Offset(0.0, 200.0));
    await tester.pump();

    await tester.tap(find.text('Tennessee'));
    expect(log, equals(<String>['Tennessee']));
    log.clear();

    await tester.tap(find.text('Pennsylvania'));
    expect(log, equals(<String>['Pennsylvania']));
    log.clear();
  });

  testWidgets('GridView.extent control test', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.extent(
          maxCrossAxisExtent: 200.0,
          children: kStates.map<Widget>((String state) {
            return GestureDetector(
              onTap: () {
                log.add(state);
              },
              child: Container(
                color: const Color(0xFF0000FF),
                child: Text(state),
              ),
            );
          }).toList(),
        ),
      ),
    );

    expect(tester.getSize(find.text('Arkansas')), equals(const Size(200.0, 200.0)));

    for (int i = 0; i < 8; ++i) {
      await tester.tap(find.text(kStates[i]));
      expect(log, equals(<String>[kStates[i]]));
      log.clear();
    }

    expect(find.text('Nevada'), findsNothing);

    await tester.drag(find.text('Arkansas'), const Offset(0.0, -4000.0));
    await tester.pump();

    expect(find.text('Alabama'), findsNothing);

    expect(tester.getCenter(find.text('Tennessee')),
        equals(const Offset(300.0, 100.0)));

    await tester.tap(find.text('Tennessee'));
    expect(log, equals(<String>['Tennessee']));
    log.clear();
  });

  testWidgets('GridView large scroll jump', (WidgetTester tester) async {
    final List<int> log = <int>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.extent(
          scrollDirection: Axis.horizontal,
          maxCrossAxisExtent: 200.0,
          childAspectRatio: 0.75,
          children: List<Widget>.generate(80, (int i) {
            return Builder(
              builder: (BuildContext context) {
                log.add(i);
                return Container(
                  child: Text('$i'),
                );
              }
            );
          }),
        ),
      ),
    );

    expect(tester.getSize(find.text('4')), equals(const Size(200.0 / 0.75, 200.0)));

    expect(log, equals(<int>[
      0, 1, 2, // col 0
      3, 4, 5, // col 1
      6, 7, 8, // col 2
      9, 10, 11, // col 3 (in cached area)
    ]));
    log.clear();

    for (int i = 0; i < 9; i++) {
      expect(find.text('$i'), findsOneWidget);
    }
    for (int i = 9; i < 80; i++) {
      expect(find.text('$i'), findsNothing);
    }

    final ScrollableState state = tester.state(find.byType(Scrollable));
    final ScrollPosition position = state.position;
    position.jumpTo(3025.0);

    expect(log, isEmpty);
    await tester.pump();

    expect(log, equals(<int>[
      30, 31, 32, // col 10 (in cached area)
      33, 34, 35, // col 11
      36, 37, 38, // col 12
      39, 40, 41, // col 13
      42, 43, 44, // col 14
      45, 46, 47, // col 15 (in cached area)
    ]));
    log.clear();

    for (int i = 0; i < 33; i++) {
      expect(find.text('$i'), findsNothing);
    }
    for (int i = 33; i < 45; i++) {
      expect(find.text('$i'), findsOneWidget);
    }
    for (int i = 45; i < 80; i++) {
      expect(find.text('$i'), findsNothing);
    }

    position.jumpTo(975.0);

    expect(log, isEmpty);
    await tester.pump();

    expect(log, equals(<int>[
      6, 7, 8, // col2 (in cached area)
      9, 10, 11, // col 3
      12, 13, 14, // col 4
      15, 16, 17, // col 5
      18, 19, 20, // col 6
      21, 22, 23, // col 7 (in cached area)
    ]));
    log.clear();

    for (int i = 0; i < 9; i++) {
      expect(find.text('$i'), findsNothing);
    }
    for (int i = 9; i < 21; i++) {
      expect(find.text('$i'), findsOneWidget);
    }
    for (int i = 21; i < 80; i++) {
      expect(find.text('$i'), findsNothing);
    }
  });

  testWidgets('GridView - change crossAxisCount', (WidgetTester tester) async {
    final List<int> log = <int>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
          children: List<Widget>.generate(40, (int i) {
            return Builder(
              builder: (BuildContext context) {
                log.add(i);
                return Container(
                  child: Text('$i'),
                );
              }
            );
          }),
        ),
      ),
    );

    expect(tester.getSize(find.text('4')), equals(const Size(200.0, 200.0)));

    expect(log, equals(<int>[
      0, 1, 2, 3, // row 0
      4, 5, 6, 7, // row 1
      8, 9, 10, 11, // row 2
      12, 13, 14, 15, // row 3 (in cached area)
      16, 17, 18, 19, // row 4 (in cached area)
    ]));
    for (int i = 0; i < 12; i++) {
      expect(find.text('$i'), findsOneWidget);
    }
    for (int i = 12; i < 40; i++) {
      expect(find.text('$i'), findsNothing);
    }
    log.clear();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          children: List<Widget>.generate(40, (int i) {
            return Builder(
              builder: (BuildContext context) {
                log.add(i);
                return Container(
                  child: Text('$i'),
                );
              }
            );
          }),
        ),
      ),
    );

    expect(log, equals(<int>[
      0, 1, 2, 3, // row 0
      4, 5, 6, 7, // row 1
      8, 9, 10, 11, // row 2
      12, 13, 14, 15, // row 3 (in cached area)
      16, 17, 18, 19, // row 4 (in cached area)
    ]));
    log.clear();

    expect(tester.getSize(find.text('3')), equals(const Size(400.0, 400.0)));
    expect(find.text('4'), findsNothing);
  });

  testWidgets('GridView - change maxChildCrossAxisExtent', (WidgetTester tester) async {
    final List<int> log = <int>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200.0,
          ),
          children: List<Widget>.generate(40, (int i) {
            return Builder(
              builder: (BuildContext context) {
                log.add(i);
                return Container(
                  child: Text('$i'),
                );
              }
            );
          }),
        ),
      ),
    );

    expect(tester.getSize(find.text('4')), equals(const Size(200.0, 200.0)));

    expect(log, equals(<int>[
      0, 1, 2, 3, // row 0
      4, 5, 6, 7, // row 1
      8, 9, 10, 11, // row 2
      12, 13, 14, 15, // row 3 (in cached area)
      16, 17, 18, 19, // row 4 (in cached area)
    ]));
    for (int i = 0; i < 12; i++) {
      expect(find.text('$i'), findsOneWidget);
    }
    for (int i = 12; i < 40; i++) {
      expect(find.text('$i'), findsNothing);
    }
    log.clear();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400.0,
          ),
          children: List<Widget>.generate(40, (int i) {
            return Builder(
              builder: (BuildContext context) {
                log.add(i);
                return Container(
                  child: Text('$i'),
                );
              }
            );
          }),
        ),
      ),
    );

    expect(log, equals(<int>[
      0, 1, 2, 3, // row 0
      4, 5, 6, 7, // row 1
      8, 9, 10, 11, // row 2
      12, 13, 14, 15, // row 3 (in cached area)
      16, 17, 18, 19, // row 4 (in cached area)
    ]));
    log.clear();

    expect(tester.getSize(find.text('3')), equals(const Size(400.0, 400.0)));
    expect(find.text('4'), findsNothing);
  });

  testWidgets('One-line GridView paints', (WidgetTester tester) async {
    const Color green = Color(0xFF00FF00);

    final Container container = Container(
      decoration: const BoxDecoration(
        color: green,
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            height: 200.0,
            child: GridView.count(
              cacheExtent: 0.0,
              crossAxisCount: 2,
              children: <Widget>[ container, container, container, container ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GridView), paints..rect(color: green)..rect(color: green));
    expect(find.byType(GridView), isNot(paints..rect(color: green)..rect(color: green)..rect(color: green)));
  });

  testWidgets('GridView in zero context', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 0.0,
            height: 0.0,
            child: GridView.count(
              crossAxisCount: 4,
              children: List<Widget>.generate(20, (int i) {
                return Container(
                  child: Text('$i'),
                );
              }),
            ),
          ),
        ),
      ),
    );

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('GridView in unbounded context', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            children: List<Widget>.generate(20, (int i) {
              return Container(
                child: Text('$i'),
              );
            }),
          ),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.text('19'), findsOneWidget);
  });

  testWidgets('GridView.builder control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
          shrinkWrap: true,
          itemCount: 20,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              child: Text('$index'),
            );
          },
        ),
      ),
    );
    expect(find.text('0'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('12'), findsNothing);
  });

  testWidgets('GridView.builder with undefined itemCount', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              child: Text('$index'),
            );
          },
        ),
      ),
    );
    expect(find.text('0'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    await tester.drag(find.byType(GridView), const Offset(0.0, -300.0));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('13'), findsOneWidget);
  });

  testWidgets('GridView cross axis layout', (WidgetTester tester) async {
    final Key target = UniqueKey();

    Widget build(TextDirection textDirection) {
      return Directionality(
        textDirection: textDirection,
        child: GridView.count(
          crossAxisCount: 4,
          children: <Widget>[
            Container(key: target),
          ],
        ),
      );
    }

    await tester.pumpWidget(build(TextDirection.ltr));

    expect(tester.getTopLeft(find.byKey(target)), Offset.zero);
    expect(tester.getBottomRight(find.byKey(target)), const Offset(200.0, 200.0));

    await tester.pumpWidget(build(TextDirection.rtl));

    expect(tester.getTopLeft(find.byKey(target)), const Offset(600.0, 0.0));
    expect(tester.getBottomRight(find.byKey(target)), const Offset(800.0, 200.0));
  });
}
