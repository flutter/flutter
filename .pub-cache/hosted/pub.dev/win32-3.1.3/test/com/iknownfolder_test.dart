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

  final knownfolder = IKnownFolder(ptr);
  test('Can instantiate IKnownFolder.getId', () {
    expect(knownfolder.getId, isA<Function>());
  });
  test('Can instantiate IKnownFolder.getCategory', () {
    expect(knownfolder.getCategory, isA<Function>());
  });
  test('Can instantiate IKnownFolder.getShellItem', () {
    expect(knownfolder.getShellItem, isA<Function>());
  });
  test('Can instantiate IKnownFolder.getPath', () {
    expect(knownfolder.getPath, isA<Function>());
  });
  test('Can instantiate IKnownFolder.setPath', () {
    expect(knownfolder.setPath, isA<Function>());
  });
  test('Can instantiate IKnownFolder.getIDList', () {
    expect(knownfolder.getIDList, isA<Function>());
  });
  test('Can instantiate IKnownFolder.getFolderType', () {
    expect(knownfolder.getFolderType, isA<Function>());
  });
  test('Can instantiate IKnownFolder.getRedirectionCapabilities', () {
    expect(knownfolder.getRedirectionCapabilities, isA<Function>());
  });
  test('Can instantiate IKnownFolder.getFolderDefinition', () {
    expect(knownfolder.getFolderDefinition, isA<Function>());
  });
  free(ptr);
}
