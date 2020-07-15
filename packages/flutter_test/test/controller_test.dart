// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

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
          Offset(0.0, 0.0),
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
              'There is a difference in the expected and actual value of the ' +
              (valueIndex == 2 ? 'first' : valueIndex == 3 ? 'second' : 'third') +
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
        if (i == 0)
          expect(logs[i], 'down $b');
        else if (i != logs.length - 1)
          expect(logs[i], 'move $b');
        else
          expect(logs[i], 'up 0');
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
        if (i == 0)
          expect(logs[i], 'down $b');
        else if (i != logs.length - 1)
          expect(logs[i], 'move $b');
        else
          expect(logs[i], 'up 0');
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
        if (i == 0)
          expect(logs[i], 'down $b');
        else if (i != logs.length - 1)
          expect(logs[i], 'move $b');
        else
          expect(logs[i], 'up 0');
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
        if (i == 0)
          expect(logs[i], 'down $b');
        else if (i != logs.length - 1)
          expect(logs[i], 'move $b');
        else
          expect(logs[i], 'up 0');
      }
    },
  );

  testWidgets(
    'ensureVisibl: scrolls to make widget visible',
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
      expect(find.text('Item 15', skipOffstage: true), findsNothing);

      await tester.ensureVisible(find.text('Item 15', skipOffstage: false));
      await tester.pumpAndSettle();

      expect(find.text('Item 15', skipOffstage: true), findsOneWidget);
    },
  );
}
