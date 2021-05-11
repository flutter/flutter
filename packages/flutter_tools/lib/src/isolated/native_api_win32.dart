// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../windows/native_api.dart';

/// An implementation of [NativeApi] which uses the win32 package.
class Win32NativeApi extends NativeApi {
  const Win32NativeApi();

  @override
  int launchApp(String auimid, List<String> args) {
    int hResult = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }

    Pointer<Utf16>? auimidPtr;
    Pointer<Uint32>? processId;
    Pointer<Utf16>? arguments;
    ApplicationActivationManager? aam;
    try {
      auimidPtr = auimid.toNativeUtf16();
      processId = calloc<Uint32>();
      arguments = args.join(',').toNativeUtf16();
      aam = ApplicationActivationManager.createInstance();
      hResult = aam.ActivateApplication(auimidPtr, arguments, 0, processId);
      if (FAILED(hResult)) {
        throw WindowsException(hResult);
      }
      return processId.value;
    } finally {
      if (auimidPtr != null) {
        free(auimidPtr);
      }
      if (processId != null) {
        free(processId);
      }
      if (aam != null) {
        free(aam.ptr);
      }
      if (arguments != null) {
        free(arguments);
      }
      CoUninitialize();
    }
  }
}
