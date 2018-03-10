// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('BottomNavigationBar callback test', (WidgetTester tester) async {
    int mutatedIndex;

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          bottomNavigationBar: new BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
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
            items: const <BottomNavigationBarItem>[
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
    expect(box.size.height, kBottomNavigationBarHeight);
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('Alarm'), findsOneWidget);
  });

  testWidgets('BottomNavigationBar adds bottom padding to height', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new MediaQuery(
          data: const MediaQueryData(padding: const EdgeInsets.only(bottom: 40.0)),
          child: new Scaffold(
            bottomNavigationBar: new BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
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
      )
    );

    const double labelBottomMargin = 8.0; // _kBottomMargin in implementation.
    const double additionalPadding = 40.0 - labelBottomMargin;
    const double expectedHeight = kBottomNavigationBarHeight + additionalPadding;
    expect(tester.getSize(find.byType(BottomNavigationBar)).height, expectedHeight);
  });

  testWidgets('BottomNavigationBar action size test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          bottomNavigationBar: new BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            items: const <BottomNavigationBarItem>[
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
    expect(actions.elementAt(0).size.width, 480.0);
    expect(actions.elementAt(1).size.width, 320.0);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          bottomNavigationBar: new BottomNavigationBar(
            currentIndex: 1,
            type: BottomNavigationBarType.shifting,
            items: const <BottomNavigationBarItem>[
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
    expect(actions.elementAt(0).size.width, 320.0);
    expect(actions.elementAt(1).size.width, 480.0);
  });

  testWidgets('BottomNavigationBar multiple taps test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          bottomNavigationBar: new BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            items: const <BottomNavigationBarItem>[
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
              items: const <BottomNavigationBarItem>[
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
              items: const <BottomNavigationBarItem>[
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


  testWidgets('BottomNavigationBar responds to textScaleFactor', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          bottomNavigationBar: new BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                title: const Text('A'),
                icon: const Icon(Icons.ac_unit),
              ),
              const BottomNavigationBarItem(
                title: const Text('B'),
                icon: const Icon(Icons.battery_alert),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox defaultBox = tester.renderObject(find.byType(BottomNavigationBar));
    expect(defaultBox.size.height, equals(kBottomNavigationBarHeight));

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          bottomNavigationBar: new BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            items: const <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                title: const Text('A'),
                icon: const Icon(Icons.ac_unit),
              ),
              const BottomNavigationBarItem(
                title: const Text('B'),
                icon: const Icon(Icons.battery_alert),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox shiftingBox = tester.renderObject(find.byType(BottomNavigationBar));
    expect(shiftingBox.size.height, equals(kBottomNavigationBarHeight));

    await tester.pumpWidget(
      new MaterialApp(
        home: new MediaQuery(
          data: const MediaQueryData(textScaleFactor: 2.0),
          child: new Scaffold(
            bottomNavigationBar: new BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                const BottomNavigationBarItem(
                  title: const Text('A'),
                  icon: const Icon(Icons.ac_unit),
                ),
                const BottomNavigationBarItem(
                  title: const Text('B'),
                  icon: const Icon(Icons.battery_alert),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(BottomNavigationBar));
    expect(box.size.height, equals(68.0));
  });

  testWidgets('BottomNavigationBar limits width of tiles with long titles', (WidgetTester tester) async {
    final Text longTextA = new Text(''.padLeft(100, 'A'));
    final Text longTextB = new Text(''.padLeft(100, 'B'));

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          bottomNavigationBar: new BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              new BottomNavigationBarItem(
                title: longTextA,
                icon: const Icon(Icons.ac_unit),
              ),
              new BottomNavigationBarItem(
                title: longTextB,
                icon: const Icon(Icons.battery_alert),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(BottomNavigationBar));
    expect(box.size.height, equals(kBottomNavigationBarHeight));

    final RenderBox itemBoxA = tester.renderObject(find.text(longTextA.data));
    expect(itemBoxA.size, equals(const Size(400.0, 14.0)));
    final RenderBox itemBoxB = tester.renderObject(find.text(longTextB.data));
    expect(itemBoxB.size, equals(const Size(400.0, 14.0)));
  });

  testWidgets('BottomNavigationBar paints circles', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.ltr,
        bottomNavigationBar: new BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              title: const Text('A'),
              icon: const Icon(Icons.ac_unit),
            ),
            const BottomNavigationBarItem(
              title: const Text('B'),
              icon: const Icon(Icons.battery_alert),
            ),
          ],
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(BottomNavigationBar));
    expect(box, isNot(paints..circle()));

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(box, paints..circle(x: 200.0));

    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(box, paints..circle(x: 200.0)..circle(x: 600.0));

    // Now we flip the directionality and verify that the circles switch positions.
    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.rtl,
        bottomNavigationBar: new BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              title: const Text('A'),
              icon: const Icon(Icons.ac_unit),
            ),
            const BottomNavigationBarItem(
              title: const Text('B'),
              icon: const Icon(Icons.battery_alert),
            ),
          ],
        ),
      ),
    );

    expect(box, paints..circle(x: 600.0)..circle(x: 200.0));

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(box, paints..circle(x: 600.0)..circle(x: 200.0)..circle(x: 600.0));
  });

  testWidgets('BottomNavigationBar semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.ltr,
        bottomNavigationBar: new BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: const Icon(Icons.ac_unit),
              title: const Text('AC'),
            ),
            const BottomNavigationBarItem(
              icon: const Icon(Icons.access_alarm),
              title: const Text('Alarm'),
            ),
            const BottomNavigationBarItem(
              icon: const Icon(Icons.hot_tub),
              title: const Text('Hot Tub'),
            ),
          ],
        ),
      ),
    );

    // TODO(goderbauer): traversal order is incorrect, https://github.com/flutter/flutter/issues/14375
    final TestSemantics expected = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics(
          id: 1,
          flags: <SemanticsFlag>[SemanticsFlag.isSelected],
          actions: <SemanticsAction>[SemanticsAction.tap],
          label: 'AC\nTab 1 of 3',
          textDirection: TextDirection.ltr,
          nextNodeId: -1,
          previousNodeId: 3, // Should be 2
        ),
        new TestSemantics(
          id: 2,
          actions: <SemanticsAction>[SemanticsAction.tap],
          label: 'Alarm\nTab 2 of 3',
          textDirection: TextDirection.ltr,
          nextNodeId: 3,
          previousNodeId: -1, // Should be 1
        ),
        new TestSemantics(
          id: 3,
          actions: <SemanticsAction>[SemanticsAction.tap],
          label: 'Hot Tub\nTab 3 of 3',
          textDirection: TextDirection.ltr,
          nextNodeId: 1, // Should be -1
          previousNodeId: 2,
        ),
      ],
    );
    expect(semantics, hasSemantics(expected, ignoreTransform: true, ignoreRect: true));

    semantics.dispose();
  });

}

Widget boilerplate({ Widget bottomNavigationBar, @required TextDirection textDirection }) {
  assert(textDirection != null);
  return new Localizations(
    locale: const Locale('en', 'US'),
    delegates: const <LocalizationsDelegate<dynamic>>[
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    child: new Directionality(
      textDirection: textDirection,
      child: new MediaQuery(
        data: const MediaQueryData(),
        child: new Material(
          child: new Scaffold(
            bottomNavigationBar: bottomNavigationBar,
          ),
        ),
      ),
    ),
  );
}
