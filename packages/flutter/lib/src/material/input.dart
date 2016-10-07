// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'debug.dart';
import 'icon.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'material.dart';
import 'text_selection.dart';
import 'theme.dart';

export 'package:flutter_services/editing.dart' show KeyboardType;

/// A material design text input field.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * <https://www.google.com/design/spec/components/text-fields.html>
///
/// For a detailed guide on using the input widget, see:
///
/// * <https://flutter.io/text-input/>
class Input extends StatefulWidget {
  /// Creates a text input field.
  ///
  /// By default, the input uses a keyboard appropriate for text entry.
  Input({
    Key key,
    this.value,
    this.keyboardType: KeyboardType.text,
    this.icon,
    this.labelText,
    this.hintText,
    this.errorText,
    this.style,
    this.hideText: false,
    this.isDense: false,
    this.autofocus: false,
    this.multiline: false,
    this.formField,
    this.onChanged,
    this.onSubmitted
  }) : super(key: key);

  /// The text of the input field.
  final InputValue value;

  /// The type of keyboard to use for editing the text.
  final KeyboardType keyboardType;

  /// An icon to show adjacent to the input field.
  ///
  /// The size and color of the icon is configured automatically using an
  /// [IconTheme] and therefore does not need to be explicitly given in the
  /// icon widget.
  ///
  /// See [Icon], [ImageIcon].
  final Widget icon;

  /// Text to show above the input field.
  final String labelText;

  /// Text to show inline in the input field when it would otherwise be empty.
  final String hintText;

  /// Text to show when the input text is invalid.
  final String errorText;

  /// The style to use for the text being edited.
  final TextStyle style;

  /// Whether to hide the text being edited (e.g., for passwords).
  final bool hideText;

  /// Whether the input field is part of a dense form (i.e., uses less vertical space).
  final bool isDense;

  /// Whether this input field should focus itself is nothing else is already focused.
  final bool autofocus;

  /// True if the text should wrap and span multiple lines, false if it should
  /// stay on a single line and scroll when overflowed.
  final bool multiline;

  /// Form-specific data, required if this Input is part of a Form.
  final FormField<String> formField;

  /// Called when the text being edited changes.
  final ValueChanged<InputValue> onChanged;

  /// Called when the user indicates that they are done editing the text in the field.
  final ValueChanged<InputValue> onSubmitted;

  @override
  _InputState createState() => new _InputState();
}

const Duration _kTransitionDuration = const Duration(milliseconds: 200);
const Curve _kTransitionCurve = Curves.fastOutSlowIn;

class _InputState extends State<Input> {
  GlobalKey<RawInputLineState> _rawInputLineKey = new GlobalKey<RawInputLineState>();

  GlobalKey get focusKey => config.key is GlobalKey ? config.key : _rawInputLineKey;

  // Optional state to retain if we are inside a Form widget.
  _FormFieldData _formData;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    ThemeData themeData = Theme.of(context);
    BuildContext focusContext = focusKey.currentContext;
    bool focused = focusContext != null && Focus.at(focusContext, autofocus: config.autofocus);
    if (_formData == null)
      _formData = _FormFieldData.maybeCreate(context, this);
    InputValue value =  _formData?.value ?? config.value ?? InputValue.empty;
    ValueChanged<InputValue> onChanged = _formData?.onChanged ?? config.onChanged;
    ValueChanged<InputValue> onSubmitted = _formData?.onSubmitted ?? config.onSubmitted;
    String errorText = config.errorText;

    if (errorText == null && config.formField != null && config.formField.validator != null)
      errorText = config.formField.validator(value.text);

    TextStyle textStyle = config.style ?? themeData.textTheme.subhead;
    Color activeColor = themeData.hintColor;
    if (focused) {
      switch (themeData.brightness) {
        case Brightness.dark:
          activeColor = themeData.accentColor;
          break;
        case Brightness.light:
          activeColor = themeData.primaryColor;
          break;
      }
    }
    double topPadding = config.isDense ? 12.0 : 16.0;

    List<Widget> stackChildren = <Widget>[];

    bool hasInlineLabel = config.labelText != null && !focused && !value.text.isNotEmpty;

