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
            actions: <ContextMenuSheetAction>[
              ContextMenuSheetAction(
                child: const Text('ContextMenuSheetAction'),
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
  Finder _findContextMenuRouteStatic() {
    return find.descendant(
      of: find.byType(CupertinoApp),
      matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_ContextMenuRouteStatic'),
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
      expect(_findContextMenuRouteStatic(), findsOneWidget);
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
      expect(_findContextMenuRouteStatic(), findsOneWidget);

      // Tap and ensure that the ContextMenu is closed.
      await tester.tapAt(const Offset(1.0, 1.0));
      await tester.pumpAndSettle();
      expect(_findContextMenuRouteStatic(), findsNothing);
    });
  });
}
