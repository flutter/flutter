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
  test('Can instantiate ITypeInfo.getTypeAttr', () {
    expect(typeinfo.getTypeAttr, isA<Function>());
  });
  test('Can instantiate ITypeInfo.getTypeComp', () {
    expect(typeinfo.getTypeComp, isA<Function>());
  });
  test('Can instantiate ITypeInfo.getFuncDesc', () {
    expect(typeinfo.getFuncDesc, isA<Function>());
  });
  test('Can instantiate ITypeInfo.getVarDesc', () {
    expect(typeinfo.getVarDesc, isA<Function>());
  });
  test('Can instantiate ITypeInfo.getNames', () {
    expect(typeinfo.getNames, isA<Function>());
  });
  test('Can instantiate ITypeInfo.getRefTypeOfImplType', () {
    expect(typeinfo.getRefTypeOfImplType, isA<Function>());
  });
  test('Can instantiate ITypeInfo.getImplTypeFlags', () {
    expect(typeinfo.getImplTypeFlags, isA<Function>());
  });
  test('Can instantiate ITypeInfo.getIDsOfNames', () {
    expect(typeinfo.getIDsOfNames, isA<Function>());
  });
  test('Can instantiate ITypeInfo.invoke', () {
    expect(typeinfo.invoke, isA<Function>());
  });
  test('Can instantiate ITypeInfo.getDocumentation', () {
    expect(typeinfo.getDocumentation, isA<Function>());
  });
  test('Can instantiate ITypeInfo.getDllEntry', () {
    expect(typeinfo.getDllEntry, isA<Function>());
  });
  test('Can instantiate ITypeInfo.getRefTypeInfo', () {
    expect(typeinfo.getRefTypeInfo, isA<Function>());
  });
  test('Can instantiate ITypeInfo.addressOfMember', () {
    expect(typeinfo.addressOfMember, isA<Function>());
  });
  test('Can instantiate ITypeInfo.createInstance', () {
    expect(typeinfo.createInstance, isA<Function>());
  });
  test('Can instantiate ITypeInfo.getMops', () {
    expect(typeinfo.getMops, isA<Function>());
  });
  test('Can instantiate ITypeInfo.getContainingTypeLib', () {
    expect(typeinfo.getContainingTypeLib, isA<Function>());
  });
  test('Can instantiate ITypeInfo.releaseTypeAttr', () {
    expect(typeinfo.releaseTypeAttr, isA<Function>());
  });
  test('Can instantiate ITypeInfo.releaseFuncDesc', () {
    expect(typeinfo.releaseFuncDesc, isA<Function>());
  });
  test('Can instantiate ITypeInfo.releaseVarDesc', () {
    expect(typeinfo.releaseVarDesc, isA<Function>());
  });
  free(ptr);
}
