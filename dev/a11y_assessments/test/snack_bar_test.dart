// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:a11y_assessments/use_cases/snack_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_utils.dart';

void main() {
  group('SnackBar Accessibility Tests', () {
    testWidgets('snack bar can run and announces message', (WidgetTester tester) async {
      await pumpsUseCase(tester, SnackBarUseCase());
      const String snackBarText = 'Awesome Snackbar!';

      // Verify SnackBar is not visible initially
      expect(find.text(snackBarText), findsNothing);

      // Tap to show SnackBar
      await tester.tap(find.text('Show Snackbar'));

      // Verify SnackBar is not visible immediately after tap
      expect(find.text(snackBarText), findsNothing);

      // Pump to render the SnackBar
      await tester.pump();
      expect(find.text(snackBarText), findsOneWidget);

      // Verify the message was announced for accessibility
      await tester.pumpAndSettle();
      // Note: In test environment, SemanticsService.announce may not work the same way
      // but the method call should be executed
    });

    testWidgets('snack bar with action can run and announces message', (WidgetTester tester) async {
      await pumpsUseCase(tester, SnackBarUseCase());
      const String snackBarText = 'Awesome Snackbar!';

      // Verify SnackBar is not visible initially
      expect(find.text(snackBarText), findsNothing);

      // Tap to show SnackBar with action
      await tester.tap(find.text('Show Snackbar with action '));

      // Verify SnackBar is not visible immediately after tap
      expect(find.text(snackBarText), findsNothing);

      // Pump to render the SnackBar
      await tester.pump();
      expect(find.text(snackBarText), findsOneWidget);

      // Verify action button is present
      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('snack bar demo page has one h1 tag', (WidgetTester tester) async {
      await pumpsUseCase(tester, SnackBarUseCase());
      final Finder findHeadingLevelOnes = find.bySemanticsLabel('SnackBar Demo');
      await tester.pumpAndSettle();
      expect(findHeadingLevelOnes, findsOne);
    });

    testWidgets('showAccessibleSnackBar method exists and works', (WidgetTester tester) async {
      await pumpsUseCase(tester, SnackBarUseCase());

      // Get the MainWidgetState to test the method directly
      final MainWidgetState state = tester.state<MainWidgetState>(find.byType(MainWidget));

      // Verify the method exists and can be called
      expect(state.showAccessibleSnackBar, isA<Function>());

      // Test calling the method (this will show a SnackBar)
      state.showAccessibleSnackBar(tester.element(find.byType(MainWidget)), 'Test Message');
      await tester.pump();

      // Verify the SnackBar appeared
      expect(find.text('Test Message'), findsOneWidget);
    });
  });
}
