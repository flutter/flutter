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
  test('Can instantiate ISpeechObjectToken.GetDescription', () {
    expect(speechobjecttoken.GetDescription, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.SetId', () {
    expect(speechobjecttoken.SetId, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.GetAttribute', () {
    expect(speechobjecttoken.GetAttribute, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.CreateInstance', () {
    expect(speechobjecttoken.CreateInstance, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.Remove', () {
    expect(speechobjecttoken.Remove, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.GetStorageFileName', () {
    expect(speechobjecttoken.GetStorageFileName, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.RemoveStorageFileName', () {
    expect(speechobjecttoken.RemoveStorageFileName, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.IsUISupported', () {
    expect(speechobjecttoken.IsUISupported, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.DisplayUI', () {
    expect(speechobjecttoken.DisplayUI, isA<Function>());
  });
  test('Can instantiate ISpeechObjectToken.MatchesAttributes', () {
    expect(speechobjecttoken.MatchesAttributes, isA<Function>());
  });
  free(ptr);
}
