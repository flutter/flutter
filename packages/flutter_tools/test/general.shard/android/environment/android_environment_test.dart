// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/environment/environment.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';
import '../../../src/fakes.dart';

void main() {
  late Config config;
  late BufferLogger logger;
  late MemoryFileSystem fs;
  late FakeProcessManager processManager;

  setUp(() {
    config = Config.test();
    logger = BufferLogger.test();
    fs = MemoryFileSystem.test();
    processManager = FakeProcessManager.empty();
  });

  group(AndroidEnvironmentResolver, () {
    testWithoutContext('short-circuits and skips incompatible Java candidates', () {
      final os = _FakeOperatingSystemUtils();

      // Setup JDK 22 (incompatible) and Studio JDK 17 (compatible)
      fs.file('/jdk22/bin/java').createSync(recursive: true);
      fs.file('/studio-jdk17/bin/java').createSync(recursive: true);
      fs.file('/sdk/cmdline-tools/latest/bin/sdkmanager').createSync(recursive: true);
      fs.directory('/sdk/platform-tools').createSync(recursive: true);

      processManager.addCommand(
        const FakeCommand(
          command: <String>['/sdk/cmdline-tools/latest/bin/sdkmanager', '--version'],
          exitCode: 1,
        ),
      );

      processManager.addCommand(
        const FakeCommand(
          command: <String>['/sdk/cmdline-tools/latest/bin/sdkmanager', '--version'],
        ),
      );

      final javaLocator = _FakeJavaLocator(<JavaHomeCandidate>[
        (path: '/jdk22', source: JavaSource.flutterConfig),
        (path: '/studio-jdk17', source: JavaSource.androidStudio),
      ]);
      final sdkLocator = _FakeSdkLocator(<Directory>[fs.directory('/sdk')]);

      final resolver = AndroidEnvironmentResolver(
        javaLocator: javaLocator,
        sdkLocator: sdkLocator,
        compatibilityChecker: AndroidCompatibilityChecker(
          fileSystem: fs,
          processManager: processManager,
          platform: FakePlatform(),
          operatingSystemUtils: os,
          logger: logger,
        ),
        fileSystem: fs,
        config: config,
        logger: logger,
        platform: FakePlatform(),
        processManager: processManager,
      );

      final ResolvedAndroidEnvironment? resolved = resolver.resolve();
      expect(resolved, isNotNull);
      expect(resolved!.sdk, isNotNull);
      expect(resolved.java, isNotNull);
      expect(resolved.java!.javaHome, '/studio-jdk17');
      expect(resolved.java!.javaSource, JavaSource.androidStudio);
      expect(resolved.incompatibleJavaCandidates.length, 1);
      expect(resolved.incompatibleJavaCandidates.first.path, '/jdk22');

      // Verify memoization: calling resolve() again doesn't re-run commands
      final ResolvedAndroidEnvironment? second = resolver.resolve();
      expect(second, same(resolved));
    });
  });
}

class _FakeOperatingSystemUtils extends FakeOperatingSystemUtils {
  @override
  File? which(String execName) => null;

  @override
  List<File> whichAll(String execName) => <File>[];
}

class _FakeJavaLocator implements CandidateLocator<JavaHomeCandidate> {
  _FakeJavaLocator(this._candidates);
  final List<JavaHomeCandidate> _candidates;
  @override
  Iterable<JavaHomeCandidate> get candidates => _candidates;
}

class _FakeSdkLocator implements CandidateLocator<Directory> {
  _FakeSdkLocator(this._candidates);
  final List<Directory> _candidates;
  @override
  Iterable<Directory> get candidates => _candidates;
}
