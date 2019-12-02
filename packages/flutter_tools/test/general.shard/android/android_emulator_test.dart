// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/android_emulator.dart';
import 'package:flutter_tools/src/device.dart';

import '../../src/common.dart';
import '../../src/context.dart';

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
    testUsingContext('reads expected metadata', () {
      const String emulatorID = '1234';
      const String manufacturer = 'Me';
      const String displayName = 'The best one';
      final Map<String, String> properties = <String, String>{
        'hw.device.manufacturer': manufacturer,
        'avd.ini.displayname': displayName,
      };
      final AndroidEmulator emulator =
          AndroidEmulator(emulatorID, properties);
      expect(emulator.id, emulatorID);
      expect(emulator.name, displayName);
      expect(emulator.manufacturer, manufacturer);
      expect(emulator.category, Category.mobile);
      expect(emulator.platformType, PlatformType.android);
    });
    testUsingContext('prefers displayname for name', () {
      const String emulatorID = '1234';
      const String displayName = 'The best one';
      final Map<String, String> properties = <String, String>{
        'avd.ini.displayname': displayName,
      };
      final AndroidEmulator emulator =
          AndroidEmulator(emulatorID, properties);
      expect(emulator.name, displayName);
    });
    testUsingContext('uses cleaned up ID if no displayname is set', () {
      // Android Studio uses the ID with underscores replaced with spaces
      // for the name if displayname is not set so we do the same.
      const String emulatorID = 'This_is_my_ID';
      final Map<String, String> properties = <String, String>{
        'avd.ini.notadisplayname': 'this is not a display name',
      };
      final AndroidEmulator emulator =
          AndroidEmulator(emulatorID, properties);
      expect(emulator.name, 'This is my ID');
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
