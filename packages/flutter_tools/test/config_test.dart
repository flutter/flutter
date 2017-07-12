// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  Config config;
  MockAndroidStudio mockAndroidStudio;

  setUp(() {
    final Directory tempDirectory = fs.systemTempDirectory.createTempSync('flutter_test');
    final File file = fs.file(fs.path.join(tempDirectory.path, '.settings'));
    config = new Config(file);
    mockAndroidStudio = new MockAndroidStudio();
  });

  group('config', () {
    test('get set value', () async {
      expect(config.getValue('foo'), null);
      config.setValue('foo', 'bar');
      expect(config.getValue('foo'), 'bar');
      expect(config.keys, contains('foo'));
    });

    test('removeValue', () async {
      expect(config.getValue('foo'), null);
      config.setValue('foo', 'bar');
      expect(config.getValue('foo'), 'bar');
      expect(config.keys, contains('foo'));
      config.removeValue('foo');
      expect(config.getValue('foo'), null);
      expect(config.keys, isNot(contains('foo')));
    });

    testUsingContext('machine flag', () async {
      final BufferLogger logger = context[Logger];
      final ConfigCommand command = new ConfigCommand();
      await command.handleMachine();

      expect(logger.statusText, isNotEmpty);
      final dynamic json = JSON.decode(logger.statusText);
      expect(json, isMap);
      expect(json.containsKey('android-studio-dir'), true);
      expect(json['android-studio-dir'], isNotNull);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => mockAndroidStudio,
    });
  });
}

class MockAndroidStudio extends Mock implements AndroidStudio, Comparable<AndroidStudio> {
  @override
  String get directory => 'path/to/android/stdio';
}
