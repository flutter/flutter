// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that Win32 API prototypes can be successfully loaded (i.e. that
// lookupFunction works for all the APIs generated)

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_local_variable

@TestOn('windows')

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

import 'package:win32/win32.dart';

void main() {
  final ptr = calloc<COMObject>();

  final networklistmanager = INetworkListManager(ptr);
  test('Can instantiate INetworkListManager.GetNetworks', () {
    expect(networklistmanager.GetNetworks, isA<Function>());
  });
  test('Can instantiate INetworkListManager.GetNetwork', () {
    expect(networklistmanager.GetNetwork, isA<Function>());
  });
  test('Can instantiate INetworkListManager.GetNetworkConnections', () {
    expect(networklistmanager.GetNetworkConnections, isA<Function>());
  });
  test('Can instantiate INetworkListManager.GetNetworkConnection', () {
    expect(networklistmanager.GetNetworkConnection, isA<Function>());
  });
  test('Can instantiate INetworkListManager.GetConnectivity', () {
    expect(networklistmanager.GetConnectivity, isA<Function>());
  });
  test('Can instantiate INetworkListManager.SetSimulatedProfileInfo', () {
    expect(networklistmanager.SetSimulatedProfileInfo, isA<Function>());
  });
  test('Can instantiate INetworkListManager.ClearSimulatedProfileInfo', () {
    expect(networklistmanager.ClearSimulatedProfileInfo, isA<Function>());
  });
  free(ptr);
}
