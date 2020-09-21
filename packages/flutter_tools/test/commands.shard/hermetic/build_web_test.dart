// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_web.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

void main() {
  FileSystem fileSystem;
  final Platform fakePlatform = FakePlatform(
    operatingSystem: 'linux',
    environment: <String, String>{
      'FLUTTER_ROOT': '/'
    }
  );

  setUpAll(() {
    Cache.flutterRoot = '';
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('name: foo\n');
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('web', 'index.html')).createSync(recursive: true);
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
  });

  testUsingContext('Refuses to build for web when missing index.html', () async {
    fileSystem.file(fileSystem.path.join('web', 'index.html')).deleteSync();

    expect(buildWeb(
      FlutterProject.current(),
      fileSystem.path.join('lib', 'main.dart'),
      BuildInfo.debug,
      false,
      false,
      null,
    ), throwsToolExit());
  }, overrides: <Type, Generator>{
    Platform: () => fakePlatform,
    FileSystem: () => fileSystem,
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
    Pub: () => MockPub(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Refuses to build a debug build for web', () async {
    final CommandRunner<void> runner = createTestCommandRunner(BuildCommand());

    expect(() => runner.run(<String>['build', 'web', '--debug']),
      throwsA(isA<UsageException>()));
  }, overrides: <Type, Generator>{
    Platform: () => fakePlatform,
    FileSystem: () => fileSystem,
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
    Pub: () => MockPub(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Refuses to build for web when feature is disabled', () async {
    final CommandRunner<void> runner = createTestCommandRunner(BuildCommand());

    expect(
      () => runner.run(<String>['build', 'web']),
      throwsToolExit(),
    );
  }, overrides: <Type, Generator>{
    Platform: () => fakePlatform,
    FileSystem: () => fileSystem,
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: false),
    Pub: () => MockPub(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Builds a web bundle - end to end', () async {
    final BuildCommand buildCommand = BuildCommand();
    applyMocksToCommand(buildCommand);
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    final List<String> dependencies = <String>[
      fileSystem.path.join('packages', 'flutter_tools', 'lib', 'src', 'build_system', 'targets', 'web.dart'),
      fileSystem.path.join('bin', 'cache', 'flutter_web_sdk'),
      fileSystem.path.join('bin', 'cache', 'dart-sdk', 'bin', 'snapshots', 'dart2js.dart.snapshot'),
      fileSystem.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
      fileSystem.path.join('bin', 'cache', 'dart-sdk '),
    ];
    for (final String dependency in dependencies) {
      fileSystem.file(dependency).createSync(recursive: true);
    }

    // Project files.
    fileSystem.file('.packages')
      .writeAsStringSync('''
foo:lib/
fizz:bar/lib/
''');
    fileSystem.file('pubspec.yaml')
      .writeAsStringSync('''
name: foo

dependencies:
  flutter:
    sdk: flutter
  fizz:
    path:
      bar/
''');
    fileSystem.file(fileSystem.path.join('bar', 'pubspec.yaml'))
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: bar

flutter:
  plugin:
    platforms:
      web:
        pluginClass: UrlLauncherPlugin
        fileName: url_launcher_web.dart
''');
    fileSystem.file(fileSystem.path.join('bar', 'lib', 'url_launcher_web.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('''
class UrlLauncherPlugin {}
''');
    fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
      .writeAsStringSync('void main() { }');

    // Process calls. We're not testing that these invocations are correct because
    // that is covered in targets/web_test.dart.
    when(globals.buildSystem.build(any, any)).thenAnswer((Invocation invocation) async {
      return BuildResult(success: true);
    });
    await runner.run(<String>['build', 'web']);

    expect(fileSystem.file(fileSystem.path.join('lib', 'generated_plugin_registrant.dart')).existsSync(), true);
  }, overrides: <Type, Generator>{
    Platform: () => fakePlatform,
    FileSystem: () => fileSystem,
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
    Pub: () => MockPub(),
    ProcessManager: () => FakeProcessManager.any(),
    BuildSystem: () => MockBuildSystem(),
  });

  testUsingContext('hidden if feature flag is not enabled', () async {
    expect(BuildWebCommand(verboseHelp: false).hidden, true);
  }, overrides: <Type, Generator>{
    Platform: () => fakePlatform,
    FileSystem: () => fileSystem,
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: false),
    Pub: () => MockPub(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('not hidden if feature flag is enabled', () async {
    expect(BuildWebCommand(verboseHelp: false).hidden, false);
  }, overrides: <Type, Generator>{
    Platform: () => fakePlatform,
    FileSystem: () => fileSystem,
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
    Pub: () => MockPub(),
    ProcessManager: () => FakeProcessManager.any(),
  });
}

class MockBuildSystem extends Mock implements BuildSystem {}
class MockPub extends Mock implements Pub {}
