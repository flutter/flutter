// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:nativewrappers';
import 'dart:typed_data';

void main() {}

class SomeClass {
  int i;
  SomeClass(this.i);
}

void giveObjectToNative(Object someObject) native 'GiveObjectToNative';

void signalDone() native 'SignalDone';

@pragma('vm:entry-point')
void callGiveObjectToNative() {
  giveObjectToNative(SomeClass(123));
}

@pragma('vm:entry-point')
void testClearLater() {
  giveObjectToNative(SomeClass(123));
  signalDone();
}

// Test helpers for simple void calls through Tonic.

@FfiNative<Void Function()>('Nop', isLeaf: true)
external void nop();

@pragma('vm:entry-point')
void callNop() {
  nop();
  signalDone();
}

// Test helpers for calls with bool through Tonic.

@FfiNative<Bool Function(Bool)>('EchoBool')
external bool echoBool(bool arg);

@pragma('vm:entry-point')
void callEchoBool() {
  if (echoBool(true)) {
    signalDone();
  }
}

// Test helpers for calls with int through Tonic.

@FfiNative<IntPtr Function(IntPtr)>('EchoIntPtr')
external int echoIntPtr(int arg);

@pragma('vm:entry-point')
void callEchoIntPtr() {
  if (echoIntPtr(23) == 23) {
    signalDone();
  }
}

// Test helpers for calls with float through Tonic.

@FfiNative<Float Function(Float)>('EchoFloat')
external double echoFloat(double arg);

@pragma('vm:entry-point')
void callEchoFloat() {
  if (echoFloat(23.0) == 23.0) {
    signalDone();
  }
}

// Test helpers for calls with double through Tonic.

@FfiNative<Double Function(Double)>('EchoDouble')
external double echoDouble(double arg);

@pragma('vm:entry-point')
void callEchoDouble() {
  if (echoDouble(23.0) == 23.0) {
    signalDone();
  }
}

// Test helpers for calls with Dart_Handle through Tonic.

@FfiNative<Handle Function(Handle)>('EchoHandle')
external Object echoHandle(Object arg);

@pragma('vm:entry-point')
void callEchoHandle() {
  if (echoHandle('Hello EchoHandle') == 'Hello EchoHandle') {
    signalDone();
  }
}

// Test helpers for calls with std::string through Tonic.

@FfiNative<Handle Function(Handle)>('EchoString')
external String echoString(String arg);

@pragma('vm:entry-point')
void callEchoString() {
  if (echoString('Hello EchoString') == 'Hello EchoString') {
    signalDone();
  }
}

// Test helpers for calls with std::u16string through Tonic.

@FfiNative<Handle Function(Handle)>('EchoU16String')
external String echoU16String(String arg);

@pragma('vm:entry-point')
void callEchoU16String() {
  if (echoU16String('Hello EchoU16String') == 'Hello EchoU16String') {
    signalDone();
  }
}

// Test helpers for calls with std::vector through Tonic.

@FfiNative<Handle Function(Handle)>('EchoVector')
external List<String> echoVector(List<String> arg);

@pragma('vm:entry-point')
void callEchoVector() {
  if (echoVector(['Hello EchoVector'])[0] == 'Hello EchoVector') {
    signalDone();
  }
}

// Test helpers for calls with DartWrappable through Tonic.

class MyNativeClass extends NativeFieldWrapperClass1 {
  MyNativeClass(int value) {
    _Create(this, value);
  }

  @FfiNative<Void Function(Handle, IntPtr)>('CreateNative')
  external static void _Create(MyNativeClass self, int value);

  @FfiNative<Int32 Function(Pointer<Void>, Int32, Handle)>(
      'MyNativeClass::MyTestFunction')
  external static int myTestFunction(MyNativeClass self, int x, Object handle);

  @FfiNative<Handle Function(Pointer<Void>, Int64)>(
      'MyNativeClass::MyTestMethod')
  external Object myTestMethod(int a);
}

@FfiNative<IntPtr Function(Pointer<Void>)>('EchoWrappable')
external int echoWrappable(MyNativeClass arg);

@pragma('vm:entry-point')
void callEchoWrappable() {
  final myNative = MyNativeClass(0x1234);
  if (echoWrappable(myNative) == 0x1234) {
    signalDone();
  }
}

// Test helpers for calls with TypedList<..> through Tonic.

@FfiNative<Handle Function(Handle)>('EchoTypedList')
external Float32List echoTypedList(Float32List arg);

@pragma('vm:entry-point')
void callEchoTypedList() {
  final typedList = Float32List.fromList([99.9, 3.14, 0.01]);
  if (echoTypedList(typedList) == typedList) {
    signalDone();
  }
}

//

@pragma('vm:entry-point')
void callMyTestFunction() {
  final myNative = MyNativeClass(1234);
  if (MyNativeClass.myTestFunction(myNative, 34, myNative) == 1268) {
    signalDone();
  }
}

//

@pragma('vm:entry-point')
void callMyTestMethod() {
  final myNative = MyNativeClass(1234);
  if (myNative.myTestMethod(43) == 1277) {
    signalDone();
  }
}
