// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:sky_services/raw_keyboard/raw_keyboard.mojom.dart' as mojom;
import 'package:sky_services/sky/input_event.mojom.dart' as mojom;

import 'basic.dart';
import 'framework.dart';

class RawKeyboardListener extends StatefulComponent {
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
  final Widget child;

  _RawKeyboardListenerState createState() => new _RawKeyboardListenerState();
}

class _RawKeyboardListenerState extends State<RawKeyboardListener> implements mojom.RawKeyboardListener {
  void initState() {
    super.initState();
    _attachOrDetachKeyboard();
  }

  mojom.RawKeyboardListenerStub _stub;

  void didUpdateConfig(RawKeyboardListener oldConfig) {
    _attachOrDetachKeyboard();
  }

  void dispose() {
    _detachKeyboard();
    super.dispose();
  }

  void _attachOrDetachKeyboard() {
    if (config.focused && _stub == null)
      _attachKeyboard();
    else if (!config.focused && _stub != null)
      _detachKeyboard();
  }

  void _attachKeyboard() {
    assert(_stub == null);
    _stub = new mojom.RawKeyboardListenerStub.unbound()..impl = this;
    mojom.RawKeyboardServiceProxy keyboard = new mojom.RawKeyboardServiceProxy.unbound();
    shell.connectToService(null, keyboard);
    keyboard.ptr.addListener(_stub);
    keyboard.close();
  }

  void _detachKeyboard() {
    assert(_stub != null);
    _stub.close();
    _stub = null;
  }

  void onKey(mojom.InputEvent event) {
    if (config.onKey != null)
      config.onKey(event);
  }

  Widget build(BuildContext context) {
    return config.child;
  }
}
