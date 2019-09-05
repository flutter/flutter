// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';

void main() {
  const double _kOpenScale = 1.2;
  final UniqueKey childKey = UniqueKey();
  final Widget child = Container(
    key: childKey,
    width: 100.0,
    height: 100.0,
    color: CupertinoColors.activeOrange,
  );

  Widget _getContextMenu() {
    return CupertinoApp(
      home: CupertinoPageScaffold(
        child: Center(
          child: ContextMenu(
            actions: const <ContextMenuSheetAction>[
              ContextMenuSheetAction(
                child: Text('ContextMenuSheetAction'),
              ),
            ],
            child: child,
          ),
        ),
      ),
    );
  }

  // Finds the child widget that is rendered inside of _DecoyChild.
  Finder _findDecoyChild(Widget child) {
    return find.descendant(
      of: find.byType(ShaderMask),
      matching: find.byWidgetPredicate((Widget w) => w == child),
    );
  }

  // Finds the child widget rendered inside of _ContextMenuRouteStatic.
  Finder _findStatic() {
    return find.descendant(
      of: find.byType(CupertinoApp),
      matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_ContextMenuRouteStatic'),
    );
  }

  Finder _findStaticChild(Widget child) {
    return find.descendant(
      of: _findStatic(),
      matching: find.byWidgetPredicate((Widget w) => w == child),
    );
  }

  group('ContextMenu before and during opening', () {
    testWidgets('An unopened ContextMenu renders child in the same place as without', (WidgetTester tester) async {
      // Measure the child in the scene with no ContextMenu.
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: child,
            ),
          ),
        ),
      );
      final Rect childRect = tester.getRect(find.byKey(childKey));

      // When wrapped in a ContextMenu, the child is rendered in the same Rect.
      await tester.pumpWidget(_getContextMenu());
      expect(find.byKey(childKey), findsOneWidget);
      expect(tester.getRect(find.byKey(childKey)), childRect);
    });

    testWidgets('Can open ContextMenu by tap and hold', (WidgetTester tester) async {
      await tester.pumpWidget(_getContextMenu());
      expect(find.byKey(childKey), findsOneWidget);
      final Rect childRect = tester.getRect(find.byKey(childKey));
      expect(find.byType(ShaderMask), findsNothing);

      // Start a press on the child.
      final TestGesture gesture = await tester.startGesture(childRect.center);
      await tester.pump();

      // The _DecoyChild is showing directly on top of the child.
      expect(_findDecoyChild(child), findsOneWidget);
      Rect decoyChildRect = tester.getRect(_findDecoyChild(child));
      expect(childRect, equals(decoyChildRect));

      // After a small delay, the _DecoyChild has begun to animate.
      await tester.pump(const Duration(milliseconds: 100));
      decoyChildRect = tester.getRect(_findDecoyChild(child));
      expect(childRect, isNot(equals(decoyChildRect)));

      // Eventually the decoy fully scales by _kOpenSize.
      await tester.pump(const Duration(milliseconds: 500));
      decoyChildRect = tester.getRect(_findDecoyChild(child));
      expect(childRect, isNot(equals(decoyChildRect)));
      expect(decoyChildRect.width, childRect.width * _kOpenScale);

      // Then the ContextMenu opens.
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_findStatic(), findsOneWidget);
    });
  });

  group('ContextMenu when open', () {
    testWidgets('Can close ContextMenu by background tap', (WidgetTester tester) async {
      await tester.pumpWidget(_getContextMenu());

      // Open the ContextMenu
      final Rect childRect = tester.getRect(find.byKey(childKey));
      final TestGesture gesture = await tester.startGesture(childRect.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_findStatic(), findsOneWidget);

      // Tap and ensure that the ContextMenu is closed.
      await tester.tapAt(const Offset(1.0, 1.0));
      await tester.pumpAndSettle();
      expect(_findStatic(), findsNothing);
    });

    testWidgets('Can close ContextMenu by dragging down', (WidgetTester tester) async {
      await tester.pumpWidget(_getContextMenu());

      // Open the ContextMenu
      final Rect childRect = tester.getRect(find.byKey(childKey));
      final TestGesture gesture = await tester.startGesture(childRect.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_findStatic(), findsOneWidget);

      // Drag down not far enough and it bounces back and doesn't close.
      expect(_findStaticChild(child), findsOneWidget);
      Offset staticChildCenter = tester.getCenter(_findStaticChild(child));
      TestGesture swipeGesture = await tester.startGesture(staticChildCenter);
      await swipeGesture.moveBy(
        const Offset(0.0, 100.0),
        timeStamp: const Duration(milliseconds: 100),
      );
      await tester.pump();
      await swipeGesture.up();
      await tester.pump();
      expect(tester.getCenter(_findStaticChild(child)).dy, greaterThan(staticChildCenter.dy));
      await tester.pumpAndSettle();
      expect(tester.getCenter(_findStaticChild(child)), equals(staticChildCenter));
      expect(_findStatic(), findsOneWidget);

      // Drag down far enough and it does close.
      expect(_findStaticChild(child), findsOneWidget);
      staticChildCenter = tester.getCenter(_findStaticChild(child));
      swipeGesture = await tester.startGesture(staticChildCenter);
      await swipeGesture.moveBy(
        const Offset(0.0, 200.0),
        timeStamp: const Duration(milliseconds: 100),
      );
      await tester.pump();
      await swipeGesture.up();
      await tester.pumpAndSettle();
      expect(_findStatic(), findsNothing);
    });

    testWidgets('Can close ContextMenu by flinging down', (WidgetTester tester) async {
      await tester.pumpWidget(_getContextMenu());

      // Open the ContextMenu
      final Rect childRect = tester.getRect(find.byKey(childKey));
      final TestGesture gesture = await tester.startGesture(childRect.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_findStatic(), findsOneWidget);

      // Fling up and nothing happens.
      expect(_findStaticChild(child), findsOneWidget);
      await tester.fling(_findStaticChild(child), const Offset(0.0, -100.0), 1000.0);
      await tester.pumpAndSettle();
      expect(_findStaticChild(child), findsOneWidget);

      // Fling down to close the menu.
      expect(_findStaticChild(child), findsOneWidget);
      await tester.fling(_findStaticChild(child), const Offset(0.0, 100.0), 1000.0);
      await tester.pumpAndSettle();
      expect(_findStatic(), findsNothing);
    });
  });
}
