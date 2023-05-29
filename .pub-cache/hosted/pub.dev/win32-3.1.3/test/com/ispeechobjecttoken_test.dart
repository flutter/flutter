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

  final speechobjecttoken = ISpeechObjectToken(ptr);
  test('Can instantiate ISpeechObjectToken.getDescription', () {
    expect(speechobjecttoken.getDescription, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.setId', () {
    expect(speechobjecttoken.setId, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.getAttribute', () {
    expect(speechobjecttoken.getAttribute, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.createInstance', () {
    expect(speechobjecttoken.createInstance, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.remove', () {
    expect(speechobjecttoken.remove, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.getStorageFileName', () {
    expect(speechobjecttoken.getStorageFileName, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.removeStorageFileName', () {
    expect(speechobjecttoken.removeStorageFileName, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.isUISupported', () {
    expect(speechobjecttoken.isUISupported, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.displayUI', () {
    expect(speechobjecttoken.displayUI, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.matchesAttributes', () {
    expect(speechobjecttoken.matchesAttributes, isA<Function>());
  });
  free(ptr);
}
