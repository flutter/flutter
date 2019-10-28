// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_kernel_compiler.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_pm.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  Cache.disableLocking();

  MockPlatform linuxPlatform;
  MockPlatform windowsPlatform;
  MockFuchsiaSdk fuchsiaSdk;

  setUp(() {
    linuxPlatform = MockPlatform();
    windowsPlatform = MockPlatform();
    fuchsiaSdk = MockFuchsiaSdk();

    when(linuxPlatform.isLinux).thenReturn(true);
    when(linuxPlatform.isWindows).thenReturn(false);
    when(linuxPlatform.isMacOS).thenReturn(false);
    when(windowsPlatform.isWindows).thenReturn(true);
    when(windowsPlatform.isLinux).thenReturn(false);
    when(windowsPlatform.isMacOS).thenReturn(false);
  });

  group('Fuchsia build fails gracefully when', () {
    testUsingContext('there is no Fuchsia project', () async {
      final BuildCommand command = BuildCommand();
      applyMocksToCommand(command);
      expect(
          createTestCommandRunner(command)
              .run(const <String>['build', 'fuchsia']),
          throwsA(isInstanceOf<ToolExit>()));
    }, overrides: <Type, Generator>{
      Platform: () => linuxPlatform,
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('there is no cmx file', () async {
      final BuildCommand command = BuildCommand();
      applyMocksToCommand(command);
      fs.directory('fuchsia').createSync(recursive: true);
      fs.file('.packages').createSync();
      fs.file('pubspec.yaml').createSync();

      expect(
          createTestCommandRunner(command)
              .run(const <String>['build', 'fuchsia']),
          throwsA(isInstanceOf<ToolExit>()));
    }, overrides: <Type, Generator>{
      Platform: () => linuxPlatform,
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('on Windows platform', () async {
      final BuildCommand command = BuildCommand();
      applyMocksToCommand(command);
      const String appName = 'app_name';
      fs
          .file(fs.path.join('fuchsia', 'meta', '$appName.cmx'))
          ..createSync(recursive: true)
          ..writeAsStringSync('{}');
      fs.file('.packages').createSync();
      final File pubspecFile = fs.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync('name: $appName');

      expect(
          createTestCommandRunner(command)
              .run(const <String>['build', 'fuchsia']),
          throwsA(isInstanceOf<ToolExit>()));
    }, overrides: <Type, Generator>{
      Platform: () => windowsPlatform,
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('there is no Fuchsia kernel compiler', () async {
      final BuildCommand command = BuildCommand();
      applyMocksToCommand(command);
      const String appName = 'app_name';
      fs
          .file(fs.path.join('fuchsia', 'meta', '$appName.cmx'))
          ..createSync(recursive: true)
          ..writeAsStringSync('{}');
      fs.file('.packages').createSync();
      fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      final File pubspecFile = fs.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync('name: $appName');
      expect(
          createTestCommandRunner(command)
              .run(const <String>['build', 'fuchsia']),
          throwsA(isInstanceOf<ToolExit>()));
    }, overrides: <Type, Generator>{
      Platform: () => linuxPlatform,
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  testUsingContext('Fuchsia build parts fit together right', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    const String appName = 'app_name';
    fs
        .file(fs.path.join('fuchsia', 'meta', '$appName.cmx'))
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');
    fs.file('.packages').createSync();
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    final File pubspecFile = fs.file('pubspec.yaml')..createSync();
    pubspecFile.writeAsStringSync('name: $appName');

    await createTestCommandRunner(command)
        .run(const <String>['build', 'fuchsia']);
    final String farPath =
        fs.path.join(getFuchsiaBuildDirectory(), 'pkg', 'app_name-0.far');
    expect(fs.file(farPath).existsSync(), isTrue);
  }, overrides: <Type, Generator>{
    Platform: () => linuxPlatform,
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
    FuchsiaSdk: () => fuchsiaSdk,
  });
}

class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': '/',
  };
}

class MockFuchsiaPM extends Mock implements FuchsiaPM {
  String _appName;

  @override
  Future<bool> init(String buildPath, String appName) async {
    if (!fs.directory(buildPath).existsSync()) {
      return false;
    }
    fs
        .file(fs.path.join(buildPath, 'meta', 'package'))
        .createSync(recursive: true);
    _appName = appName;
    return true;
  }

  @override
  Future<bool> genkey(String buildPath, String outKeyPath) async {
    if (!fs.file(fs.path.join(buildPath, 'meta', 'package')).existsSync()) {
      return false;
    }
    fs.file(outKeyPath).createSync(recursive: true);
    return true;
  }

  @override
  Future<bool> build(String buildPath, String keyPath, String manifestPath) async {
    if (!fs.file(fs.path.join(buildPath, 'meta', 'package')).existsSync() ||
        !fs.file(keyPath).existsSync() ||
        !fs.file(manifestPath).existsSync()) {
      return false;
    }
    fs.file(fs.path.join(buildPath, 'meta.far')).createSync(recursive: true);
    return true;
  }

  @override
  Future<bool> archive(String buildPath, String keyPath, String manifestPath) async {
    if (!fs.file(fs.path.join(buildPath, 'meta', 'package')).existsSync() ||
        !fs.file(keyPath).existsSync() ||
        !fs.file(manifestPath).existsSync()) {
      return false;
    }
    if (_appName == null) {
      return false;
    }
    fs
        .file(fs.path.join(buildPath, '$_appName-0.far'))
        .createSync(recursive: true);
    return true;
  }
}

class MockFuchsiaKernelCompiler extends Mock implements FuchsiaKernelCompiler {
  @override
  Future<void> build({
    @required FuchsiaProject fuchsiaProject,
    @required String target, // E.g., lib/main.dart
    BuildInfo buildInfo = BuildInfo.debug,
  }) async {
    final String outDir = getFuchsiaBuildDirectory();
    final String appName = fuchsiaProject.project.manifest.appName;
    final String manifestPath = fs.path.join(outDir, '$appName.dilpmanifest');
    fs.file(manifestPath).createSync(recursive: true);
  }
}

class MockFuchsiaSdk extends Mock implements FuchsiaSdk {
  @override
  final FuchsiaPM fuchsiaPM = MockFuchsiaPM();

  @override
  final FuchsiaKernelCompiler fuchsiaKernelCompiler =
      MockFuchsiaKernelCompiler();
}
