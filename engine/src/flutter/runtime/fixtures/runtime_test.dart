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
  notifyResult(saveCompilationTrace().isNotEmpty);
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
  notifyResult(args.length == 1 && args[0] == 'arg1');
}

@pragma('vm:entry-point')
void trampoline() {
  notifyNative();
}

void notifySuccess(bool success) native 'NotifySuccess';

@pragma('vm:entry-point')
void testCanConvertEmptyList(List<int> args){
  notifySuccess(args.length == 0);
}

@pragma('vm:entry-point')
void testCanConvertListOfStrings(List<String> args){
  notifySuccess(args.length == 4 &&
                args[0] == 'tinker' &&
                args[1] == 'tailor' &&
                args[2] == 'soldier' &&
                args[3] == 'sailor');
}

@pragma('vm:entry-point')
void testCanConvertListOfDoubles(List<double> args){
  notifySuccess(args.length == 4 &&
                args[0] == 1.0 &&
                args[1] == 2.0 &&
                args[2] == 3.0 &&
                args[3] == 4.0);
}

@pragma('vm:entry-point')
void testCanConvertListOfInts(List<int> args){
  notifySuccess(args.length == 4 &&
                args[0] == 1 &&
                args[1] == 2 &&
                args[2] == 3 &&
                args[3] == 4);
}
