// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../painting/text_style.dart';
import '../widgets/basic.dart';
import '../widgets/theme.dart';
import 'editable_string.dart';
import 'editable_text.dart';
import 'keyboard.dart';

typedef void ValueChanged(value);

const double _kHintOpacity = 0.26;
const EdgeDims _kTextfieldPadding = const EdgeDims.symmetric(vertical: 8.0);

class Input extends Component {

  Input({String key,
         this.placeholder,
         this.onChanged,
         this.focused})
      : super(key: key, stateful: true) {
    _editableValue = new EditableString(
      text: _value,
      onUpdated: _handleTextUpdated
    );
  }

  String placeholder;
  ValueChanged onChanged;
  bool focused = false;

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
    if (focused && !_isAttachedToKeyboard) {
      keyboard.show(_editableValue.stub);
      _isAttachedToKeyboard = true;
    }

    TextStyle textStyle = Theme.of(this).text.subhead;
    List<Widget> textChildren = <Widget>[];

    if (placeholder != null && _value.isEmpty) {
      Widget child = new Opacity(
        key: "placeholder",
        child: new Text(placeholder, style: textStyle),
        opacity: _kHintOpacity
      );
      textChildren.add(child);
    }

    ThemeData themeData = Theme.of(this);
    Color focusHighlightColor = themeData.accentColor;
    Color cursorColor = themeData.accentColor;
    if (themeData.primarySwatch != null) {
      cursorColor = Theme.of(this).primarySwatch[200];
      focusHighlightColor = focused ? themeData.primarySwatch[400] : themeData.primarySwatch[200];
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
