// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../input_border.dart';
import '../input_decorator.dart';
import '../material_localizations.dart';
import '../text_field.dart';
import '../theme.dart';

import 'date_utils.dart' as utils;

/// Provides a pair of text fields that allow the user to enter the start and
/// end dates that represent a range of dates.
//
// This is not publicly exported (see pickers.dart), as it is just an
// internal component used by [showDateRangePicker].
class InputDateRangePicker extends StatefulWidget {
  /// Creates a row with two text fields configured to accept the start and end dates
  /// of a date range.
  InputDateRangePicker({
    Key key,
    DateTime initialStartDate,
    DateTime initialEndDate,
    @required DateTime firstDate,
    @required DateTime lastDate,
    @required this.onStartDateChanged,
    @required this.onEndDateChanged,
    this.helpText,
    this.errorFormatText,
    this.errorInvalidText,
    this.errorInvalidRangeText,
    this.fieldStartHintText,
    this.fieldEndHintText,
    this.fieldStartLabelText,
    this.fieldEndLabelText,
    this.autofocus = false,
    this.autovalidate = false,
  }) : initialStartDate = initialStartDate == null ? null : utils.dateOnly(initialStartDate),
        initialEndDate = initialEndDate == null ? null : utils.dateOnly(initialEndDate),
        assert(firstDate != null),
        firstDate = utils.dateOnly(firstDate),
        assert(lastDate != null),
        lastDate = utils.dateOnly(lastDate),
        assert(firstDate != null),
        assert(lastDate != null),
        assert(autofocus != null),
        assert(autovalidate != null),
        super(key: key);

  /// The [DateTime] that represents the start of the initial date range selection.
  final DateTime initialStartDate;

  /// The [DateTime] that represents the end of the initial date range selection.
  final DateTime initialEndDate;

  /// The earliest allowable [DateTime] that the user can select.
  final DateTime firstDate;

  /// The latest allowable [DateTime] that the user can select.
  final DateTime lastDate;

  /// Called when the user changes the start date of the selected range.
  final ValueChanged<DateTime> onStartDateChanged;

  /// Called when the user changes the end date of the selected range.
  final ValueChanged<DateTime> onEndDateChanged;

  /// The text that is displayed at the top of the header.
  ///
  /// This is used to indicate to the user what they are selecting a date for.
  final String helpText;

  /// Error text used to indicate the text in a field is not a valid date.
  final String errorFormatText;

  /// Error text used to indicate the date in a field is not in the valid range
  /// of [firstDate] - [lastDate].
  final String errorInvalidText;

  /// Error text used to indicate the dates given don't form a valid date
  /// range (i.e. the start date is after the end date).
  final String errorInvalidRangeText;

  /// Hint text shown when the start date field is empty.
  final String fieldStartHintText;

  /// Hint text shown when the end date field is empty.
  final String fieldEndHintText;

  /// Label used for the start date field.
  final String fieldStartLabelText;

  /// Label used for the end date field.
  final String fieldEndLabelText;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// If true, this the date fields will validate and update their error text
  /// immediately after every change. Otherwise, you must call
  /// [InputDateRangePickerState.validate] to validate.
  final bool autovalidate;

  @override
  InputDateRangePickerState createState() => InputDateRangePickerState();
}

/// The current state of an [InputDateRangePicker]. Can be used to
/// [validate] the date field entries.
class InputDateRangePickerState extends State<InputDateRangePicker> {
  String _startInputText;
  String _endInputText;
  DateTime _startDate;
  DateTime _endDate;
  TextEditingController _startController;
  TextEditingController _endController;
  String _startErrorText;
  String _endErrorText;
  bool _autoSelected = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _startController = TextEditingController();
    _endDate = widget.initialEndDate;
    _endController = TextEditingController();
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    if (_startDate != null) {
      _startInputText = localizations.formatCompactDate(_startDate);
      final bool selectText = widget.autofocus && !_autoSelected;
      _updateController(_startController, _startInputText, selectText);
      _autoSelected = selectText;
    }

    if (_endDate != null) {
      _endInputText = localizations.formatCompactDate(_endDate);
      _updateController(_endController, _endInputText, false);
    }
  }

  /// Validates that the text in the start and end fields represent a valid
  /// date range.
  ///
  /// Will return true if the range is valid. If not, it will
  /// return false and display an appropriate error message under one of the
  /// text fields.
  bool validate() {
    String startError = _validateDate(_startDate);
    final String endError = _validateDate(_endDate);
    if (startError == null && endError == null) {
      if (_startDate.isAfter(_endDate)) {
        startError = widget.errorInvalidRangeText ?? MaterialLocalizations.of(context).invalidDateRangeLabel;
      }
    }
    setState(() {
      _startErrorText = startError;
      _endErrorText = endError;
    });
    return startError == null && endError == null;
  }

  DateTime _parseDate(String text) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    return localizations.parseCompactDate(text);
  }

  String _validateDate(DateTime date) {
    if (date == null) {
      return widget.errorFormatText ?? MaterialLocalizations.of(context).invalidDateFormatLabel;
    } else if (date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate)) {
      return widget.errorInvalidText ?? MaterialLocalizations.of(context).dateOutOfRangeLabel;
    }
    return null;
  }

  void _updateController(TextEditingController controller, String text, bool selectText) {
    TextEditingValue textEditingValue = controller.value.copyWith(text: text);
    if (selectText) {
      textEditingValue = textEditingValue.copyWith(selection: TextSelection(
        baseOffset: 0,
        extentOffset: text.length,
      ));
    }
    controller.value = textEditingValue;
  }

  void _handleStartChanged(String text) {
    setState(() {
      _startInputText = text;
      _startDate = _parseDate(text);
      widget.onStartDateChanged?.call(_startDate);
    });
    if (widget.autovalidate) {
      validate();
    }
  }

  void _handleEndChanged(String text) {
    setState(() {
      _endInputText = text;
      _endDate = _parseDate(text);
      widget.onEndDateChanged?.call(_endDate);
    });
    if (widget.autovalidate) {
      validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final InputDecorationTheme inputTheme = Theme.of(context).inputDecorationTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _startController,
            decoration: InputDecoration(
              border: inputTheme.border ?? const UnderlineInputBorder(),
              filled: inputTheme.filled ?? true,
              hintText: widget.fieldStartHintText ?? localizations.dateHelpText,
              labelText: widget.fieldStartLabelText ?? localizations.dateRangeStartLabel,
              errorText: _startErrorText,
            ),
            keyboardType: TextInputType.datetime,
            onChanged: _handleStartChanged,
            autofocus: widget.autofocus,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _endController,
            decoration: InputDecoration(
              border: inputTheme.border ?? const UnderlineInputBorder(),
              filled: inputTheme.filled ?? true,
              hintText: widget.fieldEndHintText ?? localizations.dateHelpText,
              labelText: widget.fieldEndLabelText ?? localizations.dateRangeEndLabel,
              errorText: _endErrorText,
            ),
            keyboardType: TextInputType.datetime,
            onChanged: _handleEndChanged,
          ),
        ),
      ],
    );
  }
}
