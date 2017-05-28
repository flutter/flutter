// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BottomNavigationBar callback test', (WidgetTester tester) async {
    int mutatedIndex;

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          bottomNavigationBar: new BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: const Icon(Icons.ac_unit),
                title: const Text('AC')
              ),
              const BottomNavigationBarItem(
                icon: const Icon(Icons.access_alarm),
                title: const Text('Alarm')
              )
            ],
            onTap: (int index) {
              mutatedIndex = index;
            }
          )
        )
      )
    );

    await tester.tap(find.text('Alarm'));

    expect(mutatedIndex, 1);
  });

  testWidgets('BottomNavigationBar content test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          bottomNavigationBar: new BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: const Icon(Icons.ac_unit),
                title: const Text('AC')
              ),
              const BottomNavigationBarItem(
                icon: const Icon(Icons.access_alarm),
                title: const Text('Alarm')
              )
            ]
          )
        )
      )
    );

    final RenderBox box = tester.renderObject(find.byType(BottomNavigationBar));
    expect(box.size.height, 60.0);
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('Alarm'), findsOneWidget);
  });

  testWidgets('BottomNavigationBar action size test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          bottomNavigationBar: new BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: const Icon(Icons.ac_unit),
                title: const Text('AC')
              ),
              const BottomNavigationBarItem(
                icon: const Icon(Icons.access_alarm),
                title: const Text('Alarm')
              )
            ]
          )
        )
      )
    );

    Iterable<RenderBox> actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.length, 2);
    expect(actions.elementAt(0).size.width, 158.4);
    expect(actions.elementAt(1).size.width, 105.6);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          bottomNavigationBar: new BottomNavigationBar(
            currentIndex: 1,
            type: BottomNavigationBarType.shifting,
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: const Icon(Icons.ac_unit),
                title: const Text('AC')
              ),
              const BottomNavigationBarItem(
                icon: const Icon(Icons.access_alarm),
                title: const Text('Alarm')
              )
            ]
          )
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
      new MaterialApp(
        home: new Scaffold(
          bottomNavigationBar: new BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: const Icon(Icons.ac_unit),
                title: const Text('AC')
              ),
              const BottomNavigationBarItem(
                icon: const Icon(Icons.access_alarm),
                title: const Text('Alarm')
              ),
              const BottomNavigationBarItem(
                icon: const Icon(Icons.access_time),
                title: const Text('Time')
              ),
              const BottomNavigationBarItem(
                icon: const Icon(Icons.add),
                title: const Text('Add')
              )
            ]
          )
        )
      )
    );

    // We want to make sure that the last label does not get displaced,
    // irrespective of how many taps happen on the first N - 1 labels and how
    // they grow.

    Iterable<RenderBox> actions = tester.renderObjectList(find.byType(InkResponse));
    final Offset originalOrigin = actions.elementAt(3).localToGlobal(Offset.zero);

    await tester.tap(find.text('AC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.elementAt(3).localToGlobal(Offset.zero), equals(originalOrigin));

    await tester.tap(find.text('Alarm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.elementAt(3).localToGlobal(Offset.zero), equals(originalOrigin));

    await tester.tap(find.text('Time'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.elementAt(3).localToGlobal(Offset.zero), equals(originalOrigin));
  });

  testWidgets('BottomNavigationBar inherits shadowed app theme for shifting navbar', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.light),
        home: new Theme(
          data: new ThemeData(brightness: Brightness.dark),
          child: new Scaffold(
            bottomNavigationBar: new BottomNavigationBar(
              type: BottomNavigationBarType.shifting,
              items: <BottomNavigationBarItem>[
                const BottomNavigationBarItem(
                  icon: const Icon(Icons.ac_unit),
                  title: const Text('AC')
                ),
                const BottomNavigationBarItem(
                  icon: const Icon(Icons.access_alarm),
                  title: const Text('Alarm')
                ),
                const BottomNavigationBarItem(
                  icon: const Icon(Icons.access_time),
                  title: const Text('Time')
                ),
                const BottomNavigationBarItem(
                  icon: const Icon(Icons.add),
                  title: const Text('Add')
                )
              ]
            )
          )
        )
      )
    );

    await tester.tap(find.text('Alarm'));
    await tester.pump(const Duration(seconds: 1));
    expect(Theme.of(tester.element(find.text('Alarm'))).brightness, equals(Brightness.dark));
  });

  testWidgets('BottomNavigationBar inherits shadowed app theme for fixed navbar', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.light),
        home: new Theme(
          data: new ThemeData(brightness: Brightness.dark),
          child: new Scaffold(
            bottomNavigationBar: new BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              items: <BottomNavigationBarItem>[
                const BottomNavigationBarItem(
                  icon: const Icon(Icons.ac_unit),
                  title: const Text('AC')
                ),
                const BottomNavigationBarItem(
                  icon: const Icon(Icons.access_alarm),
                  title: const Text('Alarm')
                ),
                const BottomNavigationBarItem(
                  icon: const Icon(Icons.access_time),
                  title: const Text('Time')
                ),
                const BottomNavigationBarItem(
                  icon: const Icon(Icons.add),
                  title: const Text('Add')
                )
              ]
            )
          )
        )
      )
    );

    await tester.tap(find.text('Alarm'));
    await tester.pump(const Duration(seconds: 1));
    expect(Theme.of(tester.element(find.text('Alarm'))).brightness, equals(Brightness.dark));
  });

  testWidgets('BottomNavigationBar iconSize test', (WidgetTester tester) async {
    double builderIconSize;
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          bottomNavigationBar: new BottomNavigationBar(
            iconSize: 12.0,
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                title: const Text('A'),
                icon: const Icon(Icons.ac_unit),
              ),
              new BottomNavigationBarItem(
                title: const Text('B'),
                icon: new Builder(
                  builder: (BuildContext context) {
                    builderIconSize = IconTheme.of(context).size;
                    return new SizedBox(
                      width: builderIconSize,
                      height: builderIconSize,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(Icon));
    expect(box.size.width, equals(12.0));
    expect(box.size.height, equals(12.0));
    expect(builderIconSize, 12.0);
  });


}
