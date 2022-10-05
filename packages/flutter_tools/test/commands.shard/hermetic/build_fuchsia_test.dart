// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_fuchsia.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_kernel_compiler.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_pm.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

// Defined globally for fakes to use.
FileSystem fileSystem;

void main() {
  Cache.disableLocking();

  final Platform linuxPlatform = FakePlatform(
    environment: const <String, String>{
      'FLUTTER_ROOT': '/',
    },
  );
  final Platform windowsPlatform = FakePlatform(
    operatingSystem: 'windows',
    environment: const <String, String>{
      'FLUTTER_ROOT': '/',
    },
  );
  FakeFuchsiaSdk fuchsiaSdk;

  setUp(() {
    fuchsiaSdk = FakeFuchsiaSdk();
    fileSystem = MemoryFileSystem.test();
  });

  group('Fuchsia build fails gracefully when', () {
    testUsingContext('The feature is disabled', () async {
      final BuildCommand command = BuildCommand();
      fileSystem.directory('fuchsia').createSync(recursive: true);
      fileSystem.file('.packages').createSync();
      fileSystem.file('pubspec.yaml').createSync();
      fileSystem.file('lib/main.dart').createSync(recursive: true);

      expect(
        createTestCommandRunner(command).run(const <String>['build', 'fuchsia']),
        throwsToolExit(message: '"build fuchsia" is currently disabled'),
      );
    }, overrides: <Type, Generator>{
      Platform: () => linuxPlatform,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FeatureFlags: () => TestFeatureFlags(),
    });
    testUsingContext('there is no Fuchsia project', () async {
      final BuildCommand command = BuildCommand();

      expect(
        createTestCommandRunner(command).run(const <String>['build', 'fuchsia']),
        throwsToolExit(),
      );
    }, overrides: <Type, Generator>{
      Platform: () => linuxPlatform,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FeatureFlags: () => TestFeatureFlags(isFuchsiaEnabled: true),
    });

    testUsingContext('there is no cmx file', () async {
      final BuildCommand command = BuildCommand();
      fileSystem.directory('fuchsia').createSync(recursive: true);
      fileSystem.file('.packages').createSync();
      fileSystem.file('pubspec.yaml').createSync();

      expect(
        createTestCommandRunner(command).run(const <String>['build', 'fuchsia']),
        throwsToolExit(),
      );
    }, overrides: <Type, Generator>{
      Platform: () => linuxPlatform,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FeatureFlags: () => TestFeatureFlags(isFuchsiaEnabled: true),
    });

    testUsingContext('on Windows platform', () async {
      final BuildCommand command = BuildCommand();
      const String appName = 'app_name';
      fileSystem
        .file(fileSystem.path.join('fuchsia', 'meta', '$appName.cmx'))
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');
      fileSystem.file('.packages').createSync();
      final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync('name: $appName');

      final bool supported = BuildFuchsiaCommand(verboseHelp: false).supported;
      expect(
        createTestCommandRunner(command).run(const <String>['build', 'fuchsia']),
        supported ? throwsToolExit() : throwsA(isA<UsageException>()),
      );
    }, overrides: <Type, Generator>{
      Platform: () => windowsPlatform,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FeatureFlags: () => TestFeatureFlags(isFuchsiaEnabled: true),
    });

    testUsingContext('there is no Fuchsia kernel compiler', () async {
      final BuildCommand command = BuildCommand();
      const String appName = 'app_name';
      fileSystem
        .file(fileSystem.path.join('fuchsia', 'meta', '$appName.cmx'))
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');
      fileSystem.file('.packages').createSync();
      fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
      final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync('name: $appName');

      expect(
        createTestCommandRunner(command).run(const <String>['build', 'fuchsia']),
        throwsToolExit(),
      );
    }, overrides: <Type, Generator>{
      Platform: () => linuxPlatform,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FeatureFlags: () => TestFeatureFlags(isFuchsiaEnabled: true),
    });
  });

  testUsingContext('Fuchsia build parts fit together right', () async {
    final BuildCommand command = BuildCommand();
    const String appName = 'app_name';
    fileSystem
        .file(fileSystem.path.join('fuchsia', 'meta', '$appName.cmx'))
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
    final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
    pubspecFile.writeAsStringSync('name: $appName');

    await createTestCommandRunner(command)
      .run(const <String>['build', 'fuchsia']);
    final String farPath = fileSystem.path.join(
      getFuchsiaBuildDirectory(), 'pkg', 'app_name-0.far',
    );

    expect(fileSystem.file(farPath), exists);
  }, overrides: <Type, Generator>{
    Platform: () => linuxPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    FuchsiaSdk: () => fuchsiaSdk,
    FeatureFlags: () => TestFeatureFlags(isFuchsiaEnabled: true),
  });
}

class FakeFuchsiaPM extends Fake implements FuchsiaPM {
  String _appName;

  @override
  Future<bool> init(String buildPath, String appName) async {
    if (!fileSystem.directory(buildPath).existsSync()) {
      return false;
    }
    fileSystem
        .file(fileSystem.path.join(buildPath, 'meta', 'package'))
        .createSync(recursive: true);
    _appName = appName;
    return true;
  }

  @override
  Future<bool> build(String buildPath, String manifestPath) async {
    if (!fileSystem.file(fileSystem.path.join(buildPath, 'meta', 'package')).existsSync() ||
        !fileSystem.file(manifestPath).existsSync()) {
      return false;
    }
    fileSystem.file(fileSystem.path.join(buildPath, 'meta.far')).createSync(recursive: true);
    return true;
  }

  @override
  Future<bool> archive(String buildPath, String manifestPath) async {
    if (!fileSystem.file(fileSystem.path.join(buildPath, 'meta', 'package')).existsSync() ||
        !fileSystem.file(manifestPath).existsSync()) {
      return false;
    }
    if (_appName == null) {
      return false;
    }
    fileSystem
        .file(fileSystem.path.join(buildPath, '$_appName-0.far'))
        .createSync(recursive: true);
    return true;
  }
}

class FakeFuchsiaKernelCompiler extends Fake implements FuchsiaKernelCompiler {
  @override
  Future<void> build({
    @required FuchsiaProject fuchsiaProject,
    @required String target, // E.g., lib/main.dart
    BuildInfo buildInfo = BuildInfo.debug,
  }) async {
    final String outDir = getFuchsiaBuildDirectory();
    final String appName = fuchsiaProject.project.manifest.appName;
    final String manifestPath = fileSystem.path.join(outDir, '$appName.dilpmanifest');
    fileSystem.file(manifestPath).createSync(recursive: true);
  }
}

class FakeFuchsiaSdk extends Fake implements FuchsiaSdk {
  @override
  final FuchsiaPM fuchsiaPM = FakeFuchsiaPM();

  @override
  final FuchsiaKernelCompiler fuchsiaKernelCompiler =
      FakeFuchsiaKernelCompiler();
}
