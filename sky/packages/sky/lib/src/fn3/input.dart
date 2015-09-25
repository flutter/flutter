// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/services.dart';
import 'package:sky/painting.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/editable_text.dart';
import 'package:sky/src/fn3/focus.dart';
import 'package:sky/src/fn3/framework.dart';
import 'package:sky/src/fn3/theme.dart';

export 'package:sky/services.dart' show KeyboardType;

typedef void StringValueChanged(String value);

// TODO(eseidel): This isn't right, it's 16px on the bottom:
// http://www.google.com/design/spec/components/text-fields.html#text-fields-single-line-text-field
const EdgeDims _kTextfieldPadding = const EdgeDims.symmetric(vertical: 8.0);

class Input extends StatefulComponent {
  Input({
    GlobalKey key,
    this.initialValue: '',
    this.placeholder,
    this.onChanged,
    this.keyboardType: KeyboardType.TEXT
  }): super(key: key);

  final String initialValue;
  final KeyboardType keyboardType;
  final String placeholder;
  final StringValueChanged onChanged;

  InputState createState() => new InputState();
}

class InputState extends State<Input> {
  String _value;
  EditableString _editableValue;
  KeyboardHandle _keyboardHandle = KeyboardHandle.unattached;

  void initState(BuildContext context) {
    super.initState(context);
    _value = config.initialValue;
    _editableValue = new EditableString(
      text: _value,
      onUpdated: _handleTextUpdated
    );
  }

  void _handleTextUpdated() {
    if (_value != _editableValue.text) {
      setState(() {
        _value = _editableValue.text;
      });
      if (config.onChanged != null)
        config.onChanged(_value);
    }
  }

  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    bool focused = FocusState.at(context, config);

    if (focused && !_keyboardHandle.attached) {
      _keyboardHandle = keyboard.show(_editableValue.stub, config.keyboardType);
    } else if (!focused && _keyboardHandle.attached) {
      _keyboardHandle.release();
    }

    TextStyle textStyle = themeData.text.subhead;
    List<Widget> textChildren = <Widget>[];

    if (config.placeholder != null && _value.isEmpty) {
      Widget child = new Opacity(
        key: const ValueKey<String>('placeholder'),
        child: new Text(config.placeholder, style: textStyle),
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
      onPointerDown: (_) {
        if (FocusState.at(context, config)) {
          assert(_keyboardHandle.attached);
          _keyboardHandle.showByRequest();
        } else {
          FocusState.moveTo(context, config);
          // we'll get told to rebuild and we'll take care of the keyboard then
        }
      }
    );
  }

  void dispose() {
    if (_keyboardHandle.attached)
      _keyboardHandle.release();
    super.dispose();
  }
}
