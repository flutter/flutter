// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

class TestDragData {
  const TestDragData(
    this.slop,
    this.dragDistance,
    this.expectedOffsets,
  );

  final Offset slop;
  final Offset dragDistance;
  final List<Offset> expectedOffsets;
}

void main() {
  testWidgets(
    'WidgetTester.drag must break the offset into multiple parallel components if '
    'the drag goes outside the touch slop values',
    (WidgetTester tester) async {
      // This test checks to make sure that the total drag will be correctly split into
      // pieces such that the first (and potentially second) moveBy function call(s) in
      // controller.drag() will never have a component greater than the touch
      // slop in that component's respective axis.
      const List<TestDragData> offsetResults = <TestDragData>[
        TestDragData(
          Offset(10.0, 10.0),
          Offset(-150.0, 200.0),
          <Offset>[
            Offset(-7.5, 10.0),
            Offset(-2.5, 3.333333333333333),
            Offset(-140.0, 186.66666666666666),
          ],
        ),
        TestDragData(
          Offset(10.0, 10.0),
          Offset(150, -200),
          <Offset>[
            Offset(7.5, -10),
            Offset(2.5, -3.333333333333333),
            Offset(140.0, -186.66666666666666),
          ],
        ),
        TestDragData(
          Offset(10.0, 10.0),
          Offset(-200, 150),
          <Offset>[
            Offset(-10, 7.5),
            Offset(-3.333333333333333, 2.5),
            Offset(-186.66666666666666, 140.0),
          ],
        ),
        TestDragData(
          Offset(10.0, 10.0),
          Offset(200.0, -150.0),
          <Offset>[
            Offset(10, -7.5),
            Offset(3.333333333333333, -2.5),
            Offset(186.66666666666666, -140.0),
          ],
        ),
        TestDragData(
          Offset(10.0, 10.0),
          Offset(-150.0, -200.0),
          <Offset>[
            Offset(-7.5, -10.0),
            Offset(-2.5, -3.333333333333333),
            Offset(-140.0, -186.66666666666666),
          ],
        ),
        TestDragData(
          Offset(10.0, 10.0),
          Offset(8.0, 3.0),
          <Offset>[
            Offset(8.0, 3.0),
          ],
        ),
        TestDragData(
          Offset(10.0, 10.0),
          Offset(3.0, 8.0),
          <Offset>[
            Offset(3.0, 8.0),
          ],
        ),
        TestDragData(
          Offset(10.0, 10.0),
          Offset(20.0, 5.0),
          <Offset>[
            Offset(10.0, 2.5),
            Offset(10.0, 2.5),
          ],
        ),
        TestDragData(
          Offset(10.0, 10.0),
          Offset(5.0, 20.0),
          <Offset>[
            Offset(2.5, 10.0),
            Offset(2.5, 10.0),
          ],
        ),
        TestDragData(
          Offset(10.0, 10.0),
          Offset(20.0, 15.0),
          <Offset>[
            Offset(10.0, 7.5),
            Offset(3.333333333333333, 2.5),
            Offset(6.666666666666668, 5.0),
          ],
        ),
        TestDragData(
          Offset(10.0, 10.0),
          Offset(15.0, 20.0),
          <Offset>[
            Offset(7.5, 10.0),
            Offset(2.5, 3.333333333333333),
            Offset(5.0, 6.666666666666668),
          ],
        ),
        TestDragData(
          Offset(10.0, 10.0),
          Offset(20.0, 20.0),
          <Offset>[
            Offset(10.0, 10.0),
            Offset(10.0, 10.0),
          ],
        ),
        TestDragData(
          Offset(10.0, 10.0),
          Offset(0.0, 5.0),
          <Offset>[
            Offset(0.0, 5.0),
          ],
        ),

        //// Varying touch slops
        TestDragData(
          Offset(12.0, 5.0),
          Offset(0.0, 5.0),
          <Offset>[
            Offset(0.0, 5.0),
          ],
        ),
        TestDragData(
          Offset(12.0, 5.0),
          Offset(20.0, 5.0),
          <Offset>[
            Offset(12.0, 3.0),
            Offset(8.0, 2.0),
          ],
        ),
        TestDragData(
          Offset(12.0, 5.0),
          Offset(5.0, 20.0),
          <Offset>[
            Offset(1.25, 5.0),
            Offset(3.75, 15.0),
          ],
        ),
        TestDragData(
          Offset(5.0, 12.0),
          Offset(5.0, 20.0),
          <Offset>[
            Offset(3.0, 12.0),
            Offset(2.0, 8.0),
          ],
        ),
        TestDragData(
          Offset(5.0, 12.0),
          Offset(20.0, 5.0),
          <Offset>[
            Offset(5.0, 1.25),
            Offset(15.0, 3.75),
          ],
        ),
        TestDragData(
          Offset(18.0, 18.0),
          Offset(0.0, 150.0),
          <Offset>[
            Offset(0.0, 18.0),
            Offset(0.0, 132.0),
          ],
        ),
        TestDragData(
          Offset(18.0, 18.0),
          Offset(0.0, -150.0),
          <Offset>[
            Offset(0.0, -18.0),
            Offset(0.0, -132.0),
          ],
        ),
        TestDragData(
          Offset(18.0, 18.0),
          Offset(-150.0, 0.0),
          <Offset>[
            Offset(-18.0, 0.0),
            Offset(-132.0, 0.0),
          ],
        ),
        TestDragData(
          Offset.zero,
          Offset(-150.0, 0.0),
          <Offset>[
            Offset(-150.0, 0.0),
          ],
        ),
        TestDragData(
          Offset(18.0, 18.0),
          Offset(-32.0, 0.0),
          <Offset>[
            Offset(-18.0, 0.0),
            Offset(-14.0, 0.0),
          ],
        ),
      ];

      final List<Offset> dragOffsets = <Offset>[];

      await tester.pumpWidget(
        Listener(
          onPointerMove: (PointerMoveEvent event) {
            dragOffsets.add(event.delta);
          },
          child: const Text('test', textDirection: TextDirection.ltr),
        ),
      );

      for (int resultIndex = 0; resultIndex < offsetResults.length; resultIndex += 1) {
        final TestDragData testResult = offsetResults[resultIndex];
        await tester.drag(
          find.text('test'),
          testResult.dragDistance,
          touchSlopX: testResult.slop.dx,
          touchSlopY: testResult.slop.dy,
        );
        expect(
          testResult.expectedOffsets.length,
          dragOffsets.length,
          reason:
            'There is a difference in the number of expected and actual split offsets for the drag with:\n'
            'Touch Slop: ${testResult.slop}\n'
            'Delta:      ${testResult.dragDistance}\n',
        );
        for (int valueIndex = 0; valueIndex < offsetResults[resultIndex].expectedOffsets.length; valueIndex += 1) {
          expect(
            testResult.expectedOffsets[valueIndex],
            offsetMoreOrLessEquals(dragOffsets[valueIndex]),
            reason:
              'There is a difference in the expected and actual value of the '
              '${valueIndex == 2 ? 'first' : valueIndex == 3 ? 'second' : 'third'}'
              ' split offset for the drag with:\n'
              'Touch slop: ${testResult.slop}\n'
              'Delta:      ${testResult.dragDistance}\n'
          );
        }
        dragOffsets.clear();
      }
    },
  );

  testWidgets(
    'WidgetTester.tap must respect buttons',
    (WidgetTester tester) async {
      final List<String> logs = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Listener(
            onPointerDown: (PointerDownEvent event) => logs.add('down ${event.buttons}'),
            onPointerMove: (PointerMoveEvent event) => logs.add('move ${event.buttons}'),
            onPointerUp: (PointerUpEvent event) => logs.add('up ${event.buttons}'),
            child: const Text('test'),
          ),
        ),
      );

      await tester.tap(find.text('test'), buttons: kSecondaryMouseButton);

      const String b = '$kSecondaryMouseButton';
      for(int i = 0; i < logs.length; i++) {
        if (i == 0) {
          expect(logs[i], 'down $b');
        } else if (i != logs.length - 1) {
          expect(logs[i], 'move $b');
        } else {
          expect(logs[i], 'up 0');
        }
      }
    },
  );

  testWidgets(
    'WidgetTester.press must respect buttons',
    (WidgetTester tester) async {
      final List<String> logs = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Listener(
            onPointerDown: (PointerDownEvent event) => logs.add('down ${event.buttons}'),
            onPointerMove: (PointerMoveEvent event) => logs.add('move ${event.buttons}'),
            onPointerUp: (PointerUpEvent event) => logs.add('up ${event.buttons}'),
            child: const Text('test'),
          ),
        ),
      );

      await tester.press(find.text('test'), buttons: kSecondaryMouseButton);

      const String b = '$kSecondaryMouseButton';
      expect(logs, equals(<String>['down $b']));
    },
  );

  testWidgets(
    'WidgetTester.longPress must respect buttons',
    (WidgetTester tester) async {
      final List<String> logs = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Listener(
            onPointerDown: (PointerDownEvent event) => logs.add('down ${event.buttons}'),
            onPointerMove: (PointerMoveEvent event) => logs.add('move ${event.buttons}'),
            onPointerUp: (PointerUpEvent event) => logs.add('up ${event.buttons}'),
            child: const Text('test'),
          ),
        ),
      );

      await tester.longPress(find.text('test'), buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      const String b = '$kSecondaryMouseButton';
      for(int i = 0; i < logs.length; i++) {
        if (i == 0) {
          expect(logs[i], 'down $b');
        } else if (i != logs.length - 1) {
          expect(logs[i], 'move $b');
        } else {
          expect(logs[i], 'up 0');
        }
      }
    },
  );

  testWidgets(
    'WidgetTester.drag must respect buttons',
    (WidgetTester tester) async {
      final List<String> logs = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Listener(
            onPointerDown: (PointerDownEvent event) => logs.add('down ${event.buttons}'),
            onPointerMove: (PointerMoveEvent event) => logs.add('move ${event.buttons}'),
            onPointerUp: (PointerUpEvent event) => logs.add('up ${event.buttons}'),
            child: const Text('test'),
          ),
        ),
      );

      await tester.drag(find.text('test'), const Offset(-150.0, 200.0), buttons: kSecondaryMouseButton);

      const String b = '$kSecondaryMouseButton';
      for(int i = 0; i < logs.length; i++) {
        if (i == 0) {
          expect(logs[i], 'down $b');
        } else if (i != logs.length - 1) {
          expect(logs[i], 'move $b');
        } else {
          expect(logs[i], 'up 0');
        }
      }
    },
  );

  testWidgets(
    'WidgetTester.drag works with trackpad kind',
    (WidgetTester tester) async {
      final List<String> logs = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Listener(
            onPointerDown: (PointerDownEvent event) => logs.add('down ${event.buttons}'),
            onPointerMove: (PointerMoveEvent event) => logs.add('move ${event.buttons}'),
            onPointerUp: (PointerUpEvent event) => logs.add('up ${event.buttons}'),
            onPointerPanZoomStart: (PointerPanZoomStartEvent event) => logs.add('panZoomStart'),
            onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) => logs.add('panZoomUpdate ${event.pan}'),
            onPointerPanZoomEnd: (PointerPanZoomEndEvent event) => logs.add('panZoomEnd'),
            child: const Text('test'),
          ),
        ),
      );

      await tester.drag(find.text('test'), const Offset(-150.0, 200.0), kind: PointerDeviceKind.trackpad);

      for(int i = 0; i < logs.length; i++) {
        if (i == 0) {
          expect(logs[i], 'panZoomStart');
        } else if (i != logs.length - 1) {
          expect(logs[i], startsWith('panZoomUpdate'));
        } else {
          expect(logs[i], 'panZoomEnd');
        }
      }
    },
  );

  testWidgets(
    'WidgetTester.fling must respect buttons',
    (WidgetTester tester) async {
      final List<String> logs = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Listener(
            onPointerDown: (PointerDownEvent event) => logs.add('down ${event.buttons}'),
            onPointerMove: (PointerMoveEvent event) => logs.add('move ${event.buttons}'),
            onPointerUp: (PointerUpEvent event) => logs.add('up ${event.buttons}'),
            child: const Text('test'),
          ),
        ),
      );

      await tester.fling(find.text('test'), const Offset(-10.0, 0.0), 1000.0, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      const String b = '$kSecondaryMouseButton';
      for(int i = 0; i < logs.length; i++) {
        if (i == 0) {
          expect(logs[i], 'down $b');
        } else if (i != logs.length - 1) {
          expect(logs[i], 'move $b');
        } else {
          expect(logs[i], 'up 0');
        }
      }
    },
  );

  testWidgets(
    'WidgetTester.fling produces strictly monotonically increasing timestamps, '
    'when given a large velocity',
    (WidgetTester tester) async {
      // Velocity trackers may misbehave if the `PointerMoveEvent`s' have the
      // same timestamp. This is more likely to happen when the velocity tracker
      // has a small sample size.
      final List<Duration> logs = <Duration>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Listener(
            onPointerMove: (PointerMoveEvent event) => logs.add(event.timeStamp),
            child: const Text('test'),
          ),
        ),
      );

      await tester.fling(find.text('test'), const Offset(0.0, -50.0), 10000.0);
      await tester.pumpAndSettle();

      for (int i = 0; i + 1 < logs.length; i += 1) {
        expect(logs[i + 1],  greaterThan(logs[i]));
      }
  });

  testWidgets(
    'WidgetTester.timedDrag must respect buttons',
    (WidgetTester tester) async {
      final List<String> logs = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Listener(
            onPointerDown: (PointerDownEvent event) => logs.add('down ${event.buttons}'),
            onPointerMove: (PointerMoveEvent event) => logs.add('move ${event.buttons}'),
            onPointerUp: (PointerUpEvent event) => logs.add('up ${event.buttons}'),
            child: const Text('test'),
          ),
        ),
      );

      await tester.timedDrag(
        find.text('test'),
        const Offset(-200.0, 0.0),
        const Duration(seconds: 1),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();

      const String b = '$kSecondaryMouseButton';
      for(int i = 0; i < logs.length; i++) {
        if (i == 0) {
          expect(logs[i], 'down $b');
        } else if (i != logs.length - 1) {
          expect(logs[i], 'move $b');
        } else {
          expect(logs[i], 'up 0');
        }
      }
    },
  );

  testWidgets(
    'WidgetTester.timedDrag uses correct pointer',
    (WidgetTester tester) async {
      final List<String> logs = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Listener(
            onPointerDown: (PointerDownEvent event) => logs.add('down ${event.pointer}'),
            child: const Text('test'),
          ),
        ),
      );

      await tester.timedDrag(
        find.text('test'),
        const Offset(-200.0, 0.0),
        const Duration(seconds: 1),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();

      await tester.timedDrag(
        find.text('test'),
        const Offset(200.0, 0.0),
        const Duration(seconds: 1),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();

      expect(logs.length, 2);
      expect(logs[0], isNotNull);
      expect(logs[1], isNotNull);
      expect(logs[1] != logs[0], isTrue);
    },
  );

  testWidgets(
    'ensureVisible: scrolls to make widget visible',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 20,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int i) => ListTile(title: Text('Item $i')),
            ),
          ),
        ),
      );

      // Make sure widget isn't on screen
      expect(find.text('Item 15'), findsNothing);

      await tester.ensureVisible(find.text('Item 15', skipOffstage: false));
      await tester.pumpAndSettle();

      expect(find.text('Item 15'), findsOneWidget);
    },
  );

  group('scrollUntilVisible: scrolls to make unbuilt widget visible', () {
    testWidgets(
      'Vertical',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 50,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int i) => ListTile(title: Text('Item $i')),
              ),
            ),
          ),
        );

        // Make sure widget isn't built yet.
        expect(find.text('Item 45', skipOffstage: false), findsNothing);

        await tester.scrollUntilVisible(
          find.text('Item 45', skipOffstage: false),
          100,
        );
        await tester.pumpAndSettle();

        // Now the widget is on screen.
        expect(find.text('Item 45'), findsOneWidget);
      },
    );

    testWidgets(
      'Horizontal',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 50,
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                // ListTile does not support horizontal list
                itemBuilder: (BuildContext context, int i) => Text('Item $i'),
              ),
            ),
          ),
        );

        // Make sure widget isn't built yet.
        expect(find.text('Item 45', skipOffstage: false), findsNothing);

        await tester.scrollUntilVisible(
          find.text('Item 45', skipOffstage: false),
          100,
        );
        await tester.pumpAndSettle();

        // Now the widget is on screen.
        expect(find.text('Item 45'), findsOneWidget);
      },
    );

    testWidgets(
      'Fail',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 50,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int i) => ListTile(title: Text('Item $i')),
              ),
            ),
          ),
        );

        try {
          await tester.scrollUntilVisible(
            find.text('Item 55', skipOffstage: false),
            100,
          );
        } on StateError catch (e) {
          expect(e.message, 'No element');
        }
      },
    );

    testWidgets('Drag Until Visible', (WidgetTester tester) async {
      // when there are two implicit [Scrollable], `scrollUntilVisible` is hard
      // to use.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                SizedBox(height: 200, child: ListView.builder(
                  key: const Key('listView-a'),
                  itemCount: 50,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int i) => ListTile(title: Text('Item a-$i')),
                )),
                const Divider(thickness: 5),
                Expanded(child: ListView.builder(
                  key: const Key('listView-b'),
                  itemCount: 50,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int i) => ListTile(title: Text('Item b-$i')),
                )),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scrollable), findsNWidgets(2));

      // Make sure widget isn't built yet.
      expect(find.text('Item b-45', skipOffstage: false), findsNothing);

      await tester.dragUntilVisible(
        find.text('Item b-45', skipOffstage: false),
        find.byKey(const ValueKey<String>('listView-b')),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      // Now the widget is on screen.
      expect(find.text('Item b-45'), findsOneWidget);
    });
  });

  group('SemanticsController', () {
    group('find', () {
      testWidgets('throws when there are no semantics', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Text('hello'),
            ),
          ),
        );

        expect(() => tester.semantics.find(find.text('hello')), throwsStateError);
      }, semanticsEnabled: false);

      testWidgets('throws when there are multiple results from the finder', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: const <Widget>[
                  Text('hello'),
                  Text('hello'),
                ],
              ),
            ),
          ),
        );

        expect(() => tester.semantics.find(find.text('hello')), throwsStateError);
      });

      testWidgets('Returns the correct SemanticsData', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OutlinedButton(
                onPressed: () { },
                child: const Text('hello'),
              ),
            ),
          ),
        );

        final SemanticsNode node = tester.semantics.find(find.text('hello'));
        final SemanticsData semantics = node.getSemanticsData();
        expect(semantics.label, 'hello');
        expect(semantics.hasAction(SemanticsAction.tap), true);
        expect(semantics.hasFlag(SemanticsFlag.isButton), true);
      });

      testWidgets('Can enable semantics for tests via semanticsEnabled', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OutlinedButton(
                onPressed: () { },
                child: const Text('hello'),
              ),
            ),
          ),
        );

        final SemanticsNode node = tester.semantics.find(find.text('hello'));
        final SemanticsData semantics = node.getSemanticsData();
        expect(semantics.label, 'hello');
        expect(semantics.hasAction(SemanticsAction.tap), true);
        expect(semantics.hasFlag(SemanticsFlag.isButton), true);
      });

      testWidgets('Returns merged SemanticsData', (WidgetTester tester) async {
        const Key key = Key('test');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Semantics(
                label: 'A',
                child: Semantics(
                  label: 'B',
                  child: Semantics(
                    key: key,
                    label: 'C',
                    child: Container(),
                  ),
                ),
              ),
            ),
          ),
        );

        final SemanticsNode node = tester.semantics.find(find.byKey(key));
        final SemanticsData semantics = node.getSemanticsData();
        expect(semantics.label, 'A\nB\nC');
      });

      testWidgets('Does not return partial semantics', (WidgetTester tester) async {
        final Key key = UniqueKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MergeSemantics(
                child: Semantics(
                  container: true,
                  label: 'A',
                  child: Semantics(
                    container: true,
                    key: key,
                    label: 'B',
                    child: Container(),
                  ),
                ),
              ),
            ),
          ),
        );

        final SemanticsNode node = tester.semantics.find(find.byKey(key));
        final SemanticsData semantics = node.getSemanticsData();
        expect(semantics.label, 'A\nB');
      });
    });

    group('simulatedTraversal', () {
      final List<Matcher> fullTraversalMatchers = <Matcher>[
        containsSemantics(isHeader: true, label: 'Semantics Test'),
        containsSemantics(isTextField: true),
        containsSemantics(label: 'Off Switch'),
        containsSemantics(hasToggledState: true),
        containsSemantics(label: 'On Switch'),
        containsSemantics(hasToggledState: true, isToggled: true),
        containsSemantics(label: "Multiline\nIt's a\nmultiline label!"),
        containsSemantics(label: 'Slider'),
        containsSemantics(isSlider: true, value: '50%'),
        containsSemantics(label: 'Enabled Button'),
        containsSemantics(isButton: true, label: 'Tap'),
        containsSemantics(label: 'Disabled Button'),
        containsSemantics(isButton: true, label: "Don't Tap"),
        containsSemantics(label: 'Checked Radio'),
        containsSemantics(hasCheckedState: true, isChecked: true),
        containsSemantics(label: 'Unchecked Radio'),
        containsSemantics(hasCheckedState: true, isChecked: false),
      ];

      testWidgets('produces expected traversal', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: _SemanticsTestWidget()));

        expect(
          tester.semantics.simulatedAccessibilityTraversal(),
          orderedEquals(fullTraversalMatchers));
      });

      testWidgets('starts traversal at semantics node for `start`', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: _SemanticsTestWidget()));

        // We're expecting the traversal to start where the slider is.
        final List<Matcher> expectedMatchers = <Matcher>[...fullTraversalMatchers]..removeRange(0, 8);

        expect(
          tester.semantics.simulatedAccessibilityTraversal(start: find.byType(Slider)),
          orderedEquals(expectedMatchers));
      });

      testWidgets('throws StateError if `start` not found in traversal', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: _SemanticsTestWidget()));

        // We look for a SingleChildScrollView since the view itself isn't
        // important for accessiblity, so it won't show up in the traversal
        expect(
          () => tester.semantics.simulatedAccessibilityTraversal(start: find.byType(SingleChildScrollView)),
          throwsA(isA<StateError>()),
        );
      });

      testWidgets('ends traversal at semantics node for `end`', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: _SemanticsTestWidget()));

        // We're expecting the traversal to end where the slider is, inclusive.
        final Iterable<Matcher> expectedMatchers = <Matcher>[...fullTraversalMatchers].getRange(0, 9);

        expect(
          tester.semantics.simulatedAccessibilityTraversal(end: find.byType(Slider)),
          orderedEquals(expectedMatchers));
      });

      testWidgets('throws StateError if `end` not found in traversal', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: _SemanticsTestWidget()));

        // We look for a SingleChildScrollView since the view itself isn't
        // important for semantics, so it won't show up in the traversal
        expect(
          () => tester.semantics.simulatedAccessibilityTraversal(end: find.byType(SingleChildScrollView)),
          throwsA(isA<StateError>()),
        );
      });

      testWidgets('returns traversal between `start` and `end` if both are provided', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: _SemanticsTestWidget()));

        // We're expecting the traversal to start at the text field and end at the slider.
        final Iterable<Matcher> expectedMatchers = <Matcher>[...fullTraversalMatchers].getRange(1, 9);

        expect(
          tester.semantics.simulatedAccessibilityTraversal(
            start: find.byType(TextField),
            end: find.byType(Slider),
          ),
          orderedEquals(expectedMatchers));
      });

      testWidgets('can do fuzzy traversal match with `containsAllInOrder`', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: _SemanticsTestWidget()));

        // Grab a sample of the matchers to validate that not every matcher is
        // needed to validate a traversal when using `containsAllInOrder`.
        final Iterable<Matcher> expectedMatchers = <Matcher>[...fullTraversalMatchers]
          ..removeAt(0)
          ..removeLast()
          ..mapIndexed<Matcher?>((int i, Matcher element) => i.isEven ? element : null)
          .whereNotNull();

        expect(
          tester.semantics.simulatedAccessibilityTraversal(),
          containsAllInOrder(expectedMatchers));
      });
    });
  });
}

