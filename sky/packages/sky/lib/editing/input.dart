// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/editing/editable_string.dart';
import 'package:sky/editing/editable_text.dart';
import 'package:sky/mojo/keyboard.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/focus.dart';
import 'package:sky/widgets/theme.dart';

typedef void StringValueChanged(String value);

// TODO(eseidel): This isn't right, it's 16px on the bottom:
// http://www.google.com/design/spec/components/text-fields.html#text-fields-single-line-text-field
const EdgeDims _kTextfieldPadding = const EdgeDims.symmetric(vertical: 8.0);

class Input extends StatefulComponent {

  Input({
    GlobalKey key,
    this.placeholder,
    this.onChanged
  }): super(key: key);

  String placeholder;
  StringValueChanged onChanged;

  String _value = '';
  EditableString _editableValue;
  KeyboardHandle _keyboardHandle = KeyboardHandle.unattached;

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
  }

  void _handleTextUpdated() {
    if (_value != _editableValue.text) {
      setState(() {
        _value = _editableValue.text;
      });
      if (onChanged != null)
        onChanged(_value);
    }
  }

  Widget build() {
    ThemeData themeData = Theme.of(this);
    bool focused = Focus.at(this);

    if (focused && !_keyboardHandle.attached) {
      _keyboardHandle = keyboard.show(_editableValue.stub);
    } else if (!focused && _keyboardHandle.attached) {
      _keyboardHandle.release();
    }

    TextStyle textStyle = themeData.text.subhead;
    List<Widget> textChildren = <Widget>[];

    if (placeholder != null && _value.isEmpty) {
      Widget child = new Opacity(
        key: new Key('placeholder'),
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
      onPointerDown: focus
    );
  }

  void focus(_) {
    if (Focus.at(this)) {
      assert(_keyboardHandle.attached);
      _keyboardHandle.showByRequest();
    } else {
      Focus.moveTo(this);
      // we'll get told to rebuild and we'll take care of the keyboard then
    }
  }

  void didUnmount() {
    if (_keyboardHandle.attached)
      _keyboardHandle.release();
    super.didUnmount();
  }
}
