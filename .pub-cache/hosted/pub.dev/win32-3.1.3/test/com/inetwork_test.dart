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
  test('Can instantiate INetwork.getName', () {
    expect(network.getName, isA<Function>());
  });
  test('Can instantiate INetwork.setName', () {
    expect(network.setName, isA<Function>());
  });
  test('Can instantiate INetwork.getDescription', () {
    expect(network.getDescription, isA<Function>());
  });
  test('Can instantiate INetwork.setDescription', () {
    expect(network.setDescription, isA<Function>());
  });
  test('Can instantiate INetwork.getNetworkId', () {
    expect(network.getNetworkId, isA<Function>());
  });
  test('Can instantiate INetwork.getDomainType', () {
    expect(network.getDomainType, isA<Function>());
  });
  test('Can instantiate INetwork.getNetworkConnections', () {
    expect(network.getNetworkConnections, isA<Function>());
  });
  test('Can instantiate INetwork.getTimeCreatedAndConnected', () {
    expect(network.getTimeCreatedAndConnected, isA<Function>());
  });
  test('Can instantiate INetwork.getConnectivity', () {
    expect(network.getConnectivity, isA<Function>());
  });
  test('Can instantiate INetwork.getCategory', () {
    expect(network.getCategory, isA<Function>());
  });
  test('Can instantiate INetwork.setCategory', () {
    expect(network.setCategory, isA<Function>());
  });
  free(ptr);
}
