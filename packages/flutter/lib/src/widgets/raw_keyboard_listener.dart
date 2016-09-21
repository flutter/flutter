// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_services/raw_keyboard.dart' as mojom;
import 'package:flutter_services/input_event.dart' as mojom;

import 'basic.dart';
import 'framework.dart';

/// A widget that calls a callback whenever the user presses a key on a keyboard.
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
  final ValueChanged<mojom.InputEvent> onKey;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  _RawKeyboardListenerState createState() => new _RawKeyboardListenerState();
}

class _RawKeyboardListenerState extends State<RawKeyboardListener> implements mojom.RawKeyboardListener {
  @override
  void initState() {
    super.initState();
    _attachOrDetachKeyboard();
  }

  mojom.RawKeyboardListenerStub _stub;

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

  void _attachKeyboardIfDetached() {
    if (_stub != null)
      return;
    _stub = new mojom.RawKeyboardListenerStub.unbound()..impl = this;
    mojom.RawKeyboardServiceProxy keyboard = shell.connectToViewAssociatedService(mojom.RawKeyboardService.connectToService);
    keyboard.addListener(_stub);
    keyboard.close();
  }

  void _detachKeyboardIfAttached() {
    _stub?.close();
    _stub = null;
  }

  @override
  void onKey(mojom.InputEvent event) {
    if (config.onKey != null)
      config.onKey(event);
  }

  @override
  Widget build(BuildContext context) {
    return config.child;
  }
}
