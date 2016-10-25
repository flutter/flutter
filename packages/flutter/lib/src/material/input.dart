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

/// A material design text input field.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// The [text], [selection], and [composing] properties control the editable
/// text. If null, the [Input] widget will manage them for you, as the user
/// edits the input field. Otherwise, they should be updated in response to the
/// [onChanged] event.
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
  Input({
    Key key,
    this.text,
    this.selection,
    this.composing,
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

  /// The editable text displayed in the input field. If this is null, the
  /// [Input] manages it for you.
  final String text;

  /// The range of editable text that is currently selected. If this is null,
  /// the [Input] manages it for you.
  final TextSelection selection;

  /// The range of editable text that is still being composed. If this is null,
  /// the [Input] manages it for you.
  final TextRange composing;

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
  /// The [text], [selection], and [composing] arguments must be updated (or
  /// remain null to allow the [Input] to manage them) each time [onChanged] is
  /// invoked.
  final ValueChanged<InputValue> onChanged;

  /// Called when the user indicates that they are done editing the text in the field.
  final ValueChanged<InputValue> onSubmitted;

  @override
  _InputState createState() => new _InputState();
}

const Duration _kTransitionDuration = const Duration(milliseconds: 200);
const Curve _kTransitionCurve = Curves.fastOutSlowIn;

class _InputState extends State<Input> {
  GlobalKey<RawInputState> _rawInputKey = new GlobalKey<RawInputState>();

  GlobalKey get focusKey => config.key is GlobalKey ? config.key : _rawInputKey;

  InputValue _currentValue;
  void _onChanged(InputValue val) {
    // We call setState more often than necessary, because this only controls
    // whether the hint text is displayed, but it's simpler to always call it.
    setState(() {
      _currentValue = val;
    });
    if (config.onChanged != null)
      config.onChanged(val);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    ThemeData themeData = Theme.of(context);
    BuildContext focusContext = focusKey.currentContext;
    bool focused = focusContext != null && Focus.at(focusContext, autofocus: config.autofocus);
    String errorText = config.errorText;
    TextStyle textStyle = config.style ?? themeData.textTheme.subhead;
    Color activeColor = themeData.hintColor;
    String text = config.text ?? _currentValue?.text ?? '';
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

    bool hasInlineLabel = config.labelText != null && !focused && text.isEmpty;

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

    if (config.hintText != null && text.isEmpty && !hasInlineLabel) {
      TextStyle hintStyle = themeData.textTheme.subhead.copyWith(color: themeData.hintColor);
      stackChildren.add(new Positioned(
        left: 0.0,
        top: topPadding + textStyle.fontSize - hintStyle.fontSize,
        child: new Text(config.hintText, style: hintStyle)
      ));
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
      child: new RawInput(
        key: _rawInputKey,
        text: config.text,
        selection: config.selection,
        composing: config.composing,
        focusKey: focusKey,
        style: textStyle,
        hideText: config.hideText,
        maxLines: config.maxLines,
        cursorColor: themeData.textSelectionColor,
        selectionColor: themeData.textSelectionColor,
        selectionControls: materialTextSelectionControls,
        platform: Theme.of(context).platform,
        keyboardType: config.keyboardType,
        onChanged: _onChanged,
        onSubmitted: config.onSubmitted,
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
        onTap: () => _rawInputKey.currentState?.requestKeyboard(),
        child: child
      )
    );
  }
}
