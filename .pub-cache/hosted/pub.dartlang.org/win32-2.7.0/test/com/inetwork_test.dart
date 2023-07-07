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

  final network = INetwork(ptr);
  test('Can instantiate INetwork.GetName', () {
    expect(network.GetName, isA<Function>());
  });
  test('Can instantiate INetwork.SetName', () {
    expect(network.SetName, isA<Function>());
  });
  test('Can instantiate INetwork.GetDescription', () {
    expect(network.GetDescription, isA<Function>());
  });
  test('Can instantiate INetwork.SetDescription', () {
    expect(network.SetDescription, isA<Function>());
  });
  test('Can instantiate INetwork.GetNetworkId', () {
    expect(network.GetNetworkId, isA<Function>());
  });
  test('Can instantiate INetwork.GetDomainType', () {
    expect(network.GetDomainType, isA<Function>());
  });
  test('Can instantiate INetwork.GetNetworkConnections', () {
    expect(network.GetNetworkConnections, isA<Function>());
  });
  test('Can instantiate INetwork.GetTimeCreatedAndConnected', () {
    expect(network.GetTimeCreatedAndConnected, isA<Function>());
  });
  test('Can instantiate INetwork.GetConnectivity', () {
    expect(network.GetConnectivity, isA<Function>());
  });
  test('Can instantiate INetwork.GetCategory', () {
    expect(network.GetCategory, isA<Function>());
  });
  test('Can instantiate INetwork.SetCategory', () {
    expect(network.SetCategory, isA<Function>());
  });
  free(ptr);
}
