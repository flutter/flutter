// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:ffi';
import 'dart:nativewrappers';

/// This is a simple test fuction.
@Native<Int32 Function()>(symbol: 'InternalFlutterGpuTestProc')
external int testProc();

/// This is a test callback that follows the same pattern as much of dart:ui --
/// immediately returning an error string and supplying an asynchronous result
/// via callback later.
typedef Callback<T> = void Function(T result);
@Native<Handle Function(Handle)>(
    symbol: 'InternalFlutterGpuTestProcWithCallback')
external String? testProcWithCallback(Callback<int> callback);

/// This is a test of NativeFieldWrapperClass1, which is commonly used in
/// dart:ui to enable Dart to dictate the lifetime of a C counterpart.
base class FlutterGpuTestClass extends NativeFieldWrapperClass1 {
  FlutterGpuTestClass() {
    _constructor();
  }

  /// This "constructor" is used to instantiate and wrap the C counterpart.
  /// This is a common pattern in dart:ui.
  @Native<Void Function(Handle)>(symbol: 'InternalFlutterGpuTestClass_Create')
  external void _constructor();

  /// This is a method that will supply a pointer to the C data counterpart when
  /// calling the gunction
  @Native<Void Function(Pointer<Void>, Int)>(
      symbol: 'InternalFlutterGpuTestClass_Method')
  external void coolMethod(int something);
}
