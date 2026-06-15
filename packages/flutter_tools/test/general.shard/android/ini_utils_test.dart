// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/ini_utils.dart';
import 'package:test/test.dart';

void main() {
  group('parseIniLines', () {
    test('parses ini files', () {
      const iniFile = '''
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

    test('handles empty or commented lines', () {
      const iniFile = '''
        # This is a comment
        
        # Another comment
        foo=bar
      ''';
      final Map<String, String> results = parseIniLines(iniFile.split('\n'));

      expect(results, <String, String>{'foo': 'bar'});
    });

    test('ignores lines without "="', () {
      const iniFile = '''
        invalid_line_without_equals
        foo=bar
      ''';
      final Map<String, String> results = parseIniLines(iniFile.split('\n'));

      expect(results, <String, String>{'foo': 'bar'});
    });

    test('handles values containing "="', () {
      const iniFile = '''
        foo=bar=baz
      ''';
      final Map<String, String> results = parseIniLines(iniFile.split('\n'));

      expect(results, <String, String>{'foo': 'bar=baz'});
    });
  });
}
