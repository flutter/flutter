// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/test/test_wrapper.dart';

import '../../bin/fuchsia_tester.dart' as fuchsia_tester;
import '../src/common.dart';
import '../src/fakes.dart';

void main() {
  tearDown(() {
    exitCode = 0;
  });

  testWithoutContext(
    'fuchsia_tester.run executes hermetically without an ambient AppContext zone',
    () async {
      final fs = MemoryFileSystem.test();
      final artifacts = Artifacts.test(fileSystem: fs);
      final toolContext = FakeToolContext(
        artifacts: artifacts,
        fs: fs,
        platform: FakePlatform(numberOfProcessors: 4),
      );
      final testWrapper = _FakeTestWrapper(configuredExitCode: 42);

      final Directory workDir = fs.currentDirectory.childDirectory('fuchsia_test');
      final File packagesFile =
          workDir.childDirectory('.dart_tool').childFile('package_config.json')
            ..createSync(recursive: true)
            ..writeAsStringSync('{"configVersion": 2, "packages": []}');
      final File shellFile = workDir.childFile('flutter_tester')..createSync(recursive: true);
      final Directory sdkRootDir = workDir.childDirectory('sdk_root')..createSync(recursive: true);
      final File strongDillFile = sdkRootDir.childFile('platform_strong.dill')..createSync();
      final File icudtlFile = workDir.childFile('icudtl.dat')..createSync();
      final File testSourceFile = workDir.childFile('widget_test.dart')..createSync();
      final File testDillFile = workDir.childFile('widget_test.dart.dill')..createSync();
      final File testsManifestFile = workDir.childFile('tests.json')
        ..writeAsStringSync(
          jsonEncode(<Map<String, String>>[
            <String, String>{'source': testSourceFile.path, 'dill': testDillFile.path},
          ]),
        );

      await fuchsia_tester.run(
        <String>[
          '--packages=${packagesFile.path}',
          '--shell=${shellFile.path}',
          '--sdk-root=${sdkRootDir.path}',
          '--icudtl=${icudtlFile.path}',
          '--tests=${testsManifestFile.path}',
        ],
        toolContext: toolContext,
        testWrapper: testWrapper,
      );

      final Link testerLink = fs.link(artifacts.getArtifactPath(Artifact.flutterTester));
      expect(testerLink.existsSync(), isTrue);
      expect(testerLink.targetSync(), fs.path.absolute(shellFile.path));

      final Directory patchedSdkDir = fs.directory(
        artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath),
      );
      expect(
        fs.link(patchedSdkDir.childFile('platform_strong.dill').path).targetSync(),
        strongDillFile.path,
      );
      expect(
        fs.link(patchedSdkDir.childFile('platform.dill').path).targetSync(),
        'platform_strong.dill',
      );

      expect(testWrapper.registeredRuntimes, contains(Runtime.vm));
      expect(testWrapper.lastArgs, isNotNull);
      expect(
        testWrapper.lastArgs,
        containsAll(<String>[
          '--concurrency=2',
          '--chain-stack-traces',
          Uri.file(testSourceFile.resolveSymbolicLinksSync()).toString(),
        ]),
      );
      expect(exitCode, 42);
    },
  );

  testWithoutContext(
    'fuchsia_tester.run throws ToolExit when shell binary or sdk-root is invalid',
    () async {
      final fs = MemoryFileSystem.test();
      final toolContext = FakeToolContext(
        artifacts: Artifacts.test(fileSystem: fs),
        fs: fs,
      );
      final Directory workDir = fs.currentDirectory.childDirectory('invalid_inputs')
        ..createSync(recursive: true);
      final File packagesFile = workDir.childFile('package_config.json')..createSync();
      final Directory shellAsDir = workDir.childDirectory('not_a_file')..createSync();
      final File shellFile = workDir.childFile('flutter_tester')..createSync();
      final Directory sdkRootDir = workDir.childDirectory('sdk_root')..createSync();
      final File icudtlFile = workDir.childFile('icudtl.dat')..createSync();
      final File testsManifestFile = workDir.childFile('tests.json')..writeAsStringSync('[]');

      await expectLater(
        fuchsia_tester.run(
          <String>[
            '--packages=${packagesFile.path}',
            '--shell=${shellAsDir.path}',
            '--sdk-root=${sdkRootDir.path}',
            '--icudtl=${icudtlFile.path}',
            '--tests=${testsManifestFile.path}',
          ],
          toolContext: toolContext,
          testWrapper: _FakeTestWrapper(),
        ),
        throwsToolExit(message: 'Cannot find Flutter shell at'),
      );

      await expectLater(
        fuchsia_tester.run(
          <String>[
            '--packages=${packagesFile.path}',
            '--shell=${shellFile.path}',
            '--sdk-root=${workDir.childDirectory('missing_sdk').path}',
            '--icudtl=${icudtlFile.path}',
            '--tests=${testsManifestFile.path}',
          ],
          toolContext: toolContext,
          testWrapper: _FakeTestWrapper(),
        ),
        throwsToolExit(message: 'Cannot find SDK files at'),
      );
    },
  );
}

class _FakeTestWrapper implements TestWrapper {
  _FakeTestWrapper({this.configuredExitCode = 0});

  final int configuredExitCode;
  final registeredRuntimes = <Runtime>[];
  List<String>? lastArgs;

  @override
  Future<void> main(List<String> args) async {
    lastArgs = args;
    exitCode = configuredExitCode;
  }

  @override
  void registerPlatformPlugin(
    Iterable<Runtime> runtimes,
    FutureOr<PlatformPlugin> Function() platforms,
  ) {
    registeredRuntimes.addAll(runtimes);
  }
}
