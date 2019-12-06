// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/depfile.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/build_system/targets/web.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

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

    when(mockWindowsPlatform.isWindows).thenReturn(true);
    when(mockWindowsPlatform.isMacOS).thenReturn(false);
    when(mockWindowsPlatform.isLinux).thenReturn(false);

    testbed = Testbed(setup: () {
      final File packagesFile = fs.file(fs.path.join('foo', '.packages'))
        ..createSync(recursive: true)
        ..writeAsStringSync('foo:lib/\n');
      PackageMap.globalPackagesPath = packagesFile.path;

      environment = Environment(
        projectDir: fs.currentDirectory.childDirectory('foo'),
        outputDir: fs.currentDirectory,
        buildDir: fs.currentDirectory,
        defines: <String, String>{
          kTargetFile: fs.path.join('foo', 'lib', 'main.dart'),
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

  test('WebEntrypointTarget generates an entrypoint for a file outside of main', () => testbed.run(() async {
    environment.defines[kTargetFile] = fs.path.join('other', 'lib', 'main.dart');
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Import.
    expect(generated, contains("import 'file:///other/lib/main.dart' as entrypoint;"));
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

  test('Dart2JSTarget calls dart2js with expected args in profile mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    when(processManager.run(any)).thenAnswer((Invocation invocation) async {
      return FakeProcessResult(exitCode: 0);
    });
    await const Dart2JSTarget().build(environment);

    final List<String> expected = <String>[
      fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
      fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'snapshots', 'dart2js.dart.snapshot'),
      '--libraries-spec=' + fs.path.join('bin', 'cache', 'flutter_web_sdk', 'libraries.json'),
      '-O4', // highest optimizations
      '--no-minify', // but uses unminified names for debugging
      '-o',
      environment.buildDir.childFile('main.dart.js').absolute.path,
      '--packages=${fs.path.join('foo', '.packages')}',
      '-Ddart.vm.profile=true',
      environment.buildDir.childFile('main.dart').absolute.path,
    ];
    verify(processManager.run(expected)).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('Dart2JSTarget calls dart2js with expected args in release mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    when(processManager.run(any)).thenAnswer((Invocation invocation) async {
      return FakeProcessResult(exitCode: 0);
    });
    await const Dart2JSTarget().build(environment);

    final List<String> expected = <String>[
      fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
      fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'snapshots', 'dart2js.dart.snapshot'),
      '--libraries-spec=' + fs.path.join('bin', 'cache', 'flutter_web_sdk', 'libraries.json'),
      '-O4', // highest optimizations.
      '-o',
      environment.buildDir.childFile('main.dart.js').absolute.path,
      '--packages=${fs.path.join('foo', '.packages')}',
      '-Ddart.vm.product=true',
      environment.buildDir.childFile('main.dart').absolute.path,
    ];
    verify(processManager.run(expected)).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('Dart2JSTarget calls dart2js with expected args in release with dart2js optimization override', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[kDart2jsOptimization] = 'O3';
    when(processManager.run(any)).thenAnswer((Invocation invocation) async {
      return FakeProcessResult(exitCode: 0);
    });
    await const Dart2JSTarget().build(environment);

    final List<String> expected = <String>[
      fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
      fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'snapshots', 'dart2js.dart.snapshot'),
      '--libraries-spec=' + fs.path.join('bin', 'cache', 'flutter_web_sdk', 'libraries.json'),
      '-O3', // configured optimizations.
      '-o',
      environment.buildDir.childFile('main.dart.js').absolute.path,
      '--packages=${fs.path.join('foo', '.packages')}',
      '-Ddart.vm.product=true',
      environment.buildDir.childFile('main.dart').absolute.path,
    ];
    verify(processManager.run(expected)).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('Dart2JSTarget produces expected depfile', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    when(processManager.run(any)).thenAnswer((Invocation invocation) async {
      environment.buildDir.childFile('main.dart.js.deps')
        ..writeAsStringSync('file:///a.dart');
      return FakeProcessResult(exitCode: 0);
    });
    await const Dart2JSTarget().build(environment);

    expect(environment.buildDir.childFile('dart2js.d').existsSync(), true);
    final Depfile depfile = Depfile.parse(environment.buildDir.childFile('dart2js.d'));

    expect(depfile.inputs.single.path, fs.path.absolute('a.dart'));
    expect(depfile.outputs.single.path,
      environment.buildDir.childFile('main.dart.js').absolute.path);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('Dart2JSTarget calls dart2js with Dart defines in release mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[kDartDefines] = '["FOO=bar","BAZ=qux"]';
    when(processManager.run(any)).thenAnswer((Invocation invocation) async {
      return FakeProcessResult(exitCode: 0);
    });
    await const Dart2JSTarget().build(environment);

    final List<String> expected = <String>[
      fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
      fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'snapshots', 'dart2js.dart.snapshot'),
      '--libraries-spec=' + fs.path.join('bin', 'cache', 'flutter_web_sdk', 'libraries.json'),
      '-O4',
      '-o',
      environment.buildDir.childFile('main.dart.js').absolute.path,
      '--packages=${fs.path.join('foo', '.packages')}',
      '-Ddart.vm.product=true',
      '-DFOO=bar',
      '-DBAZ=qux',
      environment.buildDir.childFile('main.dart').absolute.path,
    ];
    verify(processManager.run(expected)).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('Dart2JSTarget calls dart2js with Dart defines in profile mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[kDartDefines] = '["FOO=bar","BAZ=qux"]';
    when(processManager.run(any)).thenAnswer((Invocation invocation) async {
      return FakeProcessResult(exitCode: 0);
    });
    await const Dart2JSTarget().build(environment);

    final List<String> expected = <String>[
      fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
      fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'snapshots', 'dart2js.dart.snapshot'),
      '--libraries-spec=' + fs.path.join('bin', 'cache', 'flutter_web_sdk', 'libraries.json'),
      '-O4',
      '--no-minify',
      '-o',
      environment.buildDir.childFile('main.dart.js').absolute.path,
      '--packages=${fs.path.join('foo', '.packages')}',
      '-Ddart.vm.profile=true',
      '-DFOO=bar',
      '-DBAZ=qux',
      environment.buildDir.childFile('main.dart').absolute.path,
    ];
    verify(processManager.run(expected)).called(1);
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
    verifyNever(processManager.run(any));
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockPlatform extends Mock implements Platform {}
