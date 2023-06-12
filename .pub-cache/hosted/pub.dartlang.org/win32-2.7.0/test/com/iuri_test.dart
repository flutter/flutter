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
  test('Can instantiate IUri.GetPropertyBSTR', () {
    expect(uri.GetPropertyBSTR, isA<Function>());
  });
  test('Can instantiate IUri.GetPropertyLength', () {
    expect(uri.GetPropertyLength, isA<Function>());
  });
  test('Can instantiate IUri.GetPropertyDWORD', () {
    expect(uri.GetPropertyDWORD, isA<Function>());
  });
  test('Can instantiate IUri.HasProperty', () {
    expect(uri.HasProperty, isA<Function>());
  });
  test('Can instantiate IUri.GetAbsoluteUri', () {
    expect(uri.GetAbsoluteUri, isA<Function>());
  });
  test('Can instantiate IUri.GetAuthority', () {
    expect(uri.GetAuthority, isA<Function>());
  });
  test('Can instantiate IUri.GetDisplayUri', () {
    expect(uri.GetDisplayUri, isA<Function>());
  });
  test('Can instantiate IUri.GetDomain', () {
    expect(uri.GetDomain, isA<Function>());
  });
  test('Can instantiate IUri.GetExtension', () {
    expect(uri.GetExtension, isA<Function>());
  });
  test('Can instantiate IUri.GetFragment', () {
    expect(uri.GetFragment, isA<Function>());
  });
  test('Can instantiate IUri.GetHost', () {
    expect(uri.GetHost, isA<Function>());
  });
  test('Can instantiate IUri.GetPassword', () {
    expect(uri.GetPassword, isA<Function>());
  });
  test('Can instantiate IUri.GetPath', () {
    expect(uri.GetPath, isA<Function>());
  });
  test('Can instantiate IUri.GetPathAndQuery', () {
    expect(uri.GetPathAndQuery, isA<Function>());
  });
  test('Can instantiate IUri.GetQuery', () {
    expect(uri.GetQuery, isA<Function>());
  });
  test('Can instantiate IUri.GetRawUri', () {
    expect(uri.GetRawUri, isA<Function>());
  });
  test('Can instantiate IUri.GetSchemeName', () {
    expect(uri.GetSchemeName, isA<Function>());
  });
  test('Can instantiate IUri.GetUserInfo', () {
    expect(uri.GetUserInfo, isA<Function>());
  });
  test('Can instantiate IUri.GetUserName', () {
    expect(uri.GetUserName, isA<Function>());
  });
  test('Can instantiate IUri.GetHostType', () {
    expect(uri.GetHostType, isA<Function>());
  });
  test('Can instantiate IUri.GetPort', () {
    expect(uri.GetPort, isA<Function>());
  });
  test('Can instantiate IUri.GetScheme', () {
    expect(uri.GetScheme, isA<Function>());
  });
  test('Can instantiate IUri.GetZone', () {
    expect(uri.GetZone, isA<Function>());
  });
  test('Can instantiate IUri.GetProperties', () {
    expect(uri.GetProperties, isA<Function>());
  });
  test('Can instantiate IUri.IsEqual', () {
    expect(uri.IsEqual, isA<Function>());
  });
  free(ptr);
}
