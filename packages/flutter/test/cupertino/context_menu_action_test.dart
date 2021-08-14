// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Constants taken from _ContextMenuActionState.
  const Color _kBackgroundColor = Color(0xFFEEEEEE);
  const Color _kBackgroundColorPressed = Color(0xFFDDDDDD);
  const Color _kRegularActionColor = CupertinoColors.black;
  const Color _kDestructiveActionColor = CupertinoColors.destructiveRed;
  const FontWeight _kDefaultActionWeight = FontWeight.w600;

  Widget _getApp({VoidCallback? onPressed, bool isDestructiveAction = false, bool isDefaultAction = false}) {
    final UniqueKey actionKey = UniqueKey();
    final CupertinoContextMenuAction action = CupertinoContextMenuAction(
      key: actionKey,
      onPressed: onPressed,
      trailingIcon: CupertinoIcons.home,
      isDestructiveAction: isDestructiveAction,
      isDefaultAction: isDefaultAction,
      child: const Text('I am a CupertinoContextMenuAction'),
    );

    return CupertinoApp(
      home: CupertinoPageScaffold(
        child: Center(
          child: action,
        ),
      ),
    );
  }

  BoxDecoration _getDecoration(WidgetTester tester) {
    final Finder finder = find.descendant(
      of: find.byType(CupertinoContextMenuAction),
      matching: find.byType(Container),
    );
    expect(finder, findsOneWidget);
    final Container container = tester.widget(finder);
    return container.decoration! as BoxDecoration;
  }

  TextStyle _getTextStyle(WidgetTester tester) {
    final Finder finder = find.descendant(
      of: find.byType(CupertinoContextMenuAction),
      matching: find.byType(DefaultTextStyle),
    );
    expect(finder, findsOneWidget);
    final DefaultTextStyle defaultStyle = tester.widget(finder);
    return defaultStyle.style;
  }

  Icon _getIcon(WidgetTester tester) {
    final Finder finder = find.descendant(
      of: find.byType(CupertinoContextMenuAction),
      matching: find.byType(Icon),
    );
    expect(finder, findsOneWidget);
    final Icon icon = tester.widget(finder);
    return icon;
  }

  testWidgets('responds to taps', (WidgetTester tester) async {
    bool wasPressed = false;
    await tester.pumpWidget(_getApp(onPressed: () {
      wasPressed = true;
    }));

    expect(wasPressed, false);
    await tester.tap(find.byType(CupertinoContextMenuAction));
    expect(wasPressed, true);
  });

  testWidgets('turns grey when pressed and held', (WidgetTester tester) async {
    await tester.pumpWidget(_getApp());
    expect(_getDecoration(tester).color, _kBackgroundColor);

    final Offset actionCenter = tester.getCenter(find.byType(CupertinoContextMenuAction));
    final TestGesture gesture = await tester.startGesture(actionCenter);
    await tester.pump();
    expect(_getDecoration(tester).color, _kBackgroundColorPressed);

    await gesture.up();
    await tester.pump();
    expect(_getDecoration(tester).color, _kBackgroundColor);
  });

  testWidgets('icon and textStyle colors are correct out of the box', (WidgetTester tester) async {
    await tester.pumpWidget(_getApp());
    expect(_getTextStyle(tester).color, _kRegularActionColor);
    expect(_getIcon(tester).color, _kRegularActionColor);
  });

  testWidgets('icon and textStyle colors are correct for destructive actions', (WidgetTester tester) async {
    await tester.pumpWidget(_getApp(isDestructiveAction: true));
    expect(_getTextStyle(tester).color, _kDestructiveActionColor);
    expect(_getIcon(tester).color, _kDestructiveActionColor);
  });

  testWidgets('textStyle is correct for defaultAction', (WidgetTester tester) async {
    await tester.pumpWidget(_getApp(isDefaultAction: true));
    expect(_getTextStyle(tester).fontWeight, _kDefaultActionWeight);
  });

}
