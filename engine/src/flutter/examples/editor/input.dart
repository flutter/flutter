// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../framework/fn.dart';
import '../../framework/theme/colors.dart';
import 'editable_string.dart';
import 'editable_text.dart';
import 'keyboard.dart';

typedef void ValueChanged(value);

class Input extends Component {
  static final Style _style = new Style('''
    display: paragraph;
    margin: 8px;
    padding: 8px;
    border-bottom: 1px solid ${Grey[200]};
    align-self: center;
    height: 1.2em;
    white-space: pre;
    overflow: hidden;'''
  );

  static final String _focusedInlineStyle = '''
    padding: 7px;
    border-bottom: 2px solid ${Blue[500]};''';

  ValueChanged onChanged;
  String value;

  bool _focused = false;
  EditableString _editableValue;

  Input({Object key, this.value: ''}) : super(key: key, stateful: true) {
    _editableValue = new EditableString(text: value,
                                        onUpdated: _handleTextUpdated);
    events.listen('click', _handleClick);
  }

  void _handleClick(_) {
    keyboard.show(_editableValue.stub);
    setState(() {
      _focused = true;
    });
  }

  void _handleTextUpdated() {
    setState(() {});
    if (value != _editableValue.text) {
      value = _editableValue.text;
      if (onChanged != null)
        onChanged(value);
    }
  }

  Node build() {
    return new Container(
      style: _style,
      inlineStyle: _focused ? _focusedInlineStyle : null,
      children: [
        new EditableText(value: _editableValue, focused: _focused),
      ]
    );
  }
}
