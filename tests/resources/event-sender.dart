// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "dart:async";
import "dart:sky";
import "dart:sky.internals" as internals;
import "package:mojom/mojo/input_event_constants.mojom.dart" as constants;
import "package:mojom/mojo/input_events.mojom.dart" as events;
import "package:mojom/mojo/input_key_codes.mojom.dart" as codes;
import "package:mojom/sky/test_harness.mojom.dart" as harness;
import "package:sky/mojo/embedder.dart";

bool _isDone = false;
int _keyPressesRemaining = 0;

final Set<int> _chars = new Set.from([
  codes.KeyboardCode_A,
  codes.KeyboardCode_B,
  codes.KeyboardCode_C,
  codes.KeyboardCode_D,
  codes.KeyboardCode_E,
  codes.KeyboardCode_F,
  codes.KeyboardCode_G,
  codes.KeyboardCode_H,
  codes.KeyboardCode_I,
  codes.KeyboardCode_J,
  codes.KeyboardCode_K,
  codes.KeyboardCode_L,
  codes.KeyboardCode_M,
  codes.KeyboardCode_N,
  codes.KeyboardCode_O,
  codes.KeyboardCode_P,
  codes.KeyboardCode_Q,
  codes.KeyboardCode_R,
  codes.KeyboardCode_S,
  codes.KeyboardCode_T,
  codes.KeyboardCode_U,
  codes.KeyboardCode_V,
  codes.KeyboardCode_W,
  codes.KeyboardCode_X,
  codes.KeyboardCode_Y,
  codes.KeyboardCode_Z,
]);

void _checkComplete() {
  if (!_isDone)
    return;
  if (_keyPressesRemaining != 0)
    return;
  new Timer(Duration.ZERO, () {
    internals.notifyTestComplete(internals.contentAsText());
  });
}

void handleKeyPress_(Event event) {
  --_keyPressesRemaining;
  _checkComplete();
}

harness.TestHarnessProxy _init() {
  document.addEventListener('keypress', handleKeyPress_);

  var harnessProxy = new harness.TestHarnessProxy.unbound();
  embedder.connectToService("mojo:sky_tester", harnessProxy);
  return harnessProxy;
}

final harness.TestHarnessProxy _harness = _init();

// |0| should be EventFlags_NONE once its a compile-time constant.
void keyDown(int keyCode, [int eventFlags = 0]) {
  if (!_chars.contains(keyCode)) {
    _harness.ptr.dispatchInputEvent(
        new events.Event()
        ..action = constants.EventType_KEY_PRESSED
        ..flags = eventFlags
        ..keyData = (new events.KeyData()
                     ..keyCode = keyCode
                     ..windowsKeyCode = keyCode));

    _harness.ptr.dispatchInputEvent(
        new events.Event()
        ..action = constants.EventType_KEY_PRESSED
        ..flags = eventFlags
        ..keyData = (new events.KeyData()
                     ..isChar = true
                     ..windowsKeyCode = keyCode));
  } else {
    ++_keyPressesRemaining;
    _harness.ptr.dispatchInputEvent(
       new events.Event()
        ..action = constants.EventType_KEY_PRESSED
        ..flags = eventFlags
        ..keyData = (new events.KeyData()
                     ..keyCode = keyCode
                     ..isChar = true
                     ..character = keyCode
                     ..text = keyCode
                     ..unmodifiedText = keyCode));
  }
}

void done() {
  if (_isDone)
    throw "Already done.";
  _isDone = true;
  _checkComplete();
}
