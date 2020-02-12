// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/depfile.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/build_system/targets/web.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:platform/platform.dart';

import '../../../src/common.dart';
import '../../../src/mocks.dart';
import '../../../src/testbed.dart';

void main() {
  Testbed testbed;
  Environment environment;
  MockPlatform mockPlatform;
  MockPlatform  mockWindowsPlatform;

  setUp(() {
    mockPlatform = MockPlatform();
    mockWindowsPlatform = MockPlatform();

    when(mockPlatform.isWindows).thenReturn(false);
    when(mockPlatform.isMacOS).thenReturn(true);
    when(mockPlatform.isLinux).thenReturn(false);
    when(mockPlatform.environment).thenReturn(const <String, String>{});

    when(mockWindowsPlatform.isWindows).thenReturn(true);
    when(mockWindowsPlatform.isMacOS).thenReturn(false);
    when(mockWindowsPlatform.isLinux).thenReturn(false);

    testbed = Testbed(setup: () {
      final File packagesFile = globals.fs.file(globals.fs.path.join('foo', '.packages'))
        ..createSync(recursive: true)
        ..writeAsStringSync('foo:lib/\n');
      PackageMap.globalPackagesPath = packagesFile.path;
      globals.fs.currentDirectory.childDirectory('bar').createSync();

      environment = Environment.test(
        globals.fs.currentDirectory,
        projectDir: globals.fs.currentDirectory.childDirectory('foo'),
        outputDir: globals.fs.currentDirectory.childDirectory('bar'),
        defines: <String, String>{
          kTargetFile: globals.fs.path.join('foo', 'lib', 'main.dart'),
        }
      );
      environment.buildDir.createSync(recursive: true);
    }, overrides: <Type, Generator>{
      Platform: () => mockPlatform,
    });
  });

  test('WebEntrypointTarget generates an entrypoint with plugins and init platform', () => testbed.run(() async {
    environment.defines[kHasWebPlugins] = 'true';
    environment.defines[kInitializePlatform] = 'true';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Plugins
    expect(generated, contains("import 'package:foo/generated_plugin_registrant.dart';"));
    expect(generated, contains('registerPlugins(webPluginRegistry);'));

    // Platform
    expect(generated, contains('if (true) {'));

    // Main
    expect(generated, contains('entrypoint.main();'));

    // Import.
    expect(generated, contains("import 'package:foo/main.dart' as entrypoint;"));
  }));

  test('WebReleaseBundle copies dart2js output and resource files to output directory', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    final Directory webResources = environment.projectDir.childDirectory('web');
    webResources.childFile('index.html')
      ..createSync(recursive: true);
    webResources.childFile('foo.txt')
      ..writeAsStringSync('A');
    environment.buildDir.childFile('main.dart.js').createSync();

    await const WebReleaseBundle().build(environment);

    expect(environment.outputDir.childFile('foo.txt')
      .readAsStringSync(), 'A');
    expect(environment.outputDir.childFile('main.dart.js')
      .existsSync(), true);
    expect(environment.outputDir.childDirectory('assets')
      .childFile('AssetManifest.json').existsSync(), true);

    // Update to arbitary resource file triggers rebuild.
    webResources.childFile('foo.txt').writeAsStringSync('B');

    await const WebReleaseBundle().build(environment);

    expect(environment.outputDir.childFile('foo.txt')
      .readAsStringSync(), 'B');
  }));

  test('WebEntrypointTarget generates an entrypoint for a file outside of main', () => testbed.run(() async {
    environment.defines[kTargetFile] = globals.fs.path.join('other', 'lib', 'main.dart');
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Import.
    expect(generated, contains("import 'file:///other/lib/main.dart' as entrypoint;"));
  }));

  test('WebEntrypointTarget generates a plugin registrant for a file outside of main', () => testbed.run(() async {
    environment.defines[kTargetFile] = globals.fs.path.join('other', 'lib', 'main.dart');
    environment.defines[kHasWebPlugins] = 'true';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Import.
    expect(generated, contains("import 'file:///other/lib/main.dart' as entrypoint;"));
    expect(generated, contains("import 'file:///foo/lib/generated_plugin_registrant.dart';"));
  }));


  test('WebEntrypointTarget generates an entrypoint with plugins and init platform on windows', () => testbed.run(() async {
    environment.defines[kHasWebPlugins] = 'true';
    environment.defines[kInitializePlatform] = 'true';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Plugins
    expect(generated, contains("import 'package:foo/generated_plugin_registrant.dart';"));
    expect(generated, contains('registerPlugins(webPluginRegistry);'));

    // Platform
    expect(generated, contains('if (true) {'));

    // Main
    expect(generated, contains('entrypoint.main();'));

    // Import.
    expect(generated, contains("import 'package:foo/main.dart' as entrypoint;"));
  }, overrides: <Type, Generator>{
    Platform: () => mockWindowsPlatform,
  }));

  test('WebEntrypointTarget generates an entrypoint without plugins and init platform', () => testbed.run(() async {
    environment.defines[kHasWebPlugins] = 'false';
    environment.defines[kInitializePlatform] = 'true';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Plugins
    expect(generated, isNot(contains("import 'package:foo/generated_plugin_registrant.dart';")));
    expect(generated, isNot(contains('registerPlugins(webPluginRegistry);')));

    // Platform
    expect(generated, contains('if (true) {'));

    // Main
    expect(generated, contains('entrypoint.main();'));
  }));

  test('WebEntrypointTarget generates an entrypoint with plugins and without init platform', () => testbed.run(() async {
    environment.defines[kHasWebPlugins] = 'true';
    environment.defines[kInitializePlatform] = 'false';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Plugins
    expect(generated, contains("import 'package:foo/generated_plugin_registrant.dart';"));
    expect(generated, contains('registerPlugins(webPluginRegistry);'));

    // Platform
    expect(generated, contains('if (false) {'));

    // Main
    expect(generated, contains('entrypoint.main();'));
  }));

  test('WebEntrypointTarget generates an entrypoint without plugins and without init platform', () => testbed.run(() async {
    environment.defines[kHasWebPlugins] = 'false';
    environment.defines[kInitializePlatform] = 'false';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Plugins
    expect(generated, isNot(contains("import 'package:foo/generated_plugin_registrant.dart';")));
    expect(generated, isNot(contains('registerPlugins(webPluginRegistry);')));

    // Platform
    expect(generated, contains('if (false) {'));

    // Main
    expect(generated, contains('entrypoint.main();'));
  }));

  test('Dart2JSTarget calls dart2js with expected args with csp', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[kCspMode] = 'true';
    when(globals.processManager.run(any)).thenAnswer((Invocation invocation) async {
      return FakeProcessResult(exitCode: 0);
    });
    await const Dart2JSTarget().build(environment);

    final List<String> expected = <String>[
      globals.fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
      globals.fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'snapshots', 'dart2js.dart.snapshot'),
      '--libraries-spec=' + globals.fs.path.join('bin', 'cache', 'flutter_web_sdk', 'libraries.json'),
      '-O4', // highest optimizations
      '--no-minify', // but uses unminified names for debugging
      '-o',
      environment.buildDir.childFile('main.dart.js').absolute.path,
      '--packages=${globals.fs.path.join('foo', '.packages')}',
      '-Ddart.vm.profile=true',
      '--csp',
      environment.buildDir.childFile('main.dart').absolute.path,
    ];
    verify(globals.processManager.run(expected)).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));


  test('Dart2JSTarget calls dart2js with expected args in profile mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    when(globals.processManager.run(any)).thenAnswer((Invocation invocation) async {
      return FakeProcessResult(exitCode: 0);
    });
    await const Dart2JSTarget().build(environment);

    final List<String> expected = <String>[
      globals.fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
      globals.fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'snapshots', 'dart2js.dart.snapshot'),
      '--libraries-spec=' + globals.fs.path.join('bin', 'cache', 'flutter_web_sdk', 'libraries.json'),
      '-O4', // highest optimizations
      '--no-minify', // but uses unminified names for debugging
      '-o',
      environment.buildDir.childFile('main.dart.js').absolute.path,
      '--packages=${globals.fs.path.join('foo', '.packages')}',
      '-Ddart.vm.profile=true',
      environment.buildDir.childFile('main.dart').absolute.path,
    ];
    verify(globals.processManager.run(expected)).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('Dart2JSTarget calls dart2js with expected args in release mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    when(globals.processManager.run(any)).thenAnswer((Invocation invocation) async {
      return FakeProcessResult(exitCode: 0);
    });
    await const Dart2JSTarget().build(environment);

    final List<String> expected = <String>[
      globals.fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
      globals.fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'snapshots', 'dart2js.dart.snapshot'),
      '--libraries-spec=' + globals.fs.path.join('bin', 'cache', 'flutter_web_sdk', 'libraries.json'),
      '-O4', // highest optimizations.
      '-o',
      environment.buildDir.childFile('main.dart.js').absolute.path,
      '--packages=${globals.fs.path.join('foo', '.packages')}',
      '-Ddart.vm.product=true',
      environment.buildDir.childFile('main.dart').absolute.path,
    ];
    verify(globals.processManager.run(expected)).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('Dart2JSTarget calls dart2js with expected args in release with dart2js optimization override', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[kDart2jsOptimization] = 'O3';
    when(globals.processManager.run(any)).thenAnswer((Invocation invocation) async {
      return FakeProcessResult(exitCode: 0);
    });
    await const Dart2JSTarget().build(environment);

    final List<String> expected = <String>[
      globals.fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
      globals.fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'snapshots', 'dart2js.dart.snapshot'),
      '--libraries-spec=' + globals.fs.path.join('bin', 'cache', 'flutter_web_sdk', 'libraries.json'),
      '-O3', // configured optimizations.
      '-o',
      environment.buildDir.childFile('main.dart.js').absolute.path,
      '--packages=${globals.fs.path.join('foo', '.packages')}',
      '-Ddart.vm.product=true',
      environment.buildDir.childFile('main.dart').absolute.path,
    ];
    verify(globals.processManager.run(expected)).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('Dart2JSTarget produces expected depfile', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    when(globals.processManager.run(any)).thenAnswer((Invocation invocation) async {
      environment.buildDir.childFile('main.dart.js.deps')
        ..writeAsStringSync('file:///a.dart');
      return FakeProcessResult(exitCode: 0);
    });
    await const Dart2JSTarget().build(environment);

    expect(environment.buildDir.childFile('dart2js.d').existsSync(), true);
    final Depfile depfile = Depfile.parse(environment.buildDir.childFile('dart2js.d'));

    expect(depfile.inputs.single.path, globals.fs.path.absolute('a.dart'));
    expect(depfile.outputs.single.path,
      environment.buildDir.childFile('main.dart.js').absolute.path);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('Dart2JSTarget calls dart2js with Dart defines in release mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[kDartDefines] = '["FOO=bar","BAZ=qux"]';
    when(globals.processManager.run(any)).thenAnswer((Invocation invocation) async {
      return FakeProcessResult(exitCode: 0);
    });
    await const Dart2JSTarget().build(environment);

    final List<String> expected = <String>[
      globals.fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
      globals.fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'snapshots', 'dart2js.dart.snapshot'),
      '--libraries-spec=' + globals.fs.path.join('bin', 'cache', 'flutter_web_sdk', 'libraries.json'),
      '-O4',
      '-o',
      environment.buildDir.childFile('main.dart.js').absolute.path,
      '--packages=${globals.fs.path.join('foo', '.packages')}',
      '-Ddart.vm.product=true',
      '-DFOO=bar',
      '-DBAZ=qux',
      environment.buildDir.childFile('main.dart').absolute.path,
    ];
    verify(globals.processManager.run(expected)).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('Dart2JSTarget calls dart2js with Dart defines in profile mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[kDartDefines] = '["FOO=bar","BAZ=qux"]';
    when(globals.processManager.run(any)).thenAnswer((Invocation invocation) async {
      return FakeProcessResult(exitCode: 0);
    });
    await const Dart2JSTarget().build(environment);

    final List<String> expected = <String>[
      globals.fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
      globals.fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'snapshots', 'dart2js.dart.snapshot'),
      '--libraries-spec=' + globals.fs.path.join('bin', 'cache', 'flutter_web_sdk', 'libraries.json'),
      '-O4',
      '--no-minify',
      '-o',
      environment.buildDir.childFile('main.dart.js').absolute.path,
      '--packages=${globals.fs.path.join('foo', '.packages')}',
      '-Ddart.vm.profile=true',
      '-DFOO=bar',
      '-DBAZ=qux',
      environment.buildDir.childFile('main.dart').absolute.path,
    ];
    verify(globals.processManager.run(expected)).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('Dart2JSTarget throws developer-friendly exception on misformatted DartDefines', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[kDartDefines] = '[misformatted json';
    try {
      await const Dart2JSTarget().build(environment);
      fail('Call to build() must not have succeeded.');
    } on Exception catch(exception) {
      expect(
        '$exception',
        'Exception: The value of -D$kDartDefines is not formatted correctly.\n'
        'The value must be a JSON-encoded list of strings but was:\n'
        '[misformatted json',
      );
    }

    // Should not attempt to run any processes.
    verifyNever(globals.processManager.run(any));
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('Generated service worker correctly inlines file hashes', () {
    final String result = generateServiceWorker(<String, String>{'/foo': 'abcd'});

    expect(result, contains('{\n  "/foo": "abcd"\n};'));
  });

  test('WebServiceWorker generates a service_worker for a web resource folder', () => testbed.run(() async {
    environment.outputDir.childDirectory('a').childFile('a.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('A');
    await const WebServiceWorker().build(environment);

    expect(environment.outputDir.childFile('flutter_service_worker.js'), exists);
    // Contains file hash.
    expect(environment.outputDir.childFile('flutter_service_worker.js').readAsStringSync(),
      contains('"/a/a.txt": "7fc56270e7a70fa81a5935b72eacbe29"'));
    expect(environment.buildDir.childFile('service_worker.d'), exists);
    // Depends on resource file.
    expect(environment.buildDir.childFile('service_worker.d').readAsStringSync(), contains('a/a.txt'));
  }));
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockPlatform extends Mock implements Platform {}
