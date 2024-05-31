// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/menu_anchor/menu_anchor.3.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SimpleCascadingMenu Tests', () {
    testWidgets('Menu button opens and closes the menu', (WidgetTester tester) async {
      await tester.pumpWidget(const SimpleCascadingMenuApp());

      // Find the menu button.
      final Finder menuButton = find.byType(IconButton);
      expect(menuButton, findsOneWidget);

      // Tap the menu button to open the menu.
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Verify that the menu is open.
      expect(find.text('Revert'), findsOneWidget);

      // Tap the menu button again to close the menu.
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Verify that the menu is closed.
      expect(find.text('Revert'), findsNothing);
    });

    testWidgets('Menu items are tappable', (WidgetTester tester) async {
      final Completer<void> revertCompleter = Completer<void>();

      // Build the SimpleCascadingMenu widget with the callback.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: <Widget>[
                MenuAnchor(
                  childFocusNode: FocusNode(debugLabel: 'Menu Button'),
                  menuChildren: <Widget>[
                    MenuItemButton(
                      key: const ValueKey<String>('revertButton'),
                      child: const Text('Revert'),
                      onPressed: () {
                        revertCompleter.complete();
                      },
                    ),
                    MenuItemButton(
                      child: const Text('Setting'),
                      onPressed: () {},
                    ),
                    MenuItemButton(
                      child: const Text('Send Feedback'),
                      onPressed: () {},
                    ),
                  ],
                  builder: (_, MenuController controller, Widget? child) {
                    return IconButton(
                      key: const ValueKey<String>('menuButton'),
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      icon: const Icon(Icons.more_vert),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Find the menu button.
      final Finder menuButton = find.byKey(const ValueKey<String>('menuButton'));
      expect(menuButton, findsOneWidget);

      // Tap the menu button to open the menu.
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Find the "Revert" menu item.
      final Finder revertItem = find.byKey(const ValueKey<String>('revertButton'));
      expect(revertItem, findsOneWidget);

      // Tap the "Revert" menu item.
      await tester.tap(revertItem);
      await tester.pumpAndSettle();

       // Verify that the "Revert" callback was called and completed.
      await revertCompleter.future;
      expect(revertCompleter.isCompleted, isTrue);
    });

    testWidgets('Does not show debug banner', (WidgetTester tester) async {
      await tester.pumpWidget(const SimpleCascadingMenuApp());
      expect(find.byType(CheckedModeBanner), findsNothing);
    });
  });
}
