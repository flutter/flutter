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

  final networkconnection = INetworkConnection(ptr);
  test('Can instantiate INetworkConnection.GetNetwork', () {
    expect(networkconnection.GetNetwork, isA<Function>());
  });
  test('Can instantiate INetworkConnection.GetConnectivity', () {
    expect(networkconnection.GetConnectivity, isA<Function>());
  });
  test('Can instantiate INetworkConnection.GetConnectionId', () {
    expect(networkconnection.GetConnectionId, isA<Function>());
  });
  test('Can instantiate INetworkConnection.GetAdapterId', () {
    expect(networkconnection.GetAdapterId, isA<Function>());
  });
  test('Can instantiate INetworkConnection.GetDomainType', () {
    expect(networkconnection.GetDomainType, isA<Function>());
  });
  free(ptr);
}
