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
  test('Can instantiate IShellLink.GetPath', () {
    expect(shelllink.GetPath, isA<Function>());
  });
  test('Can instantiate IShellLink.GetIDList', () {
    expect(shelllink.GetIDList, isA<Function>());
  });
  test('Can instantiate IShellLink.SetIDList', () {
    expect(shelllink.SetIDList, isA<Function>());
  });
  test('Can instantiate IShellLink.GetDescription', () {
    expect(shelllink.GetDescription, isA<Function>());
  });
  test('Can instantiate IShellLink.SetDescription', () {
    expect(shelllink.SetDescription, isA<Function>());
  });
  test('Can instantiate IShellLink.GetWorkingDirectory', () {
    expect(shelllink.GetWorkingDirectory, isA<Function>());
  });
  test('Can instantiate IShellLink.SetWorkingDirectory', () {
    expect(shelllink.SetWorkingDirectory, isA<Function>());
  });
  test('Can instantiate IShellLink.GetArguments', () {
    expect(shelllink.GetArguments, isA<Function>());
  });
  test('Can instantiate IShellLink.SetArguments', () {
    expect(shelllink.SetArguments, isA<Function>());
  });
  test('Can instantiate IShellLink.GetHotkey', () {
    expect(shelllink.GetHotkey, isA<Function>());
  });
  test('Can instantiate IShellLink.SetHotkey', () {
    expect(shelllink.SetHotkey, isA<Function>());
  });
  test('Can instantiate IShellLink.GetShowCmd', () {
    expect(shelllink.GetShowCmd, isA<Function>());
  });
  test('Can instantiate IShellLink.SetShowCmd', () {
    expect(shelllink.SetShowCmd, isA<Function>());
  });
  test('Can instantiate IShellLink.GetIconLocation', () {
    expect(shelllink.GetIconLocation, isA<Function>());
  });
  test('Can instantiate IShellLink.SetIconLocation', () {
    expect(shelllink.SetIconLocation, isA<Function>());
  });
  test('Can instantiate IShellLink.SetRelativePath', () {
    expect(shelllink.SetRelativePath, isA<Function>());
  });
  test('Can instantiate IShellLink.Resolve', () {
    expect(shelllink.Resolve, isA<Function>());
  });
  test('Can instantiate IShellLink.SetPath', () {
    expect(shelllink.SetPath, isA<Function>());
  });
  free(ptr);
}
