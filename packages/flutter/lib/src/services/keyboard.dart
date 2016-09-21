// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_services/editing.dart' as mojom;

import 'shell.dart';

export 'package:flutter_services/editing.dart' show KeyboardType;

/// An interface to the system's keyboard.
///
/// Most clients will want to use the [keyboard] singleton instance.
class Keyboard {
  /// Creates a keyboard that wraps the given keyboard service.
  ///
  /// This constructor is exposed for use by tests. Most non-test clients should
  /// use the [keyboard] singleton instance.
  Keyboard(this.service);

  /// The underlying keyboard service.
  ///
  /// It is rare to interact with the keyboard service directly. Instead, most
  /// clients should interact with the service by first calling [attach] and
  /// then using the returned [KeyboardHandle].
  final mojom.Keyboard service;

  KeyboardHandle _currentHandle;

  bool _hidePending = false;

  /// Begin interacting with the keyboard.
  ///
  /// Calling this function helps multiple clients coordinate about which one is
  /// currently interacting with the keyboard. The returned [KeyboardHandle]
  /// provides interfaces for actually interacting with the keyboard.
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

/// An object that represents a session with the keyboard.
///
/// Keyboard handles are created by the [Keyboard.attach] function. When first
/// created, the keyboard handle is attached to the keyboard as the currently
/// active client. A keyboard handle can become detached either by an explicit
/// calle to [release] or because another client attaches themselves.
class KeyboardHandle {
  KeyboardHandle._(Keyboard keyboard) : _keyboard = keyboard, _attached = true;

  final Keyboard _keyboard;

  /// Whether this handle is currently attached to the keyboard.
  ///
  /// If another client calls [Keyboard.attach], this handle will be marked as
  /// no longer attached to the keyboard.
  bool get attached => _attached;
  bool _attached;

  /// Request that the keyboard become visible (if necesssary).
  void show() {
    assert(_attached);
    assert(_keyboard._currentHandle == this);
    _keyboard.service.show();
  }

  /// Disclaim interest in the keyboard.
  ///
  /// After calling this function, [attached] will be `false` and the keyboard
  /// will disappear (if possible).
  void release() {
    if (_attached) {
      assert(_keyboard._currentHandle == this);
      _attached = false;
      _keyboard._currentHandle = null;
      _keyboard._scheduleHide();
    }
    assert(_keyboard._currentHandle != this);
  }

  /// Changes the keyboard's state.
  ///
  /// The given `state` is uploaded to the keyboard, overwriting whatever state
  /// the keyboard had previously.
  ///
  /// Interacting with the keyboard is inherently racy because there are two
  /// asynchronous writers: code that wishes to change keyboard state
  /// spontaneously (e.g., because the user pasted some text) and the user
  /// themselves. For this reason, state set by this function might overwrite
  /// state that user has modified in the keyboard that has not yet been
  /// reported via the keyboard client.
  ///
  /// Should be called only if `attached` is `true`.
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

/// A singleton for managing interactions with the keyboard.
///
/// You can begin a session with the keyboard by calling the [Keyboard.attach]
/// method on this object.
final Keyboard keyboard = new Keyboard(_keyboardProxy);
