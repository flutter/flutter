// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BottomNavigationBar callback test', (WidgetTester tester) async {
    int mutatedIndex;

    await tester.pumpWidget(
      new Scaffold(
        bottomNavigationBar: new BottomNavigationBar(
          labels: <DestinationLabel>[
            new DestinationLabel(
              icon: new Icon(Icons.ac_unit),
              title: new Text('AC')
            ),
            new DestinationLabel(
              icon: new Icon(Icons.access_alarm),
              title: new Text('Alarm')
            )
          ],
          onTap: (int index) {
            mutatedIndex = index;
          }
        )
      )
    );

    await tester.tap(find.text('Alarm'));

    expect(mutatedIndex, 1);
  });

  testWidgets('BottomNavigationBar content test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Scaffold(
        bottomNavigationBar: new BottomNavigationBar(
          labels: <DestinationLabel>[
            new DestinationLabel(
              icon: new Icon(Icons.ac_unit),
              title: new Text('AC')
            ),
            new DestinationLabel(
              icon: new Icon(Icons.access_alarm),
              title: new Text('Alarm')
            )
          ]
        )
      )
    );

    RenderBox box = tester.renderObject(find.byType(BottomNavigationBar));
    expect(box.size.height, 60.0);
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('Alarm'), findsOneWidget);
  });

  testWidgets('BottomNavigationBar action size test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Scaffold(
        bottomNavigationBar: new BottomNavigationBar(
          type: BottomNavigationBarType.shifting,
          labels: <DestinationLabel>[
            new DestinationLabel(
              icon: new Icon(Icons.ac_unit),
              title: new Text('AC')
            ),
            new DestinationLabel(
              icon: new Icon(Icons.access_alarm),
              title: new Text('Alarm')
            )
          ]
        )
      )
    );

    Iterable<RenderBox> actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.length, 2);
    expect(actions.elementAt(0).size.width, 158.4);
    expect(actions.elementAt(1).size.width, 105.6);

    await tester.pumpWidget(
      new Scaffold(
        bottomNavigationBar: new BottomNavigationBar(
          currentIndex: 1,
          type: BottomNavigationBarType.shifting,
          labels: <DestinationLabel>[
            new DestinationLabel(
              icon: new Icon(Icons.ac_unit),
              title: new Text('AC')
            ),
            new DestinationLabel(
              icon: new Icon(Icons.access_alarm),
              title: new Text('Alarm')
            )
          ]
        )
      )
    );

    await tester.pump(const Duration(milliseconds: 200));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.length, 2);
    expect(actions.elementAt(0).size.width, 105.6);
    expect(actions.elementAt(1).size.width, 158.4);
  });

  testWidgets('BottomNavigationBar multiple taps test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Scaffold(
        bottomNavigationBar: new BottomNavigationBar(
          type: BottomNavigationBarType.shifting,
          labels: <DestinationLabel>[
            new DestinationLabel(
              icon: new Icon(Icons.ac_unit),
              title: new Text('AC')
            ),
            new DestinationLabel(
              icon: new Icon(Icons.access_alarm),
              title: new Text('Alarm')
            ),
            new DestinationLabel(
              icon: new Icon(Icons.access_time),
              title: new Text('Time')
            ),
            new DestinationLabel(
              icon: new Icon(Icons.add),
              title: new Text('Add')
            )
          ]
        )
      )
    );

    // We want to make sure that the last label does not get displaced,
    // irrespective of how many taps happen on the first N - 1 labels and how
    // they grow.

    Iterable<RenderBox> actions = tester.renderObjectList(find.byType(InkResponse));
    Point originalOrigin = actions.elementAt(3).localToGlobal(Point.origin);

    await tester.tap(find.text('AC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.elementAt(3).localToGlobal(Point.origin), equals(originalOrigin));

    await tester.tap(find.text('Alarm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.elementAt(3).localToGlobal(Point.origin), equals(originalOrigin));

    await tester.tap(find.text('Time'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.elementAt(3).localToGlobal(Point.origin), equals(originalOrigin));
  });
}
