// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Signals a waiting latch in the native test.
void signal() native 'Signal';

// Signals a waiting latch in the native test, passing a boolean value.
void signalBoolValue(bool value) native 'SignalBoolValue';

// Signals a waiting latch in the native test, which returns a value to the fixture.
bool signalBoolReturn() native 'SignalBoolReturn';

void main() {
}

@pragma('vm:entry-point')
void customEntrypoint() {
}

@pragma('vm:entry-point')
void verifyNativeFunction() {
  signal();
}

@pragma('vm:entry-point')
void verifyNativeFunctionWithParameters() {
  signalBoolValue(true);
}

@pragma('vm:entry-point')
void verifyNativeFunctionWithReturn() {
  bool value = signalBoolReturn();
  signalBoolValue(value);
}
