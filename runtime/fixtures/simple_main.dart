// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

void main() {
}

@pragma('vm:entry-point')
void sayHi() {
  print("Hi");
}

@pragma('vm:entry-point')
void throwExceptionNow() {
  throw("Hello");
}

@pragma('vm:entry-point')
void canRegisterNativeCallback() async {
  print("In function canRegisterNativeCallback");
  NotifyNative();
  print("Called native method from canRegisterNativeCallback");
}

void NotifyNative() native "NotifyNative";


@pragma('vm:entry-point')
void testIsolateShutdown() {  }
