import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AlertDialog DropdownButton Integration Test', () {
    testWidgets('should not crash when clicking dropdown inside alert dialog', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find and tap the button to show the alert dialog
      final showDialogButton = find.text('Show Alert');
      expect(showDialogButton, findsOneWidget);

      await tester.tap(showDialogButton);
      await tester.pumpAndSettle();

      // Verify the dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);

      // Find the dropdown button
      final dropdownButton = find.byType(DropdownButtonFormField<String>);
      expect(dropdownButton, findsOneWidget);

      // This is the action that was causing the crash
      // Tap on the dropdown to open it - this is the critical test
      await tester.tap(dropdownButton);
      await tester.pumpAndSettle();

      // The fact that we reach this point without crashing means our fix works!
      print('SUCCESS: DropdownButton in AlertDialog opened without crash!');
      print('The computeDryBaseline implementation in RenderAligningShiftedBox has fixed the issue 169214.');
    });
  });
}
