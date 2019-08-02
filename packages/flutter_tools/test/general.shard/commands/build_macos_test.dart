// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/macos/application_package.dart';
import 'package:flutter_tools/src/macos/build_macos.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

void main() {
  MemoryFileSystem memoryFilesystem;
  MockProcess mockProcess;
  MockPlatform macosPlatform;
  MockPlatform notMacosPlatform;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    memoryFilesystem = MemoryFileSystem();
    mockProcess = MockProcess();
    macosPlatform = MockPlatform();
    notMacosPlatform = MockPlatform();
    when(mockProcess.exitCode).thenAnswer((Invocation invocation) async {
    return 0;
    });
    when(mockProcess.stderr).thenAnswer((Invocation invocation) {
      return const Stream<List<int>>.empty();
    });
    when(mockProcess.stdout).thenAnswer((Invocation invocation) {
      return const Stream<List<int>>.empty();
    });
    when(macosPlatform.isMacOS).thenReturn(true);
    when(notMacosPlatform.isMacOS).thenReturn(false);
  });

  testUsingContext('macOS build fails when there is no macos project', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    expect(createTestCommandRunner(command).run(
      const <String>['build', 'macos']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build fails on non-macOS platform', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'macos']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => notMacosPlatform,
    FileSystem: () => memoryFilesystem,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build copies to output directory', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    when(macOSBuilder.buildMacOS(
      flutterProject: anyNamed('flutterProject'),
      buildInfo: anyNamed('buildInfo'),
      targetOverride: anyNamed('targetOverride'),
    )).thenAnswer((Invocation invocation) async {
      final Directory appDir = fs.directory(fs.path.join('foo', 'bar', 'Flutter.app'));
      final File executable = fs.file(fs.path.join('foo', 'bar', 'Flutter.app', 'Contents', 'MacOS', 'App'));
      executable.createSync(recursive: true);
      return PrebuiltMacOSApp(
        bundleDir: appDir,
        bundleName: 'Flutter.app',
        executableAndId: ExecutableAndId(executable.path,  '2'),
      );
    });
    fs.directory('macos').createSync(recursive: true);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--release', '-ofoo']
    );

    verify(os.chmod(any, 'x')).called(1);
    expect(fs.directory(fs.path.join('foo', 'Flutter.app')).existsSync(), true);
  }, overrides: <Type, Generator>{
    OperatingSystemUtils: () => MockOperatingSystemUtils(),
    FileSystem: () => MemoryFileSystem(),
    MacOSBuilder: () => MockMacOSBuilder(),
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('Refuses to build for macOS when feature is disabled', () {
    final CommandRunner<void> runner = createTestCommandRunner(BuildCommand());

    expect(() => runner.run(<String>['build', 'macos']),
        throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: false),
  });
}

class MockProcess extends Mock implements Process {}
class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': '/',
  };
}
class MockMacOSBuilder extends Mock implements MacOSBuilder {}
class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}