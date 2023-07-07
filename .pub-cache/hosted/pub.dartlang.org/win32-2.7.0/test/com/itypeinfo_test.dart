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

  final typeinfo = ITypeInfo(ptr);
  test('Can instantiate ITypeInfo.GetTypeAttr', () {
    expect(typeinfo.GetTypeAttr, isA<Function>());
  });
  test('Can instantiate ITypeInfo.GetTypeComp', () {
    expect(typeinfo.GetTypeComp, isA<Function>());
  });
  test('Can instantiate ITypeInfo.GetFuncDesc', () {
    expect(typeinfo.GetFuncDesc, isA<Function>());
  });
  test('Can instantiate ITypeInfo.GetVarDesc', () {
    expect(typeinfo.GetVarDesc, isA<Function>());
  });
  test('Can instantiate ITypeInfo.GetNames', () {
    expect(typeinfo.GetNames, isA<Function>());
  });
  test('Can instantiate ITypeInfo.GetRefTypeOfImplType', () {
    expect(typeinfo.GetRefTypeOfImplType, isA<Function>());
  });
  test('Can instantiate ITypeInfo.GetImplTypeFlags', () {
    expect(typeinfo.GetImplTypeFlags, isA<Function>());
  });
  test('Can instantiate ITypeInfo.GetIDsOfNames', () {
    expect(typeinfo.GetIDsOfNames, isA<Function>());
  });
  test('Can instantiate ITypeInfo.Invoke', () {
    expect(typeinfo.Invoke, isA<Function>());
  });
  test('Can instantiate ITypeInfo.GetDocumentation', () {
    expect(typeinfo.GetDocumentation, isA<Function>());
  });
  test('Can instantiate ITypeInfo.GetDllEntry', () {
    expect(typeinfo.GetDllEntry, isA<Function>());
  });
  test('Can instantiate ITypeInfo.GetRefTypeInfo', () {
    expect(typeinfo.GetRefTypeInfo, isA<Function>());
  });
  test('Can instantiate ITypeInfo.AddressOfMember', () {
    expect(typeinfo.AddressOfMember, isA<Function>());
  });
  test('Can instantiate ITypeInfo.CreateInstance', () {
    expect(typeinfo.CreateInstance, isA<Function>());
  });
  test('Can instantiate ITypeInfo.GetMops', () {
    expect(typeinfo.GetMops, isA<Function>());
  });
  test('Can instantiate ITypeInfo.GetContainingTypeLib', () {
    expect(typeinfo.GetContainingTypeLib, isA<Function>());
  });
  test('Can instantiate ITypeInfo.ReleaseTypeAttr', () {
    expect(typeinfo.ReleaseTypeAttr, isA<Function>());
  });
  test('Can instantiate ITypeInfo.ReleaseFuncDesc', () {
    expect(typeinfo.ReleaseFuncDesc, isA<Function>());
  });
  test('Can instantiate ITypeInfo.ReleaseVarDesc', () {
    expect(typeinfo.ReleaseVarDesc, isA<Function>());
  });
  free(ptr);
}
