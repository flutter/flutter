// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/depfile.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/build_system/targets/web.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/mocks.dart';
import '../../../src/testbed.dart';

const List<String> kDart2jsLinuxArgs = <String>[
  'bin/cache/dart-sdk/bin/dart',
   '--disable-dart-dev',
  'bin/cache/dart-sdk/bin/snapshots/dart2js.dart.snapshot',
  '--libraries-spec=bin/cache/flutter_web_sdk/libraries.json',
];

void main() {
  Testbed testbed;
  Environment environment;
  FakeProcessManager processManager;
  final Platform linux = FakePlatform(
    operatingSystem: 'linux',
    environment: <String, String>{},
  );
  final Platform windows = FakePlatform(
    operatingSystem: 'windows',
    environment: <String, String>{},
  );
  DepfileService depfileService;

  setUp(() {
    testbed = Testbed(setup: () {
      globals.fs.file('.packages')
        ..createSync(recursive: true)
        ..writeAsStringSync('foo:foo/lib/\n');
      globals.fs.currentDirectory.childDirectory('bar').createSync();
      processManager = FakeProcessManager.list(<FakeCommand>[]);

      environment = Environment.test(
        globals.fs.currentDirectory,
        projectDir: globals.fs.currentDirectory.childDirectory('foo'),
        outputDir: globals.fs.currentDirectory.childDirectory('bar'),
        defines: <String, String>{
          kTargetFile: globals.fs.path.join('foo', 'lib', 'main.dart'),
        },
        artifacts: MockArtifacts(),
        processManager: FakeProcessManager.any(),
        logger: globals.logger,
        fileSystem: globals.fs,
      );
      depfileService = DepfileService(
      fileSystem: globals.fs,
      logger: globals.logger,
    );
      environment.buildDir.createSync(recursive: true);
    }, overrides: <Type, Generator>{
      Platform: () => linux,
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
      ..createSync(recursive: true)
      ..writeAsStringSync('''
<html>
  <script src="main.dart.js" type="application/javascript"></script>
  <script>
    navigator.serviceWorker.register('flutter_service_worker.js');
  </script>
</html>
''');
    webResources.childFile('foo.txt')
      .writeAsStringSync('A');
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
    // Appends number to requests for service worker and main.dart.js
    expect(environment.outputDir.childFile('index.html').readAsStringSync(), allOf(
      contains('<script src="main.dart.js?v='),
      contains('flutter_service_worker.js?v='),
    ));
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
    expect(generated, contains("import 'package:foo/generated_plugin_registrant.dart';"));
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
    Platform: () => windows,
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
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.packages',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '-O4',
        '--no-minify',
        '--csp',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));


  test('Dart2JSTarget calls dart2js with expected args with enabled experiment', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[kExtraFrontEndOptions] = '--enable-experiment=non-nullable';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '--enable-experiment=non-nullable',
        '-Ddart.vm.profile=true',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.packages',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '--enable-experiment=non-nullable',
        '-Ddart.vm.profile=true',
        '-O4',
        '--no-minify',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget calls dart2js with expected args in profile mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.packages',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '-O4',
        '--no-minify',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget calls dart2js with expected args in release mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.packages',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '-O4',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget calls dart2js with expected args in release with dart2js optimization override', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[kDart2jsOptimization] = 'O3';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.packages',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '-O3',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget produces expected depfile', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    when(globals.processManager.run(any)).thenAnswer((Invocation invocation) async {
      environment.buildDir.childFile('app.dill.deps')
        .writeAsStringSync('file:///a.dart');
      return FakeProcessResult(exitCode: 0);
    });
    await const Dart2JSTarget().build(environment);

    expect(environment.buildDir.childFile('dart2js.d'), exists);
    final Depfile depfile = depfileService.parse(environment.buildDir.childFile('dart2js.d'));

    expect(depfile.inputs.single.path, globals.fs.path.absolute('a.dart'));
    expect(depfile.outputs.single.path,
      environment.buildDir.childFile('main.dart.js').absolute.path);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('Dart2JSTarget calls dart2js with Dart defines in release mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[kDartDefines] = 'FOO=bar,BAZ=qux';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '-DFOO=bar',
        '-DBAZ=qux',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.packages',
       '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '-DFOO=bar',
        '-DBAZ=qux',
        '-O4',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget calls dart2js with Dart defines in profile mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[kDartDefines] = 'FOO=bar,BAZ=qux';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '-DFOO=bar',
        '-DBAZ=qux',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.packages',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '-DFOO=bar',
        '-DBAZ=qux',
        '-O4',
        '--no-minify',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Generated service worker is empty with none-strategy', () {
    final String result = generateServiceWorker(<String, String>{'/foo': 'abcd'}, <String>[], serviceWorkerStrategy: ServiceWorkerStrategy.none);

    expect(result, '');
  });

  test('Generated service worker correctly inlines file hashes', () {
    final String result = generateServiceWorker(<String, String>{'/foo': 'abcd'}, <String>[], serviceWorkerStrategy: ServiceWorkerStrategy.offlineFirst);

    expect(result, contains('{\n  "/foo": "abcd"\n};'));
  });

  test('Generated service worker includes core files', () {
    final String result = generateServiceWorker(<String, String>{'/foo': 'abcd'}, <String>['foo', 'bar'], serviceWorkerStrategy: ServiceWorkerStrategy.offlineFirst);

    expect(result, contains('"foo",\n"bar"'));
  });

  test('WebServiceWorker generates a service_worker for a web resource folder', () => testbed.run(() async {
    environment.outputDir.childDirectory('a').childFile('a.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('A');
    await const WebServiceWorker().build(environment);

    expect(environment.outputDir.childFile('flutter_service_worker.js'), exists);
    // Contains file hash.
    expect(environment.outputDir.childFile('flutter_service_worker.js').readAsStringSync(),
      contains('"a/a.txt": "7fc56270e7a70fa81a5935b72eacbe29"'));
    expect(environment.buildDir.childFile('service_worker.d'), exists);
    // Depends on resource file.
    expect(environment.buildDir.childFile('service_worker.d').readAsStringSync(),
      contains('a/a.txt'));
    // Contains NOTICES
    expect(environment.outputDir.childFile('flutter_service_worker.js').readAsStringSync(),
      contains('NOTICES'));
  }));

  test('WebServiceWorker contains baseUrl cache', () => testbed.run(() async {
    environment.outputDir
      .childFile('index.html')
      .createSync(recursive: true);
    await const WebServiceWorker().build(environment);

    expect(environment.outputDir.childFile('flutter_service_worker.js'), exists);
    // Contains file hash for both `/` and index.html.
    expect(environment.outputDir.childFile('flutter_service_worker.js').readAsStringSync(),
      contains('"/": "d41d8cd98f00b204e9800998ecf8427e"'));
    expect(environment.outputDir.childFile('flutter_service_worker.js').readAsStringSync(),
      contains('"index.html": "d41d8cd98f00b204e9800998ecf8427e"'));
    expect(environment.buildDir.childFile('service_worker.d'), exists);
  }));

  test('WebServiceWorker does not cache source maps', () => testbed.run(() async {
    environment.outputDir
      .childFile('main.dart.js')
      .createSync(recursive: true);
    environment.outputDir
      .childFile('main.dart.js.map')
      .createSync(recursive: true);
    await const WebServiceWorker().build(environment);

    // No caching of source maps.
    expect(environment.outputDir.childFile('flutter_service_worker.js').readAsStringSync(),
      isNot(contains('"main.dart.js.map"')));
    // Expected twice, once for RESOURCES and once for CORE.
    expect(environment.outputDir.childFile('flutter_service_worker.js').readAsStringSync(),
      contains('"main.dart.js"'));
  }));
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockArtifacts extends Mock implements Artifacts {}
