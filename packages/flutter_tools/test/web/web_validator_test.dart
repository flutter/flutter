// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/web_validator.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/testbed.dart';

void main() {
  group('WebValidator', () {
    Testbed testbed;
    WebValidator webValidator;
    MockPlatform mockPlatform;

    setUp(() {
      testbed = Testbed(setup: () {
        fs.file(kMacOSExecutable).createSync(recursive: true);
        fs.file('chrome_foo').createSync();
        return null;
      }, overrides: <Type, Generator>{
        Platform: () => mockPlatform,
      });
      webValidator = const WebValidator();
      mockPlatform = MockPlatform();
      when(mockPlatform.isMacOS).thenReturn(true);
      when(mockPlatform.isWindows).thenReturn(false);
      when(mockPlatform.isLinux).thenReturn(false);
    });

    test('Can find macOS executable ', () => testbed.run(() async {
      final ValidationResult result = await webValidator.validate();
      expect(result.type, ValidationType.installed);
    }));

    test('Can notice missing macOS executable ', () => testbed.run(() async {
      fs.file(kMacOSExecutable).deleteSync();
      final ValidationResult result = await webValidator.validate();
      expect(result.type, ValidationType.missing);
    }));
  });
}

class MockPlatform extends Mock implements Platform  {
  @override
  Map<String, String> get environment => const <String, String>{};
}
