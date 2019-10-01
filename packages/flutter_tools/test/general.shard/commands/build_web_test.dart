// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:args/command_runner.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
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
  MockWebCompilationProxy mockWebCompilationProxy;
  Testbed testbed;
  MockPlatform mockPlatform;
  bool addArchive = false;

  setUpAll(() {
    Cache.flutterRoot = '';
    Cache.disableLocking();
  });

  setUp(() {
    addArchive = false;
    mockWebCompilationProxy = MockWebCompilationProxy();
    testbed = Testbed(setup: () {
      fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('name: foo\n');
      fs.file('.packages').createSync();
      fs.file(fs.path.join('web', 'index.html')).createSync(recursive: true);
      fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      when(mockWebCompilationProxy.initialize(
        projectName: anyNamed('projectName'),
        projectDirectory: anyNamed('projectDirectory'),
        mode: anyNamed('mode'),
        initializePlatform: anyNamed('initializePlatform'),
      )).thenAnswer((Invocation invocation) {
        final String prefix = fs.path.join('.dart_tool', 'build', 'flutter_web', 'foo', 'lib');
        final String path = fs.path.join(prefix, 'main_web_entrypoint.dart.js');
        fs.file(path).createSync(recursive: true);
        fs.file('$path.map').createSync();
        if (addArchive) {
          final List<int> bytes = utf8.encode('void main() {}');
          final TarEncoder encoder = TarEncoder();
          final Archive archive = Archive()
            ..addFile(ArchiveFile.noCompress('main_web_entrypoint.1.dart.js', bytes.length, bytes));
          fs.file(fs.path.join(prefix, 'main_web_entrypoint.dart.js.tar.gz'))
            ..writeAsBytes(encoder.encode(archive));
        }
        return Future<bool>.value(true);
      });
    }, overrides: <Type, Generator>{
      WebCompilationProxy: () => mockWebCompilationProxy,
      Platform: () => mockPlatform,
      FlutterVersion: () => MockFlutterVersion(),
      FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
    });
  });

  test('Copies generated part files out of build directory', () => testbed.run(() async {
    addArchive = true;
    await buildWeb(
      FlutterProject.current(),
      fs.path.join('lib', 'main.dart'),
      BuildInfo.release,
      false,
    );

    expect(fs.file(fs.path.join('build', 'web', 'main_web_entrypoint.1.dart.js')), exists);
    expect(fs.file(fs.path.join('build', 'web', 'main.dart.js')), exists);
  }));

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
