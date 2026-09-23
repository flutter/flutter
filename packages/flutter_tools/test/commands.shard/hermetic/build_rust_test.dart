// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/bundle.dart' show defaultManifestPath;
import 'package:flutter_tools/src/bundle_builder.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_rust.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import '../../src/test_flutter_command_runner.dart';

final Platform linuxPlatform = FakePlatform();
final Platform notLinuxPlatform = FakePlatform(operatingSystem: 'windows');

void main() {
  late MemoryFileSystem fileSystem;
  late BufferLogger logger;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
  });

  void setUpMockRustProject() {
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('''
name: rust_app
environment:
  sdk: ^3.9.0
flutter:
  shell: rust
''');
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'rust_app');
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
    fileSystem.file('runner-rs/Cargo.toml').createSync(recursive: true);
  }

  BuildRustCommand createCommand({
    Platform? platform,
    ProcessManager? processManager,
    BundleBuilder? bundleBuilder,
  }) {
    final Platform effectivePlatform = platform ?? (context.get<Platform>() ?? linuxPlatform);
    final ProcessManager effectiveProcessManager =
        processManager ?? context.get<ProcessManager>() ?? FakeProcessManager.any();
    final toolContext = FakeToolContext(
      cache: Cache.test(
        rootOverride: fileSystem.directory('flutter'),
        logger: logger,
        processManager: effectiveProcessManager,
      ),
      fs: fileSystem,
      logger: logger,
      platform: effectivePlatform,
      processManager: effectiveProcessManager,
      projectFactory: FlutterProjectFactory(fileSystem: fileSystem, logger: logger),
    );
    return BuildRustCommand(
      toolContext: toolContext,
      verboseHelp: false,
      bundleBuilder: bundleBuilder ?? FakeBundleBuilder(),
    );
  }

  testUsingContext(
    'is hidden on non-Linux hosts',
    () async {
      final BuildRustCommand command = createCommand(platform: notLinuxPlatform);
      expect(command.hidden, true);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'is not hidden on Linux hosts',
    () async {
      final BuildRustCommand command = createCommand(platform: linuxPlatform);
      expect(command.hidden, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'fails on non-Linux hosts',
    () async {
      setUpMockRustProject();
      final BuildRustCommand command = createCommand(platform: notLinuxPlatform);

      await expectLater(
        createTestCommandRunner(command).run(const <String>['rust', '--no-pub']),
        throwsToolExit(message: '"build rust" only supported on Linux hosts.'),
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'fails when the project does not use the Rust shell',
    () async {
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('''
name: not_rust_app
environment:
  sdk: ^3.9.0
''');
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'not_rust_app');
      fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
      final BuildRustCommand command = createCommand();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['rust', '--no-pub']),
        throwsToolExit(
          message:
              'No Rust-shell project configured. Run `flutter create --shell=rust '
              '--platforms=linux .` first.',
        ),
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'rejects profile mode',
    () async {
      setUpMockRustProject();
      final BuildRustCommand command = createCommand();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['rust', '--no-pub', '--profile']),
        throwsToolExit(
          message: 'The Flutter Rust shell currently supports debug and release modes only.',
        ),
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'builds the release runner with cargo and reports the built executable',
    () async {
      setUpMockRustProject();
      fileSystem.file('runner-rs/Cargo.lock').createSync(recursive: true);
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['cargo', 'build', '--release', '--locked'],
          workingDirectory: '/runner-rs',
        ),
      ]);
      final BuildRustCommand command = createCommand(processManager: processManager);

      await createTestCommandRunner(command).run(const <String>['rust', '--no-pub', '--release']);

      expect(processManager.hasRemainingExpectations, false);
      expect(
        logger.statusText,
        contains(fileSystem.path.join('runner-rs', 'target', 'release', 'rust_app')),
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'builds the debug runner without --release or --locked when there is no lockfile',
    () async {
      setUpMockRustProject();
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['cargo', 'build'], workingDirectory: '/runner-rs'),
      ]);
      final BuildRustCommand command = createCommand(processManager: processManager);

      await createTestCommandRunner(command).run(const <String>['rust', '--no-pub', '--debug']);

      expect(processManager.hasRemainingExpectations, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'fails when cargo build exits non-zero',
    () async {
      setUpMockRustProject();
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['cargo', 'build'],
          workingDirectory: '/runner-rs',
          exitCode: 1,
        ),
      ]);
      final BuildRustCommand command = createCommand(processManager: processManager);

      await expectLater(
        createTestCommandRunner(command).run(const <String>['rust', '--no-pub', '--debug']),
        throwsToolExit(message: 'Unable to build the Rust shell runner.'),
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );
}

class FakeBundleBuilder extends Fake implements BundleBuilder {
  @override
  Future<void> build({
    required TargetPlatform platform,
    required BuildInfo buildInfo,
    FlutterProject? project,
    String? mainPath,
    String manifestPath = defaultManifestPath,
    String? applicationKernelFilePath,
    String? depfilePath,
    String? assetDirPath,
    BuildSystem? buildSystem,
    Target? target,
  }) async {}
}
