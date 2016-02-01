// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mojo_services/keyboard/keyboard.mojom.dart';

import 'binding.dart';

export 'package:mojo_services/keyboard/keyboard.mojom.dart';

/// An interface to the system's keyboard.
///
/// Most clients will want to use the [keyboard] singleton instance.
class Keyboard {
  Keyboard(this.service);

  // The service is exposed in case you need direct access.
  // However, as a general rule, you should be able to do
  // most of what you need using only this class.
  final KeyboardService service;

  KeyboardHandle _currentHandle;

  bool _hidePending = false;

  KeyboardHandle show(KeyboardClientStub stub, KeyboardType keyboardType) {
    assert(stub != null);
    _currentHandle?.release();
    assert(_currentHandle == null);
    _currentHandle = new KeyboardHandle._show(this, stub, keyboardType);
    return _currentHandle;
  }

  void _scheduleHide() {
    if (_hidePending) return;
    _hidePending = true;

    // Schedule a deferred task that hides the keyboard.  If someone else shows
    // the keyboard during this update cycle, then the task will do nothing.
    scheduleMicrotask(() {
      _hidePending = false;
      if (_currentHandle == null) {
        service.hide();
      }
    });
  }

}

class KeyboardHandle {

  KeyboardHandle._show(Keyboard keyboard, KeyboardClientStub stub, KeyboardType keyboardType) : _keyboard = keyboard {
    _keyboard.service.show(stub, keyboardType);
    _attached = true;
  }

  final Keyboard _keyboard;

  bool _attached;
  bool get attached => _attached;

  void showByRequest() {
    assert(_attached);
    assert(_keyboard._currentHandle == this);
    _keyboard.service.showByRequest();
  }

  void release() {
    if (_attached) {
      assert(_keyboard._currentHandle == this);
      _attached = false;
      _keyboard._currentHandle = null;
      _keyboard._scheduleHide();
    }
    assert(_keyboard._currentHandle != this);
  }

  void setText(String text) {
    assert(_attached);
    assert(_keyboard._currentHandle == this);
    _keyboard.service.setText(text);
  }

  void setSelection(int start, int end) {
    assert(_attached);
    assert(_keyboard._currentHandle == this);
    _keyboard.service.setSelection(start, end);
  }

}

KeyboardServiceProxy _initKeyboardProxy() {
  KeyboardServiceProxy proxy = new KeyboardServiceProxy.unbound();
  shell.connectToService(null, proxy);
  return proxy;
}

final KeyboardServiceProxy _keyboardProxy = _initKeyboardProxy();
final Keyboard keyboard = new Keyboard(_keyboardProxy.ptr);
