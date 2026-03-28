import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_test/flutter_test.dart';

// --- DatePtBrInputFormatter ---
class DatePtBrInputFormatter extends TextInputFormatter {
  DatePtBrInputFormatter(MaterialLocalizations localizations)
    : _separator = localizations.dateSeparator,
      _segmentLengths = _extractSegments(localizations.formatCompactDate(DateTime(2001, 12, 31)));

  final String _separator;
  final List<int> _segmentLengths;

  int get _maxDigits => _segmentLengths.fold(0, (int sum, int length) => sum + length);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (!newValue.composing.isCollapsed) {
      return newValue;
    }

    final String digits = _digitsOnly(newValue.text).characters.take(_maxDigits).toString();
    final int selectionEnd = newValue.selection.end.clamp(0, newValue.text.length);
    final int digitsBeforeCursor = _digitsOnly(
      newValue.text.substring(0, selectionEnd),
    ).length.clamp(0, digits.length);
    final String formattedValue = _applyMask(digits);
    final int cursorOffset = _selectionOffsetForDigits(digitsBeforeCursor);

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  static List<int> _extractSegments(String sample) {
    final List<int> segments = RegExp(
      r'[0-9]+',
    ).allMatches(sample).map((Match match) => match.group(0)!.length).toList();

    if (segments.length == 3) {
      return segments;
    }

    return <int>[2, 2, 4];
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  String _applyMask(String digits) {
    final StringBuffer buffer = StringBuffer();
    int cursor = 0;

    for (int segmentIndex = 0; segmentIndex < _segmentLengths.length; segmentIndex++) {
      if (cursor >= digits.length) {
        break;
      }

      final int end = (cursor + _segmentLengths[segmentIndex]).clamp(0, digits.length);
      buffer.write(digits.substring(cursor, end));
      cursor = end;

      if (cursor < digits.length && segmentIndex < _segmentLengths.length - 1) {
        buffer.write(_separator);
      }
    }

    return buffer.toString();
  }

  int _selectionOffsetForDigits(int digitsBeforeCursor) {
    int offset = digitsBeforeCursor;
    int digitsBoundary = 0;

    for (int index = 0; index < _segmentLengths.length - 1; index++) {
      digitsBoundary += _segmentLengths[index];
      if (digitsBeforeCursor > digitsBoundary) {
        offset += _separator.length;
      }
    }

    return offset;
  }
}

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
