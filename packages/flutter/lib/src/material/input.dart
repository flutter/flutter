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

export 'package:flutter/services.dart' show TextInputType;

class InputField extends StatefulWidget {
  InputField({
    Key key,
    this.focusKey,
    this.value,
    this.keyboardType: TextInputType.text,
    this.hintText,
    this.style,
    this.hideText: false,
    this.maxLines: 1,
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  final GlobalKey focusKey;

  /// The current state of text of the input field. This includes the selected
  /// text, if any, among other things.
  final InputValue value;

  /// The type of keyboard to use for editing the text.
  final TextInputType keyboardType;

  /// Text to show inline in the input field when it would otherwise be empty.
  final String hintText;

  /// The style to use for the text being edited.
  final TextStyle style;

  /// Whether to hide the text being edited (e.g., for passwords).
  ///
  /// When this is set to true, all the characters in the input are replaced by
  /// U+2022 BULLET characters (•).
  final bool hideText;

  /// The maximum number of lines for the text to span, wrapping if necessary.
  /// If this is 1 (the default), the text will not wrap, but will scroll
  /// horizontally instead.
  final int maxLines;

  /// Called when the text being edited changes.
  ///
  /// The [value] must be updated each time [onChanged] is invoked.
  final ValueChanged<InputValue> onChanged;

  /// Called when the user indicates that they are done editing the text in the field.
  final ValueChanged<InputValue> onSubmitted;

  @override
  _InputFieldState createState() => new _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  GlobalKey<RawInputState> _rawInputKey = new GlobalKey<RawInputState>();
  GlobalKey<RawInputState> _focusKey = new GlobalKey();

  GlobalKey get focusKey => config.focusKey ?? (config.key is GlobalKey ? config.key : _focusKey);

  void requestKeyboard() {
    _rawInputKey.currentState?.requestKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final InputValue value = config.value ?? InputValue.empty;
    final ThemeData themeData = Theme.of(context);
    final TextStyle textStyle = config.style ?? themeData.textTheme.subhead;

    final List<Widget> stackChildren = <Widget>[
      new GestureDetector(
        key: focusKey == _focusKey ? _focusKey : null,
        behavior: HitTestBehavior.opaque,
        onTap: () {
          requestKeyboard();
        },
        // Since the focusKey may have been created here, defer building the
        // RawInput until the focusKey's context has been set. This is necessary
        // because the RawInput will check the focus, like Focus.at(focusContext),
        // when it builds.
        child: new Builder(
          builder: (BuildContext context) {
            return new RawInput(
              key: _rawInputKey,
              value: value,
              focusKey: focusKey,
              style: textStyle,
              hideText: config.hideText,
              maxLines: config.maxLines,
              cursorColor: themeData.textSelectionColor,
              selectionColor: themeData.textSelectionColor,
              selectionControls: materialTextSelectionControls,
              platform: Theme.of(context).platform,
              keyboardType: config.keyboardType,
              onChanged: config.onChanged,
              onSubmitted: config.onSubmitted,
            );
          }
        ),
      ),
    ];

    if (config.hintText != null && value.text.isEmpty) {
      TextStyle hintStyle = themeData.textTheme.subhead.copyWith(color: themeData.hintColor);
      stackChildren.add(
        new Positioned(
          left: 0.0,
          top: textStyle.fontSize - hintStyle.fontSize,
          child: new IgnorePointer(
            child: new Text(config.hintText, style: hintStyle),
          ),
        ),
      );
    }

    return new RepaintBoundary(child: new Stack(children: stackChildren));
  }
}

/// A material design text input field.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// The [value] field must be updated each time the [onChanged] callback is
/// invoked. Be sure to include the full [value] provided by the [onChanged]
/// callback, or information like the current selection will be lost.
///
/// See also:
///
///  * <https://material.google.com/components/text-fields.html>
///
/// For a detailed guide on using the input widget, see:
///
/// * <https://flutter.io/text-input/>
class Input extends StatefulWidget {
  /// Creates a text input field.
  ///
  /// By default, the input uses a keyboard appropriate for text entry.
  //
  // Note: If you change this constructor signature, please also update
  // InputFormField below.
  Input({
    Key key,
    this.value,
    this.keyboardType: TextInputType.text,
    this.icon,
    this.labelText,
    this.hintText,
    this.errorText,
    this.style,
    this.hideText: false,
    this.isDense: false,
    this.autofocus: false,
    this.maxLines: 1,
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  /// The current state of text of the input field. This includes the selected
  /// text, if any, among other things.
  final InputValue value;

  /// The type of keyboard to use for editing the text.
  final TextInputType keyboardType;

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
  ///
  /// When this is set to true, all the characters in the input are replaced by
  /// U+2022 BULLET characters (•).
  final bool hideText;

  /// Whether the input field is part of a dense form (i.e., uses less vertical space).
  final bool isDense;

  /// Whether this input field should focus itself if nothing else is already focused.
  final bool autofocus;

  /// The maximum number of lines for the text to span, wrapping if necessary.
  /// If this is 1 (the default), the text will not wrap, but will scroll
  /// horizontally instead.
  final int maxLines;

  /// Called when the text being edited changes.
  ///
  /// The [value] must be updated each time [onChanged] is invoked.
  final ValueChanged<InputValue> onChanged;

  /// Called when the user indicates that they are done editing the text in the field.
  final ValueChanged<InputValue> onSubmitted;

  @override
  _InputState createState() => new _InputState();
}

const Duration _kTransitionDuration = const Duration(milliseconds: 200);
const Curve _kTransitionCurve = Curves.fastOutSlowIn;

class _InputState extends State<Input> {
  GlobalKey<_InputFieldState> _inputFieldKey = new GlobalKey<_InputFieldState>(debugLabel: 'Input.inputField');
  GlobalKey<_InputFieldState> _focusKey = new GlobalKey(debugLabel: 'Input.focus');

  GlobalKey get focusKey => config.key is GlobalKey ? config.key : _focusKey;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    ThemeData themeData = Theme.of(context);
    BuildContext focusContext = focusKey.currentContext;
    bool focused = focusContext != null && Focus.at(focusContext, autofocus: config.autofocus);
    InputValue value = config.value ?? InputValue.empty;
    String errorText = config.errorText;

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

    final bool hasInlineLabel = config.labelText != null && !focused && !value.text.isNotEmpty;
    if (config.labelText != null) {
      final TextStyle labelStyle = hasInlineLabel ?
        themeData.textTheme.subhead.copyWith(color: themeData.hintColor) :
        themeData.textTheme.caption.copyWith(color: activeColor);

      final double topPaddingIncrement = themeData.textTheme.caption.fontSize + (config.isDense ? 4.0 : 8.0);
      double top = topPadding;
      if (hasInlineLabel)
        top += topPaddingIncrement + textStyle.fontSize - labelStyle.fontSize;

      stackChildren.add(
        new AnimatedPositioned(
          left: 0.0,
          top: top,
          duration: _kTransitionDuration,
          curve: _kTransitionCurve,
          child: new AnimatedOpacity(
            opacity: focused ? 1.0 : 0.0,
            curve: _kTransitionCurve,
            duration: _kTransitionDuration,
            child: new Text(config.labelText, style: labelStyle)
          ),
        ),
      );

      topPadding += topPaddingIncrement;
    }

    Color borderColor = activeColor;
    double bottomPadding = 8.0;
    double bottomBorder = focused ? 2.0 : 1.0;
    double bottomHeight = config.isDense ? 14.0 : 18.0;

    if (errorText != null) {
      borderColor = themeData.errorColor;
      bottomBorder = 2.0;
      if (!config.isDense)
        bottomPadding = 1.0;
    }

    EdgeInsets padding = new EdgeInsets.only(top: topPadding, bottom: bottomPadding);
    Border border = new Border(
      bottom: new BorderSide(
        color: borderColor,
        width: bottomBorder,
      )
    );
    EdgeInsets margin = new EdgeInsets.only(bottom: bottomHeight - (bottomPadding + bottomBorder));

    stackChildren.add(new AnimatedContainer(
      margin: margin,
      padding: padding,
      duration: _kTransitionDuration,
      curve: _kTransitionCurve,
      decoration: new BoxDecoration(
        border: border,
      ),
      // Since the focusKey may have been created here, defer building the
      // InputField until the focusKey's context has been set. This is necessary
      // because our descendants may check the focus, like Focus.at(focusContext),
      // when they build.
      child: new Builder(
        builder: (BuildContext context) {
          return new InputField(
            key: _inputFieldKey,
            focusKey: focusKey,
            value: value,
            style: textStyle,
            hideText: config.hideText,
            maxLines: config.maxLines,
            keyboardType: config.keyboardType,
            hintText: config.hintText,
            onChanged: config.onChanged,
            onSubmitted: config.onSubmitted,
          );
        }
      ),
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

    return new GestureDetector(
      key: config.key is GlobalKey ? null : focusKey,
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _inputFieldKey.currentState?.requestKeyboard();
      },
      child: child,
    );
  }
}

/// A [FormField] that contains an [Input].
class InputFormField extends FormField<InputValue> {
  InputFormField({
    Key key,
    GlobalKey focusKey,
    TextInputType keyboardType: TextInputType.text,
    Icon icon,
    String labelText,
    String hintText,
    TextStyle style,
    bool hideText: false,
    bool isDense: false,
    bool autofocus: false,
    int maxLines: 1,
    InputValue initialValue: InputValue.empty,
    FormFieldSetter<InputValue> onSaved,
    FormFieldValidator<InputValue> validator,
  }) : super(
    key: key,
    initialValue: initialValue,
    onSaved: onSaved,
    validator: validator,
    builder: (FormFieldState<InputValue> field) {
      return new Input(
        key: focusKey,
        keyboardType: keyboardType,
        icon: icon,
        labelText: labelText,
        hintText: hintText,
        style: style,
        hideText: hideText,
        isDense: isDense,
        autofocus: autofocus,
        maxLines: maxLines,
        value: field.value,
        onChanged: field.onChanged,
        errorText: field.errorText,
      );
    },
  );
}
