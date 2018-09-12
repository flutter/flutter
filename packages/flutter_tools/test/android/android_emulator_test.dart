// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/android_emulator.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('android_emulator', () {
    testUsingContext('flags emulators without config', () {
      const String emulatorID = '1234';
      final AndroidEmulator emulator = AndroidEmulator(emulatorID);
      expect(emulator.id, emulatorID);
      expect(emulator.hasConfig, false);
    });
    testUsingContext('flags emulators with config', () {
      const String emulatorID = '1234';
      final AndroidEmulator emulator =
          AndroidEmulator(emulatorID, <String, String>{'name': 'test'});
      expect(emulator.id, emulatorID);
      expect(emulator.hasConfig, true);
    });
    testUsingContext('stores expected metadata', () {
      const String emulatorID = '1234';
      const String name = 'My Test Name';
      const String manufacturer = 'Me';
      const String label = 'The best one';
      final Map<String, String> properties = <String, String>{
        'hw.device.name': name,
        'hw.device.manufacturer': manufacturer,
        'avd.ini.displayname': label
      };
      final AndroidEmulator emulator =
          AndroidEmulator(emulatorID, properties);
      expect(emulator.id, emulatorID);
      expect(emulator.name, name);
      expect(emulator.manufacturer, manufacturer);
      expect(emulator.label, label);
    });
    testUsingContext('parses ini files', () {
      const String iniFile = '''
        hw.device.name=My Test Name
        #hw.device.name=Bad Name

        hw.device.manufacturer=Me
        avd.ini.displayname = dispName
      ''';
      final Map<String, String> results = parseIniLines(iniFile.split('\n'));
      expect(results['hw.device.name'], 'My Test Name');
      expect(results['hw.device.manufacturer'], 'Me');
      expect(results['avd.ini.displayname'], 'dispName');
    });
  });
}
