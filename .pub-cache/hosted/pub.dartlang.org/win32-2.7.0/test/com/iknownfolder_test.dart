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
  test('Can instantiate IKnownFolder.GetId', () {
    expect(knownfolder.GetId, isA<Function>());
  });
  test('Can instantiate IKnownFolder.GetCategory', () {
    expect(knownfolder.GetCategory, isA<Function>());
  });
  test('Can instantiate IKnownFolder.GetShellItem', () {
    expect(knownfolder.GetShellItem, isA<Function>());
  });
  test('Can instantiate IKnownFolder.GetPath', () {
    expect(knownfolder.GetPath, isA<Function>());
  });
  test('Can instantiate IKnownFolder.SetPath', () {
    expect(knownfolder.SetPath, isA<Function>());
  });
  test('Can instantiate IKnownFolder.GetIDList', () {
    expect(knownfolder.GetIDList, isA<Function>());
  });
  test('Can instantiate IKnownFolder.GetFolderType', () {
    expect(knownfolder.GetFolderType, isA<Function>());
  });
  test('Can instantiate IKnownFolder.GetRedirectionCapabilities', () {
    expect(knownfolder.GetRedirectionCapabilities, isA<Function>());
  });
  test('Can instantiate IKnownFolder.GetFolderDefinition', () {
    expect(knownfolder.GetFolderDefinition, isA<Function>());
  });
  free(ptr);
}
