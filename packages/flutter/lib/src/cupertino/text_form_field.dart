// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

import 'text_field.dart';

/// A [FormField] that contains a [CupertinoTextField].
///
/// This is a convenience widget that wraps a [CupertinoTextField] widget in a
/// [FormField].
///
/// A [Form] ancestor is not required. The [Form] simply makes it easier to
/// save, reset, or validate multiple fields at once. To use without a [Form],
/// pass a [GlobalKey] to the constructor and use [GlobalKey.currentState] to
/// save or reset the form field.
///
/// When a [controller] is specified, its [TextEditingController.text]
/// defines the [initialValue]. If this [FormField] is part of a scrolling
/// container that lazily constructs its children, like a [ListView] or a
/// [CustomScrollView], then a [controller] should be specified.
/// The controller's lifetime should be managed by a stateful widget ancestor
/// of the scrolling container.
///
/// If a [controller] is not specified, [initialValue] can be used to give
/// the automatically generated controller an initial value.
///
/// Remember to [dispose] of the [TextEditingController] when it is no longer needed.
/// This will ensure we discard any resources used by the object.
///
/// For a documentation about the various parameters, see [CupertinoTextField].
///
/// {@tool sample}
///
/// Creates a [CupertinoTextFormField] with a [BoxDecoration] and validator function.
///
/// ```dart
/// CupertinoTextFormField(
///   decoration: BoxDecoration(
///     border: Border.all(
///       color: CupertinoColors.lightBackgroundGray,
///       style: BorderStyle.solid,
///       width: 0.0,
///     ),
///     borderRadius: BorderRadius.all(Radius.circular(4.0)),
///   ),
///   onSaved: (String value) {
///     // This optional block of code can be used to run
///     // code when the user saves the form.
///   },
///   validator: (String value) {
///     return value.contains('@') ? 'Do not use the @ char.' : null;
///   },
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * <https://developer.apple.com/documentation/uikit/uitextfield>
///  * [CupertinoTextField], which is the underlying text field without the [FormField]
///    integration.
///  * [BoxDecoration], which is how you can customize the widget's look
///  * Learn how to use a [TextEditingController] in one of our [cookbook recipe]s.(https://flutter.dev/docs/cookbook/forms/text-field-changes#2-use-a-texteditingcontroller)
class CupertinoTextFormField extends FormField<String> {
  /// Creates a [FormField] that contains a [CupertinoTextField].
  ///
  /// When a [controller] is specified, [initialValue] must be null (the
  /// default). If [controller] is null, then a [TextEditingController]
  /// will be constructed automatically and its `text` will be initialized
  /// to [initalValue] or the empty string.
  ///
  /// For documentation about the various parameters, see the [CupertinoTextField] class
  /// and [new CupertinoTextField], the constructor.
  CupertinoTextFormField({
    Key key,
    this.controller,
    String initialValue,
    FormFieldSetter<String> onSaved,
    FormFieldValidator<String> validator,
    bool autovalidate = false,
    bool enabled = true,
    FocusNode focusNode,
    BoxDecoration decoration,
    EdgeInsetsGeometry padding= const EdgeInsets.all(6.0),
    String placeholder,
    TextStyle placeholderStyle,
    Widget prefix,
    OverlayVisibilityMode prefixMode = OverlayVisibilityMode.always,
    Widget suffix,
    OverlayVisibilityMode suffixMode = OverlayVisibilityMode.always,
    OverlayVisibilityMode clearButtonMode = OverlayVisibilityMode.never,
    TextInputType keyboardType,
    TextInputAction textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextStyle style,
    StrutStyle strutStyle,
    TextAlign textAlign = TextAlign.start,
    TextAlignVertical textAlignVertical,
    bool readOnly = false,
    ToolbarOptions toolbarOptions,
    bool showCursor,
    bool autofocus = false,
    bool obscureText = false,
    bool autocorrect = true,
    int maxLines = 1,
    int minLines,
    bool expands = false,
    int maxLength,
    bool maxLengthEnforced = true,
    ValueChanged<String> onChanged,
    VoidCallback onEditingComplete,
    ValueChanged<String> onFieldSubmitted,
    List<TextInputFormatter> inputFormatters,
    double cursorWidth = 2.0,
    Radius cursorRadius,
    Color cursorColor,
    Brightness keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    bool enableInteractiveSelection = true,
    GestureTapCallback onTap,
    ScrollController scrollController,
    ScrollPhysics scrollPhysics,
  }) :
  assert(initialValue == null || controller == null),
  assert(autovalidate != null),
  assert(textAlign != null),
  assert(readOnly != null),
  assert(autofocus != null),
  assert(obscureText != null),
  assert(autocorrect != null),
  assert(maxLengthEnforced != null),
  assert(scrollPadding != null),
  assert(dragStartBehavior != null),
  assert(maxLines == null || maxLines > 0),
  assert(minLines == null || minLines > 0),
  assert(
    (maxLines == null) || (minLines == null) || (maxLines >= minLines),
    'minLines can\'t be greater than maxLines',
  ),
  assert(expands != null),
  assert(
    !expands || (maxLines == null && minLines == null),
    'minLines and maxLines must be null when expands is true.',
  ),
  assert(maxLength == null || maxLength > 0),
  assert(enableInteractiveSelection != null),
  assert(clearButtonMode != null),
  assert(prefixMode != null),
  assert(suffixMode != null),
  super(
    key: key,
    initialValue: controller != null ? controller.text : (initialValue ?? ''),
    onSaved: onSaved,
    validator: validator,
    autovalidate: autovalidate,
    enabled: enabled,
    builder: (FormFieldState<String> field) {
      final _CupertinoTextFormFieldState state = field;
      void onChangedHandler(String value) {
        if (onChanged != null) {
          onChanged(value);
        }
        field.didChange(value);
      }
      return CupertinoTextField(
        controller: state._effectiveController,
        focusNode: focusNode,
        decoration: decoration,
        padding: padding,
        placeholder: placeholder,
        placeholderStyle: placeholderStyle,
        prefix: prefix,
        prefixMode: prefixMode,
        suffix: suffix,
        suffixMode: suffixMode,
        clearButtonMode: clearButtonMode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textAlignVertical: textAlignVertical,
        readOnly: readOnly,
        toolbarOptions: toolbarOptions,
        showCursor: showCursor,
        autofocus: autofocus,
        obscureText: obscureText,
        autocorrect: autocorrect,
        maxLines: maxLines,
        minLines: minLines,
        expands: expands,
        maxLength: maxLength,
        maxLengthEnforced: maxLengthEnforced,
        onChanged: onChangedHandler,
        onEditingComplete: onEditingComplete,
        onSubmitted: onFieldSubmitted,
        inputFormatters: inputFormatters,
        enabled: enabled,
        cursorWidth: cursorWidth,
        cursorRadius: cursorRadius,
        cursorColor: cursorColor,
        keyboardAppearance: keyboardAppearance,
        scrollPadding: scrollPadding,
        dragStartBehavior: dragStartBehavior,
        enableInteractiveSelection: enableInteractiveSelection,
        onTap: onTap,
        scrollController: scrollController,
        scrollPhysics: scrollPhysics,
      );
    },
  );

