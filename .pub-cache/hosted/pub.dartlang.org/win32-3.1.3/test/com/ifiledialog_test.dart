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
  test('Can instantiate IFileDialog.setFileTypes', () {
    expect(filedialog.setFileTypes, isA<Function>());
  });
  test('Can instantiate IFileDialog.setFileTypeIndex', () {
    expect(filedialog.setFileTypeIndex, isA<Function>());
  });
  test('Can instantiate IFileDialog.getFileTypeIndex', () {
    expect(filedialog.getFileTypeIndex, isA<Function>());
  });
  test('Can instantiate IFileDialog.advise', () {
    expect(filedialog.advise, isA<Function>());
  });
  test('Can instantiate IFileDialog.unadvise', () {
    expect(filedialog.unadvise, isA<Function>());
  });
  test('Can instantiate IFileDialog.setOptions', () {
    expect(filedialog.setOptions, isA<Function>());
  });
  test('Can instantiate IFileDialog.getOptions', () {
    expect(filedialog.getOptions, isA<Function>());
  });
  test('Can instantiate IFileDialog.setDefaultFolder', () {
    expect(filedialog.setDefaultFolder, isA<Function>());
  });
  test('Can instantiate IFileDialog.setFolder', () {
    expect(filedialog.setFolder, isA<Function>());
  });
  test('Can instantiate IFileDialog.getFolder', () {
    expect(filedialog.getFolder, isA<Function>());
  });
  test('Can instantiate IFileDialog.getCurrentSelection', () {
    expect(filedialog.getCurrentSelection, isA<Function>());
  });
  test('Can instantiate IFileDialog.setFileName', () {
    expect(filedialog.setFileName, isA<Function>());
  });
  test('Can instantiate IFileDialog.getFileName', () {
    expect(filedialog.getFileName, isA<Function>());
  });
  test('Can instantiate IFileDialog.setTitle', () {
    expect(filedialog.setTitle, isA<Function>());
  });
  test('Can instantiate IFileDialog.setOkButtonLabel', () {
    expect(filedialog.setOkButtonLabel, isA<Function>());
  });
  test('Can instantiate IFileDialog.setFileNameLabel', () {
    expect(filedialog.setFileNameLabel, isA<Function>());
  });
  test('Can instantiate IFileDialog.getResult', () {
    expect(filedialog.getResult, isA<Function>());
  });
  test('Can instantiate IFileDialog.addPlace', () {
    expect(filedialog.addPlace, isA<Function>());
  });
  test('Can instantiate IFileDialog.setDefaultExtension', () {
    expect(filedialog.setDefaultExtension, isA<Function>());
  });
  test('Can instantiate IFileDialog.close', () {
    expect(filedialog.close, isA<Function>());
  });
  test('Can instantiate IFileDialog.setClientGuid', () {
    expect(filedialog.setClientGuid, isA<Function>());
  });
  test('Can instantiate IFileDialog.clearClientData', () {
    expect(filedialog.clearClientData, isA<Function>());
  });
  test('Can instantiate IFileDialog.setFilter', () {
    expect(filedialog.setFilter, isA<Function>());
  });
  free(ptr);
}
