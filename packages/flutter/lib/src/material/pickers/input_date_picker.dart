// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../material.dart';
import '../input_border.dart';
import '../input_decorator.dart';
import '../material_localizations.dart';
import '../text_form_field.dart';
import '../theme.dart';

import 'date_picker_common.dart';
import 'date_utils.dart' as utils;

/// A [TextFormField] configured to accept and validate a date entered by the user.
///
/// When the field is saved or submitted, the text will be parsed into a
/// [DateTime] according to the ambient locale's compact date format. If the
/// input text doesn't parse into a date, the [errorFormatText] message will
/// be displayed under the field.
///
/// [firstDate], [lastDate], and [selectableDayPredicate] provide constraints on
/// what days are valid. If the input date isn't in the date range or doesn't pass
/// the given predicate, then the [errorInvalidText] message will be displayed
/// under the field.
///
/// See also:
///
///  * [showDatePicker], which shows a dialog that contains a material design
///    date picker which includes support for text entry of dates.
///  * [MaterialLocalizations.parseCompactDate], which is used to parse the text
///    input into a [DateTime].
///
class InputDatePickerFormField extends StatefulWidget {
  /// Creates a [TextFormField] configured to accept and validate a date.
  ///
  /// If the optional [initialDate] is provided, then it will be used to populate
  /// the text field. If the [fieldHintText] is provided, it will be shown instead.
  ///
  /// If [initialDate] is provided, it must not be before [firstDate] or after
  /// [lastDate]. If [selectableDayPredicate] is provided, it must return `true`
  /// for [initialDate].
  ///
  /// [firstDate] must be on or before [lastDate].
  ///
  /// [firstDate], [lastDate], and [autofocus] must be non-null.
  ///
  InputDatePickerFormField({
    Key? key,
    DateTime? initialDate,
    DateTime? currentDate,
    DateTime? firstDate,
    DateTime? lastDate,
    this.onDateSubmitted,
    this.onDateSaved,
    this.selectableDayPredicate,
    this.errorFormatText,
    this.errorInvalidText,
    this.errorEmptyText,
    this.fieldHintText,
    this.fieldLabelText,
    this.helperText,
    this.controller,
    this.autofocus = false,
    this.allowEmptyDate = false,
    this.textInputAction,
  }) : assert(autofocus != null),
       initialDate = initialDate != null ? utils.dateOnly(initialDate) : null,
       currentDate = currentDate != null ? utils.dateOnly(currentDate) : null,
       firstDate = firstDate != null ? utils.dateOnly(firstDate) : DateTime(0),
       lastDate = lastDate != null ? utils.dateOnly(lastDate) : DateTime(2100),
       super(key: key) {
    assert(
      !this.lastDate.isBefore(this.firstDate),
      'lastDate ${this.lastDate} must be on or after firstDate ${this.firstDate}.'
    );
    assert(
      initialDate == null || !this.initialDate!.isBefore(this.firstDate),
      'initialDate ${this.initialDate} must be on or after firstDate ${this.firstDate}.'
    );
    assert(
      initialDate == null || !this.initialDate!.isAfter(this.lastDate),
      'initialDate ${this.initialDate} must be on or before lastDate ${this.lastDate}.'
    );
    assert(
      selectableDayPredicate == null || initialDate == null || selectableDayPredicate!(this.initialDate!),
      'Provided initialDate ${this.initialDate} must satisfy provided selectableDayPredicate.'
    );
  }

  /// If provided, it will be used as the default value for the field.
  final DateTime? initialDate;

  /// The [currentDate] represents the current day (i.e. today). This
  /// date will be highlighted in the day grid. If null, the date of
  /// `DateTime.now()` will be used.
  final DateTime? currentDate;
  /// The earliest allowable [DateTime] that the user can input.
  final DateTime firstDate;

  /// The latest allowable [DateTime] that the user can input.
  final DateTime lastDate;

  /// An optional method to call when the user indicates they are done editing
  /// the text in the field. Will only be called if the input represents a valid
  /// [DateTime].
  final ValueChanged<DateTime>? onDateSubmitted;

  /// An optional method to call with the final date when the form is
  /// saved via [FormState.save]. Will only be called if the input represents
  /// a valid [DateTime].
  final ValueChanged<DateTime>? onDateSaved;

  /// Function to provide full control over which [DateTime] can be selected.
  final SelectableDayPredicate? selectableDayPredicate;

  /// The error text displayed if the entered date is not in the correct format.
  final String? errorFormatText;

  /// The error text displayed if the date is not valid.
  ///
  /// A date is not valid if it is earlier than [firstDate], later than
  /// [lastDate], or doesn't pass the [selectableDayPredicate].
  final String? errorInvalidText;

  /// The error text displayed if the text is empty.
  final String? errorEmptyText;
  /// The hint text displayed in the [TextField].
  ///
  /// If this is null, it will default to the date format string. For example,
  /// 'mm/dd/yyyy' for en_US.
  final String? fieldHintText;

