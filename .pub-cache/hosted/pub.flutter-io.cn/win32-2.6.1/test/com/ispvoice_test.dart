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

  final spvoice = ISpVoice(ptr);
  test('Can instantiate ISpVoice.SetOutput', () {
    expect(spvoice.SetOutput, isA<Function>());
  });
  test('Can instantiate ISpVoice.GetOutputObjectToken', () {
    expect(spvoice.GetOutputObjectToken, isA<Function>());
  });
  test('Can instantiate ISpVoice.GetOutputStream', () {
    expect(spvoice.GetOutputStream, isA<Function>());
  });
  test('Can instantiate ISpVoice.Pause', () {
    expect(spvoice.Pause, isA<Function>());
  });
  test('Can instantiate ISpVoice.Resume', () {
    expect(spvoice.Resume, isA<Function>());
  });
  test('Can instantiate ISpVoice.SetVoice', () {
    expect(spvoice.SetVoice, isA<Function>());
  });
  test('Can instantiate ISpVoice.GetVoice', () {
    expect(spvoice.GetVoice, isA<Function>());
  });
  test('Can instantiate ISpVoice.Speak', () {
    expect(spvoice.Speak, isA<Function>());
  });
  test('Can instantiate ISpVoice.SpeakStream', () {
    expect(spvoice.SpeakStream, isA<Function>());
  });
  test('Can instantiate ISpVoice.GetStatus', () {
    expect(spvoice.GetStatus, isA<Function>());
  });
  test('Can instantiate ISpVoice.Skip', () {
    expect(spvoice.Skip, isA<Function>());
  });
  test('Can instantiate ISpVoice.SetPriority', () {
    expect(spvoice.SetPriority, isA<Function>());
  });
  test('Can instantiate ISpVoice.GetPriority', () {
    expect(spvoice.GetPriority, isA<Function>());
  });
  test('Can instantiate ISpVoice.SetAlertBoundary', () {
    expect(spvoice.SetAlertBoundary, isA<Function>());
  });
  test('Can instantiate ISpVoice.GetAlertBoundary', () {
    expect(spvoice.GetAlertBoundary, isA<Function>());
  });
  test('Can instantiate ISpVoice.SetRate', () {
    expect(spvoice.SetRate, isA<Function>());
  });
  test('Can instantiate ISpVoice.GetRate', () {
    expect(spvoice.GetRate, isA<Function>());
  });
  test('Can instantiate ISpVoice.SetVolume', () {
    expect(spvoice.SetVolume, isA<Function>());
  });
  test('Can instantiate ISpVoice.GetVolume', () {
    expect(spvoice.GetVolume, isA<Function>());
  });
  test('Can instantiate ISpVoice.WaitUntilDone', () {
    expect(spvoice.WaitUntilDone, isA<Function>());
  });
  test('Can instantiate ISpVoice.SetSyncSpeakTimeout', () {
    expect(spvoice.SetSyncSpeakTimeout, isA<Function>());
  });
  test('Can instantiate ISpVoice.GetSyncSpeakTimeout', () {
    expect(spvoice.GetSyncSpeakTimeout, isA<Function>());
  });
  test('Can instantiate ISpVoice.SpeakCompleteEvent', () {
    expect(spvoice.SpeakCompleteEvent, isA<Function>());
  });
  test('Can instantiate ISpVoice.IsUISupported', () {
    expect(spvoice.IsUISupported, isA<Function>());
  });
  test('Can instantiate ISpVoice.DisplayUI', () {
    expect(spvoice.DisplayUI, isA<Function>());
  });
  free(ptr);
}
