// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'debug.dart';
import 'icon.dart';
import 'theme.dart';

export 'package:sky_services/editing/editing.mojom.dart' show KeyboardType;

/// A material design text input field.
class Input extends StatefulComponent {
  Input({
    Key key,
    this.value: InputValue.empty,
    this.keyboardType: KeyboardType.text,
    this.icon,
    this.labelText,
    this.hintText,
    this.errorText,
    this.style,
    this.hideText: false,
    this.isDense: false,
    this.autofocus: false,
    this.onChanged,
    this.onSubmitted
  }) : super(key: key);

  /// The text of the input field.
  final InputValue value;

  /// The type of keyboard to use for editing the text.
  final KeyboardType keyboardType;

  /// An icon to show adjacent to the input field.
  final String icon;

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

  /// Called when the text being edited changes.
  final ValueChanged<InputValue> onChanged;

  /// Called when the user indicates that they are done editing the text in the field.
  final ValueChanged<InputValue> onSubmitted;

  _InputState createState() => new _InputState();
}

const Duration _kTransitionDuration = const Duration(milliseconds: 200);
const Curve _kTransitionCurve = Curves.ease;

class _InputState extends State<Input> {
  GlobalKey<RawInputLineState> _rawInputLineKey = new GlobalKey<RawInputLineState>();

  GlobalKey get focusKey => config.key is GlobalKey ? config.key : _rawInputLineKey;

  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    ThemeData themeData = Theme.of(context);
    BuildContext focusContext = focusKey.currentContext;
    bool focused = focusContext != null && Focus.at(focusContext, autofocus: config.autofocus);

    TextStyle textStyle = config.style ?? themeData.text.subhead;
    Color focusHighlightColor = themeData.accentColor;
    if (themeData.primarySwatch != null)
      focusHighlightColor = focused ? themeData.primarySwatch[400] : themeData.hintColor;
    double topPadding = config.isDense ? 12.0 : 16.0;

    List<Widget> stackChildren = <Widget>[];

    bool hasInlineLabel = config.labelText != null && !focused && !config.value.text.isNotEmpty;

    if (config.labelText != null) {
      TextStyle labelStyle = hasInlineLabel ?
        themeData.text.subhead.copyWith(color: themeData.hintColor) :
        themeData.text.caption.copyWith(color: focused ? focusHighlightColor : themeData.hintColor);

      double topPaddingIncrement = themeData.text.caption.fontSize + (config.isDense ? 4.0 : 8.0);
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

    if (config.hintText != null && config.value.text.isEmpty && !hasInlineLabel) {
      TextStyle hintStyle = themeData.text.subhead.copyWith(color: themeData.hintColor);
      stackChildren.add(new Positioned(
        left: 0.0,
        top: topPadding + textStyle.fontSize - hintStyle.fontSize,
        child: new Text(config.hintText, style: hintStyle)
      ));
    }

    Color cursorColor = themeData.primarySwatch == null ?
      themeData.accentColor :
      themeData.primarySwatch[200];

    EdgeDims margin = new EdgeDims.only(bottom: config.isDense ? 4.0 : 8.0);
    EdgeDims padding = new EdgeDims.only(top: topPadding, bottom: 8.0);
    Color borderColor = focusHighlightColor;
    double borderWidth = focused ? 2.0 : 1.0;

    if (config.errorText != null) {
      borderColor = themeData.errorColor;
      borderWidth = 2.0;
      if (!config.isDense) {
        margin = const EdgeDims.only(bottom: 15.0);
        padding = new EdgeDims.only(top: topPadding, bottom: 1.0);
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
        value: config.value,
        focusKey: focusKey,
        style: textStyle,
        hideText: config.hideText,
        cursorColor: cursorColor,
        selectionColor: cursorColor,
        keyboardType: config.keyboardType,
        onChanged: config.onChanged,
        onSubmitted: config.onSubmitted
      )
    ));

    if (config.errorText != null && !config.isDense) {
      TextStyle errorStyle = themeData.text.caption.copyWith(color: themeData.errorColor);
      stackChildren.add(new Positioned(
        left: 0.0,
        bottom: 0.0,
        child: new Text(config.errorText, style: errorStyle)
      ));
    }

    Widget child = new Stack(children: stackChildren);

    if (config.icon != null) {
      double iconSize = config.isDense ? 18.0 : 24.0;
      double iconTop = topPadding + (textStyle.fontSize - iconSize) / 2.0;
      child = new Row(
        alignItems: FlexAlignItems.start,
        children: [
          new Container(
            margin: new EdgeDims.only(right: 16.0, top: iconTop),
            width: config.isDense ? 40.0 : 48.0,
            child: new Icon(
              icon: config.icon,
              color: focused ? focusHighlightColor : Colors.black45,
              size: config.isDense ? IconSize.s18 : IconSize.s24
            )
          ),
          new Flexible(child: child)
        ]
      );
    }

    return new GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _rawInputLineKey.currentState?.requestKeyboard(),
      child: new Padding(
        padding: const EdgeDims.symmetric(horizontal: 16.0),
        child: child
      )
    );
  }
}
