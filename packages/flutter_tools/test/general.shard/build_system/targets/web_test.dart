// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/depfile.dart';
import 'package:flutter_tools/src/build_system/targets/web.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/html_utils.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:flutter_tools/src/web/file_generators/flutter_js.dart' as flutter_js;
import 'package:flutter_tools/src/web/file_generators/flutter_service_worker_js.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';
import '../../../src/testbed.dart';

const List<String> _kDart2jsLinuxArgs = <String>[
  'Artifact.engineDartBinary.TargetPlatform.web_javascript',
  '--disable-dart-dev',
  'Artifact.dart2jsSnapshot.TargetPlatform.web_javascript',
  '--platform-binaries=HostArtifact.webPlatformKernelFolder',
  '--invoker=flutter_tool',
];

const List<String> _kDart2WasmLinuxArgs = <String> [
  'Artifact.engineDartAotRuntime.TargetPlatform.web_javascript',
  '--disable-dart-dev',
  'Artifact.dart2wasmSnapshot.TargetPlatform.web_javascript',
  '--packages=.dart_tool/package_config.json',
  '--dart-sdk=Artifact.engineDartSdkPath.TargetPlatform.web_javascript',
  '--multi-root-scheme',
  'org-dartlang-sdk',
  '--multi-root',
  'HostArtifact.flutterWebSdk',
  '--multi-root',
  _kDartSdkRoot,
  '--libraries-spec',
  'HostArtifact.flutterWebLibrariesJson',
];

const List<String> _kWasmOptLinuxArgrs = <String> [
  'Artifact.wasmOptBinary.TargetPlatform.web_javascript',
  '--all-features',
  '--closed-world',
  '--traps-never-happen',
  '-O3',
  '--type-ssa',
  '--gufa',
  '-O3',
  '--type-merging',
];

/// The result of calling `.parent` on a Memory directory pointing to
/// `'Artifact.engineDartSdkPath.TargetPlatform.web_javascript'`.
const String _kDartSdkRoot = '.';

