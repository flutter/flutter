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

  final shelllink = IShellLink(ptr);
  test('Can instantiate IShellLink.getPath', () {
    expect(shelllink.getPath, isA<Function>());
  });
  test('Can instantiate IShellLink.getIDList', () {
    expect(shelllink.getIDList, isA<Function>());
  });
  test('Can instantiate IShellLink.setIDList', () {
    expect(shelllink.setIDList, isA<Function>());
  });
  test('Can instantiate IShellLink.getDescription', () {
    expect(shelllink.getDescription, isA<Function>());
  });
  test('Can instantiate IShellLink.setDescription', () {
    expect(shelllink.setDescription, isA<Function>());
  });
  test('Can instantiate IShellLink.getWorkingDirectory', () {
    expect(shelllink.getWorkingDirectory, isA<Function>());
  });
  test('Can instantiate IShellLink.setWorkingDirectory', () {
    expect(shelllink.setWorkingDirectory, isA<Function>());
  });
  test('Can instantiate IShellLink.getArguments', () {
    expect(shelllink.getArguments, isA<Function>());
  });
  test('Can instantiate IShellLink.setArguments', () {
    expect(shelllink.setArguments, isA<Function>());
  });
  test('Can instantiate IShellLink.getHotkey', () {
    expect(shelllink.getHotkey, isA<Function>());
  });
  test('Can instantiate IShellLink.setHotkey', () {
    expect(shelllink.setHotkey, isA<Function>());
  });
  test('Can instantiate IShellLink.getShowCmd', () {
    expect(shelllink.getShowCmd, isA<Function>());
  });
  test('Can instantiate IShellLink.setShowCmd', () {
    expect(shelllink.setShowCmd, isA<Function>());
  });
  test('Can instantiate IShellLink.getIconLocation', () {
    expect(shelllink.getIconLocation, isA<Function>());
  });
  test('Can instantiate IShellLink.setIconLocation', () {
    expect(shelllink.setIconLocation, isA<Function>());
  });
  test('Can instantiate IShellLink.setRelativePath', () {
    expect(shelllink.setRelativePath, isA<Function>());
  });
  test('Can instantiate IShellLink.resolve', () {
    expect(shelllink.resolve, isA<Function>());
  });
  test('Can instantiate IShellLink.setPath', () {
    expect(shelllink.setPath, isA<Function>());
  });
  free(ptr);
}
