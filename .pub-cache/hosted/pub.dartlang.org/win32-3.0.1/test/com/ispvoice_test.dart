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
  test('Can instantiate ISpVoice.setOutput', () {
    expect(spvoice.setOutput, isA<Function>());
  });
  test('Can instantiate ISpVoice.getOutputObjectToken', () {
    expect(spvoice.getOutputObjectToken, isA<Function>());
  });
  test('Can instantiate ISpVoice.getOutputStream', () {
    expect(spvoice.getOutputStream, isA<Function>());
  });
  test('Can instantiate ISpVoice.pause', () {
    expect(spvoice.pause, isA<Function>());
  });
  test('Can instantiate ISpVoice.resume', () {
    expect(spvoice.resume, isA<Function>());
  });
  test('Can instantiate ISpVoice.setVoice', () {
    expect(spvoice.setVoice, isA<Function>());
  });
  test('Can instantiate ISpVoice.getVoice', () {
    expect(spvoice.getVoice, isA<Function>());
  });
  test('Can instantiate ISpVoice.speak', () {
    expect(spvoice.speak, isA<Function>());
  });
  test('Can instantiate ISpVoice.speakStream', () {
    expect(spvoice.speakStream, isA<Function>());
  });
  test('Can instantiate ISpVoice.getStatus', () {
    expect(spvoice.getStatus, isA<Function>());
  });
  test('Can instantiate ISpVoice.skip', () {
    expect(spvoice.skip, isA<Function>());
  });
  test('Can instantiate ISpVoice.setPriority', () {
    expect(spvoice.setPriority, isA<Function>());
  });
  test('Can instantiate ISpVoice.getPriority', () {
    expect(spvoice.getPriority, isA<Function>());
  });
  test('Can instantiate ISpVoice.setAlertBoundary', () {
    expect(spvoice.setAlertBoundary, isA<Function>());
  });
  test('Can instantiate ISpVoice.getAlertBoundary', () {
    expect(spvoice.getAlertBoundary, isA<Function>());
  });
  test('Can instantiate ISpVoice.setRate', () {
    expect(spvoice.setRate, isA<Function>());
  });
  test('Can instantiate ISpVoice.getRate', () {
    expect(spvoice.getRate, isA<Function>());
  });
  test('Can instantiate ISpVoice.setVolume', () {
    expect(spvoice.setVolume, isA<Function>());
  });
  test('Can instantiate ISpVoice.getVolume', () {
    expect(spvoice.getVolume, isA<Function>());
  });
  test('Can instantiate ISpVoice.waitUntilDone', () {
    expect(spvoice.waitUntilDone, isA<Function>());
  });
  test('Can instantiate ISpVoice.setSyncSpeakTimeout', () {
    expect(spvoice.setSyncSpeakTimeout, isA<Function>());
  });
  test('Can instantiate ISpVoice.getSyncSpeakTimeout', () {
    expect(spvoice.getSyncSpeakTimeout, isA<Function>());
  });
  test('Can instantiate ISpVoice.speakCompleteEvent', () {
    expect(spvoice.speakCompleteEvent, isA<Function>());
  });
  test('Can instantiate ISpVoice.isUISupported', () {
    expect(spvoice.isUISupported, isA<Function>());
  });
  test('Can instantiate ISpVoice.displayUI', () {
    expect(spvoice.displayUI, isA<Function>());
  });
  free(ptr);
}
