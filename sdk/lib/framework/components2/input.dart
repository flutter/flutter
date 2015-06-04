// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../editing2/editable_string.dart';
import '../editing2/editable_text.dart';
import '../editing2/keyboard.dart';
import '../fn2.dart';
import '../theme2/colors.dart';
import '../theme2/typography.dart' as typography;
import '../rendering/flex.dart';
import 'dart:sky' as sky;

typedef void ValueChanged(value);

class Input extends Component {
  // static final Style _style = new Style('''
  //   transform: translateX(0);
  //   margin: 8px;
  //   padding: 8px;
  //   border-bottom: 1px solid ${Grey[200]};
  //   align-self: center;
  //   height: 1.2em;
  //   white-space: pre;
  //   overflow: hidden;'''
  // );

  // static final Style _placeholderStyle = new Style('''
  //   top: 8px;
  //   left: 8px;
  //   position: absolute;
  //   ${typography.black.caption};'''
  // );

  // static final String _focusedInlineStyle = '''
  //   padding: 7px;
  //   border-bottom: 2px solid ${Blue[500]};''';

  ValueChanged onChanged;
  String placeholder;
  bool focused = false;

  String _value = '';
  bool _isAttachedToKeyboard = false;
  EditableString _editableValue;

  Input({Object key,
         this.placeholder,
         this.onChanged,
         this.focused})
      : super(key: key, stateful: true) {
    _editableValue = new EditableString(text: _value,
                                        onUpdated: _handleTextUpdated);
    onDidUnmount(() {
      if (_isAttachedToKeyboard)
        keyboard.hide();
    });
  }

  void _handleTextUpdated() {
    scheduleBuild();
    if (_value != _editableValue.text) {
      _value = _editableValue.text;
      if (onChanged != null)
        onChanged(_value);
    }
  }

  UINode build() {
    if (focused && !_isAttachedToKeyboard) {
      keyboard.show(_editableValue.stub);
      _isAttachedToKeyboard = true;
    }

    List<UINode> children = [];

    if (placeholder != null && _value.isEmpty) {
      children.add(new Container(
          // style: _placeholderStyle,
          child: new Text(placeholder)
      ));
    }

    children.add(new EditableText(value: _editableValue, focused: focused));

    return new EventListenerNode(
      new FlexContainer(
        direction: FlexDirection.vertical,
        // style: _style,
        // inlineStyle: focused ? _focusedInlineStyle : null,
        children: children
      ),
      onPointerDown: (sky.Event e) => keyboard.showByRequest()
    );
  }
}
