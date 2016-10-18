// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

import 'basic.dart';
import 'framework.dart';

/// A widget that calls a callback whenever the user presses or releases a key
/// on a keyboard.
///
/// A [RawKeyboardListener] is useful for listening to raw key events and
/// hardware buttons that are represented as keys. Typically used by games and
/// other apps that use keyboards for purposes other than text entry.
///
/// For text entry, consider using a [RawInputLine], which integrates with
/// on-screen keyboards and input method editors (IMEs).
///
/// See also:
///
///  * [RawInputLine], which should be used instead of this widget for text
///    entry.
class RawKeyboardListener extends StatefulWidget {
  /// Creates a widget that receives raw keyboard events.
  ///
  /// For text entry, consider using a [RawInputLine], which integrates with
  /// on-screen keyboards and input method editors (IMEs).
  RawKeyboardListener({
    Key key,
    this.focused: false,
    this.onKey,
    this.child
  }) : super(key: key) {
    assert(child != null);
  }

  /// Whether this widget should actually listen for raw keyboard events.
  ///
  /// Typically set to the value returned by [Focus.at] for the [GlobalKey] of
  /// the widget that builds the raw keyboard listener.
  final bool focused;

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
    _attachOrDetachKeyboard();
  }

  @override
  void didUpdateConfig(RawKeyboardListener oldConfig) {
    _attachOrDetachKeyboard();
  }

  @override
  void dispose() {
    _detachKeyboardIfAttached();
    super.dispose();
  }

  void _attachOrDetachKeyboard() {
    if (config.focused)
      _attachKeyboardIfDetached();
    else
      _detachKeyboardIfAttached();
  }

  bool _listening = false;

  void _attachKeyboardIfDetached() {
    if (_listening)
      return;
    RawKeyboard.instance.addListener(_handleRawKeyEvent);
  }

  void _detachKeyboardIfAttached() {
    if (!_listening)
      return;
    RawKeyboard.instance.removeListener(_handleRawKeyEvent);
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    if (config.onKey != null)
      config.onKey(event);
  }

  @override
  Widget build(BuildContext context) {
    return config.child;
  }
}
