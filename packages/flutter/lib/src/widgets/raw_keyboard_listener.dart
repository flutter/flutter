// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'focus_manager.dart';
import 'framework.dart';

/// A widget that calls a callback whenever the user presses or releases a key
/// on a keyboard.
///
/// A [RawKeyboardListener] is useful for listening to raw key events and
/// hardware buttons that are represented as keys. Typically used by games and
/// other apps that use keyboards for purposes other than text entry.
///
/// For text entry, consider using a [EditableText], which integrates with
/// on-screen keyboards and input method editors (IMEs).
///
/// See also:
///
///  * [EditableText], which should be used instead of this widget for text
///    entry.
class RawKeyboardListener extends StatefulWidget {
  /// Creates a widget that receives raw keyboard events.
  ///
  /// For text entry, consider using a [EditableText], which integrates with
  /// on-screen keyboards and input method editors (IMEs).
  RawKeyboardListener({
    Key key,
    @required this.focusNode,
    @required this.onKey,
    @required this.child,
  }) : super(key: key) {
    assert(focusNode != null);
    assert(child != null);
  }

  /// Controls whether this widget has keyboard focus.
  final FocusNode focusNode;

  /// Called whenever this widget receives a raw keyboard event.
  final ValueChanged<RawKeyEvent> onKey;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  _RawKeyboardListenerState createState() => new _RawKeyboardListenerState();
}

class _RawKeyboardListenerState extends State<RawKeyboardListener> {
  @override
  void initState() {
    super.initState();
    config.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateConfig(RawKeyboardListener oldConfig) {
    if (config.focusNode != oldConfig.focusNode) {
      oldConfig.focusNode.removeListener(_handleFocusChanged);
      config.focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    config.focusNode.removeListener(_handleFocusChanged);
    _detachKeyboardIfAttached();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (config.focusNode.hasFocus)
      _attachKeyboardIfDetached();
    else
      _detachKeyboardIfAttached();
  }

  bool _listening = false;

  void _attachKeyboardIfDetached() {
    if (_listening)
      return;
    RawKeyboard.instance.addListener(_handleRawKeyEvent);
    _listening = true;
  }

  void _detachKeyboardIfAttached() {
    if (!_listening)
      return;
    RawKeyboard.instance.removeListener(_handleRawKeyEvent);
    _listening = false;
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    if (config.onKey != null)
      config.onKey(event);
  }

  @override
  Widget build(BuildContext context) => config.child;
}