  /// Controls the text being edited.
  ///
  /// If null, this widget will create its own [TextEditingController] and
  /// initialize its [TextEditingController.text] with [initialValue].
  final TextEditingController controller;

  @override
  _CupertinoTextFormFieldState createState() => _CupertinoTextFormFieldState();
}

class _CupertinoTextFormFieldState extends FormFieldState<String> {
  TextEditingController _controller;

  TextEditingController get _effectiveController => widget.controller ?? _controller;

  @override
  CupertinoTextFormField get widget => super.widget;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController(text: widget.initialValue);
    } else {
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void didUpdateWidget(CupertinoTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      widget.controller?.addListener(_handleControllerChanged);

      if (oldWidget.controller != null && widget.controller == null)
        _controller = TextEditingController.fromValue(oldWidget.controller.value);
      if (widget.controller != null) {
        setValue(widget.controller.text);
        if (oldWidget.controller == null)
          _controller = null;
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  void reset() {
    super.reset();
    setState(() {
      _effectiveController.text = widget.initialValue;
    });
  }

  void _handleControllerChanged() {
    // Suppress changes that originated from within this class.
    //
    // In the case where a controller has been passed in to this widget, we
    // register this change listener. In these cases, we'll also receive change
    // notifications for changes originating from within this class -- for
    // example, the reset() method. In such cases, the FormField value will
    // already have been set.
    if (_effectiveController.text != value)
      didChange(_effectiveController.text);
  }
}
