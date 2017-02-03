// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('ListView itemExtent control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new ListView(
        itemExtent: 200.0,
        children: new List<Widget>.generate(20, (int i) {
          return new Container(
            child: new Text('$i'),
          );
        }),
      ),
    );

    RenderBox box = tester.renderObject<RenderBox>(find.byType(Container).first);
    expect(box.size.height, equals(200.0));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);

    await tester.scroll(find.byType(ListView), const Offset(0.0, -250.0));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsNothing);
    expect(find.text('6'), findsNothing);

    await tester.scroll(find.byType(ListView), const Offset(0.0, 200.0));
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('ListView large scroll jump', (WidgetTester tester) async {
    List<int> log = <int>[];

    await tester.pumpWidget(
      new ListView(
        itemExtent: 200.0,
        children: new List<Widget>.generate(20, (int i) {
          return new Builder(
            builder: (BuildContext context) {
              log.add(i);
              return new Container(
                child: new Text('$i'),
              );
            }
          );
        }),
      ),
    );

    expect(log, equals(<int>[0, 1, 2]));
    log.clear();

    Scrollable2State state = tester.state(find.byType(Scrollable2));
    ScrollPosition position = state.position;
    position.jumpTo(2025.0);

    expect(log, isEmpty);
    await tester.pump();

    expect(log, equals(<int>[10, 11, 12, 13]));
    log.clear();

    position.jumpTo(975.0);

    expect(log, isEmpty);
    await tester.pump();

    expect(log, equals(<int>[4, 5, 6, 7]));
    log.clear();
  });
}
