// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_web.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/build_runner/resident_web_runner.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;
  MockPlatform mockPlatform;

  setUpAll(() {
    Cache.flutterRoot = '';
    Cache.disableLocking();
  });

  setUp(() {
    testbed = Testbed(setup: () {
      fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('name: foo\n');
      fs.file('.packages').createSync();
      fs.file(fs.path.join('web', 'index.html')).createSync(recursive: true);
      fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    }, overrides: <Type, Generator>{
      Platform: () => mockPlatform,
      FlutterVersion: () => MockFlutterVersion(),
      FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
    });
  });

  test('Refuses to build for web when missing index.html', () => testbed.run(() async {
    fs.file(fs.path.join('web', 'index.html')).deleteSync();

    expect(buildWeb(
      FlutterProject.current(),
      fs.path.join('lib', 'main.dart'),
      BuildInfo.debug,
      false,
    ), throwsA(isInstanceOf<ToolExit>()));
  }));

  test('Refuses to build using runner when missing index.html', () => testbed.run(() async {
    fs.file(fs.path.join('web', 'index.html')).deleteSync();

    final ResidentWebRunner runner = ResidentWebRunner(
      null,
      flutterProject: FlutterProject.current(),
      ipv6: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
    );
    expect(await runner.run(), 1);
  }));

  test('Refuses to build a debug build for web', () => testbed.run(() async {
    final CommandRunner<void> runner = createTestCommandRunner(BuildCommand());

    expect(() => runner.run(<String>['build', 'web', '--debug']),
        throwsA(isInstanceOf<UsageException>()));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
  }));

  test('Refuses to build for web when feature is disabled', () => testbed.run(() async {
    final CommandRunner<void> runner = createTestCommandRunner(BuildCommand());

    expect(() => runner.run(<String>['build', 'web']),
        throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: false),
  }));

  test('Builds a web bundle - end to end', () => testbed.run(() async {
    final CommandRunner<void> runner = createTestCommandRunner(BuildCommand());
    final List<String> dependencies = <String>[
      fs.path.join('packages', 'flutter_tools', 'lib', 'src', 'build_system', 'targets', 'web.dart'),
      fs.path.join('bin', 'cache', 'flutter_web_sdk'),
      fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'snapshots', 'dart2js.dart.snapshot'),
      fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
      fs.path.join('bin', 'cache', 'dart-sdk '),
    ];
    for (String dependency in dependencies) {
      fs.file(dependency).createSync(recursive: true);
    }

    // Project files.
    fs.file('.packages')
      ..writeAsStringSync('''
foo:lib/
fizz:bar/lib/
''');
    fs.file('pubspec.yaml')
      ..writeAsStringSync('''
name: foo

dependencies:
  flutter:
    sdk: flutter
  fizz:
    path:
      bar/
''');
    fs.file(fs.path.join('bar', 'pubspec.yaml'))
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
    fs.file(fs.path.join('bar', 'lib', 'url_launcher_web.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('''
class UrlLauncherPlugin {}
''');
    fs.file(fs.path.join('lib', 'main.dart'))
      ..writeAsStringSync('void main() { }');

    // Process calls. We're not testing that these invocations are correct because
    // that is covered in targets/web_test.dart.
    when(buildSystem.build(any, any)).thenAnswer((Invocation invocation) async {
      return BuildResult(success: true);
    });

    await runner.run(<String>['build', 'web']);

    expect(fs.file(fs.path.join('lib', 'generated_plugin_registrant.dart')).existsSync(), true);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
    BuildSystem: () => MockBuildSystem(),
  }));

  test('hidden if feature flag is not enabled', () => testbed.run(() async {
    expect(BuildWebCommand().hidden, true);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: false),
  }));

  test('not hidden if feature flag is enabled', () => testbed.run(() async {
    expect(BuildWebCommand().hidden, false);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
  }));
}

class MockBuildSystem extends Mock implements BuildSystem {}
class MockWebCompilationProxy extends Mock implements WebCompilationProxy {}
class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': '/',
  };
}
class MockFlutterVersion extends Mock implements FlutterVersion {
  @override
  bool get isMaster => true;
}
