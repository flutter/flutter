// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RenderAligningShiftedBox computeDryBaseline implementation test', () {
    // Regression test for: https://github.com/flutter/flutter/issues/169214
    // Tests that RenderAligningShiftedBox properly implements computeDryBaseline
    // by using a widget tree that previously caused crashes before the implementation
    testWidgets(
      'DropdownButtonFormField in Wrap in AlertDialog should not crash due to missing computeDryBaseline',
      (WidgetTester tester) async {
        String? selectedValue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) {
                  return ElevatedButton(
                    key: const Key('show_dialog_button'),
                    onPressed: () {
                      showDialog<void>(
                        barrierDismissible: false,
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            scrollable: true,
                            title: const Text('Alert Dialog'),
                            content: Wrap(
                              children: <Widget>[
                                SizedBox(
                                  width: 300,
                                  child: DropdownButtonFormField<String>(
                                    key: const Key('dropdown_button'),
                                    value: selectedValue,
                                    items: const <DropdownMenuItem<String>>[
                                      DropdownMenuItem<String>(
                                        value: 'option1',
                                        child: Text('Option 1'),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'option2',
                                        child: Text('Option 2'),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'option3',
                                        child: Text('Option 3'),
                                      ),
                                    ],
                                    onChanged: (String? value) {
                                      selectedValue = value;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Show Alert'),
                  );
                },
              ),
            ),
          ),
        );

        // Verify the button is present
        expect(find.byKey(const Key('show_dialog_button')), findsOneWidget);

        // Tap the button to show the dialog
        await tester.tap(find.byKey(const Key('show_dialog_button')));
        await tester.pumpAndSettle();

        // Verify the dialog is shown
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Alert Dialog'), findsOneWidget);

        // Find the dropdown button
        final Finder dropdownButton = find.byKey(const Key('dropdown_button'));
        expect(dropdownButton, findsOneWidget);

        // This is the critical test: tapping the dropdown should not crash
        // Before the computeDryBaseline implementation in RenderAligningShiftedBox,
        // this would throw an exception during baseline calculations
        await tester.tap(dropdownButton);
        await tester.pumpAndSettle();

        // Verify the dropdown menu is opened without crashing
        expect(find.text('Option 1'), findsOneWidget);
        expect(find.text('Option 2'), findsOneWidget);
        expect(find.text('Option 3'), findsOneWidget);

        // Test selecting an option to ensure full functionality
        await tester.tap(find.text('Option 2'));
        await tester.pumpAndSettle();

        // Verify the dropdown closed and option was selected
        expect(selectedValue, equals('option2'));
      },
    );
  });
}
