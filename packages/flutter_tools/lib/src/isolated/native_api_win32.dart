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
  int launchApp(String amuid, List<String> args) {
    int hResult = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }

    final Pointer<Utf16> aumid = amuid.toNativeUtf16();
    final Pointer<Uint32> processId = calloc<Uint32>();
    final Pointer<Utf16> arguments = args.join(',').toNativeUtf16();

    final ApplicationActivationManager aam = ApplicationActivationManager.createInstance();
    hResult = aam.ActivateApplication(aumid, arguments, 0, processId);
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }
    final int id = processId.value;
    free(aumid);
    free(processId);
    free(aam.ptr);
    free(arguments);
    CoUninitialize();
    return id;
  }
}
