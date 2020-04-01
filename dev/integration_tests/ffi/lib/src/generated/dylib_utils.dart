// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

ffi.DynamicLibrary dlopenPlatformSpecific(String name, {String path}) {
  return Platform.isAndroid
      ? ffi.DynamicLibrary.open('libffi_tests.so')
      : ffi.DynamicLibrary.process();
}