  /// The label text displayed in the [TextField].
  ///
  /// If this is null, it will default to the words representing the date format
  /// string. For example, 'Month, Day, Year' for en_US.
  final String? fieldLabelText;

  /// Text that provides context about the [InputDecorator.child]'s value, such
  /// as how the value will be used.
  ///
  /// If non-null, the text is displayed below the [InputDecorator.child], in
  /// the same location as [errorText]. If a non-null [errorText] value is
  /// specified then the helper text is not shown.
  final String? helperText;
  /// The [TextEditingController] to be passed to the [TextField].
  final TextEditingController? controller;
  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// If set to `true` allows the return of a `null` [DateTime].
  ///
  /// If set to `false` the validators will show an error if the field is left
  /// empty.
  ///
  /// This is useful for cases where a form needs a date, but it's not a
  /// required field and can be left empty.
  final bool allowEmptyDate;
  /// The type of action button to use for the keyboard.
  ///
  /// Defaults to [TextInputAction.newline] if [keyboardType] is
  /// [TextInputType.multiline] and [TextInputAction.done] otherwise.
  final TextInputAction? textInputAction;
  @override
  _InputDatePickerFormFieldState createState() => _InputDatePickerFormFieldState();
}

class _InputDatePickerFormFieldState extends State<InputDatePickerFormField> {
  TextEditingController? _controller;
  DateTime? _selectedDate;
  String? _inputText;
  bool _autoSelected = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedDate != null) {
      _inputText = _formatCompactDate(_selectedDate);
      TextEditingValue textEditingValue = _controller!.value.copyWith(text: _inputText);
      // Select the new text if we are auto focused and haven't selected the text before.
      if (widget.autofocus && !_autoSelected) {
        textEditingValue = textEditingValue.copyWith(selection: TextSelection(
          baseOffset: 0,
          extentOffset: _inputText!.length,
        ));
        _autoSelected = true;
      }
      _controller!.value = textEditingValue;
    }
  }

  bool _isBlank(String? s) => s == null || s.trim().isEmpty;

  String _formatCompactDate(DateTime? date) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context)!;
    return date != null ? localizations.formatCompactDate(date) : '';
  }
  DateTime? _parseDate(String? text) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context)!;
    return localizations.parseCompactDate(text);
  }

  bool _isValidAcceptableDate(DateTime? date) {
    return
      date != null &&
      !date.isBefore(widget.firstDate) &&
      !date.isAfter(widget.lastDate) &&
      (widget.selectableDayPredicate == null || widget.selectableDayPredicate!(date));
  }

  String? _validateDate(String? text) {
    if (_isBlank(text) && !widget.allowEmptyDate) {
      return widget.errorEmptyText;
    }
    final DateTime? date = _parseDate(text);
    if (date == null) {
      if (widget.allowEmptyDate) {
        return null;
      }
      return widget.errorFormatText ?? MaterialLocalizations.of(context)!.invalidDateFormatLabel;
    } else if (!_isValidAcceptableDate(date)) {
      return widget.errorInvalidText ?? MaterialLocalizations.of(context)!.dateOutOfRangeLabel;
    }
    return null;
  }

  void _handleSaved(String? text) {
    if (widget.onDateSaved != null) {
      final DateTime? date = _parseDate(text);
      if (_isValidAcceptableDate(date)) {
        _selectedDate = date;
        _inputText = text;
        widget.onDateSaved!(date!);
      }
    }
  }

  void _handleSubmitted(String text) {
    if (widget.onDateSubmitted != null) {
      final DateTime? date = _parseDate(text);
      if (_isValidAcceptableDate(date)) {
        _selectedDate = date;
        _inputText = text;
        widget.onDateSubmitted!(date!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context)!;
    final InputDecorationTheme inputTheme = Theme.of(context)!.inputDecorationTheme;
    return TextFormField(
      decoration: InputDecoration(
        border: inputTheme.border ?? const UnderlineInputBorder(),
        filled: inputTheme.filled,
        hintText: widget.fieldHintText ?? localizations.dateHelpText,
        labelText: widget.fieldLabelText ?? localizations.dateInputLabel,
        helperText: widget.helperText,
        suffixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(end: 12.0),
          child: IconButton(
            focusNode: FocusNode(skipTraversal: true),
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final DateTime selectedDate = await showDatePicker(
                context: context,
                initialDate: widget.initialDate ?? DateTime.now(),
                firstDate: widget.firstDate,
                lastDate: widget.lastDate,
                currentDate: widget.currentDate,
                fieldHintText: widget.fieldHintText,
                fieldLabelText: widget.fieldLabelText,
                errorFormatText: widget.errorFormatText,
                errorInvalidText: widget.errorInvalidText,
                locale: Localizations.localeOf(context),
              );
              _controller!.text = _formatCompactDate(selectedDate);
            },
          ),
        ),
      ),
      validator: _validateDate,
      keyboardType: TextInputType.datetime,
      textInputAction: widget.textInputAction,
      onSaved: _handleSaved,
      onFieldSubmitted: _handleSubmitted,
      autofocus: widget.autofocus,
      controller: _controller,
    );
  }
}
