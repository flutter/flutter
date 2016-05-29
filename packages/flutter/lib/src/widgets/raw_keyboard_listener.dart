// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:sky_services/raw_keyboard/raw_keyboard.mojom.dart' as mojom;
import 'package:sky_services/sky/input_event.mojom.dart' as mojom;

import 'basic.dart';
import 'framework.dart';

class RawKeyboardListener extends StatefulWidget {
  RawKeyboardListener({
    Key key,
    this.focused: false,
    this.onKey,
    this.child
  }) : super(key: key) {
    assert(child != null);
  }

  final bool focused;

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
