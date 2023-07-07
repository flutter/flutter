// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Demonstrates getting information from the Windows Management Instrumentation
// (WMI) API using the WMI Query Language (WQL).

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void main() {
  // Initialize COM
  var hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  if (FAILED(hr)) {
    throw WindowsException(hr);
  }

  // Initialize security model
  hr = CoInitializeSecurity(
      nullptr,
      -1, // COM negotiates service
      nullptr, // Authentication services
      nullptr, // Reserved
      RPC_C_AUTHN_LEVEL_DEFAULT, // authentication
      RPC_C_IMP_LEVEL_IMPERSONATE, // Impersonation
      nullptr, // Authentication info
      EOLE_AUTHENTICATION_CAPABILITIES.EOAC_NONE, // Additional capabilities
      nullptr // Reserved
      );

  if (FAILED(hr)) {
    final exception = WindowsException(hr);
    print(exception.toString());

    CoUninitialize();
    throw exception; // Program has failed.
  }

  // Obtain the initial locator to Windows Management
  // on a particular host computer.
  final pLoc = IWbemLocator(calloc<COMObject>());

  final clsid = calloc<GUID>()..ref.setGUID(CLSID_WbemLocator);
  final iid = calloc<GUID>()..ref.setGUID(IID_IWbemLocator);

  hr = CoCreateInstance(
      clsid, nullptr, CLSCTX_INPROC_SERVER, iid, pLoc.ptr.cast());

  if (FAILED(hr)) {
    final exception = WindowsException(hr);
    print(exception.toString());

    CoUninitialize();
    throw exception;
  }

  final proxy = calloc<Pointer<COMObject>>();

  // Connect to the root\cimv2 namespace with the
  // current user and obtain pointer pSvc
  // to make IWbemServices calls.

  hr = pLoc.connectServer(
      TEXT('ROOT\\CIMV2'), // WMI namespace
      nullptr, // User name
      nullptr, // User password
      nullptr, // Locale
      NULL, // Security flags
      nullptr, // Authority
      nullptr, // Context object
      proxy // IWbemServices proxy
      );

  if (FAILED(hr)) {
    final exception = WindowsException(hr);
    print(exception.toString());

    pLoc.release();
    CoUninitialize();
    throw exception; // Program has failed.
  }

  print('Connected to ROOT\\CIMV2 WMI namespace');

  final pSvc = IWbemServices(proxy.cast());

  // Set the IWbemServices proxy so that impersonation
  // of the user (client) occurs.
  hr = CoSetProxyBlanket(
      proxy.value, // the proxy to set
      RPC_C_AUTHN_WINNT, // authentication service
      RPC_C_AUTHZ_NONE, // authorization service
      nullptr, // Server principal name
      RPC_C_AUTHN_LEVEL_CALL, // authentication level
      RPC_C_IMP_LEVEL_IMPERSONATE, // impersonation level
      nullptr, // client identity
      EOLE_AUTHENTICATION_CAPABILITIES.EOAC_NONE // proxy capabilities
      );

  if (FAILED(hr)) {
    final exception = WindowsException(hr);
    print(exception.toString());
    pSvc.release();
    pLoc.release();
    CoUninitialize();
    throw exception; // Program has failed.
  }

  // Use the IWbemServices pointer to make requests of WMI.

  final pEnumerator = calloc<Pointer<COMObject>>();
  IEnumWbemClassObject enumerator;

  // For example, query for all the running processes
  hr = pSvc.execQuery(
      TEXT('WQL'),
      TEXT('SELECT * FROM Win32_Process'),
      WBEM_GENERIC_FLAG_TYPE.WBEM_FLAG_FORWARD_ONLY |
          WBEM_GENERIC_FLAG_TYPE.WBEM_FLAG_RETURN_IMMEDIATELY,
      nullptr,
      pEnumerator);

  if (FAILED(hr)) {
    final exception = WindowsException(hr);
    print(exception.toString());

    pSvc.release();
    pLoc.release();
    CoUninitialize();

    throw exception;
  } else {
    enumerator = IEnumWbemClassObject(pEnumerator.cast());

    final uReturn = calloc<Uint32>();

    var idx = 0;
    while (enumerator.ptr.address > 0) {
      final pClsObj = calloc<IntPtr>();

      hr = enumerator.next(
          WBEM_TIMEOUT_TYPE.WBEM_INFINITE, 1, pClsObj.cast(), uReturn);

      // Break out of the while loop if we've run out of processes to inspect
      if (uReturn.value == 0) break;

      idx++;

      final clsObj = IWbemClassObject(pClsObj.cast());

      final vtProp = calloc<VARIANT>();
      hr = clsObj.get(TEXT('Name'), 0, vtProp, nullptr, nullptr);
      if (SUCCEEDED(hr)) {
        print('Process: ${vtProp.ref.bstrVal.toDartString()}');
      }
      // Free BSTRs in the returned variants
      VariantClear(vtProp);
      free(vtProp);

      clsObj.release();
    }
    print('$idx processes found.');
  }

  pSvc.release();
  pLoc.release();
  enumerator.release();

  CoUninitialize();
}
