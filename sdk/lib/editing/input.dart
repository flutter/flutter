// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../painting/text_style.dart';
import '../theme/colors.dart';
import '../theme/typography.dart' as typography;
import '../widgets/basic.dart';
import 'editable_string.dart';
import 'editable_text.dart';
import 'keyboard.dart';

typedef void ValueChanged(value);

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

  static final TextStyle _placeholderStyle = typography.black.caption;

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

    List<Widget> textChildren = <Widget>[];
    if (placeholder != null && _value.isEmpty) {
      textChildren.add(new Text(placeholder, style: _placeholderStyle));
    }
    textChildren.add(
      new EditableText(value: _editableValue, focused: focused)
    );

    Border focusHighlight = new Border(bottom: new BorderSide(
      color: focused ? Blue[400] : Grey[200],
      width: focused ? 2.0 : 1.0
    ));

    // TODO(hansmuller): white-space: pre, height: 1.2em.
    Container input = new Container(
      child: new Stack(textChildren),
      padding: const EdgeDims.only(left: 8.0, right: 8.0, bottom: 12.0),
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
