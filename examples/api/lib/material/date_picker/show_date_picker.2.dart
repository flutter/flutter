// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flutter code sample showing how to use [showDatePicker] with a custom
/// [DateInputCalendarDelegate] to support configurable text input formats.

void main() => runApp(const DatePickerSampleApp());

class DatePickerSampleApp extends StatelessWidget {
  const DatePickerSampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: DatePickerSample());
  }
}

class DatePickerSample extends StatefulWidget {
  const DatePickerSample({super.key});

  @override
  State<DatePickerSample> createState() => _DatePickerSampleState();
}

class _DatePickerSampleState extends State<DatePickerSample> {
  DateTime? _selectedDate;

  DateInputFormat _formatType = DateInputFormat.dayMonthYear;
  DateSeparator _separator = DateSeparator.dot;

  Future<void> _showPicker() async {
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2021, 7, 25),
      firstDate: DateTime(2021),
      lastDate: DateTime(2999, 7, 25),
      initialEntryMode: DatePickerEntryMode.input,
      calendarDelegate: ConfigurableDateDelegate(
        formatType: _formatType,
        separator: _separator,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDate = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String label = _selectedDate == null
        ? 'No date selected'
        : DateInputFormatter(
            formatType: _formatType,
            separator: _separator.value,
          ).format(_selectedDate!);

    return Scaffold(
      appBar: AppBar(title: const Text('showDatePicker with input delegate')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(label),
            const SizedBox(height: 24),
            DropdownButtonFormField<DateInputFormat>(
              initialValue: _formatType,
              decoration: const InputDecoration(labelText: 'Date format'),
              items: DateInputFormat.values
                  .map(
                    (DateInputFormat format) => DropdownMenuItem(
                      value: format,
                      child: Text(format.patternLabel),
                    ),
                  )
                  .toList(),
              onChanged: (DateInputFormat? value) {
                if (value != null) {
                  setState(() => _formatType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DateSeparator>(
              initialValue: _separator,
              decoration: const InputDecoration(labelText: 'Separator'),
              items: DateSeparator.values
                  .map(
                    (DateSeparator sep) =>
                        DropdownMenuItem(value: sep, child: Text(sep.value)),
                  )
                  .toList(),
              onChanged: (DateSeparator? value) {
                if (value != null) {
                  setState(() => _separator = value);
                }
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _showPicker,
              child: const Text('Select date'),
            ),
          ],
        ),
      ),
    );
  }
}

enum DateInputFormat {
  dayMonthYear(fieldLengths: [2, 2, 4], patternLabel: 'dd/mm/yyyy'),
  monthDayYear(fieldLengths: [2, 2, 4], patternLabel: 'mm/dd/yyyy'),
  yearMonthDay(fieldLengths: [4, 2, 2], patternLabel: 'yyyy/mm/dd');

  const DateInputFormat({
    required this.fieldLengths,
    required this.patternLabel,
  });

  final List<int> fieldLengths;
  final String patternLabel;

  String pattern(String separator) => patternLabel.replaceAll('/', separator);
}

enum DateSeparator {
  slash('/'),
  dash('-'),
  dot('.');

  const DateSeparator(this.value);
  final String value;
}

/// A [TextInputFormatter] used by the input mode of [showDatePicker] to
/// format and validate date text according to a specific [DateInputFormat].
///
/// This formatter is intended to be used when [DatePickerEntryMode.input]
/// is enabled, ensuring that the manual date entry matches the same format
/// expected by the picker.
///
/// It:
/// - Restricts input to digits and automatically inserts the configured
///   [separator].
/// - Enforces the field order defined by [DateInputFormat]
///   (e.g. day–month–year, month–day–year, year–month–day).
/// - Provides utilities to format a [DateTime] into a string and to parse
///   user input back into a [DateTime], returning `null` for invalid values.
///
/// This formatter is typically wired through a custom calendar delegate,
/// such as [ConfigurableDateDelegate], rather than being attached directly.
class DateInputFormatter extends TextInputFormatter {
  const DateInputFormatter({required this.formatType, required this.separator});

  final DateInputFormat formatType;
  final String separator;

  String get pattern => formatType.pattern(separator);

  String format(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString().padLeft(4, '0');

    final components = switch (formatType) {
      DateInputFormat.dayMonthYear => [day, month, year],
      DateInputFormat.monthDayYear => [month, day, year],
      DateInputFormat.yearMonthDay => [year, month, day],
    };

    return components.join(separator);
  }

  DateTime? parse(String? input) {
    if (input == null || input.isEmpty) {
      return null;
    }

    final List<String> parts = input.split(separator);
    if (parts.length != 3) {
      return null;
    }

    final (String d, String m, String y) = switch (formatType) {
      DateInputFormat.dayMonthYear => (parts[0], parts[1], parts[2]),
      DateInputFormat.monthDayYear => (parts[1], parts[0], parts[2]),
      DateInputFormat.yearMonthDay => (parts[2], parts[1], parts[0]),
    };

    final int? day = int.tryParse(d);
    final int? month = int.tryParse(m);
    final int? year = int.tryParse(y);

    if (day == null || month == null || year == null) {
      return null;
    }
    if (month < 1 || month > 12 || day < 1) {
      return null;
    }

    final int lastDayOfMonth = DateTime(year, month + 1, 0).day;
    if (day > lastDayOfMonth) {
      return null;
    }

    return DateTime(year, month, day);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final int maxLength = formatType.fieldLengths.fold<int>(
      0,
      (int a, int b) => a + b,
    );

    if (digits.length > maxLength) {
      return oldValue;
    }

    final String formatted = _applyMask(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _applyMask(String digits) {
    final StringBuffer buffer = StringBuffer();
    int offset = 0;

    for (
      int i = 0;
      i < formatType.fieldLengths.length && offset < digits.length;
      i++
    ) {
      final int len = formatType.fieldLengths[i];
      final int end = (offset + len).clamp(0, digits.length);
      buffer.write(digits.substring(offset, end));
      offset = end;

      if (offset < digits.length && i < formatType.fieldLengths.length - 1) {
        buffer.write(separator);
      }
    }
    return buffer.toString();
  }
}

class ConfigurableDateDelegate extends DateInputCalendarDelegate {
  const ConfigurableDateDelegate({
    required this.formatType,
    this.separator = DateSeparator.slash,
  });

  final DateInputFormat formatType;
  final DateSeparator separator;

  DateInputFormatter get _formatter =>
      DateInputFormatter(formatType: formatType, separator: separator.value);

  @override
  List<TextInputFormatter> get inputFormatters => <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    _formatter,
  ];

  @override
  String dateHelpText(MaterialLocalizations localizations) =>
      _formatter.pattern;

  @override
  String formatCompactDate(
    DateTime date,
    MaterialLocalizations localizations,
  ) => _formatter.format(date);

  @override
  DateTime? parseCompactDate(
    String? inputString,
    MaterialLocalizations localizations,
  ) => _formatter.parse(inputString);
}
