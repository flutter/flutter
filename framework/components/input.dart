// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../editing/editable_string.dart';
import '../editing/editable_text.dart';
import '../editing/keyboard.dart';
import '../fn.dart';
import '../theme/colors.dart';

typedef void ValueChanged(value);

class Input extends Component {
  static final Style _style = new Style('''
    display: paragraph;
    transform: translateX(0);
    margin: 8px;
    padding: 8px;
    border-bottom: 1px solid ${Grey[200]};
    align-self: center;
    height: 1.2em;
    white-space: pre;
    overflow: hidden;'''
  );

  static final Style _placeholderStyle = new Style('''
    top: 8px;
    left: 8px;
    color: ${Grey[200]};
    position: absolute;'''
  );

  static final String _focusedInlineStyle = '''
    padding: 7px;
    border-bottom: 2px solid ${Blue[500]};''';

  ValueChanged onChanged;
  String value;
  String placeholder;
  bool focused = false;

  bool _isAttachedToKeyboard = false;
  EditableString _editableValue;

  Input({Object key, this.value: '', this.placeholder, this.focused})
      : super(key: key, stateful: true) {
    _editableValue = new EditableString(text: value,
                                        onUpdated: _handleTextUpdated);
  }

  void _handleTextUpdated() {
    setState(() {});
    if (value != _editableValue.text) {
      value = _editableValue.text;
      if (onChanged != null)
        onChanged(value);
    }
  }

  void didUnmount() {
    if (_isAttachedToKeyboard)
      keyboard.hide();
  }

  Node build() {
    if (focused && !_isAttachedToKeyboard) {
      keyboard.show(_editableValue.stub);
      _isAttachedToKeyboard = true;
    }

    List<Node> children = [];

    if (placeholder != null && value.isEmpty) {
      children.add(new Container(
          style: _placeholderStyle,
          children: [new Text(placeholder)]
      ));
    }

    children.add(new EditableText(value: _editableValue, focused: focused));

    return new Container(
      style: _style,
      inlineStyle: focused ? _focusedInlineStyle : null,
      children: children
    );
  }
}
