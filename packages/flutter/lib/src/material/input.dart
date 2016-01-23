// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'debug.dart';
import 'icon.dart';
import 'theme.dart';

export 'package:flutter/rendering.dart' show ValueChanged;
export 'package:flutter/services.dart' show KeyboardType;

/// A material design text input field.
class Input extends Scrollable {
  Input({
    GlobalKey key,
    this.initialValue: '',
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
  }) : super(
    key: key,
    initialScrollOffset: 0.0,
    scrollDirection: Axis.horizontal
  ) {
    assert(key != null);
  }

  /// Initial editable text for the input field.
  final String initialValue;

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
  final ValueChanged<String> onChanged;

  /// Called when the user indicates that they are done editing the text in the field.
  final ValueChanged<String> onSubmitted;

  InputState createState() => new InputState();
}

class InputState extends ScrollableState<Input> {
  String _value;
  EditableString _editableString;
  KeyboardHandle _keyboardHandle = KeyboardHandle.unattached;

  double _contentWidth = 0.0;
  double _containerWidth = 0.0;

  EditableString get editableValue => _editableString;

  void initState() {
    super.initState();
    _value = config.initialValue;
    _editableString = new EditableString(
      text: _value,
      onUpdated: _handleTextUpdated,
      onSubmitted: _handleTextSubmitted
    );
  }

  void _handleTextUpdated() {
    if (_value != _editableString.text) {
      setState(() {
        _value = _editableString.text;
      });
      if (config.onChanged != null)
        config.onChanged(_value);
    }
  }

  void _handleTextSubmitted() {
    Focus.clear(context);
    if (config.onSubmitted != null)
      config.onSubmitted(_value);
  }

  Widget _buildEditableField({
    ThemeData themeData,
    bool focused,
    Color focusHighlightColor,
    TextStyle textStyle,
    double topPadding
  }) {
    Color cursorColor = themeData.primarySwatch == null ?
      themeData.accentColor :
      themeData.primarySwatch[200];

    EdgeDims margin = new EdgeDims.only(bottom: config.isDense ? 4.0 : 8.0);
    EdgeDims padding = new EdgeDims.only(top: topPadding, bottom: 8.0);
    Color borderColor = focusHighlightColor;
    double borderWidth = focused ? 2.0 : 1.0;

    if (config.errorText != null) {
      borderColor = Colors.red[700];
      borderWidth = 2.0;
      if (!config.isDense) {
        margin = const EdgeDims.only(bottom: 15.0);
        padding = new EdgeDims.only(top: topPadding, bottom: 1.0);
      }
    }

    return new Container(
      margin: margin,
      padding: padding,
      decoration: new BoxDecoration(
        border: new Border(
          bottom: new BorderSide(
            color: borderColor,
            width: borderWidth
          )
        )
      ),
      child: new SizeObserver(
        onSizeChanged: _handleContainerSizeChanged,
        child: new RawEditableLine(
          value: _editableString,
          focused: focused,
          style: textStyle,
          hideText: config.hideText,
          cursorColor: cursorColor,
          onContentSizeChanged: _handleContentSizeChanged,
          scrollOffset: scrollOffsetVector
        )
      )
    );
  }

  Widget buildContent(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    ThemeData themeData = Theme.of(context);
    bool focused = Focus.at(context, autofocus: config.autofocus);

    if (focused && !_keyboardHandle.attached) {
      _keyboardHandle = keyboard.show(_editableString.stub, config.keyboardType);
      _keyboardHandle.setText(_editableString.text);
      _keyboardHandle.setSelection(_editableString.selection.start,
                                   _editableString.selection.end);
    } else if (!focused && _keyboardHandle.attached) {
      _keyboardHandle.release();
    }

    TextStyle textStyle = config.style ?? themeData.text.subhead;
    Color focusHighlightColor = themeData.accentColor;
    if (themeData.primarySwatch != null)
      focusHighlightColor = focused ? themeData.primarySwatch[400] : themeData.hintColor;
    double topPadding = config.isDense ? 12.0 : 16.0;

    List<Widget> stackChildren = <Widget>[];

    if (config.labelText != null) {
      TextStyle labelStyle = themeData.text.caption.copyWith(color: focused ? focusHighlightColor : themeData.hintColor);
      stackChildren.add(new Positioned(
        left: 0.0,
        top: topPadding,
        child: new Text(config.labelText, style: labelStyle)
      ));
      topPadding += labelStyle.fontSize + (config.isDense ? 4.0 : 8.0);
    }

    if (config.hintText != null && _value.isEmpty) {
      TextStyle hintStyle = textStyle.copyWith(color: themeData.hintColor);
      stackChildren.add(new Positioned(
        left: 0.0,
        top: topPadding,
        child: new Text(config.hintText, style: hintStyle)
      ));
    }

    stackChildren.add(_buildEditableField(
      themeData: themeData,
      focused: focused,
      focusHighlightColor: focusHighlightColor,
      textStyle: textStyle,
      topPadding: topPadding
    ));

    if (config.errorText != null && !config.isDense) {
      TextStyle errorStyle = themeData.text.caption.copyWith(color: Colors.red[700]);
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
      onTap: () {
        if (Focus.at(context)) {
          assert(_keyboardHandle.attached);
          _keyboardHandle.showByRequest();
        } else {
          Focus.moveTo(config.key);
          // we'll get told to rebuild and we'll take care of the keyboard then
        }
      },
      child: new Padding(
        padding: const EdgeDims.symmetric(horizontal: 16.0),
        child: child
      )
    );
  }

  void dispose() {
    if (_keyboardHandle.attached)
      _keyboardHandle.release();
    super.dispose();
  }

  ScrollBehavior createScrollBehavior() => new BoundedBehavior();
  BoundedBehavior get scrollBehavior => super.scrollBehavior;

  void _handleContainerSizeChanged(Size newSize) {
    _containerWidth = newSize.width;
    _updateScrollBehavior();
  }

  void _handleContentSizeChanged(Size newSize) {
    _contentWidth = newSize.width;
    _updateScrollBehavior();
  }

  void _updateScrollBehavior() {
    // Set the scroll offset to match the content width so that the cursor
    // (which is always at the end of the text) will be visible.
    scrollTo(scrollBehavior.updateExtents(
      contentExtent: _contentWidth,
      containerExtent: _containerWidth,
      scrollOffset: _contentWidth
    ));
  }
}
