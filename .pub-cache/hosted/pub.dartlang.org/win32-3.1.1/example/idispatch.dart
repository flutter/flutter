// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Demonstrates the use of IDispatch for calling COM automation objects from
// Dart.

// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// A helper object to work with IDispatch objects.
class Dispatcher {
  final String progID;
  final IDispatch disp;

  late final Pointer<GUID> IID_NULL;

  Dispatcher(this.progID, this.disp) {
    IID_NULL = calloc<GUID>();
  }

  factory Dispatcher.fromProgID(String progID) {
    final ptrProgID = progID.toNativeUtf16();
    final clsid = calloc<GUID>();
    final pIID_IDispatch = calloc<GUID>()..ref.setGUID(IID_IDispatch);
    final ppv = calloc<COMObject>();

    try {
      var hr = CLSIDFromProgID(ptrProgID, clsid);
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }

      hr = CoCreateInstance(
          clsid, nullptr, CLSCTX_INPROC_SERVER, pIID_IDispatch, ppv.cast());
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }

      final iDispatch = IDispatch(ppv);

      return Dispatcher(progID, iDispatch);
    } finally {
      free(ptrProgID);
      free(clsid);
      free(pIID_IDispatch);
    }
  }

  int getDispId(String member) {
    final ptNameFunc = member.toNativeUtf16();
    final ptName = calloc<Pointer<Utf16>>()..value = ptNameFunc;
    final dispid = calloc<Int32>();

    try {
      final hr = disp.getIDsOfNames(
          IID_NULL, ptName.cast(), 1, LOCALE_USER_DEFAULT, dispid);
      if (FAILED(hr)) {
        throw WindowsException(hr);
      } else {
        return dispid.value;
      }
    } finally {
      free(ptNameFunc);
      free(ptName);
      free(dispid);
    }
  }

  int get typeInfoCount {
    final count = calloc<Uint32>();

    try {
      final hr = disp.getTypeInfoCount(count);
      if (SUCCEEDED(hr)) {
        return count.value;
      } else {
        throw WindowsException(hr);
      }
    } finally {
      free(count);
    }
  }

  void invokeMethod(int dispid, [Pointer<DISPPARAMS>? params]) {
    Pointer<DISPPARAMS> args;
    if (params == null) {
      args = calloc<DISPPARAMS>();
    } else {
      args = params;
    }

    try {
      final hr = disp.invoke(dispid, IID_NULL, LOCALE_SYSTEM_DEFAULT,
          DISPATCH_METHOD, args, nullptr, nullptr, nullptr);
      if (FAILED(hr)) {
        throw WindowsException(hr);
      } else {
        return;
      }
    } finally {
      if (params == null) {
        free(args);
      }
    }
  }

  void dispose() {
    free(disp.ptr);
    free(IID_NULL);
  }
}

void main() {
  final hr = OleInitialize(nullptr);
  if (FAILED(hr)) throw WindowsException(hr);

  final dispatcher = Dispatcher.fromProgID('Shell.Application');

  // Example of calling an automation method with no parameters
  print('Minimizing all windows via Shell.Application Automation object');
  final minimizeAllMethod = dispatcher.getDispId('MinimizeAll');
  dispatcher.invokeMethod(minimizeAllMethod);

  // Example of calling an automation method with a parameter
  print(r'Launching the Windows Explorer, starting at the C:\ directory');
  final folderLocation = BSTR.fromString(r'C:\');
  final exploreMethod = dispatcher.getDispId('Explore');
  final exploreParam = calloc<VARIANT>();
  VariantInit(exploreParam);
  exploreParam
    ..ref.vt = VARENUM.VT_BSTR
    ..ref.bstrVal = folderLocation.ptr;
  final exploreParams = calloc<DISPPARAMS>()
    ..ref.cArgs = 1
    ..ref.rgvarg = exploreParam;
  dispatcher.invokeMethod(exploreMethod, exploreParams);
  free(exploreParams);
  free(exploreParam);
  folderLocation.free();

  print('Cleaning up.');
  dispatcher.dispose();
  OleUninitialize();
}
