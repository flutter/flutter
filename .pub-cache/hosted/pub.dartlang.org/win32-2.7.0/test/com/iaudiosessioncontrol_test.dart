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

  final audiosessioncontrol = IAudioSessionControl(ptr);
  test('Can instantiate IAudioSessionControl.GetState', () {
    expect(audiosessioncontrol.GetState, isA<Function>());
  });
  test('Can instantiate IAudioSessionControl.GetDisplayName', () {
    expect(audiosessioncontrol.GetDisplayName, isA<Function>());
  });
  test('Can instantiate IAudioSessionControl.SetDisplayName', () {
    expect(audiosessioncontrol.SetDisplayName, isA<Function>());
  });
  test('Can instantiate IAudioSessionControl.GetIconPath', () {
    expect(audiosessioncontrol.GetIconPath, isA<Function>());
  });
  test('Can instantiate IAudioSessionControl.SetIconPath', () {
    expect(audiosessioncontrol.SetIconPath, isA<Function>());
  });
  test('Can instantiate IAudioSessionControl.GetGroupingParam', () {
    expect(audiosessioncontrol.GetGroupingParam, isA<Function>());
  });
  test('Can instantiate IAudioSessionControl.SetGroupingParam', () {
    expect(audiosessioncontrol.SetGroupingParam, isA<Function>());
  });
  test('Can instantiate IAudioSessionControl.RegisterAudioSessionNotification',
      () {
    expect(
        audiosessioncontrol.RegisterAudioSessionNotification, isA<Function>());
  });
  test(
      'Can instantiate IAudioSessionControl.UnregisterAudioSessionNotification',
      () {
    expect(audiosessioncontrol.UnregisterAudioSessionNotification,
        isA<Function>());
  });
  free(ptr);
}
