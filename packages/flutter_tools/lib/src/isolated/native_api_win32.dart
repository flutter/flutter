// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../windows/native_api.dart';

/// An implementation of [NativeApi] which uses the win32 package.
///
// TODO(jonahwilliams): add support for looking up AMUID from application GUID
// Powershell to get the AUMID for an installed app
// $foo = get-appxpackage | where {$_.Name -like "Microsoft.WindowsCalculator"}
// $aumid = $foo.packagefamilyname + "!" + (Get-AppxPackageManifest $foo).package.applications.application.id
// write-host $aumid
class Win32NativeApi extends NativeApi {
  const Win32NativeApi();

  @override
  ApplicationInstance launchApp(String amuid) {
    int hResult = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }

    final Pointer<Utf16> aumid = amuid.toNativeUtf16();
    final Pointer<Uint32> processId = calloc<Uint32>();

    final ApplicationActivationManager aam = ApplicationActivationManager.createInstance();
    hResult = aam.ActivateApplication(aumid, nullptr, 0, processId);
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }
    free(aumid);
    return _Win32ApplicationInstance(processId, aam);
  }
}

class _Win32ApplicationInstance extends ApplicationInstance {
  _Win32ApplicationInstance(this.processId, this.aam);

  final Pointer<Uint32> processId;
  final ApplicationActivationManager aam;

  @override
  int get id => processId.value;

  @override
  void dispose() {
    free(processId);
    free(aam.ptr);
    CoUninitialize();
  }
}
