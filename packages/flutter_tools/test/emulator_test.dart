// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/emulator.dart';
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  group('EmulatorManager', () {
    testUsingContext('getEmulators', () async {
      // Test that EmulatorManager.getEmulators() doesn't throw.
      final EmulatorManager emulatorManager = new EmulatorManager();
      final List<Emulator> emulators = await emulatorManager.getAllAvailableEmulators().toList();
      expect(emulators, isList);
    });

    testUsingContext('getEmulatorsById', () async {
      final _MockEmulator emulator1 = new _MockEmulator('Nexus_5', 'Nexus 5', 'Google', '');
      final _MockEmulator emulator2 = new _MockEmulator('Nexus_5X_API_27_x86', 'Nexus 5X', 'Google', '');
      final _MockEmulator emulator3 = new _MockEmulator('iOS Simulator', 'iOS Simulator', 'Apple', '');
      final List<Emulator> emulators = <Emulator>[emulator1, emulator2, emulator3];
      final EmulatorManager emulatorManager = new TestEmulatorManager(emulators);

      Future<Null> expectEmulator(String id, List<Emulator> expected) async {
        expect(await emulatorManager.getEmulatorsById(id).toList(), expected);
      }
      expectEmulator('Nexus_5', <Emulator>[emulator1]);
      expectEmulator('Nexus_5X', <Emulator>[emulator2]);
      expectEmulator('Nexus_5X_API_27_x86', <Emulator>[emulator2]);
      expectEmulator('Nexus', <Emulator>[emulator1, emulator2]);
      expectEmulator('iOS Simulator', <Emulator>[emulator3]);
      expectEmulator('ios', <Emulator>[emulator3]);
    });
  });
}

class TestEmulatorManager extends EmulatorManager {
  final List<Emulator> allEmulators;

  TestEmulatorManager(this.allEmulators);

  @override
  Stream<Emulator> getAllAvailableEmulators() {
    return new Stream<Emulator>.fromIterable(allEmulators);
  }
}

class _MockEmulator extends Emulator {
  _MockEmulator(String id, this.name, this.manufacturer, this.label) : super(id, true);

  @override
  final String name;
 
  @override
  final String manufacturer;
 
  @override
  final String label;

  @override
  void launch() {
    throw new UnimplementedError('Not implemented in Mock');
  }

  
}
