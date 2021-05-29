// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/web_validator.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  Platform platform;
  FakeProcessManager fakeProcessManager;
  ChromiumLauncher chromeLauncher;
  FileSystem fileSystem;
  ChromiumValidator webValidator;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    fakeProcessManager = FakeProcessManager.list(<FakeCommand>[]);
    platform = FakePlatform(
      operatingSystem: 'macos',
      environment: <String, String>{},
    );
    chromeLauncher = ChromiumLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: fakeProcessManager,
      operatingSystemUtils: null,
      browserFinder: findChromeExecutable,
      logger: BufferLogger.test(),
    );
    webValidator = webValidator = ChromeValidator(
      platform: platform,
      chromiumLauncher: chromeLauncher,
    );
  });

  testWithoutContext('WebValidator can find executable on macOS', () async {
    final ValidationResult result = await webValidator.validate();

    expect(result.type, ValidationType.installed);
  });

  testWithoutContext('WebValidator Can notice missing macOS executable ', () async {
    fakeProcessManager.excludedExecutables.add(kMacOSExecutable);

    final ValidationResult result = await webValidator.validate();

    expect(result.type, ValidationType.missing);
  });

  testWithoutContext('WebValidator does not warn about CHROME_EXECUTABLE unless it cant find chrome ', () async {
    fakeProcessManager.excludedExecutables.add(kMacOSExecutable);

    final ValidationResult result = await webValidator.validate();

    expect(result.messages, const <ValidationMessage>[
      ValidationMessage.hint(
          'Cannot find Chrome. Try setting CHROME_EXECUTABLE to a Chrome executable.'),
    ]);
    expect(result.type, ValidationType.missing);
  });
}
