// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import '../rendering/flex.dart';
import '../widgets/wrappers.dart';
import 'editable_string.dart';
import 'editable_text.dart';
import 'keyboard.dart';

typedef void ValueChanged(value);

class Input extends Component {

  Input({Object key,
         this.placeholder,
         this.onChanged,
         this.focused})
      : super(key: key, stateful: true) {
    _editableValue = new EditableString(
      text: _value,
      onUpdated: _handleTextUpdated
    );
  }

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
      // style: _style,
      // inlineStyle: focused ? _focusedInlineStyle : null,
      new Stack(children),
      onPointerDown: (sky.Event e) => keyboard.showByRequest()
    );
  }

  void didUnmount() {
    if (_isAttachedToKeyboard)
      keyboard.hide();
    super.didUnmount();
  }

}
