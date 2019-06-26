// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tool_api/doctor.dart';

import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import 'package:platform/platform.dart';
import 'package:web_extension/main.dart';

void main() {
  group('FlutterWebExtension', () {
    FlutterWebExtension webExtension;
    MockPlatform mockPlatform;
    MockProcessManager mockProcessManager;

    setUp(() {
      mockProcessManager = MockProcessManager();
      mockPlatform = MockPlatform();
      webExtension = FlutterWebExtension();
      when(mockPlatform.isMacOS).thenReturn(true);
      when(mockPlatform.isWindows).thenReturn(false);
      when(mockPlatform.isLinux).thenReturn(false);
      when(mockProcessManager.canRun(any)).thenReturn(true);
      webExtension.processManager = mockProcessManager;
      webExtension.platform = mockPlatform;
    });

    test('Can find macOS executable ', () async {
      final ValidationResult result = await webExtension.doctorDomain.diagnose(const <String, Object>{});
      expect(result.type, ValidationType.installed);
    });

    test('Can notice missing macOS executable ', () async {
      when(mockProcessManager.canRun(kMacOSExecutable)).thenReturn(false);
      final ValidationResult result = await webExtension.doctorDomain.diagnose(const <String, Object>{});
      expect(result.type, ValidationType.missing);
    });

    test('Doesn\'t warn about CHROME_EXECUTABLE unless it cant find chrome ', () async {
      when(mockProcessManager.canRun(kMacOSExecutable)).thenReturn(false);
      final ValidationResult result = await webExtension.doctorDomain.diagnose(const <String, Object>{});
      expect(result.messages, const <ValidationMessage>[
        ValidationMessage('CHROME_EXECUTABLE not set', type: ValidationMessageType.hint)
      ]);
      expect(result.type, ValidationType.missing);
    });
  });
}

class MockPlatform extends Mock implements Platform  {
  @override
  Map<String, String> get environment => const <String, String>{};
}

class MockProcessManager extends Mock implements ProcessManager {}
