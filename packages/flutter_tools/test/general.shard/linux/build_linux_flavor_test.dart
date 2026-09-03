// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/cmake.dart';
import 'package:flutter_tools/src/cmake_project.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

const _kTestFlutterRoot = '/flutter';

final Platform linuxPlatform = FakePlatform(
  environment: <String, String>{'FLUTTER_ROOT': _kTestFlutterRoot, 'HOME': '/'},
);

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  late MemoryFileSystem fileSystem;
  late FakeProcessManager processManager;
  late Logger logger;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    Cache.flutterRoot = _kTestFlutterRoot;
    logger = BufferLogger.test();
    processManager = FakeProcessManager.empty();
  });

  void setUpMockProjectFilesForBuild() {
    fileSystem.file('pubspec.yaml').createSync();
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
    fileSystem.file(fileSystem.path.join('linux', 'CMakeLists.txt'))
      ..createSync(recursive: true)
      ..writeAsStringSync('set(BINARY_NAME "my_app")\n');
  }

  FakeCommand cmakeFlavorCommand(String buildMode, String flavor) {
    return FakeCommand(
      command: <String>[
        'cmake',
        '-G',
        'Ninja',
        '-DCMAKE_BUILD_TYPE=${sentenceCase(buildMode)}',
        '-DFLUTTER_TARGET_PLATFORM=linux-x64',
        '/linux',
      ],
      workingDirectory: '/build/linux/x64/$flavor/$buildMode',
    );
  }

  FakeCommand ninjaFlavorCommand(String buildMode, String flavor) {
    return FakeCommand(
      command: <String>['ninja', '-C', '/build/linux/x64/$flavor/$buildMode', 'install'],
    );
  }

  BuildCommand makeBuildCommand() {
    return BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: fileSystem,
      logger: logger,
      osUtils: FakeOperatingSystemUtils(),
      config: FakeConfig(),
      platform: FakePlatform(),
      fileSystemUtils: FakeFileSystemUtils(),
      terminal: FakeTerminal(),
      plistParser: FakePlistParser(),
      processUtils: FakeProcessUtils(),
      processManager: FakeProcessManager.any(),
      templateRenderer: FakeTemplateRenderer(),
      xcode: FakeXcode(),
      artifacts: FakeArtifacts(),
      cache: FakeCache(),
      flutterVersion: FakeFlutterVersion(),
    );
  }

  testUsingContext(
    'Linux build with --flavor uses a flavor-specific build dir',
    () async {
      final BuildCommand command = makeBuildCommand();
      processManager.addCommands(<FakeCommand>[
        cmakeFlavorCommand('release', 'apple'),
        ninjaFlavorCommand('release', 'apple'),
      ]);
      setUpMockProjectFilesForBuild();

      await createTestCommandRunner(
        command,
      ).run(const <String>['build', 'linux', '--no-pub', '--flavor', 'apple']);

      expect(processManager.hasRemainingExpectations, isFalse);
      expect(testLogger.statusText, contains('✓ Built build/linux/x64/apple/release/bundle'));
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Platform: () => linuxPlatform,
      FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
      OperatingSystemUtils: () => FakeOperatingSystemUtils(),
    },
  );

  test('getCmakeExecutableName returns the binary name without a flavor suffix', () {
    final fs = MemoryFileSystem.test();
    final File cmake = fs.file('linux/CMakeLists.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('set(BINARY_NAME "my_app")\n');

    final project = _FakeCmakeProject(cmake);
    expect(getCmakeExecutableName(project), 'my_app');
  });
}

class _FakeCmakeProject extends Fake implements CmakeBasedProject {
  _FakeCmakeProject(this._cmakeFile);
  final File _cmakeFile;
  @override
  File get cmakeFile => _cmakeFile;
}
