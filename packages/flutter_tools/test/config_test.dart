// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  Config config;

  setUp(() {
    Directory tempDiretory = fs.systemTempDirectory.createTempSync('flutter_test');
    File file = fs.file(path.join(tempDiretory.path, '.settings'));
    config = new Config(file);
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
  });
}
