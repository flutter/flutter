// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/depfile.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/build_system/targets/web.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/project.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fake_process_manager.dart';

const List<String> kDart2jsLinuxArgs = <String>[
  'HostArtifact.engineDartBinary',
   '--disable-dart-dev',
  'HostArtifact.dart2jsSnapshot',
  '--libraries-spec=HostArtifact.flutterWebSdk/libraries.json',
];

final Platform linux = FakePlatform(
  operatingSystem: 'linux',
  environment: <String, String>{},
);

final Platform windows = FakePlatform(
  operatingSystem: 'windows',
  environment: <String, String>{},
);

void main() {
  Environment environment;
  FakeProcessManager processManager;
  DepfileService depfileService;
  FileSystem fileSystem;

  setUp(() {
    Cache.flutterRoot = '';
    fileSystem = MemoryFileSystem.test();
    fileSystem.file('.packages')
      ..createSync(recursive: true)
      ..writeAsStringSync('foo:foo/lib/\n');
    fileSystem.currentDirectory.childDirectory('bar').createSync();
    processManager = FakeProcessManager.empty();

    environment = Environment.test(
      fileSystem.currentDirectory,
      projectDir: fileSystem.currentDirectory.childDirectory('foo'),
      outputDir: fileSystem.currentDirectory.childDirectory('bar'),
      defines: <String, String>{
        kTargetFile: fileSystem.path.join('foo', 'lib', 'main.dart'),
      },
      artifacts: Artifacts.test(),
      processManager: processManager,
      logger: BufferLogger.test(),
      fileSystem: fileSystem,
      flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
    );
    depfileService = DepfileService(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );
    environment.buildDir.createSync(recursive: true);
  });

  testWithoutContext('WebEntrypointTarget generates an entrypoint with plugins and init platform', () async {
    final File mainFile = fileSystem.file(fileSystem.path.join('foo', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');
    environment.defines[kTargetFile] = mainFile.path;
    environment.defines[kHasWebPlugins] = 'true';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Plugins
    expect(generated, contains("import 'package:foo/generated_plugin_registrant.dart';"));
    expect(generated, contains('registerPlugins(webPluginRegistrar);'));

    // Main
    expect(generated, contains('entrypoint.main();'));

    // Import.
    expect(generated, contains("import 'package:foo/main.dart' as entrypoint;"));
  });

  // Assets still use globals
  testUsingContext('version.json is created after release build', () async {
    environment.defines[kBuildMode] = 'release';
    final Directory webResources = environment.projectDir.childDirectory('web');
    webResources.childFile('index.html')
        .createSync(recursive: true);
    environment.buildDir.childFile('main.dart.js').createSync();
    await const WebReleaseBundle().build(environment);

    expect(environment.outputDir.childFile('version.json'), exists);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  // Assets still use globals
  testUsingContext('WebReleaseBundle copies dart2js output and resource files to output directory', () async {
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

    // Update to arbitrary resource file triggers rebuild.
    webResources.childFile('foo.txt').writeAsStringSync('B');

    await const WebReleaseBundle().build(environment);

    expect(environment.outputDir.childFile('foo.txt')
      .readAsStringSync(), 'B');
    // Appends number to requests for service worker only
    expect(environment.outputDir.childFile('index.html').readAsStringSync(), allOf(
      contains('<script src="main.dart.js" type="application/javascript">'),
      contains('flutter_service_worker.js?v='),
    ));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testWithoutContext('WebEntrypointTarget generates an entrypoint for a file outside of main', () async {
    final File mainFile = fileSystem.file(fileSystem.path.join('other', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');
    environment.defines[kTargetFile] = mainFile.path;
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Import.
    expect(generated, contains("import 'file:///other/lib/main.dart' as entrypoint;"));
  });

  testWithoutContext('WebEntrypointTarget generates a plugin registrant for a file outside of main', () async {
    final File mainFile = fileSystem.file(fileSystem.path.join('other', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');
    environment.defines[kTargetFile] = mainFile.path;
    environment.defines[kHasWebPlugins] = 'true';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Import.
    expect(generated, contains("import 'file:///other/lib/main.dart' as entrypoint;"));
    expect(generated, contains("import 'package:foo/generated_plugin_registrant.dart';"));
  });


  testWithoutContext('WebEntrypointTarget generates an entrypoint with plugins and init platform on windows', () async {
    final File mainFile = fileSystem.file(fileSystem.path.join('foo', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');
    environment.defines[kTargetFile] = mainFile.path;

    environment.defines[kHasWebPlugins] = 'true';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Plugins
    expect(generated, contains("import 'package:foo/generated_plugin_registrant.dart';"));
    expect(generated, contains('registerPlugins(webPluginRegistrar);'));

    // Main
    expect(generated, contains('entrypoint.main();'));

    // Import.
    expect(generated, contains("import 'package:foo/main.dart' as entrypoint;"));
  });

  testWithoutContext('WebEntrypointTarget generates an entrypoint without plugins and init platform', () async {
    final File mainFile = fileSystem.file(fileSystem.path.join('foo', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');
    environment.defines[kTargetFile] = mainFile.path;
    environment.defines[kHasWebPlugins] = 'false';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Plugins
    expect(generated, isNot(contains("import 'package:foo/generated_plugin_registrant.dart';")));
    expect(generated, isNot(contains('registerPlugins(webPluginRegistrar);')));
    // Main
    expect(generated, contains('entrypoint.main();'));
  });

  testWithoutContext('WebEntrypointTarget generates an entrypoint with a language version', () async {
    final File mainFile = fileSystem.file(fileSystem.path.join('foo', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('// @dart=2.8\nvoid main() {}');
    environment.defines[kTargetFile] = mainFile.path;
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Language version
    expect(generated, contains('// @dart=2.8'));
  });

  testWithoutContext('WebEntrypointTarget generates an entrypoint with a language version from a package config', () async {
    final File mainFile = fileSystem.file(fileSystem.path.join('foo', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');
    fileSystem.file(fileSystem.path.join('pubspec.yaml'))
      .writeAsStringSync('name: foo\n');
    environment = Environment.test(
      fileSystem.currentDirectory,
      projectDir: fileSystem.currentDirectory.childDirectory('foo'),
      outputDir: fileSystem.currentDirectory.childDirectory('bar'),
      defines: <String, String>{
        kTargetFile: fileSystem.path.join('foo', 'lib', 'main.dart'),
      },
      artifacts: Artifacts.test(),
      processManager: processManager,
      logger: BufferLogger.test(),
      fileSystem: fileSystem,
      flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
    );

    environment.defines[kTargetFile] = mainFile.path;

    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Language version
    expect(generated, contains('// @dart=2.7'));
  });

  testWithoutContext('WebEntrypointTarget generates an entrypoint without plugins and without init platform', () async {
    final File mainFile = fileSystem.file(fileSystem.path.join('foo', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');
    environment.defines[kTargetFile] = mainFile.path;
    environment.defines[kHasWebPlugins] = 'false';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Plugins
    expect(generated, isNot(contains("import 'package:foo/generated_plugin_registrant.dart';")));
    expect(generated, isNot(contains('registerPlugins(webPluginRegistrar);')));

    // Main
    expect(generated, contains('entrypoint.main();'));
  });

  testWithoutContext('Dart2JSTarget calls dart2js with expected args with csp', () async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[kCspMode] = 'true';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '--no-source-maps',
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
        '--no-source-maps',
        '-O4',
        '--no-minify',
        '--csp',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);

    expect(processManager, hasNoRemainingExpectations);
  });


  testWithoutContext('Dart2JSTarget calls dart2js with expected args with enabled experiment', () async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[kExtraFrontEndOptions] = '--enable-experiment=non-nullable';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '--enable-experiment=non-nullable',
        '-Ddart.vm.profile=true',
        '--no-source-maps',
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
        '--no-source-maps',
        '-O4',
        '--no-minify',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Dart2JSTarget calls dart2js with expected args in profile mode', () async {
    environment.defines[kBuildMode] = 'profile';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '--no-source-maps',
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
        '--no-source-maps',
        '-O4',
        '--no-minify',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Dart2JSTarget calls dart2js with expected args in release mode', () async {
    environment.defines[kBuildMode] = 'release';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '--no-source-maps',
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
        '--no-source-maps',
        '-O4',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Dart2JSTarget calls dart2js with expected args in release mode with native null assertions', () async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[kNativeNullAssertions] = 'true';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '--native-null-assertions',
        '-Ddart.vm.product=true',
        '--no-source-maps',
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
        '--native-null-assertions',
        '-Ddart.vm.product=true',
        '--no-source-maps',
        '-O4',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Dart2JSTarget calls dart2js with expected args in release with dart2js optimization override', () async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[kDart2jsOptimization] = 'O3';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '--no-source-maps',
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
        '--no-source-maps',
        '-O3',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Dart2JSTarget produces expected depfile', () async {
    environment.defines[kBuildMode] = 'release';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '--no-source-maps',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.packages',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ], onRun: () {
        environment.buildDir.childFile('app.dill.deps')
          .writeAsStringSync('file:///a.dart');
      },
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '--no-source-maps',
        '-O4',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);

    expect(environment.buildDir.childFile('dart2js.d'), exists);
    final Depfile depfile = depfileService.parse(environment.buildDir.childFile('dart2js.d'));

    expect(depfile.inputs.single.path, fileSystem.path.absolute('a.dart'));
    expect(depfile.outputs.single.path,
      environment.buildDir.childFile('main.dart.js').absolute.path);
  });

  testWithoutContext('Dart2JSTarget calls dart2js with Dart defines in release mode', () async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[kDartDefines] = encodeDartDefines(<String>['FOO=bar', 'BAZ=qux']);
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '-DFOO=bar',
        '-DBAZ=qux',
        '--no-source-maps',
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
        '--no-source-maps',
        '-O4',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Dart2JSTarget can enable source maps', () async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[kSourceMapsEnabled] = 'true';
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

    expect(processManager, hasNoRemainingExpectations);
  });


  testWithoutContext('Dart2JSTarget calls dart2js with Dart defines in profile mode', () async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[kDartDefines] = encodeDartDefines(<String>['FOO=bar', 'BAZ=qux']);
    processManager.addCommand(FakeCommand(
      command: <String>[
        ...kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '-DFOO=bar',
        '-DBAZ=qux',
        '--no-source-maps',
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
        '--no-source-maps',
        '-O4',
        '--no-minify',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await const Dart2JSTarget().build(environment);

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Generated service worker is empty with none-strategy', () {
    final String result = generateServiceWorker(<String, String>{'/foo': 'abcd'}, <String>[], serviceWorkerStrategy: ServiceWorkerStrategy.none);

    expect(result, '');
  });

  testWithoutContext('Generated service worker correctly inlines file hashes', () {
    final String result = generateServiceWorker(<String, String>{'/foo': 'abcd'}, <String>[], serviceWorkerStrategy: ServiceWorkerStrategy.offlineFirst);

    expect(result, contains('{\n  "/foo": "abcd"\n};'));
  });

  testWithoutContext('Generated service worker includes core files', () {
    final String result = generateServiceWorker(<String, String>{'/foo': 'abcd'}, <String>['foo', 'bar'], serviceWorkerStrategy: ServiceWorkerStrategy.offlineFirst);

    expect(result, contains('"foo",\n"bar"'));
  });

  testWithoutContext('WebServiceWorker generates a service_worker for a web resource folder', () async {
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
  });

  testWithoutContext('WebServiceWorker contains baseUrl cache', () async {
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
  });

  testWithoutContext('WebServiceWorker does not cache source maps', () async {
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
  });
}
