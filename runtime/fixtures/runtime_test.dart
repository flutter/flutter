// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';
import 'dart:ui';

void main() {
}

@pragma('vm:entry-point')
void sayHi() {
  print('Hi');
}

@pragma('vm:entry-point')
void throwExceptionNow() {
  throw 'Hello';
}

@pragma('vm:entry-point')
void canRegisterNativeCallback() async {
  print('In function canRegisterNativeCallback');
  notifyNative();
  print('Called native method from canRegisterNativeCallback');
}

void notifyNative() native 'NotifyNative';

@pragma('vm:entry-point')
void testIsolateShutdown() {  }

@pragma('vm:entry-point')
void testCanSaveCompilationTrace() {
  List<int> trace;
  try {
    trace = saveCompilationTrace();
  } catch (exception) {
    print('Could not save compilation trace: ' + exception);
  }
  notifyResult(trace != null && trace.isNotEmpty);
}

void notifyResult(bool success) native 'NotifyNative';
void passMessage(String message) native 'PassMessage';

void secondaryIsolateMain(String message) {
  print('Secondary isolate got message: ' + message);
  passMessage('Hello from code is secondary isolate.');
  notifyNative();
}

@pragma('vm:entry-point')
void testCanLaunchSecondaryIsolate() {
  final onExit = RawReceivePort((_) { notifyNative(); });
  Isolate.spawn(secondaryIsolateMain, 'Hello from root isolate.', onExit: onExit.sendPort);
}

@pragma('vm:entry-point')
void testCanRecieveArguments(List<String> args) {
  notifyResult(args != null && args.length == 1 && args[0] == 'arg1');
}
