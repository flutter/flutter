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

  final filedialog = IFileDialog(ptr);
  test('Can instantiate IFileDialog.SetFileTypes', () {
    expect(filedialog.SetFileTypes, isA<Function>());
  });
  test('Can instantiate IFileDialog.SetFileTypeIndex', () {
    expect(filedialog.SetFileTypeIndex, isA<Function>());
  });
  test('Can instantiate IFileDialog.GetFileTypeIndex', () {
    expect(filedialog.GetFileTypeIndex, isA<Function>());
  });
  test('Can instantiate IFileDialog.Advise', () {
    expect(filedialog.Advise, isA<Function>());
  });
  test('Can instantiate IFileDialog.Unadvise', () {
    expect(filedialog.Unadvise, isA<Function>());
  });
  test('Can instantiate IFileDialog.SetOptions', () {
    expect(filedialog.SetOptions, isA<Function>());
  });
  test('Can instantiate IFileDialog.GetOptions', () {
    expect(filedialog.GetOptions, isA<Function>());
  });
  test('Can instantiate IFileDialog.SetDefaultFolder', () {
    expect(filedialog.SetDefaultFolder, isA<Function>());
  });
  test('Can instantiate IFileDialog.SetFolder', () {
    expect(filedialog.SetFolder, isA<Function>());
  });
  test('Can instantiate IFileDialog.GetFolder', () {
    expect(filedialog.GetFolder, isA<Function>());
  });
  test('Can instantiate IFileDialog.GetCurrentSelection', () {
    expect(filedialog.GetCurrentSelection, isA<Function>());
  });
  test('Can instantiate IFileDialog.SetFileName', () {
    expect(filedialog.SetFileName, isA<Function>());
  });
  test('Can instantiate IFileDialog.GetFileName', () {
    expect(filedialog.GetFileName, isA<Function>());
  });
  test('Can instantiate IFileDialog.SetTitle', () {
    expect(filedialog.SetTitle, isA<Function>());
  });
  test('Can instantiate IFileDialog.SetOkButtonLabel', () {
    expect(filedialog.SetOkButtonLabel, isA<Function>());
  });
  test('Can instantiate IFileDialog.SetFileNameLabel', () {
    expect(filedialog.SetFileNameLabel, isA<Function>());
  });
  test('Can instantiate IFileDialog.GetResult', () {
    expect(filedialog.GetResult, isA<Function>());
  });
  test('Can instantiate IFileDialog.AddPlace', () {
    expect(filedialog.AddPlace, isA<Function>());
  });
  test('Can instantiate IFileDialog.SetDefaultExtension', () {
    expect(filedialog.SetDefaultExtension, isA<Function>());
  });
  test('Can instantiate IFileDialog.Close', () {
    expect(filedialog.Close, isA<Function>());
  });
  test('Can instantiate IFileDialog.SetClientGuid', () {
    expect(filedialog.SetClientGuid, isA<Function>());
  });
  test('Can instantiate IFileDialog.ClearClientData', () {
    expect(filedialog.ClearClientData, isA<Function>());
  });
  test('Can instantiate IFileDialog.SetFilter', () {
    expect(filedialog.SetFilter, isA<Function>());
  });
  free(ptr);
}
