// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_api_samples/cupertino/menu_anchor/cupertino_menu_anchor.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Menu opens and displays expected items', (WidgetTester tester) async {
    Finder findMenu() {
      return find.ancestor(
            of: find.text('Regular Item'),
            matching: find.byType(FocusScope),
          )
          .first;
    }

    await tester.pumpWidget(const example.CupertinoSimpleMenuApp());
    await tester.tap(find.byType(TextButton));

    // Pump one frame: the menu should mount.
    await tester.pump();
    expect(find.text('Regular Item'), findsOneWidget);
    expect(find.text('Colorful Item'), findsOneWidget);
    expect(find.text('Default Item'), findsOneWidget);
    expect(find.text('Destructive Item'), findsOneWidget);
    expect(tester.getRect(findMenu()), const Rect.fromLTRB(400.0, 298.0, 400.0, 298.0));

    // Finish animating.
    await tester.pumpAndSettle();

    // TODO(davidhicks980): Remove this conditional if/when layout differences
    // are resolved. https://github.com/flutter/flutter/issues/102332
    if (!isBrowser) {
      expect(tester.getRect(findMenu()),
          rectMoreOrLessEquals(const Rect.fromLTRB(275.0, 60.3, 525.0, 298.0), epsilon: 0.1));
    }

    // Tap outside the menu to close.
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    expect(find.text('Regular Item'), findsNothing);
  });

  testWidgets('Focus moves to first menu item upon open', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CupertinoSimpleMenuApp());
    await tester.pump();

    // Tap the 'OPEN MENU' button and trigger a frame.
    await tester.tap(find.text('OPEN MENU'));
    await tester.pump();

    // TODO(davidhicks980): Remove conditional when focus differences are
    // resolved, https://github.com/flutter/flutter/issues/147770
    if (isBrowser) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    } else {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }

    // Verify that setFirstFocus worked.
    expect(primaryFocus?.debugLabel, '$CupertinoMenuItem(Text("Regular Item"))');

  });

  testWidgets('Items match their descriptions', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CupertinoSimpleMenuApp());
    await tester.pump();

    // Tap the 'OPEN MENU' button and trigger a frame.
    await tester.tap(find.text('OPEN MENU'));

    // Finish the opening animation.
    await tester.pumpAndSettle();

    final CupertinoMenuItem regularItem = tester.widget<CupertinoMenuItem>(
      find.widgetWithText(CupertinoMenuItem, 'Regular Item'),
    );
    expect(regularItem.subtitle, isNotNull);
    expect(regularItem.enabled, isTrue);

    final CupertinoMenuItem destructiveItem = tester.widget<CupertinoMenuItem>(
      find.widgetWithText(CupertinoMenuItem, 'Destructive Item'),
    );
    expect(destructiveItem.isDestructiveAction, isTrue);
    expect(destructiveItem.enabled, isTrue);


    final CupertinoMenuItem defaultItem = tester.widget<CupertinoMenuItem>(
      find.widgetWithText(CupertinoMenuItem, 'Default Item'),
    );
    expect(defaultItem.isDefaultAction, isTrue);
    expect(defaultItem.enabled, isTrue);


    final CupertinoMenuItem colorfulItem = tester.widget<CupertinoMenuItem>(
      find.widgetWithText(CupertinoMenuItem, 'Colorful Item'),
    );
    expect(colorfulItem.hoveredColor, isNotNull);
    expect(colorfulItem.pressedColor, isNotNull);
    expect(colorfulItem.focusedColor, isNotNull);
    expect(colorfulItem.enabled, isTrue);

    // Tap the 'Regular Item' and trigger a frame.
    await tester.tap(find.text('Regular Item'));
    await tester.pump();
    await tester.pump();

    // Verify that text is displayed when the menu is tapped.
    expect(find.text('You Pressed: Regular Item'), findsOneWidget);
  });
}
