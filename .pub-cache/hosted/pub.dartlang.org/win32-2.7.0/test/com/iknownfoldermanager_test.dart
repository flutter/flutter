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

  final knownfoldermanager = IKnownFolderManager(ptr);
  test('Can instantiate IKnownFolderManager.FolderIdFromCsidl', () {
    expect(knownfoldermanager.FolderIdFromCsidl, isA<Function>());
  });
  test('Can instantiate IKnownFolderManager.FolderIdToCsidl', () {
    expect(knownfoldermanager.FolderIdToCsidl, isA<Function>());
  });
  test('Can instantiate IKnownFolderManager.GetFolderIds', () {
    expect(knownfoldermanager.GetFolderIds, isA<Function>());
  });
  test('Can instantiate IKnownFolderManager.GetFolder', () {
    expect(knownfoldermanager.GetFolder, isA<Function>());
  });
  test('Can instantiate IKnownFolderManager.GetFolderByName', () {
    expect(knownfoldermanager.GetFolderByName, isA<Function>());
  });
  test('Can instantiate IKnownFolderManager.RegisterFolder', () {
    expect(knownfoldermanager.RegisterFolder, isA<Function>());
  });
  test('Can instantiate IKnownFolderManager.UnregisterFolder', () {
    expect(knownfoldermanager.UnregisterFolder, isA<Function>());
  });
  test('Can instantiate IKnownFolderManager.FindFolderFromPath', () {
    expect(knownfoldermanager.FindFolderFromPath, isA<Function>());
  });
  test('Can instantiate IKnownFolderManager.FindFolderFromIDList', () {
    expect(knownfoldermanager.FindFolderFromIDList, isA<Function>());
  });
  test('Can instantiate IKnownFolderManager.Redirect', () {
    expect(knownfoldermanager.Redirect, isA<Function>());
  });
  free(ptr);
}