class _SemanticsTestWidget extends StatelessWidget {
  const _SemanticsTestWidget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Semantics Test')),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const _SemanticsTestCard(
              label: 'TextField',
              widget: TextField(),
            ),
            _SemanticsTestCard(
              label: 'Off Switch',
              widget: Switch(value: false, onChanged: (bool value) {}),
            ),
            _SemanticsTestCard(
              label: 'On Switch',
              widget: Switch(value: true, onChanged: (bool value) {}),
            ),
            const _SemanticsTestCard(
              label: 'Multiline',
              widget: Text("It's a\nmultiline label!", maxLines: 2),
            ),
            _SemanticsTestCard(
              label: 'Slider',
              widget: Slider(value: .5, onChanged: (double value) {}),
            ),
            _SemanticsTestCard(
              label: 'Enabled Button',
              widget: TextButton(onPressed: () {}, child: const Text('Tap')),
            ),
            const _SemanticsTestCard(
              label: 'Disabled Button',
              widget: TextButton(onPressed: null, child: Text("Don't Tap")),
            ),
            _SemanticsTestCard(
              label: 'Checked Radio',
              widget: Radio<String>(
                value: 'checked',
                groupValue: 'checked',
                onChanged: (String? value) {},
              ),
            ),
            _SemanticsTestCard(
              label: 'Unchecked Radio',
              widget: Radio<String>(
                value: 'unchecked',
                groupValue: 'checked',
                onChanged: (String? value) {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SemanticsTestCard extends StatelessWidget {
  const _SemanticsTestCard({required this.label, required this.widget});

  final String label;
  final Widget widget;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: SizedBox(width: 200, child: widget),
      ),
    );
  }
}
