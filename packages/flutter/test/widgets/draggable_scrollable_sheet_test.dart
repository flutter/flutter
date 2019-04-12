// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget _boilerplate(VoidCallback onButtonPressed) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: <Widget>[
          FlatButton(
            child: const Text('TapHere'),
            onPressed: onButtonPressed,
          ),
          DraggableScrollableSheet(
            maxChildSize: 1.0,
            minChildSize: .25,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                color: const Color(0xFFABCDEF),
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 100,
                  itemBuilder: (BuildContext context, int index) => Text('Item $index'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  for (TargetPlatform platform in TargetPlatform.values) {
    group('$platform Scroll Physics', () {
      debugDefaultTargetPlatformOverride = platform;

      testWidgets('Can be dragged up without covering its container', (WidgetTester tester) async {
        int taps = 0;
        await tester.pumpWidget(_boilerplate(() => taps++));

        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 1);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 31'), findsNothing);

        await tester.drag(find.text('Item 1'), const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 2);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 31'), findsOneWidget);
      });

      testWidgets('Can be dragged down when not full height', (WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(null));
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 36'), findsNothing);

        await tester.drag(find.text('Item 1'), const Offset(0, 325));
        await tester.pumpAndSettle();
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsNothing);
        expect(find.text('Item 36'), findsNothing);
      });

      testWidgets('Can be dragged up and cover its container and scroll in single motion, and then dragged back down', (WidgetTester tester) async {
        int taps = 0;
        await tester.pumpWidget(_boilerplate(() => taps++));

        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 1);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 36'), findsNothing);

        await tester.drag(find.text('Item 1'), const Offset(0, -325));
        await tester.pumpAndSettle();
        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 1);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 36'), findsOneWidget);

        await tester.dragFrom(const Offset(20, 20), const Offset(0, 325));
        await tester.pumpAndSettle();
        await tester.tap(find.text('TapHere'));
        expect(taps, 2);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 18'), findsOneWidget);
        expect(find.text('Item 36'), findsNothing);
      });

      testWidgets('Can be flung up gently', (WidgetTester tester) async {
        int taps = 0;
        await tester.pumpWidget(_boilerplate(() => taps++));

        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 1);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 36'), findsNothing);
        expect(find.text('Item 70'), findsNothing);

        await tester.fling(find.text('Item 1'), const Offset(0, -200), 350);
        await tester.pumpAndSettle();
        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 2);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 36'), findsOneWidget);
        expect(find.text('Item 70'), findsNothing);
      });

      testWidgets('Can be flung up', (WidgetTester tester) async {
        int taps = 0;
        await tester.pumpWidget(_boilerplate(() => taps++));

        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 1);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 70'), findsNothing);

        await tester.fling(find.text('Item 1'), const Offset(0, -200), 2000);
        await tester.pumpAndSettle();
        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 1);
        expect(find.text('Item 1'), findsNothing);
        expect(find.text('Item 21'), findsNothing);
        expect(find.text('Item 70'), findsOneWidget);
      });

      testWidgets('Can be flung down when not full height', (WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(null));
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 36'), findsNothing);

        await tester.fling(find.text('Item 1'), const Offset(0, 325), 2000);
        await tester.pumpAndSettle();
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsNothing);
        expect(find.text('Item 36'), findsNothing);
      });

      testWidgets('Can be flung up and then back down', (WidgetTester tester) async {
        int taps = 0;
        await tester.pumpWidget(_boilerplate(() => taps++));

        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 1);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 70'), findsNothing);

        await tester.fling(find.text('Item 1'), const Offset(0, -200), 2000);
        await tester.pumpAndSettle();
        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 1);
        expect(find.text('Item 1'), findsNothing);
        expect(find.text('Item 21'), findsNothing);
        expect(find.text('Item 70'), findsOneWidget);

        await tester.fling(find.text('Item 70'), const Offset(0, 200), 2000);
        await tester.pumpAndSettle();
        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 1);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 70'), findsNothing);

        await tester.fling(find.text('Item 1'), const Offset(0, 200), 2000);
        await tester.pumpAndSettle();
        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 2);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsNothing);
        expect(find.text('Item 70'), findsNothing);
      });

      debugDefaultTargetPlatformOverride = null;
    });
  }
}
