// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/editing/editable_string.dart';
import 'package:sky/editing/editable_text.dart';
import 'package:sky/mojo/keyboard.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/theme.dart';

typedef void ValueChanged(value);

// TODO(eseidel): This isn't right, it's 16px on the bottom:
// http://www.google.com/design/spec/components/text-fields.html#text-fields-single-line-text-field
const EdgeDims _kTextfieldPadding = const EdgeDims.symmetric(vertical: 8.0);

class Input extends StatefulComponent {

  // Current thinking is that Widget will have an optional globalKey
  // or heroKey and it will ask Focus.from(this).isFocused which will
  // check using its globalKey.
  // Only one element can use a globalKey at a time and its' up to
  // Widget.sync to maintain the mapping.
  // Never makes sense to have both a localKey and a globalKey.
  // Possibly a class HeroKey who functions as a UUID.

  Input({String key,
         this.placeholder,
         this.onChanged,
         this.focused})
      : super(key: key);

  String placeholder;
  ValueChanged onChanged;
  bool focused = false;

  void initState() {
    _editableValue = new EditableString(
      text: _value,
      onUpdated: _handleTextUpdated
    );
    super.initState();
  }

  void syncFields(Input source) {
    placeholder = source.placeholder;
    onChanged = source.onChanged;
    focused = source.focused;
  }

  String _value = '';
  bool _isAttachedToKeyboard = false;
  EditableString _editableValue;

  void _handleTextUpdated() {
    scheduleBuild();
    if (_value != _editableValue.text) {
      _value = _editableValue.text;
      if (onChanged != null)
        onChanged(_value);
    }
  }

  Widget build() {
    ThemeData themeData = Theme.of(this);

    if (focused && !_isAttachedToKeyboard) {
      keyboard.show(_editableValue.stub);
      _isAttachedToKeyboard = true;
    }

    TextStyle textStyle = themeData.text.subhead;
    List<Widget> textChildren = <Widget>[];

    if (placeholder != null && _value.isEmpty) {
      Widget child = new Opacity(
        key: "placeholder",
        child: new Text(placeholder, style: textStyle),
        opacity: themeData.hintOpacity
      );
      textChildren.add(child);
    }

    Color focusHighlightColor = themeData.accentColor;
    Color cursorColor = themeData.accentColor;
    if (themeData.primarySwatch != null) {
      cursorColor = themeData.primarySwatch[200];
      focusHighlightColor = focused ? themeData.primarySwatch[400] : themeData.hintColor;
    }

    textChildren.add(new EditableText(
      value: _editableValue,
      focused: focused,
      style: textStyle,
      cursorColor: cursorColor
    ));

    Border focusHighlight = new Border(bottom: new BorderSide(
      color: focusHighlightColor,
      width: focused ? 2.0 : 1.0
    ));

    Container input = new Container(
      child: new Stack(textChildren),
      padding: _kTextfieldPadding,
      decoration: new BoxDecoration(border: focusHighlight)
    );

    return new Listener(
      child: input,
      onPointerDown: (_) => keyboard.showByRequest()
    );
  }

  void didUnmount() {
    if (_isAttachedToKeyboard)
      keyboard.hide();
    super.didUnmount();
  }
}
