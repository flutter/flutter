// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../../material.dart';

/// A [TextFormField] configured to accept and validate a time entered by the user.
///
/// When the field is saved or submitted, the text will be parsed into a
/// [TimeOfDay]. If the input text doesn't parse into a time, the
/// [errorFormatText] message will be displayed under the field.
///
/// See also:
///
///  * [showTimePicker], which shows a dialog that contains a material design
///    time picker which includes support for text entry as well.
///
class InputTimePickerFormField extends StatefulWidget {
  /// Creates a [TextFormField] configured to accept and validate time.
  ///
  /// If the optional [initialTime] is provided, then it will be used to populate
  /// the text field. If the [fieldHintText] is provided, it will be shown instead.
  ///
  /// [autofocus] must be non-null.
  ///
  const InputTimePickerFormField({
    Key? key,
    this.initialTime,
    this.onTimeSubmitted,
    this.onTimeSaved,
    this.errorFormatText,
    this.errorEmptyText,
    this.fieldHintText,
    this.fieldLabelText,
    this.helperText,
    this.controller,
    this.autofocus = false,
    this.allowEmptyTime = false,
    this.textInputAction,
  })  : assert(autofocus != null),
        assert(allowEmptyTime != null),
        super(key: key);

  /// If provided, it will be used as the default value for the field.
  final TimeOfDay? initialTime;

  /// An optional method to call when the user indicates they are done editing
  /// the text in the field. Will only be called if the input represents a valid
  /// [TimeOfDay].
  final ValueChanged<TimeOfDay?>? onTimeSubmitted;

  /// An optional method to call with the final time when the form is
  /// saved via [FormState.save]. Will only be called if the input represents
  /// a valid [TimeOfDay].
  final ValueChanged<TimeOfDay?>? onTimeSaved;

  /// The error text displayed if the entered time is not in the correct format.
  final String? errorFormatText;

  /// The error text displayed if the text is empty.
  final String? errorEmptyText;

  /// The hint text displayed in the [TextField].
  ///
  /// If this is null, it will default to the time format string. For example,
  /// 'HH:mm' for en_US.
  // TODO(anyone): Add a helper text for the time format string. This isn't currently working
  final String? fieldHintText;

  /// The label text displayed in the [TextField].
  ///
  /// If this is null, it will default to the words representing the time format
  /// string. For example, 'Hour, Minute' for en_US.
  // TODO(anyone): Add a helper text for the time format string. This isn't currently working
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

  /// If set to `true` allows the return of a `null` [TimeOfDay].
  ///
  /// If set to `false` the validators will show an error if the field is left
  /// empty.
  ///
  /// This is useful for cases where a form needs a time, but it's not a
  /// required field and can be left empty.
  final bool allowEmptyTime;

  /// The type of action button to use for the keyboard.
  ///
  /// Defaults to [TextInputAction.newline] if [keyboardType] is
  /// [TextInputType.multiline] and [TextInputAction.done] otherwise.
  final TextInputAction? textInputAction;

  @override
  _InputTimePickerFormFieldState createState() => _InputTimePickerFormFieldState();
}

class _InputTimePickerFormFieldState extends State<InputTimePickerFormField> {
  TextEditingController? _controller;
  bool isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only runs once. We can't place this on initState as TimeOfDay.format
    // needs to access the context, in order to get the localizations for the
    // time format.
    if (isInit) {
      isInit = false;
      _controller = widget.controller ??
          TextEditingController(text: widget.initialTime?.format(context));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  bool _isBlank(String? s) => s == null || s.trim().isEmpty;

  String _formatCompactTime(TimeOfDay? time) => time?.format(context) ?? '';

  TimeOfDay? _parseTime(String? text) {
    final String languageTag = Localizations.localeOf(context)!.toLanguageTag();
    DateTime? dateTime;
    try {
      // TODO(anyone): Create an equivalent parser: https://github.com/flutter/flutter/issues/68238
      // dateTime = DateFormat.Hm(languageTag).parseStrict(text);
      // Adding this just so there won't be any compilation errors, this line should be removed:
      dateTime = DateTime.now();
    } on FormatException catch (_) {
      return null;
    }
    return TimeOfDay.fromDateTime(dateTime);
  }

  String? _validateTime(String? text) {
    if (_isBlank(text) && !widget.allowEmptyTime) {
      return widget.errorEmptyText;
    }

    final TimeOfDay? time = _parseTime(text);

    if (time != null || widget.allowEmptyTime) {
      return null;
    }
    return widget.errorFormatText ??
        MaterialLocalizations.of(context)!.invalidTimeLabel;
  }

  void _handleSaved(String? text) {
    if (widget.onTimeSaved != null) {
      final TimeOfDay? time = _parseTime(text);
      widget.onTimeSaved!(time);
    }
  }

  void _handleSubmitted(String text) {
    if (widget.onTimeSubmitted != null) {
      final TimeOfDay? time = _parseTime(text);
      widget.onTimeSubmitted!(time);
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
        // TODO(anyone): Make localizations for these time texts, the same there are for dates:
        hintText: widget.fieldHintText ?? localizations.timePickerInputHelpText,
        labelText: widget.fieldLabelText ?? localizations.timePickerInputHelpText,
        helperText: widget.helperText,
        suffixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(end: 12.0),
          child: IconButton(
            focusNode: FocusNode(skipTraversal: true),
            icon: const Icon(Icons.access_time),
            onPressed: () async {
              // showTimePicker returns null if the dialog was canceled. I
              // believe it wasn't converted yet to non nullable.
              final TimeOfDay? selectedTime = await showTimePicker(
                context: context,
                initialTime: widget.initialTime ??
                    _parseTime(_controller?.text) ??
                    TimeOfDay.now(),
                initialEntryMode: TimePickerEntryMode.input,
              );

              _controller?.text = _formatCompactTime(selectedTime);
            },
          ),
        ),
      ),
      validator: _validateTime,
      keyboardType: TextInputType.datetime,
      textInputAction: widget.textInputAction,
      onSaved: _handleSaved,
      onFieldSubmitted: _handleSubmitted,
      autofocus: widget.autofocus,
      controller: _controller,
    );
  }
}