    if (config.labelText != null) {
      TextStyle labelStyle = hasInlineLabel ?
        themeData.textTheme.subhead.copyWith(color: themeData.hintColor) :
        themeData.textTheme.caption.copyWith(color: activeColor);

      double topPaddingIncrement = themeData.textTheme.caption.fontSize + (config.isDense ? 4.0 : 8.0);
      double top = topPadding;
      if (hasInlineLabel)
        top += topPaddingIncrement + textStyle.fontSize - labelStyle.fontSize;

      stackChildren.add(new AnimatedPositioned(
        left: 0.0,
        top: top,
        duration: _kTransitionDuration,
        curve: _kTransitionCurve,
        child: new Text(config.labelText, style: labelStyle)
      ));

      topPadding += topPaddingIncrement;
    }

    if (config.hintText != null && value.text.isEmpty && !hasInlineLabel) {
      TextStyle hintStyle = themeData.textTheme.subhead.copyWith(color: themeData.hintColor);
      stackChildren.add(new Positioned(
        left: 0.0,
        top: topPadding + textStyle.fontSize - hintStyle.fontSize,
        child: new Text(config.hintText, style: hintStyle)
      ));
    }

    EdgeInsets margin = new EdgeInsets.only(bottom: config.isDense ? 4.0 : 8.0);
    EdgeInsets padding = new EdgeInsets.only(top: topPadding, bottom: 8.0);
    Color borderColor = activeColor;
    double borderWidth = focused ? 2.0 : 1.0;

    if (errorText != null) {
      borderColor = themeData.errorColor;
      borderWidth = 2.0;
      if (!config.isDense) {
        margin = const EdgeInsets.only(bottom: 15.0);
        padding = new EdgeInsets.only(top: topPadding, bottom: 1.0);
      }
    }

    stackChildren.add(new AnimatedContainer(
      margin: margin,
      padding: padding,
      duration: _kTransitionDuration,
      curve: _kTransitionCurve,
      decoration: new BoxDecoration(
        border: new Border(
          bottom: new BorderSide(
            color: borderColor,
            width: borderWidth
          )
        )
      ),
      child: new RawInputLine(
        key: _rawInputLineKey,
        value: value,
        focusKey: focusKey,
        style: textStyle,
        hideText: config.hideText,
        multiline: config.multiline,
        cursorColor: themeData.textSelectionColor,
        selectionColor: themeData.textSelectionColor,
        selectionControls: materialTextSelectionControls,
        platform: Theme.of(context).platform,
        keyboardType: config.keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted
      )
    ));

    if (errorText != null && !config.isDense) {
      TextStyle errorStyle = themeData.textTheme.caption.copyWith(color: themeData.errorColor);
      stackChildren.add(new Positioned(
        left: 0.0,
        bottom: 0.0,
        child: new Text(errorText, style: errorStyle)
      ));
    }

    Widget child = new Stack(children: stackChildren);

    if (config.icon != null) {
      double iconSize = config.isDense ? 18.0 : 24.0;
      double iconTop = topPadding + (textStyle.fontSize - iconSize) / 2.0;
      child = new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            margin: new EdgeInsets.only(right: 16.0, top: iconTop),
            width: config.isDense ? 40.0 : 48.0,
            child: new IconTheme.merge(
              context: context,
              data: new IconThemeData(
                color: focused ? activeColor : Colors.black45,
                size: config.isDense ? 18.0 : 24.0
              ),
              child: config.icon
            )
          ),
          new Flexible(child: child)
        ]
      );
    }

    return new RepaintBoundary(
      child: new GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _rawInputLineKey.currentState?.requestKeyboard(),
        child: new Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: child
        )
      )
    );
  }
}

class _FormFieldData {
  _FormFieldData(this.inputState) {
    assert(field != null);
    value = inputState.config.value ?? new InputValue();
  }

  InputValue value;
  final _InputState inputState;
  FormField<String> get field => inputState.config.formField;

  static _FormFieldData maybeCreate(BuildContext context, _InputState inputState) {
    // Only create a _FormFieldData if this Input is a descendent of a Form.
    if (FormScope.of(context) != null)
      return new _FormFieldData(inputState);
    return null;
  }

  void onChanged(InputValue value) {
    FormScope scope = FormScope.of(inputState.context);
    assert(scope != null);
    this.value = value;
    if (field.setter != null)
      field.setter(value.text);
    scope.onFieldChanged();
  }

  void onSubmitted(InputValue value) {
    FormScope scope = FormScope.of(inputState.context);
    assert(scope != null);
    if (scope.form.onSubmitted != null)
      scope.form.onSubmitted();
    scope.onFieldChanged();
  }
}
