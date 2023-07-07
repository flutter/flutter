// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Get information about the network connections on the current device.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void main() {
  // Initialize COM
  var hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  if (FAILED(hr)) {
    throw WindowsException(hr);
  }

  final netManager = NetworkListManager.createInstance();
  final nlmConnectivity = calloc<Int32>();
  final enumPtr = calloc<COMObject>();
  final netPtr = calloc<COMObject>();
  final descPtr = calloc<Pointer<Utf16>>();
  final elements = calloc<Uint32>();

  try {
    hr = netManager.getConnectivity(nlmConnectivity);
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }

    final connectivity = nlmConnectivity.value;
    var isInternetConnected = false;

    // These two options are not mutually exclusive
    if (connectivity & NLM_CONNECTIVITY.NLM_CONNECTIVITY_IPV4_INTERNET ==
        NLM_CONNECTIVITY.NLM_CONNECTIVITY_IPV4_INTERNET) {
      print('Connected to the Internet via IPv4.');
      isInternetConnected = true;
    }

    if (connectivity & NLM_CONNECTIVITY.NLM_CONNECTIVITY_IPV6_INTERNET ==
        NLM_CONNECTIVITY.NLM_CONNECTIVITY_IPV6_INTERNET) {
      print('Connected to the Internet via IPv6.');
      isInternetConnected = true;
    }

    if (!isInternetConnected) {
      print('Not connected to the Internet.');
    }

    hr = netManager.getNetworks(
        NLM_ENUM_NETWORK.NLM_ENUM_NETWORK_ALL, enumPtr.cast());
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }

    print('\nNetworks (connected and disconnected) on this machine:');
    final enumerator = IEnumNetworkConnections(enumPtr);
    hr = enumerator.next(1, netPtr.cast(), elements);
    while (elements.value == 1) {
      final network = INetwork(netPtr);
      hr = network.getDescription(descPtr);
      if (SUCCEEDED(hr)) {
        final networkName = descPtr.value.toDartString();
        final isNetworkConnected = network.isConnected == VARIANT_TRUE;
        print(
            '$networkName: ${isNetworkConnected ? 'connected' : 'disconnected'}');
      }

      hr = enumerator.next(1, netPtr.cast(), elements);
    }
  } finally {
    free(elements);
    free(netPtr);
    free(enumPtr);
    free(descPtr);
    free(nlmConnectivity);
    free(netManager.ptr);

    CoUninitialize();
  }
}
