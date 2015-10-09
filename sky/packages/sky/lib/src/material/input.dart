// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation.dart';
import 'package:sky/services.dart';
import 'package:sky/painting.dart';
import 'package:sky/rendering.dart';
import 'package:sky/widgets.dart';

import 'theme.dart';

export 'package:sky/services.dart' show KeyboardType;

typedef void StringValueChanged(String value);

// TODO(eseidel): This isn't right, it's 16px on the bottom:
// http://www.google.com/design/spec/components/text-fields.html#text-fields-single-line-text-field
const EdgeDims _kTextfieldPadding = const EdgeDims.symmetric(vertical: 8.0);

class Input extends Scrollable {
  Input({
    GlobalKey key,
    this.initialValue: '',
    this.placeholder,
    this.onChanged,
    this.keyboardType: KeyboardType.TEXT
  }) : super(
    key: key,
    initialScrollOffset: 0.0,
    scrollDirection: ScrollDirection.horizontal
  );

  final String initialValue;
  final KeyboardType keyboardType;
  final String placeholder;
  final StringValueChanged onChanged;

  _InputState createState() => new _InputState();
}

class _InputState extends ScrollableState<Input> {
  String _value;
  EditableString _editableValue;
  KeyboardHandle _keyboardHandle = KeyboardHandle.unattached;

  double _contentWidth = 0.0;
  double _containerWidth = 0.0;

  void initState() {
    super.initState();
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

  Widget buildContent(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    bool focused = Focus.at(context, config);

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
      cursorColor: cursorColor,
      onContentSizeChanged: _handleContentSizeChanged,
      scrollOffset: scrollOffsetVector
    ));

    return new Listener(
      child: new SizeObserver(
        callback: _handleContainerSizeChanged,
        child: new Container(
          child: new Stack(textChildren),
          padding: _kTextfieldPadding,
          decoration: new BoxDecoration(border: new Border(
            bottom: new BorderSide(
              color: focusHighlightColor,
              width: focused ? 2.0 : 1.0
            )
          ))
        )
      ),
      onPointerDown: (_) {
        if (Focus.at(context, config)) {
          assert(_keyboardHandle.attached);
          _keyboardHandle.showByRequest();
        } else {
          Focus.moveTo(context, config);
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
      scrollOffset: _contentWidth)
    );
  }
}
