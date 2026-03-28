import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('date_picker_input_formatters', () {
    testWidgets('accepts valid US date format (MM/DD/YYYY)', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      DateTime? inputDate;
      final formatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9/]'));
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Form(
              key: formKey,
              child: InputDatePickerFormField(
                initialDate: DateTime(2020, 1, 1),
                firstDate: DateTime(2000, 1, 1),
                lastDate: DateTime(2030, 1, 1),
                onDateSaved: (date) => inputDate = date,
                inputFormatters: [formatter],
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '12/31/2025');
      formKey.currentState!.save();
      expect(inputDate, DateTime(2025, 12, 31));
    });

    testWidgets('rejects alphabetic and symbol characters', (WidgetTester tester) async {
      final formatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9/]'));
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: InputDatePickerFormField(
              initialDate: DateTime(2020, 1, 1),
              firstDate: DateTime(2000, 1, 1),
              lastDate: DateTime(2030, 1, 1),
              inputFormatters: [formatter],
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'ab@12/31/2025!');
      // Only valid characters should remain
      expect(find.text('12/31/2025'), findsOneWidget);
    });

    testWidgets('rejects invalid date format (DD-MM-YYYY)', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      DateTime? inputDate;
      final formatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9/]'));
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Form(
              key: formKey,
              child: InputDatePickerFormField(
                initialDate: DateTime(2020, 1, 1),
                firstDate: DateTime(2000, 1, 1),
                lastDate: DateTime(2030, 1, 1),
                onDateSaved: (date) => inputDate = date,
                errorFormatText: 'Invalid date format',
                inputFormatters: [formatter],
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '31/12/2025');
      // Trigger validation to display the error
      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      expect(inputDate, isNull);
      expect(find.text('Invalid date format'), findsOneWidget);
    });

    testWidgets('rejects incomplete date', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      DateTime? inputDate;
      final formatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9/]'));
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Form(
              key: formKey,
              child: InputDatePickerFormField(
                initialDate: DateTime(2020, 1, 1),
                firstDate: DateTime(2000, 1, 1),
                lastDate: DateTime(2030, 1, 1),
                onDateSaved: (date) => inputDate = date,
                errorFormatText: 'Incomplete date',
                inputFormatters: [formatter],
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '12/31');
      formKey.currentState!.save();
      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      expect(inputDate, isNull);
      expect(find.text('Incomplete date'), findsOneWidget);
    });
  });
}
