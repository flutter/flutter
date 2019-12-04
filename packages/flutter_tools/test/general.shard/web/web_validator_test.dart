// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/web_validator.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  group('WebValidator', () {
    Testbed testbed;
    WebValidator webValidator;
    MockPlatform mockPlatform;
    MockProcessManager mockProcessManager;

    setUp(() {
      mockProcessManager = MockProcessManager();
      testbed = Testbed(setup: () {
        when(mockProcessManager.canRun(kMacOSExecutable)).thenReturn(true);
        return null;
      }, overrides: <Type, Generator>{
        Platform: () => mockPlatform,
        ProcessManager: () => mockProcessManager,
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
      when(mockProcessManager.canRun(kMacOSExecutable)).thenReturn(false);
      final ValidationResult result = await webValidator.validate();
      expect(result.type, ValidationType.missing);
    }));

    test('Doesn\'t warn about CHROME_EXECUTABLE unless it cant find chrome ', () => testbed.run(() async {
      when(mockProcessManager.canRun(kMacOSExecutable)).thenReturn(false);
      final ValidationResult result = await webValidator.validate();
      expect(result.messages, <ValidationMessage>[
        ValidationMessage.hint('Cannot find Chrome. Try setting CHROME_EXECUTABLE to a Chrome executable.'),
      ]);
      expect(result.type, ValidationType.missing);
    }));
  });
}

class MockPlatform extends Mock implements Platform  {
  @override
  Map<String, String> get environment => const <String, String>{};
}

class MockProcessManager extends Mock implements ProcessManager {}
