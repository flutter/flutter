// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import 'src/common.dart';

void main() {
  Config config;
  Directory tempDir;

  setUp(() {
    tempDir = fs.systemTempDirectory.createTempSync('flutter_config_test.');
    final File file = fs.file(fs.path.join(tempDir.path, '.settings'));
    config = Config(file);
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  group('config', () {
    test('get set value', () async {
      expect(config.getValue('foo'), null);
      config.setValue('foo', 'bar');
      expect(config.getValue('foo'), 'bar');
      expect(config.keys, contains('foo'));
    });

    test('containsKey', () async {
      expect(config.containsKey('foo'), false);
      config.setValue('foo', 'bar');
      expect(config.containsKey('foo'), true);
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
  });
}