void main() {
  late Testbed testbed;
  late Environment environment;
  late FakeProcessManager processManager;
  final Platform linux = FakePlatform(
    environment: <String, String>{},
  );
  final Platform windows = FakePlatform(
    operatingSystem: 'windows',
    environment: <String, String>{},
  );

  setUp(() {
    testbed = Testbed(setup: () {
      globals.fs.file('.packages')
        ..createSync(recursive: true)
        ..writeAsStringSync('foo:foo/lib/\n');
      globals.fs.currentDirectory.childDirectory('bar').createSync();
      processManager = FakeProcessManager.empty();

      environment = Environment.test(
        globals.fs.currentDirectory,
        projectDir: globals.fs.currentDirectory.childDirectory('foo'),
        outputDir: globals.fs.currentDirectory.childDirectory('bar'),
        defines: <String, String>{
          kTargetFile: globals.fs.path.join('foo', 'lib', 'main.dart'),
        },
        artifacts: Artifacts.test(),
        processManager: processManager,
        logger: globals.logger,
        fileSystem: globals.fs,
      );
      environment.buildDir.createSync(recursive: true);
    }, overrides: <Type, Generator>{
      Platform: () => linux,
    });
  });

  test('WebEntrypointTarget generates an entrypoint with plugins and init platform', () => testbed.run(() async {
    final File mainFile = globals.fs.file(globals.fs.path.join('foo', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');
    environment.defines[kTargetFile] = mainFile.path;
    environment.defines[kHasWebPlugins] = 'true';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Plugins
    expect(generated, contains("import 'web_plugin_registrant.dart' as pluginRegistrant;"));
    expect(generated, contains('pluginRegistrant.registerPlugins();'));

    // Import.
    expect(generated, contains("import 'package:foo/main.dart' as entrypoint;"));

    // Main
    expect(generated, contains('ui_web.bootstrapEngine('));
    expect(generated, contains('entrypoint.main as _'));
  }, overrides: <Type, Generator>{
    TemplateRenderer: () => const MustacheTemplateRenderer(),
  }));

  test('version.json is created after release build', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    final Directory webResources = environment.projectDir.childDirectory('web');
    webResources.childFile('index.html')
        .createSync(recursive: true);
    environment.buildDir.childFile('main.dart.js').createSync();
    await const WebReleaseBundle(WebRendererMode.auto, isWasm: false).build(environment);

    expect(environment.outputDir.childFile('version.json'), exists);
  }));

    test('override version values', () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      environment.defines[kBuildName] = '2.0.0';
      environment.defines[kBuildNumber] = '22';
      final Directory webResources = environment.projectDir.childDirectory('web');
      webResources.childFile('index.html').createSync(recursive: true);
      environment.buildDir.childFile('main.dart.js').createSync();
      await const WebReleaseBundle(WebRendererMode.auto, isWasm: false).build(environment);

      final String versionFile = environment.outputDir
          .childFile('version.json')
          .readAsStringSync();
      expect(versionFile, contains('"version":"2.0.0"'));
      expect(versionFile, contains('"build_number":"22"'));
    }));

  test('Base href is created in index.html with given base-href after release build', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[kBaseHref] = '/basehreftest/';
    final Directory webResources = environment.projectDir.childDirectory('web');
    webResources.childFile('index.html').createSync(recursive: true);
    webResources.childFile('index.html').writeAsStringSync('''
<!DOCTYPE html><html><base href="$kBaseHrefPlaceholder"><head></head></html>
    ''');
    environment.buildDir.childFile('main.dart.js').createSync();
    await const WebReleaseBundle(WebRendererMode.auto, isWasm: false).build(environment);

    expect(environment.outputDir.childFile('index.html').readAsStringSync(), contains('/basehreftest/'));
  }));

  test('null base href does not override existing base href in index.html', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    final Directory webResources = environment.projectDir.childDirectory('web');
    webResources.childFile('index.html').createSync(recursive: true);
    webResources.childFile('index.html').writeAsStringSync('''
<!DOCTYPE html><html><head><base href='/basehreftest/'></head></html>
    ''');
    environment.buildDir.childFile('main.dart.js').createSync();
    await const WebReleaseBundle(WebRendererMode.auto, isWasm: false).build(environment);

    expect(environment.outputDir.childFile('index.html').readAsStringSync(), contains('/basehreftest/'));
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

    await const WebReleaseBundle(WebRendererMode.auto, isWasm: false).build(environment);

    expect(environment.outputDir.childFile('foo.txt')
      .readAsStringSync(), 'A');
    expect(environment.outputDir.childFile('main.dart.js')
      .existsSync(), true);
    expect(environment.outputDir.childDirectory('assets')
      .childFile('AssetManifest.json').existsSync(), true);

    // Update to arbitrary resource file triggers rebuild.
    webResources.childFile('foo.txt').writeAsStringSync('B');

    await const WebReleaseBundle(WebRendererMode.auto, isWasm: false).build(environment);

    expect(environment.outputDir.childFile('foo.txt')
      .readAsStringSync(), 'B');
    // Appends number to requests for service worker only
    expect(environment.outputDir.childFile('index.html').readAsStringSync(), allOf(
      contains('<script src="main.dart.js" type="application/javascript">'),
      contains('flutter_service_worker.js?v='),
    ));
  }));

  test('WebEntrypointTarget generates an entrypoint for a file outside of main', () => testbed.run(() async {
    final File mainFile = globals.fs.file(globals.fs.path.join('other', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');
    environment.defines[kTargetFile] = mainFile.path;
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Import.
    expect(generated, contains("import 'file:///other/lib/main.dart' as entrypoint;"));
  }, overrides: <Type, Generator>{
    TemplateRenderer: () => const MustacheTemplateRenderer(),
  }));

  test('WebEntrypointTarget generates a plugin registrant for a file outside of main', () => testbed.run(() async {
    final File mainFile = globals.fs.file(globals.fs.path.join('other', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');
    environment.defines[kTargetFile] = mainFile.path;
    environment.defines[kHasWebPlugins] = 'true';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Import.
    expect(generated, contains("import 'file:///other/lib/main.dart' as entrypoint;"));
    expect(generated, contains("import 'web_plugin_registrant.dart' as pluginRegistrant;"));
  }, overrides: <Type, Generator>{
    TemplateRenderer: () => const MustacheTemplateRenderer(),
  }));


  test('WebEntrypointTarget generates an entrypoint with plugins and init platform on windows', () => testbed.run(() async {
    final File mainFile = globals.fs.file(globals.fs.path.join('foo', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');
    environment.defines[kTargetFile] = mainFile.path;

    environment.defines[kHasWebPlugins] = 'true';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Plugins
    expect(generated, contains("import 'web_plugin_registrant.dart' as pluginRegistrant;"));
    expect(generated, contains('pluginRegistrant.registerPlugins();'));

    // Import.
    expect(generated, contains("import 'package:foo/main.dart' as entrypoint;"));

    // Main
    expect(generated, contains('ui_web.bootstrapEngine('));
    expect(generated, contains('entrypoint.main as _'));
  }, overrides: <Type, Generator>{
    Platform: () => windows,
    TemplateRenderer: () => const MustacheTemplateRenderer(),
  }));

  test('WebEntrypointTarget generates an entrypoint without plugins and init platform', () => testbed.run(() async {
    final File mainFile = globals.fs.file(globals.fs.path.join('foo', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');
    environment.defines[kTargetFile] = mainFile.path;
    environment.defines[kHasWebPlugins] = 'false';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Plugins (the generated file is a noop)
    expect(generated, contains("import 'web_plugin_registrant.dart' as pluginRegistrant;"));
    expect(generated, contains('pluginRegistrant.registerPlugins();'));

    // Import.
    expect(generated, contains("import 'package:foo/main.dart' as entrypoint;"));

    // Main
    expect(generated, contains('ui_web.bootstrapEngine('));
    expect(generated, contains('entrypoint.main as _'));
  }, overrides: <Type, Generator>{
    TemplateRenderer: () => const MustacheTemplateRenderer(),
  }));

  test('WebEntrypointTarget generates an entrypoint with a language version', () => testbed.run(() async {
    final File mainFile = globals.fs.file(globals.fs.path.join('foo', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('// @dart=2.8\nvoid main() {}');
    environment.defines[kTargetFile] = mainFile.path;
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Language version
    expect(generated, contains('// @dart=2.8'));
  }, overrides: <Type, Generator>{
    TemplateRenderer: () => const MustacheTemplateRenderer(),
  }));

  test('WebEntrypointTarget generates an entrypoint with a language version from a package config', () => testbed.run(() async {
    final File mainFile = globals.fs.file(globals.fs.path.join('foo', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');
    globals.fs.file(globals.fs.path.join('pubspec.yaml'))
      .writeAsStringSync('name: foo\n');
    environment.defines[kTargetFile] = mainFile.path;
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Language version
    expect(generated, contains('// @dart=2.7'));
  }, overrides: <Type, Generator>{
    TemplateRenderer: () => const MustacheTemplateRenderer(),
  }));

  test('WebEntrypointTarget generates an entrypoint without plugins and without init platform', () => testbed.run(() async {
    final File mainFile = globals.fs.file(globals.fs.path.join('foo', 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');
    environment.defines[kTargetFile] = mainFile.path;
    environment.defines[kHasWebPlugins] = 'false';
    await const WebEntrypointTarget().build(environment);

    final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

    // Plugins
    expect(generated, contains("import 'web_plugin_registrant.dart' as pluginRegistrant;"));
    expect(generated, contains('pluginRegistrant.registerPlugins();'));

    // Import.
    expect(generated, contains("import 'package:foo/main.dart' as entrypoint;"));

    // Main
    expect(generated, contains('ui_web.bootstrapEngine('));
    expect(generated, contains('entrypoint.main as _'));
  }, overrides: <Type, Generator>{
    TemplateRenderer: () => const MustacheTemplateRenderer(),
  }));

  test('Dart2JSTarget calls dart2js with expected args with csp', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[JsCompilerConfig.kCspMode] = 'true';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '--no-source-maps',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.dart_tool/package_config.json',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '--no-minify',
        '--no-source-maps',
        '-O4',
        '--csp',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await Dart2JSTarget(WebRendererMode.auto).build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget ignores frontend server starter path option when calling dart2js', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[kFrontendServerStarterPath] = 'path/to/frontend_server_starter.dart';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '--no-source-maps',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.dart_tool/package_config.json',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '--no-minify',
        '--no-source-maps',
        '-O4',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await Dart2JSTarget(WebRendererMode.auto).build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget calls dart2js with expected args with enabled experiment', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[kExtraFrontEndOptions] = '--enable-experiment=non-nullable';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '--enable-experiment=non-nullable',
        '-Ddart.vm.profile=true',
        '--no-source-maps',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.dart_tool/package_config.json',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '--enable-experiment=non-nullable',
        '-Ddart.vm.profile=true',
        '--no-minify',
        '--no-source-maps',
        '-O4',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await Dart2JSTarget(WebRendererMode.auto).build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget calls dart2js with expected args in profile mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '--no-source-maps',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.dart_tool/package_config.json',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '--no-minify',
        '--no-source-maps',
        '-O4',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await Dart2JSTarget(WebRendererMode.auto).build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget calls dart2js with expected args in release mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '--no-source-maps',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.dart_tool/package_config.json',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '--no-source-maps',
        '-O4',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await Dart2JSTarget(WebRendererMode.auto).build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget calls dart2js with expected args in release mode with native null assertions', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[JsCompilerConfig.kNativeNullAssertions] = 'true';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '--native-null-assertions',
        '--no-source-maps',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.dart_tool/package_config.json',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '--native-null-assertions',
        '--no-source-maps',
        '-O4',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await Dart2JSTarget(WebRendererMode.auto).build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget calls dart2js with expected args in release with dart2js optimization override', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[JsCompilerConfig.kDart2jsOptimization] = 'O3';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '--no-source-maps',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.dart_tool/package_config.json',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '--no-source-maps',
        '-O3',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await Dart2JSTarget(WebRendererMode.auto).build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget produces expected depfile', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '--no-source-maps',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.dart_tool/package_config.json',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ], onRun: () {
        environment.buildDir.childFile('app.dill.deps')
          .writeAsStringSync('file:///a.dart');
      },
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '--no-source-maps',
        '-O4',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await Dart2JSTarget(WebRendererMode.auto).build(environment);

    expect(environment.buildDir.childFile('dart2js.d'), exists);
    final Depfile depfile = environment.depFileService.parse(environment.buildDir.childFile('dart2js.d'));

    expect(depfile.inputs.single.path, globals.fs.path.absolute('a.dart'));
    expect(depfile.outputs.single.path,
      environment.buildDir.childFile('main.dart.js').absolute.path);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget calls dart2js with Dart defines in release mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[kDartDefines] = encodeDartDefines(<String>['FOO=bar', 'BAZ=qux']);
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '-DFOO=bar',
        '-DBAZ=qux',
        '--no-source-maps',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.dart_tool/package_config.json',
       '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
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

    await Dart2JSTarget(WebRendererMode.auto).build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget can enable source maps', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[JsCompilerConfig.kSourceMapsEnabled] = 'true';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.dart_tool/package_config.json',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '-O4',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await Dart2JSTarget(WebRendererMode.auto).build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));


  test('Dart2JSTarget calls dart2js with Dart defines in profile mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[kDartDefines] = encodeDartDefines(<String>['FOO=bar', 'BAZ=qux']);
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '-DFOO=bar',
        '-DBAZ=qux',
        '--no-source-maps',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.dart_tool/package_config.json',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '-DFOO=bar',
        '-DBAZ=qux',
        '--no-minify',
        '--no-source-maps',
        '-O4',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await Dart2JSTarget(WebRendererMode.auto).build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget calls dart2js with expected args with dump-info', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[JsCompilerConfig.kDart2jsDumpInfo] = 'true';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '--no-source-maps',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.dart_tool/package_config.json',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '--no-minify',
        '--no-source-maps',
        '-O4',
        '--dump-info',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await Dart2JSTarget(WebRendererMode.canvaskit).build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2JSTarget calls dart2js with expected args with no-frequency-based-minification', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[JsCompilerConfig.kDart2jsNoFrequencyBasedMinification] = 'true';
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '--no-source-maps',
        '-o',
        environment.buildDir.childFile('app.dill').absolute.path,
        '--packages=.dart_tool/package_config.json',
        '--cfe-only',
        environment.buildDir.childFile('main.dart').absolute.path,
      ]
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '--no-minify',
        '--no-source-maps',
        '-O4',
        '--no-frequency-based-minification',
        '-o',
        environment.buildDir.childFile('main.dart.js').absolute.path,
        environment.buildDir.childFile('app.dill').absolute.path,
      ]
    ));

    await Dart2JSTarget(WebRendererMode.canvaskit).build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2WasmTarget invokes dart2wasm with dart defines', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'profile';
    environment.defines[WasmCompilerConfig.kRunWasmOpt] = WasmOptLevel.defaultValue.name;
    environment.defines[kDartDefines] = encodeDartDefines(<String>['FOO=bar', 'BAZ=qux']);

    final File depFile = environment.buildDir.childFile('dart2wasm.d');

    final File outputJsFile = environment.buildDir.childFile('main.dart.unopt.mjs');
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2WasmLinuxArgs,
        '-Ddart.vm.profile=true',
        '-DFOO=bar',
        '-DBAZ=qux',
        '--depfile=${depFile.absolute.path}',
        environment.buildDir.childFile('main.dart').absolute.path,
        environment.buildDir.childFile('main.dart.unopt.wasm').absolute.path,
      ],
      onRun: () => outputJsFile..createSync()..writeAsStringSync('foo'))
    );

    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kWasmOptLinuxArgrs,
        environment.buildDir.childFile('main.dart.unopt.wasm').absolute.path,
        '-o',
        environment.buildDir.childFile('main.dart.wasm').absolute.path,
      ])
    );

    await Dart2WasmTarget(WebRendererMode.canvaskit).build(environment);

    expect(outputJsFile.existsSync(), isFalse);
    final File movedJsFile = environment.buildDir.childFile('main.dart.mjs');
    expect(movedJsFile.existsSync(), isTrue);
    expect(movedJsFile.readAsStringSync(), 'foo');
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2WasmTarget invokes dart2wasm with omit checks', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[WasmCompilerConfig.kRunWasmOpt] = WasmOptLevel.defaultValue.name;
    environment.defines[WasmCompilerConfig.kOmitTypeChecks] = 'true';

    final File depFile = environment.buildDir.childFile('dart2wasm.d');

    final File outputJsFile = environment.buildDir.childFile('main.dart.unopt.mjs');
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2WasmLinuxArgs,
        '-Ddart.vm.product=true',
        '--omit-type-checks',
        '--depfile=${depFile.absolute.path}',
        environment.buildDir.childFile('main.dart').absolute.path,
        environment.buildDir.childFile('main.dart.unopt.wasm').absolute.path,
      ],
      onRun: () => outputJsFile..createSync()..writeAsStringSync('foo'))
    );

    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kWasmOptLinuxArgrs,
        environment.buildDir.childFile('main.dart.unopt.wasm').absolute.path,
        '-o',
        environment.buildDir.childFile('main.dart.wasm').absolute.path,
      ])
    );

    await Dart2WasmTarget(WebRendererMode.canvaskit).build(environment);

    expect(outputJsFile.existsSync(), isFalse);
    final File movedJsFile = environment.buildDir.childFile('main.dart.mjs');
    expect(movedJsFile.existsSync(), isTrue);
    expect(movedJsFile.readAsStringSync(), 'foo');
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2WasmTarget invokes dart2wasm and wasm-opt with debug info in wasmopt debug mode', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[WasmCompilerConfig.kRunWasmOpt] = WasmOptLevel.debug.name;

    final File depFile = environment.buildDir.childFile('dart2wasm.d');

    final File outputJsFile = environment.buildDir.childFile('main.dart.unopt.mjs');
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2WasmLinuxArgs,
        '-Ddart.vm.product=true',
        '--depfile=${depFile.absolute.path}',
        environment.buildDir.childFile('main.dart').absolute.path,
        environment.buildDir.childFile('main.dart.unopt.wasm').absolute.path,
      ], onRun: () => outputJsFile..createSync()..writeAsStringSync('foo')));

      processManager.addCommand(FakeCommand(
        command: <String>[
          ..._kWasmOptLinuxArgrs,
          '--debuginfo',
          environment.buildDir.childFile('main.dart.unopt.wasm').absolute.path,
          '-o',
          environment.buildDir.childFile('main.dart.wasm').absolute.path,
        ]));

    await Dart2WasmTarget(WebRendererMode.canvaskit).build(environment);

    expect(outputJsFile.existsSync(), isFalse);
    final File movedJsFile = environment.buildDir.childFile('main.dart.mjs');
    expect(movedJsFile.existsSync(), isTrue);
    expect(movedJsFile.readAsStringSync(), 'foo');
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2WasmTarget invokes dart2wasm (but not wasm-opt) with wasm-opt none option', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'debug';
    environment.defines[WasmCompilerConfig.kRunWasmOpt] = WasmOptLevel.none.name;

    final File depFile = environment.buildDir.childFile('dart2wasm.d');

    final File outputJsFile = environment.buildDir.childFile('main.dart.mjs');
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2WasmLinuxArgs,
        '-Ddart.vm.product=true',
        '--depfile=${depFile.absolute.path}',
        environment.buildDir.childFile('main.dart').absolute.path,
        environment.buildDir.childFile('main.dart.wasm').absolute.path,
      ], onRun: () => outputJsFile..createSync()..writeAsStringSync('foo')));

    await Dart2WasmTarget(WebRendererMode.canvaskit).build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Dart2WasmTarget with skwasm renderer adds extra flags', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';
    environment.defines[WasmCompilerConfig.kRunWasmOpt] = WasmOptLevel.defaultValue.name;
    final File depFile = environment.buildDir.childFile('dart2wasm.d');

    final File outputJsFile = environment.buildDir.childFile('main.dart.unopt.mjs');
    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kDart2WasmLinuxArgs,
        '-Ddart.vm.product=true',
        '--import-shared-memory',
        '--shared-memory-max-pages=32768',
        '--depfile=${depFile.absolute.path}',
        environment.buildDir.childFile('main.dart').absolute.path,
        environment.buildDir.childFile('main.dart.unopt.wasm').absolute.path,
      ],
      onRun: () => outputJsFile..createSync()..writeAsStringSync('foo'))
    );

    processManager.addCommand(FakeCommand(
      command: <String>[
        ..._kWasmOptLinuxArgrs,
        environment.buildDir.childFile('main.dart.unopt.wasm').absolute.path,
        '-o',
        environment.buildDir.childFile('main.dart.wasm').absolute.path,
      ])
    );

    await Dart2WasmTarget(WebRendererMode.skwasm).build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('Generated service worker is empty with none-strategy', () => testbed.run(() {
    final String fileGeneratorsPath =
        environment.artifacts.getArtifactPath(Artifact.flutterToolsFileGenerators);
    final String result = generateServiceWorker(
      fileGeneratorsPath,
      <String, String>{'/foo': 'abcd'},
      <String>[],
      serviceWorkerStrategy: ServiceWorkerStrategy.none,
    );

    expect(result, '');
  }));

  test('Generated service worker correctly inlines file hashes', () => testbed.run(() {
    final String fileGeneratorsPath =
        environment.artifacts.getArtifactPath(Artifact.flutterToolsFileGenerators);
    final String result = generateServiceWorker(
      fileGeneratorsPath,
      <String, String>{'/foo': 'abcd'},
      <String>[],
      serviceWorkerStrategy: ServiceWorkerStrategy.offlineFirst,
    );

    expect(result, contains('{"/foo": "abcd"};'));
  }));

  test('Generated service worker includes core files', () => testbed.run(() {
    final String fileGeneratorsPath =
        environment.artifacts.getArtifactPath(Artifact.flutterToolsFileGenerators);
    final String result = generateServiceWorker(
      fileGeneratorsPath,
      <String, String>{'/foo': 'abcd'},
      <String>['foo', 'bar'],
      serviceWorkerStrategy: ServiceWorkerStrategy.offlineFirst,
    );

    expect(result, contains('"foo",\n"bar"'));
  }));

  test('WebServiceWorker generates a service_worker for a web resource folder', () => testbed.run(() async {
    environment.outputDir.childDirectory('a').childFile('a.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('A');
    await WebServiceWorker(globals.fs, WebRendererMode.auto, isWasm: false).build(environment);

    expect(environment.outputDir.childFile('flutter_service_worker.js'), exists);
    // Contains file hash.
    expect(environment.outputDir.childFile('flutter_service_worker.js').readAsStringSync(),
      contains('"a/a.txt": "7fc56270e7a70fa81a5935b72eacbe29"'));
    expect(environment.buildDir.childFile('service_worker.d'), exists);
    // Depends on resource file.
    expect(environment.buildDir.childFile('service_worker.d').readAsStringSync(),
      contains('a/a.txt'));
    // Does NOT contain NOTICES
    expect(environment.outputDir.childFile('flutter_service_worker.js').readAsStringSync(),
      isNot(contains('NOTICES')));
  }));

  test('WebServiceWorker contains baseUrl cache', () => testbed.run(() async {
    environment.outputDir
      .childFile('index.html')
      .createSync(recursive: true);
    await WebServiceWorker(globals.fs, WebRendererMode.auto, isWasm: false).build(environment);

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
    await WebServiceWorker(globals.fs, WebRendererMode.auto, isWasm: false).build(environment);

    // No caching of source maps.
    expect(environment.outputDir.childFile('flutter_service_worker.js').readAsStringSync(),
      isNot(contains('"main.dart.js.map"')));
    // Expected twice, once for RESOURCES and once for CORE.
    expect(environment.outputDir.childFile('flutter_service_worker.js').readAsStringSync(),
      contains('"main.dart.js"'));
  }));

  test('flutter.js sanity checks', () => testbed.run(() {
    final String fileGeneratorsPath = environment.artifacts
        .getArtifactPath(Artifact.flutterToolsFileGenerators);
    final String flutterJsContents =
        flutter_js.generateFlutterJsFile(fileGeneratorsPath);
    expect(flutterJsContents, contains('"use strict";'));
    expect(flutterJsContents, contains('main.dart.js'));
    expect(flutterJsContents, contains('if (!("serviceWorker" in navigator))'));
    expect(flutterJsContents, contains(r'/\.js$/,'));
    expect(flutterJsContents, contains('flutter_service_worker.js?v='));
    expect(flutterJsContents, contains('document.createElement("script")'));
    expect(flutterJsContents, contains('"application/javascript"'));
    expect(flutterJsContents, contains('const baseUri = '));
    expect(flutterJsContents, contains('document.querySelector("base")'));
    expect(flutterJsContents, contains('.getAttribute("href")'));
  }));

  test('flutter.js is not dynamically generated', () => testbed.run(() async {
    globals.fs.file('bin/cache/flutter_web_sdk/canvaskit/foo')
      ..createSync(recursive: true)
      ..writeAsStringSync('OL');

    await WebBuiltInAssets(globals.fs, WebRendererMode.auto, isWasm: false).build(environment);

    // No caching of source maps.
    final String fileGeneratorsPath = environment.artifacts
        .getArtifactPath(Artifact.flutterToolsFileGenerators);
    final String flutterJsContents =
        flutter_js.generateFlutterJsFile(fileGeneratorsPath);
    expect(
      environment.outputDir.childFile('flutter.js').readAsStringSync(),
      equals(flutterJsContents),
    );
  }));

  test('wasm build copies and generates specific files', () => testbed.run(() async {
    globals.fs.file('bin/cache/flutter_web_sdk/canvaskit/canvaskit.wasm')
      .createSync(recursive: true);

    await WebBuiltInAssets(globals.fs, WebRendererMode.auto, isWasm: true).build(environment);

    expect(environment.outputDir.childFile('main.dart.js').existsSync(), true);
    expect(environment.outputDir.childDirectory('canvaskit')
      .childFile('canvaskit.wasm')
      .existsSync(), true);
  }));

  test('wasm copies over canvaskit again if the web sdk changes', () => testbed.run(() async {
    final File canvasKitInput = globals.fs.file('bin/cache/flutter_web_sdk/canvaskit/canvaskit.wasm')
      ..createSync(recursive: true);
    canvasKitInput.writeAsStringSync('foo', flush: true);

    await WebBuiltInAssets(globals.fs, WebRendererMode.auto, isWasm: true).build(environment);

    final File canvasKitOutputBefore = environment.outputDir.childDirectory('canvaskit')
      .childFile('canvaskit.wasm');
    expect(canvasKitOutputBefore.existsSync(), true);
    expect(canvasKitOutputBefore.readAsStringSync(), 'foo');

    canvasKitInput.writeAsStringSync('bar', flush: true);

    await WebBuiltInAssets(globals.fs, WebRendererMode.auto, isWasm: true).build(environment);

    final File canvasKitOutputAfter = environment.outputDir.childDirectory('canvaskit')
      .childFile('canvaskit.wasm');
    expect(canvasKitOutputAfter.existsSync(), true);
    expect(canvasKitOutputAfter.readAsStringSync(), 'bar');
  }));
}
