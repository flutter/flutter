// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('OperatingSystemUtils', () {
    late Directory tempDir;
    late FileSystem fileSystem;

    setUp(() {
      fileSystem = LocalFileSystem.test(signals: FakeSignals());
      tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_tools_os_utils_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testWithoutContext('makeExecutable', () async {
      const Platform platform = LocalPlatform();
      final operatingSystemUtils = OperatingSystemUtils(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: platform,
        processManager: const LocalProcessManager(),
      );
      final File file = fileSystem.file(fileSystem.path.join(tempDir.path, 'foo.script'));
      file.writeAsStringSync('hello world');
      operatingSystemUtils.makeExecutable(file);

      // Skip this test on windows.
      if (!platform.isWindows) {
        final String mode = file.statSync().modeString();
        // rwxr--r--
        expect(mode.substring(0, 3), endsWith('x'));
      }
    });
  });
}
