// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter code sample for [showDatePicker].
void main() => runApp(
  const MaterialApp(
    locale: Locale('pt', 'BR'),
    supportedLocales: <Locale>[Locale('en', 'US'), Locale('pt', 'BR')],
    localizationsDelegates: <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: ShowDatePickerInputFormatters()),
  ),
);

class ShowDatePickerInputFormatters extends StatefulWidget {
  const ShowDatePickerInputFormatters({super.key});

  @override
  State<ShowDatePickerInputFormatters> createState() =>
      _ShowDatePickerInputFormattersState();
}

class _ShowDatePickerInputFormattersState
    extends State<ShowDatePickerInputFormatters> {
  DateTime? _selectedDate;
  DateTime? _selectedEndDate;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2022, 1, 1),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.input,
      inputFormatters: <TextInputFormatter>[
        DatePtBrInputFormatter(MaterialLocalizations.of(context)),
      ],
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickRangeDate() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDate == null
          ? null
          : DateTimeRange(
              start: _selectedDate!,
              end: _selectedDate!.add(const Duration(days: 7)),
            ),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.input,
      inputFormatters: <TextInputFormatter>[
        DatePtBrInputFormatter(MaterialLocalizations.of(context)),
      ],
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked.start;
        _selectedEndDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _selectedDate == null
                  ? 'No date selected'
                  : _selectedEndDate == null
                  ? 'Selected date: ${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                  : 'Selected date range: ${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year} - ${_selectedEndDate!.day.toString().padLeft(2, '0')}/${_selectedEndDate!.month.toString().padLeft(2, '0')}/${_selectedEndDate!.year}',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickDate,
              child: const Text('Select date'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickRangeDate,
              child: const Text('Select date range'),
            ),
          ],
        ),
      ),
    );
  }
}

class DatePtBrInputFormatter extends TextInputFormatter {
  DatePtBrInputFormatter(MaterialLocalizations localizations)
    : _separator = localizations.dateSeparator,
      _segmentLengths = _extractSegments(
        localizations.formatCompactDate(DateTime(2001, 12, 31)),
      );

  final String _separator;
  final List<int> _segmentLengths;

  int get _maxDigits =>
      _segmentLengths.fold(0, (int sum, int length) => sum + length);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) {
      return newValue;
    }

    final String digits = _digitsOnly(
      newValue.text,
    ).characters.take(_maxDigits).toString();
    final int selectionEnd = newValue.selection.end.clamp(
      0,
      newValue.text.length,
    );
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

    for (
      int segmentIndex = 0;
      segmentIndex < _segmentLengths.length;
      segmentIndex++
    ) {
      if (cursor >= digits.length) {
        break;
      }

      final int end = (cursor + _segmentLengths[segmentIndex]).clamp(
        0,
        digits.length,
      );
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
