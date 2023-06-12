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

  final uri = IUri(ptr);
  test('Can instantiate IUri.getPropertyBSTR', () {
    expect(uri.getPropertyBSTR, isA<Function>());
  });
  test('Can instantiate IUri.getPropertyLength', () {
    expect(uri.getPropertyLength, isA<Function>());
  });
  test('Can instantiate IUri.getPropertyDWORD', () {
    expect(uri.getPropertyDWORD, isA<Function>());
  });
  test('Can instantiate IUri.hasProperty', () {
    expect(uri.hasProperty, isA<Function>());
  });
  test('Can instantiate IUri.getAbsoluteUri', () {
    expect(uri.getAbsoluteUri, isA<Function>());
  });
  test('Can instantiate IUri.getAuthority', () {
    expect(uri.getAuthority, isA<Function>());
  });
  test('Can instantiate IUri.getDisplayUri', () {
    expect(uri.getDisplayUri, isA<Function>());
  });
  test('Can instantiate IUri.getDomain', () {
    expect(uri.getDomain, isA<Function>());
  });
  test('Can instantiate IUri.getExtension', () {
    expect(uri.getExtension, isA<Function>());
  });
  test('Can instantiate IUri.getFragment', () {
    expect(uri.getFragment, isA<Function>());
  });
  test('Can instantiate IUri.getHost', () {
    expect(uri.getHost, isA<Function>());
  });
  test('Can instantiate IUri.getPassword', () {
    expect(uri.getPassword, isA<Function>());
  });
  test('Can instantiate IUri.getPath', () {
    expect(uri.getPath, isA<Function>());
  });
  test('Can instantiate IUri.getPathAndQuery', () {
    expect(uri.getPathAndQuery, isA<Function>());
  });
  test('Can instantiate IUri.getQuery', () {
    expect(uri.getQuery, isA<Function>());
  });
  test('Can instantiate IUri.getRawUri', () {
    expect(uri.getRawUri, isA<Function>());
  });
  test('Can instantiate IUri.getSchemeName', () {
    expect(uri.getSchemeName, isA<Function>());
  });
  test('Can instantiate IUri.getUserInfo', () {
    expect(uri.getUserInfo, isA<Function>());
  });
  test('Can instantiate IUri.getUserName', () {
    expect(uri.getUserName, isA<Function>());
  });
  test('Can instantiate IUri.getHostType', () {
    expect(uri.getHostType, isA<Function>());
  });
  test('Can instantiate IUri.getPort', () {
    expect(uri.getPort, isA<Function>());
  });
  test('Can instantiate IUri.getScheme', () {
    expect(uri.getScheme, isA<Function>());
  });
  test('Can instantiate IUri.getZone', () {
    expect(uri.getZone, isA<Function>());
  });
  test('Can instantiate IUri.getProperties', () {
    expect(uri.getProperties, isA<Function>());
  });
  test('Can instantiate IUri.isEqual', () {
    expect(uri.isEqual, isA<Function>());
  });
  free(ptr);
}
