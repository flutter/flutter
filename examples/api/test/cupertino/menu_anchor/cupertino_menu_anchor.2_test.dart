// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_api_samples/cupertino/menu_anchor/cupertino_menu_anchor.2.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Menu opens and displays items', (WidgetTester tester) async {
    Finder findMenu() {
      return find.ancestor(
            of: find.text(example.MenuEntry.about.label),
            matching: find.byType(FocusScope),
          )
          .first;
    }

    await tester.pumpWidget(const example.CupertinoContextMenuApp());
    await tester.tapAt(const Offset(100, 200), buttons: kSecondaryButton);
    await tester.pumpAndSettle();


    final Rect rect = tester.getRect(findMenu());
    // TODO(davidhicks980): Remove this conditional if/when layout differences
    // are resolved. https://github.com/flutter/flutter/issues/102332
    if (!isBrowser) {
      expect(rect,
          rectMoreOrLessEquals(const Rect.fromLTRB(453.1, 201.1, 703.1, 288.8), epsilon: 0.1));
    }

    // Make sure tapping in a different place causes the menu to move.
    await tester.tapAt(const Offset(150, 225), buttons: kSecondaryButton);
    await tester.pump();

    final Rect newRect = tester.getRect(findMenu());
    // TODO(davidhicks980): Remove this conditional if/when layout differences
    // are resolved. https://github.com/flutter/flutter/issues/102332
    if (!isBrowser) {
      // Should move without closing.
      expect(newRect,
          rectMoreOrLessEquals(const Rect.fromLTRB(503.1, 226.1, 753.1, 313.8), epsilon: 0.1));
    }

    // The menu should move 50 pixels to the right and 25 pixels down.
    expect(newRect.center - rect.center, offsetMoreOrLessEquals(const Offset(50, 25), epsilon: 0.1));
  });

  testWidgets('showMessage shows a message', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CupertinoContextMenuApp());
    expect(find.text(example.CupertinoContextMenuApp.kMessage), findsNothing);

    await tester.tapAt(const Offset(200, 100), buttons: kSecondaryButton);
    await tester.pump();

    // `showMessage` and `about` should be visible, `hideMessage` should not.
    expect(find.text(example.MenuEntry.about.label), findsOneWidget);
    expect(find.text(example.MenuEntry.showMessage.label), findsOneWidget);
    expect(find.text(example.MenuEntry.hideMessage.label), findsNothing);
    expect(find.text(example.CupertinoContextMenuApp.kMessage), findsNothing);

    // Finish the opening animation.
    await tester.pumpAndSettle();

    // Tap the "showMessage" item. This will close the menu
    // menu items.
    await tester.tap(find.text(example.MenuEntry.showMessage.label));
    await tester.pump();
    await tester.pump();

    // The message should be visible after two frames. This allows focus
    // to move to the previously focused item.
    expect(find.text(example.CupertinoContextMenuApp.kMessage), findsOneWidget);

    // Let the animation finish.
    await tester.pumpAndSettle();

    // Open the menu again.
    await tester.tapAt(const Offset(200, 100), buttons: kSecondaryButton);
    await tester.pumpAndSettle();

    // The hideMessage item should be visible after tapping the showMessage item.
    expect(find.text(example.MenuEntry.about.label), findsOneWidget);
    expect(find.text(example.MenuEntry.showMessage.label), findsNothing);
    expect(find.text(example.MenuEntry.hideMessage.label), findsOneWidget);

    // Move focus to the "hideMessage" item hit enter. This should close the
    // menu and hide the message.

    // TODO(davidhicks980): Remove conditional when focus differences are
    // resolved, https://github.com/flutter/flutter/issues/147770
    if (isBrowser) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    } else {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();

    // The message should be hidden after two frames.
    expect(find.text(example.CupertinoContextMenuApp.kMessage), findsNothing);
    expect(find.text('Last Selected: ${example.MenuEntry.hideMessage.label}'),
        findsOneWidget);

    // Let the animation finish.
    await tester.pumpAndSettle();

    expect(find.text(example.MenuEntry.about.label), findsNothing);
    expect(find.text(example.MenuEntry.showMessage.label), findsNothing);
    expect(find.text(example.MenuEntry.hideMessage.label), findsNothing);

    // The message should still be hidden.
    expect(find.text(example.CupertinoContextMenuApp.kMessage), findsNothing);
    expect(find.text('Last Selected: ${example.MenuEntry.hideMessage.label}'),
        findsOneWidget);
  });
}
