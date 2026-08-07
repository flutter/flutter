// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/environment/environment.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';
import '../../../src/fakes.dart';

void main() {
  late BufferLogger logger;
  late MemoryFileSystem fs;
  late FakeProcessManager processManager;

  setUp(() {
    logger = BufferLogger.test();
    fs = MemoryFileSystem.test();
    processManager = FakeProcessManager.empty();
  });

  group(AndroidCompatibilityChecker, () {
    testWithoutContext('returns true if java runs and sdkDir is null', () {
      final os = _FakeOperatingSystemUtils();
      fs.directory('/jdk/bin').createSync(recursive: true);
      fs.file('/jdk/bin/java').createSync();

      processManager.addCommand(const FakeCommand(command: <String>['/jdk/bin/java']));

      final checker = AndroidCompatibilityChecker(
        fileSystem: fs,
        processManager: processManager,
        platform: FakePlatform(),
        operatingSystemUtils: os,
        logger: logger,
      );

      final bool isCompatible = checker.isCompatiblePair((
        path: '/jdk',
        source: JavaSource.flutterConfig,
      ), null);
      expect(isCompatible, true);
    });

    testWithoutContext(
      'returns false if java is incompatible with sdkmanager (UnsupportedClassVersionError)',
      () {
        final os = _FakeOperatingSystemUtils();
        fs.file('/jdk/bin/java').createSync(recursive: true);
        fs.file('/sdk/cmdline-tools/latest/bin/sdkmanager').createSync(recursive: true);

        processManager.addCommand(
          const FakeCommand(
            command: <String>['/sdk/cmdline-tools/latest/bin/sdkmanager', '--version'],
            exitCode: 1,
            stderr: 'Exception in thread "main" java.lang.UnsupportedClassVersionError',
          ),
        );

        final checker = AndroidCompatibilityChecker(
          fileSystem: fs,
          processManager: processManager,
          platform: FakePlatform(),
          operatingSystemUtils: os,
          logger: logger,
        );

        final bool isCompatible = checker.isCompatiblePair((
          path: '/jdk',
          source: JavaSource.flutterConfig,
        ), fs.directory('/sdk'));
        expect(isCompatible, false);
        expect(logger.traceText, contains('incompatible with sdkmanager'));
      },
    );
  });
}

class _FakeOperatingSystemUtils extends FakeOperatingSystemUtils {
  @override
  File? which(String execName) => null;

  @override
  List<File> whichAll(String execName) => <File>[];
}
