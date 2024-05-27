import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/main.dart';

void main() {
  group('SimpleCascadingMenu Tests', () {
    testWidgets('Menu button opens and closes the menu',
        (WidgetTester tester) async {
      // Build the SimpleCascadingMenu widget.
      await tester.pumpWidget(const MaterialApp(home: MyCascadingMenu()));

      // Find the menu button.
      final menuButton = find.byType(IconButton);

      // Tap the menu button to open the menu.
      await tester.tap(menuButton);
      await tester.pump();

      // Verify that the menu is open.
      expect(find.text('Revert'), findsOneWidget);

      // Tap the menu button again to close the menu.
      await tester.tap(menuButton);
      await tester.pump();

      // Verify that the menu is closed.
      expect(find.text('Revert'), findsNothing);
    });

    testWidgets('Menu items are tappable', (WidgetTester tester) async {
      // Create a mock callback for the "Revert" menu item.
      bool revertCalled = false;

      // Build the SimpleCascadingMenu widget with the callback.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                MenuAnchor(
                  childFocusNode: FocusNode(debugLabel: 'Menu Button'),
                  menuChildren: <Widget>[
                    MenuItemButton(
                      child: const Text('Revert'),
                      onPressed: () {
                        revertCalled = true;
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
      final menuButton = find.byType(IconButton);

      // Tap the menu button to open the menu.
      await tester.tap(menuButton);
      await tester.pump();

      // Find the "Revert" menu item.
      final revertItem = find.text('Revert');

      // Tap the "Revert" menu item.
      await tester.tap(revertItem);
      await tester.pump();

      // Verify that the "Revert" callback was called.
      expect(revertCalled, true);
    });
  });
}
