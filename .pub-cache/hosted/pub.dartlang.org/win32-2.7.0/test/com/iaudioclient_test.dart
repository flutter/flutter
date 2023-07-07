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

  final audioclient = IAudioClient(ptr);
  test('Can instantiate IAudioClient.Initialize', () {
    expect(audioclient.Initialize, isA<Function>());
  });
  test('Can instantiate IAudioClient.GetBufferSize', () {
    expect(audioclient.GetBufferSize, isA<Function>());
  });
  test('Can instantiate IAudioClient.GetStreamLatency', () {
    expect(audioclient.GetStreamLatency, isA<Function>());
  });
  test('Can instantiate IAudioClient.GetCurrentPadding', () {
    expect(audioclient.GetCurrentPadding, isA<Function>());
  });
  test('Can instantiate IAudioClient.IsFormatSupported', () {
    expect(audioclient.IsFormatSupported, isA<Function>());
  });
  test('Can instantiate IAudioClient.GetMixFormat', () {
    expect(audioclient.GetMixFormat, isA<Function>());
  });
  test('Can instantiate IAudioClient.GetDevicePeriod', () {
    expect(audioclient.GetDevicePeriod, isA<Function>());
  });
  test('Can instantiate IAudioClient.Start', () {
    expect(audioclient.Start, isA<Function>());
  });
  test('Can instantiate IAudioClient.Stop', () {
    expect(audioclient.Stop, isA<Function>());
  });
  test('Can instantiate IAudioClient.Reset', () {
    expect(audioclient.Reset, isA<Function>());
  });
  test('Can instantiate IAudioClient.SetEventHandle', () {
    expect(audioclient.SetEventHandle, isA<Function>());
  });
  test('Can instantiate IAudioClient.GetService', () {
    expect(audioclient.GetService, isA<Function>());
  });
  free(ptr);
}
