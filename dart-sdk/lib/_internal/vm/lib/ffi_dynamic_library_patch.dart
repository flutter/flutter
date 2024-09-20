// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;
import 'dart:typed_data';
import 'dart:isolate';
import 'dart:typed_data';

@pragma("vm:external-name", "Ffi_dl_open")
external DynamicLibrary _open(String path);
@pragma("vm:external-name", "Ffi_dl_processLibrary")
external DynamicLibrary _processLibrary();
@pragma("vm:external-name", "Ffi_dl_executableLibrary")
external DynamicLibrary _executableLibrary();

@patch
@pragma("vm:entry-point")
final class DynamicLibrary {
  @patch
  factory DynamicLibrary.open(String path) {
    return _open(path);
  }

  @patch
  factory DynamicLibrary.process() => _processLibrary();

  @patch
  factory DynamicLibrary.executable() => _executableLibrary();

  @patch
  @pragma("vm:external-name", "Ffi_dl_lookup")
  external Pointer<T> lookup<T extends NativeType>(String symbolName);

  @patch
  @pragma("vm:external-name", "Ffi_dl_providesSymbol")
  external bool providesSymbol(String symbolName);

  @pragma("vm:external-name", "Ffi_dl_getHandle")
  external int getHandle();

  @patch
  @pragma("vm:external-name", "Ffi_dl_close")
  external void close();

  @patch
  bool operator ==(Object other) {
    if (other is! DynamicLibrary) return false;
    DynamicLibrary otherLib = other;
    return getHandle() == otherLib.getHandle();
  }

  @patch
  int get hashCode {
    return getHandle().hashCode;
  }

  @patch
  Pointer<Void> get handle => Pointer.fromAddress(getHandle());
}

@patch
extension DynamicLibraryExtension on DynamicLibrary {
  @patch
  DS lookupFunction<NS extends Function, DS extends Function>(String symbolName,
          {bool isLeaf = false}) =>
      throw UnsupportedError("The body is inlined in the frontend.");
}
