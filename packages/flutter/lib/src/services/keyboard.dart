// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky_services/editing/editing.mojom.dart' as mojom;

import 'shell.dart';

export 'package:sky_services/editing/editing.mojom.dart' show KeyboardType;

/// An interface to the system's keyboard.
///
/// Most clients will want to use the [keyboard] singleton instance.
class Keyboard {
  Keyboard(this.service);

  // The service is exposed in case you need direct access.
  // However, as a general rule, you should be able to do
  // most of what you need using only this class.
  final mojom.Keyboard service;

  KeyboardHandle _currentHandle;

  bool _hidePending = false;

  KeyboardHandle attach(mojom.KeyboardClientStub stub, mojom.KeyboardConfiguration configuration) {
    assert(stub != null);
    _currentHandle?.release();
    assert(_currentHandle == null);
    _currentHandle = new KeyboardHandle._(this);
    service.setClient(stub, configuration);
    return _currentHandle;
  }

  void _scheduleHide() {
    if (_hidePending)
      return;
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
  KeyboardHandle._(Keyboard keyboard) : _keyboard = keyboard, _attached = true;

  final Keyboard _keyboard;

  bool _attached;
  bool get attached => _attached;

  void show() {
    assert(_attached);
    assert(_keyboard._currentHandle == this);
    _keyboard.service.show();
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

  void setEditingState(mojom.EditingState state) {
    assert(_attached);
    assert(_keyboard._currentHandle == this);
    _keyboard.service.setEditingState(state);
  }
}

mojom.KeyboardProxy _initKeyboardProxy() {
  return shell.connectToViewAssociatedService(mojom.Keyboard.connectToService);
}

final mojom.KeyboardProxy _keyboardProxy = _initKeyboardProxy();
final Keyboard keyboard = new Keyboard(_keyboardProxy);
