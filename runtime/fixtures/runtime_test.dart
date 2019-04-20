// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';
import 'dart:ui';

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

@pragma('vm:entry-point')
void testCanSaveCompilationTrace() {
  List<int> trace = null;
  try {
    trace = saveCompilationTrace();
  } catch (exception) {
    print("Could not save compilation trace: " + exception);
  }
  NotifyResult(trace != null && trace.length > 0);
}

void NotifyResult(bool success) native "NotifyNative";
void PassMessage(String message) native "PassMessage";

void secondaryIsolateMain(String message) {
  print("Secondary isolate got message: " + message);
  PassMessage("Hello from code is secondary isolate.");
  NotifyNative();
}

@pragma('vm:entry-point')
void testCanLaunchSecondaryIsolate() {
  Isolate.spawn(secondaryIsolateMain, "Hello from root isolate.");
  NotifyNative();
}
