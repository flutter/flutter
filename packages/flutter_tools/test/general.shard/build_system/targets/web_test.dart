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
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:flutter_tools/src/web/file_generators/flutter_service_worker_js.dart';
import 'package:flutter_tools/src/web_template.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';
import '../../../src/package_config.dart';
import '../../../src/testbed.dart';
import '../../../src/throwing_pub.dart';

const _kDart2jsLinuxArgs = <String>[
  'Artifact.engineDartBinary.TargetPlatform.web_javascript',
  'compile',
  'js',
  '--platform-binaries=HostArtifact.webPlatformKernelFolder',
  '--invoker=flutter_tool',
];

const _kStandardFlutterWebDefines = <String>[
  '-DFLUTTER_WEB_USE_SKIA=true',
  '-DFLUTTER_WEB_USE_SKWASM=false',
  '-DFLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/abcdefghijklmnopqrstuvwxyz/',
];

const _kDart2WasmLinuxArgs = <String>[
  'Artifact.engineDartBinary.TargetPlatform.web_javascript',
  'compile',
  'wasm',
  '--packages=/.dart_tool/package_config.json',
  '--extra-compiler-option=--platform=HostArtifact.webPlatformKernelFolder/dart2wasm_platform.dill',
];

void main() {
  late TestBed testbed;
  late Environment environment;
  late FakeProcessManager processManager;

  final Platform linux = FakePlatform(environment: <String, String>{});
  final Platform windows = FakePlatform(
    operatingSystem: 'windows',
    environment: <String, String>{},
  );

  setUp(() {
    testbed = TestBed(
      setup: () {
        globals.fs.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('''
name: foo
''');

        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'my_app',
          packages: <String, String>{'foo': 'foo/'},
          languageVersions: <String, String>{'foo': '2.7'},
        );
        globals.fs.currentDirectory.childDirectory('bar').createSync();
        processManager = FakeProcessManager.empty();
        globals.fs
            .file('bin/cache/flutter_web_sdk/flutter_js/flutter.js')
            .createSync(recursive: true);

        environment = Environment.test(
          globals.fs.currentDirectory,
          projectDir: globals.fs.currentDirectory.childDirectory('foo'),
          outputDir: globals.fs.currentDirectory.childDirectory('bar'),
          defines: <String, String>{
            kTargetFile: globals.fs.path.join('foo', 'lib', 'main.dart'),
            kBuildMode: BuildMode.debug.cliName,
          },
          artifacts: Artifacts.test(),
          processManager: processManager,
          logger: globals.logger,
          fileSystem: globals.fs,
        );
        environment.buildDir.createSync(recursive: true);
      },
      overrides: <Type, Generator>{Platform: () => linux},
    );
  });

  test(
    'WebEntrypointTarget generates an entrypoint with plugins and init platform',
    () => testbed.run(
      () async {
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
      },
      overrides: <Type, Generator>{
        TemplateRenderer: () => const MustacheTemplateRenderer(),
        Pub: ThrowingPub.new,
      },
    ),
  );

  test(
    'version.json is created after release build',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      final Directory webResources = environment.projectDir.childDirectory('web');
      webResources.childFile('index.html').createSync(recursive: true);
      environment.buildDir.childFile('main.dart.js').createSync();
      await WebReleaseBundle(<WebCompilerConfig>[
        const JsCompilerConfig(),
      ], const NoOpAnalytics()).build(environment);

      expect(environment.outputDir.childFile('version.json'), exists);
    }),
  );

  test(
    'override version values',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      environment.defines[kBuildName] = '2.0.0';
      environment.defines[kBuildNumber] = '22';
      final Directory webResources = environment.projectDir.childDirectory('web');
      webResources.childFile('index.html').createSync(recursive: true);
      environment.buildDir.childFile('main.dart.js').createSync();
      await WebReleaseBundle(<WebCompilerConfig>[
        const JsCompilerConfig(),
      ], const NoOpAnalytics()).build(environment);

      final String versionFile = environment.outputDir.childFile('version.json').readAsStringSync();
      expect(versionFile, contains('"version":"2.0.0"'));
      expect(versionFile, contains('"build_number":"22"'));
    }),
  );

  test(
    'Base href is created in index.html with given base-href after release build',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      environment.defines[kBaseHref] = '/basehreftest/';
      final Directory webResources = environment.projectDir.childDirectory('web');
      webResources.childFile('index.html').createSync(recursive: true);
      webResources.childFile('index.html').writeAsStringSync('''
<!DOCTYPE html><html><base href="$kBaseHrefPlaceholder"><head></head></html>
    ''');
      environment.buildDir.childFile('main.dart.js').createSync();
      await WebTemplatedFiles(<Map<String, Object?>>[]).build(environment);

      expect(
        environment.outputDir.childFile('index.html').readAsStringSync(),
        contains('/basehreftest/'),
      );
    }),
  );

  test(
    'WebTemplatedFiles emits useLocalCanvasKit in flutter_bootstrap.js when environment specifies',
    () => testbed.run(() async {
      environment.defines[kUseLocalCanvasKitFlag] = 'true';
      final Directory webResources = environment.projectDir.childDirectory('web');
      webResources.childFile('index.html').createSync(recursive: true);
      webResources.childFile('index.html').writeAsStringSync('''
<!DOCTYPE html><html><base href="$kBaseHrefPlaceholder"><head></head></html>
    ''');
      environment.buildDir.childFile('main.dart.js').createSync();
      await WebTemplatedFiles(<Map<String, Object?>>[]).build(environment);

      expect(
        environment.outputDir.childFile('flutter_bootstrap.js').readAsStringSync(),
        contains('"useLocalCanvasKit":true'),
      );
    }),
  );

  test(
    'WebTemplatedFiles includes serviceWorkerSettings in flutter_bootstrap.js by default',
    () => testbed.run(() async {
      final Directory webResources = environment.projectDir.childDirectory('web');
      environment.defines[kServiceWorkerStrategy] = 'none';
      webResources.childFile('index.html').createSync(recursive: true);
      environment.buildDir.childFile('main.dart.js').createSync();
      await WebTemplatedFiles(<Map<String, Object?>>[]).build(environment);

      expect(
        environment.outputDir.childFile('flutter_bootstrap.js').readAsStringSync(),
        contains('_flutter.loader.load();'),
      );
    }),
  );

  test(
    'WebTemplatedFiles omits serviceWorkerSettings in flutter_bootstrap.js when environment specifies',
    () => testbed.run(() async {
      final Directory webResources = environment.projectDir.childDirectory('web');
      webResources.childFile('index.html').createSync(recursive: true);
      environment.buildDir.childFile('main.dart.js').createSync();
      await WebTemplatedFiles(<Map<String, Object?>>[]).build(environment);

      expect(
        environment.outputDir.childFile('flutter_bootstrap.js').readAsStringSync(),
        stringContainsInOrder(<String>[
          '_flutter.loader.load({',
          'serviceWorkerSettings',
          'serviceWorkerVersion',
        ]),
      );
    }),
  );

  test(
    'null base href does not override existing base href in index.html',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      final Directory webResources = environment.projectDir.childDirectory('web');
      webResources.childFile('index.html').createSync(recursive: true);
      webResources.childFile('index.html').writeAsStringSync('''
<!DOCTYPE html><html><head><base href='/basehreftest/'></head></html>
    ''');
      environment.buildDir.childFile('main.dart.js').createSync();
      await WebTemplatedFiles(<Map<String, Object?>>[]).build(environment);

      expect(
        environment.outputDir.childFile('index.html').readAsStringSync(),
        contains('/basehreftest/'),
      );
    }),
  );

  group('--static-assets-url', () {
    test(
      'WebTemplatedFiles replaces placeholder with given value',
      () => testbed.run(() async {
        environment.defines[kStaticAssetsUrl] = 'https://static.example.com/example-app/';
        final Directory webResources = environment.projectDir.childDirectory('web');
        webResources.childFile('index.html').createSync(recursive: true);
        webResources.childFile('index.html').writeAsStringSync('''
<!DOCTYPE html><html><body><script>const staticAssetsUrl = "$kStaticAssetsUrlPlaceholder";</script></body></html>
    ''');
        environment.buildDir.childFile('main.dart.js').createSync();
        await WebTemplatedFiles(<Map<String, Object?>>[]).build(environment);

        expect(
          environment.outputDir.childFile('index.html').readAsStringSync(),
          contains('https://static.example.com/example-app/'),
        );
      }),
    );

    test(
      'WebTemplatedFiles replaces placeholder with / when not set',
      () => testbed.run(() async {
        final Directory webResources = environment.projectDir.childDirectory('web');
        webResources.childFile('index.html').createSync(recursive: true);
        webResources.childFile('index.html').writeAsStringSync('''
<!DOCTYPE html><html><body><script>const staticAssetsUrl = "$kStaticAssetsUrlPlaceholder";</script></body></html>
    ''');
        environment.buildDir.childFile('main.dart.js').createSync();
        await WebTemplatedFiles(<Map<String, Object?>>[]).build(environment);

        expect(
          environment.outputDir.childFile('index.html').readAsStringSync(),
          contains('staticAssetsUrl = "/"'),
        );
      }),
    );
  });

  test(
    'WebReleaseBundle copies dart2js output and resource files to output directory',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      final Directory webResources = environment.projectDir.childDirectory('web');
      webResources.childFile('foo.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('A');
      environment.buildDir.childFile('main.dart.js').createSync();
      environment.buildDir.childFile('main.dart.js.info.json').createSync();
      environment.buildDir.childFile('main.dart.js.map').createSync();
      environment.buildDir.childFile('main.dart.js_1.part.js').createSync();
      environment.buildDir.childFile('main.dart.js_1.part.js.map').createSync();

      await WebReleaseBundle(<WebCompilerConfig>[
        const JsCompilerConfig(dumpInfo: true),
      ], const NoOpAnalytics()).build(environment);

      expect(environment.outputDir.childFile('foo.txt').readAsStringSync(), 'A');
      expect(environment.outputDir.childFile('main.dart.js').existsSync(), true);
      expect(environment.outputDir.childFile('main.dart.js.info.json').existsSync(), true);
      expect(environment.outputDir.childFile('main.dart.js.map').existsSync(), true);
      expect(environment.outputDir.childFile('main.dart.js_1.part.js').existsSync(), true);
      expect(environment.outputDir.childFile('main.dart.js_1.part.js.map').existsSync(), true);
      expect(
        environment.outputDir
            .childDirectory('assets')
            .childFile('AssetManifest.bin.json')
            .existsSync(),
        true,
      );

      // Update to arbitrary resource file triggers rebuild.
      webResources.childFile('foo.txt').writeAsStringSync('B');

      await WebReleaseBundle(<WebCompilerConfig>[
        const JsCompilerConfig(),
      ], const NoOpAnalytics()).build(environment);

      expect(environment.outputDir.childFile('foo.txt').readAsStringSync(), 'B');
    }),
  );

  test(
    'WebReleaseBundle copies over output files when they change',
    () => testbed.run(() async {
      final Directory webResources = environment.projectDir.childDirectory('web');
      webResources.childFile('foo.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('A');

      environment.buildDir.childFile('main.dart.wasm')
        ..createSync()
        ..writeAsStringSync('old wasm');
      environment.buildDir.childFile('main.dart.mjs')
        ..createSync()
        ..writeAsStringSync('old mjs');
      await WebReleaseBundle(<WebCompilerConfig>[
        const WasmCompilerConfig(),
      ], const NoOpAnalytics()).build(environment);
      expect(environment.outputDir.childFile('main.dart.wasm').readAsStringSync(), 'old wasm');
      expect(environment.outputDir.childFile('main.dart.mjs').readAsStringSync(), 'old mjs');

      environment.buildDir.childFile('main.dart.wasm')
        ..createSync()
        ..writeAsStringSync('new wasm');
      environment.buildDir.childFile('main.dart.mjs')
        ..createSync()
        ..writeAsStringSync('new mjs');

      await WebReleaseBundle(<WebCompilerConfig>[
        const WasmCompilerConfig(),
      ], const NoOpAnalytics()).build(environment);

      expect(environment.outputDir.childFile('main.dart.wasm').readAsStringSync(), 'new wasm');
      expect(environment.outputDir.childFile('main.dart.mjs').readAsStringSync(), 'new mjs');
    }),
  );

  test(
    'WebEntrypointTarget generates an entrypoint for a file outside of main',
    () => testbed.run(
      () async {
        final File mainFile = globals.fs.file(globals.fs.path.join('other', 'lib', 'main.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync('void main() {}');
        environment.defines[kTargetFile] = mainFile.path;
        await const WebEntrypointTarget().build(environment);

        final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

        // Import.
        expect(generated, contains("import 'file:///other/lib/main.dart' as entrypoint;"));
      },
      overrides: <Type, Generator>{
        TemplateRenderer: () => const MustacheTemplateRenderer(),
        Pub: ThrowingPub.new,
      },
    ),
  );

  test(
    'WebEntrypointTarget generates a plugin registrant for a file outside of main',
    () => testbed.run(
      () async {
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
      },
      overrides: <Type, Generator>{
        TemplateRenderer: () => const MustacheTemplateRenderer(),
        Pub: ThrowingPub.new,
      },
    ),
  );

  test(
    'WebEntrypointTarget generates an entrypoint with plugins and init platform on windows',
    () => testbed.run(
      () async {
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
      },
      overrides: <Type, Generator>{
        Platform: () => windows,
        TemplateRenderer: () => const MustacheTemplateRenderer(),
        Pub: ThrowingPub.new,
      },
    ),
  );

  test(
    'WebEntrypointTarget generates an entrypoint without plugins and init platform',
    () => testbed.run(
      () async {
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
      },
      overrides: <Type, Generator>{
        TemplateRenderer: () => const MustacheTemplateRenderer(),
        Pub: ThrowingPub.new,
      },
    ),
  );

  test(
    'WebEntrypointTarget generates an entrypoint with a language version',
    () => testbed.run(
      () async {
        final File mainFile = globals.fs.file(globals.fs.path.join('foo', 'lib', 'main.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync('// @dart=2.8\nvoid main() {}');
        environment.defines[kTargetFile] = mainFile.path;
        await const WebEntrypointTarget().build(environment);

        final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

        // Language version
        expect(generated, contains('// @dart=2.8'));
      },
      overrides: <Type, Generator>{
        TemplateRenderer: () => const MustacheTemplateRenderer(),
        Pub: ThrowingPub.new,
      },
    ),
  );

  test(
    'WebEntrypointTarget generates an entrypoint with a language version from a package config',
    () => testbed.run(
      () async {
        final File mainFile = globals.fs.file(globals.fs.path.join('foo', 'lib', 'main.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync('void main() {}');
        globals.fs.file(globals.fs.path.join('pubspec.yaml')).writeAsStringSync('name: foo\n');
        environment.defines[kTargetFile] = mainFile.path;
        await const WebEntrypointTarget().build(environment);

        final String generated = environment.buildDir.childFile('main.dart').readAsStringSync();

        // Language version
        expect(generated, contains('// @dart=2.7'));
      },
      overrides: <Type, Generator>{
        TemplateRenderer: () => const MustacheTemplateRenderer(),
        Pub: ThrowingPub.new,
      },
    ),
  );

  test(
    'WebEntrypointTarget generates an entrypoint without plugins and without init platform',
    () => testbed.run(
      () async {
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
      },
      overrides: <Type, Generator>{
        TemplateRenderer: () => const MustacheTemplateRenderer(),
        Pub: ThrowingPub.new,
      },
    ),
  );

  test(
    'Dart2JSTarget calls dart2js with expected args with csp',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'profile';
      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        ..._kStandardFlutterWebDefines,
        '--no-source-maps',
        '-O4',
        '--no-minify',
        '--csp',
        '-o',
      ];
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(const JsCompilerConfig(csp: true, sourceMaps: false)).build(environment);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget calls dart2js with expected args with minify false',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        ..._kStandardFlutterWebDefines,
        '-O4',
        '--no-minify',
        '-o',
      ];
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(const JsCompilerConfig(minify: false)).build(environment);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget ignores frontend server starter path option when calling dart2js',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'profile';
      environment.defines[kFrontendServerStarterPath] = 'path/to/frontend_server_starter.dart';
      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        ..._kStandardFlutterWebDefines,
        '--no-source-maps',
        '-O4',
        '--no-minify',
        '-o',
      ];
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(const JsCompilerConfig(sourceMaps: false)).build(environment);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget calls dart2js with expected args with enabled experiment',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'profile';
      environment.defines[kExtraFrontEndOptions] = '--enable-experiment=non-nullable';
      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '--enable-experiment=non-nullable',
        '-Ddart.vm.profile=true',
        ..._kStandardFlutterWebDefines,
        '--no-source-maps',
        '-O4',
        '--no-minify',
        '-o',
      ];
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(const JsCompilerConfig(sourceMaps: false)).build(environment);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget calls dart2js with expected args in profile mode',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'profile';
      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        ..._kStandardFlutterWebDefines,
        '--no-source-maps',
        '-O4',
        '--no-minify',
        '-o',
      ];
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(const JsCompilerConfig(sourceMaps: false)).build(environment);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget calls dart2js with expected args in release mode',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        ..._kStandardFlutterWebDefines,
        '--no-source-maps',
        '-O4',
        '--minify',
        '-o',
      ];
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(const JsCompilerConfig(sourceMaps: false)).build(environment);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget calls dart2js with expected args in release mode with native null assertions',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        ..._kStandardFlutterWebDefines,
        '--native-null-assertions',
        '--no-source-maps',
        '-O4',
        '--minify',
        '-o',
      ];
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(
        const JsCompilerConfig(nativeNullAssertions: true, sourceMaps: false),
      ).build(environment);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget calls dart2js with expected args in release with dart2js optimization override',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        ..._kStandardFlutterWebDefines,
        '--no-source-maps',
        '-O3',
        '--minify',
        '-o',
      ];
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(
        const JsCompilerConfig(optimizationLevel: 3, sourceMaps: false),
      ).build(environment);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget produces expected depfile',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        ..._kStandardFlutterWebDefines,
        '--no-source-maps',
        '-O4',
        '--minify',
        '-o',
      ];
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
          onRun: (_) {
            environment.buildDir.childFile('app.dill.deps').writeAsStringSync('file:///a.dart');
          },
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(const JsCompilerConfig(sourceMaps: false)).build(environment);

      expect(environment.buildDir.childFile('dart2js.d'), exists);
      final Depfile depfile = environment.depFileService.parse(
        environment.buildDir.childFile('dart2js.d'),
      );

      expect(depfile.inputs.single.path, globals.fs.path.absolute('a.dart'));
      expect(
        depfile.outputs.single.path,
        environment.buildDir.childFile('main.dart.js').absolute.path,
      );
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget calls dart2js with Dart defines in release mode',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      environment.defines[kDartDefines] = encodeDartDefines(<String>['FOO=bar', 'BAZ=qux']);
      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        '-DFOO=bar',
        '-DBAZ=qux',
        ..._kStandardFlutterWebDefines,
        '--no-source-maps',
        '-O4',
        '--minify',
        '-o',
      ];
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(const JsCompilerConfig(sourceMaps: false)).build(environment);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget can enable source maps',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      environment.defines[WebCompilerConfig.kSourceMapsEnabled] = 'true';
      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.product=true',
        ..._kStandardFlutterWebDefines,
        '-O4',
        '--minify',
        '-o',
      ];
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(const JsCompilerConfig()).build(environment);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget calls dart2js with Dart defines in profile mode',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'profile';
      environment.defines[kDartDefines] = encodeDartDefines(<String>['FOO=bar', 'BAZ=qux']);
      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        '-DFOO=bar',
        '-DBAZ=qux',
        ..._kStandardFlutterWebDefines,
        '--no-source-maps',
        '-O4',
        '--no-minify',
        '-o',
      ];
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(const JsCompilerConfig(sourceMaps: false)).build(environment);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget calls dart2js with Dart defines in debug mode',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'debug';
      environment.defines[kDartDefines] = encodeDartDefines(<String>['FOO=bar', 'BAZ=qux']);
      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '-DFOO=bar',
        '-DBAZ=qux',
        ..._kStandardFlutterWebDefines,
        '--no-source-maps',
        '--enable-asserts',
        '-O1',
        '--no-minify',
        '-o',
      ];
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(const JsCompilerConfig(sourceMaps: false)).build(environment);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget calls dart2js with expected args with dump-info',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'profile';
      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        ..._kStandardFlutterWebDefines,
        '--no-source-maps',
        '-O4',
        '--no-minify',
      ];
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            '-o',
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            '--stage=dump-info-all',
            '-o',
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(
        const JsCompilerConfig(dumpInfo: true, sourceMaps: false),
      ).build(environment);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget calls dart2js with expected args with no-frequency-based-minification',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'profile';

      final common = <String>[
        ..._kDart2jsLinuxArgs,
        '-Ddart.vm.profile=true',
        ..._kStandardFlutterWebDefines,
        '--no-source-maps',
        '-O4',
        '--no-minify',
        '--no-frequency-based-minification',
        '-o',
      ];

      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('app.dill').absolute.path,
            '--packages=/.dart_tool/package_config.json',
            '--cfe-only',
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
        ),
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ...common,
            environment.buildDir.childFile('main.dart.js').absolute.path,
            environment.buildDir.childFile('app.dill').absolute.path,
          ],
        ),
      );

      await Dart2JSTarget(
        const JsCompilerConfig(noFrequencyBasedMinification: true, sourceMaps: false),
      ).build(environment);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  for (final renderer in <WebRendererMode>[WebRendererMode.canvaskit, WebRendererMode.skwasm]) {
    for (final level in <int?>[null, 0, 1, 2, 3, 4]) {
      for (final strip in <bool>[true, false]) {
        for (final defines in const <List<String>>[
          <String>[],
          <String>['FOO=bar', 'BAZ=qux'],
        ]) {
          for (final buildMode in const <String>['profile', 'release', 'debug']) {
            for (final sourceMaps in const <bool>[true, false]) {
              for (final minify in const <bool>[true, false]) {
                test(
                  'Dart2WasmTarget invokes dart2wasm with renderer=$renderer, -O$level, stripping=$strip, defines=$defines, modeMode=$buildMode sourceMaps=$sourceMaps minify=$minify',
                  () => testbed.run(() async {
                    final int expectedLevel =
                        level ??
                        switch (buildMode) {
                          'debug' => 0,
                          'profile' || 'release' => 2,
                          _ => throw UnimplementedError(),
                        };
                    environment.defines[kBuildMode] = buildMode;
                    environment.defines[kDartDefines] = encodeDartDefines(defines);

                    final File depFile = environment.buildDir.childFile('dart2wasm.d');

                    final File outputJsFile = environment.buildDir.childFile('main.dart.mjs');
                    processManager.addCommand(
                      FakeCommand(
                        command: <String>[
                          ..._kDart2WasmLinuxArgs,
                          '-Ddart.vm.profile=${buildMode == 'profile'}',
                          '-Ddart.vm.product=${buildMode == 'release'}',
                          if (buildMode != 'debug') ...<String>[
                            '--extra-compiler-option=--delete-tostring-package-uri=dart:ui',
                            '--extra-compiler-option=--delete-tostring-package-uri=package:flutter',
                          ],
                          if (renderer == WebRendererMode.skwasm) ...<String>[
                            '--extra-compiler-option=--import-shared-memory',
                            '--extra-compiler-option=--shared-memory-max-pages=32768',
                          ],
                          ...defines.map((String define) => '-D$define'),
                          if (renderer == WebRendererMode.skwasm) ...<String>[
                            '-DFLUTTER_WEB_USE_SKIA=false',
                            '-DFLUTTER_WEB_USE_SKWASM=true',
                          ],
                          if (renderer == WebRendererMode.canvaskit) ...<String>[
                            '-DFLUTTER_WEB_USE_SKIA=true',
                            '-DFLUTTER_WEB_USE_SKWASM=false',
                          ],
                          '-DFLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/abcdefghijklmnopqrstuvwxyz/',
                          '--extra-compiler-option=--depfile=${depFile.absolute.path}',
                          '-O$expectedLevel',
                          if (strip && buildMode == 'release')
                            '--strip-wasm'
                          else
                            '--no-strip-wasm',
                          if (!sourceMaps) '--no-source-maps',
                          if (minify) '--minify' else '--no-minify',
                          if (buildMode == 'debug') '--extra-compiler-option=--enable-asserts',
                          '-o',
                          environment.buildDir.childFile('main.dart.wasm').absolute.path,
                          environment.buildDir.childFile('main.dart').absolute.path,
                        ],
                        onRun: (_) => outputJsFile
                          ..createSync()
                          ..writeAsStringSync('foo'),
                      ),
                    );

                    await Dart2WasmTarget(
                      WasmCompilerConfig(
                        optimizationLevel: level,
                        stripWasm: strip,
                        renderer: renderer,
                        sourceMaps: sourceMaps,
                        minify: minify,
                      ),
                      const NoOpAnalytics(),
                    ).build(environment);

                    expect(outputJsFile.existsSync(), isTrue);
                  }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
                );
              }
            }
          }
        }
      }
    }
  }

  test('Dart2JSTarget has unique build keys for compiler configurations', () {
    const testConfigs = <JsCompilerConfig>[
      // Default values
      JsCompilerConfig(),

      // Each individual property being made non-default
      JsCompilerConfig(csp: true),
      JsCompilerConfig(dumpInfo: true),
      JsCompilerConfig(nativeNullAssertions: true),
      JsCompilerConfig(optimizationLevel: 0),
      JsCompilerConfig(noFrequencyBasedMinification: true),
      JsCompilerConfig(sourceMaps: false),
      JsCompilerConfig(minify: false),

      // All properties non-default
      JsCompilerConfig(
        csp: true,
        dumpInfo: true,
        nativeNullAssertions: true,
        optimizationLevel: 0,
        noFrequencyBasedMinification: true,
        sourceMaps: false,
      ),
    ];

    final Iterable<String> buildKeys = testConfigs.map((JsCompilerConfig config) {
      final target = Dart2JSTarget(config);
      return target.buildKey;
    });

    // Make sure all the build keys are unique.
    expect(buildKeys.toSet().length, buildKeys.length);
  });

  test('Dart2Wasm has unique build keys for compiler configurations', () {
    const testConfigs = <WasmCompilerConfig>[
      // Default values
      WasmCompilerConfig(),

      // Each individual property being made non-default
      WasmCompilerConfig(optimizationLevel: 0),
      WasmCompilerConfig(renderer: WebRendererMode.canvaskit),
      WasmCompilerConfig(stripWasm: false),
      WasmCompilerConfig(minify: false),
      WasmCompilerConfig(dryRun: true),

      // All properties non-default
      WasmCompilerConfig(
        optimizationLevel: 0,
        stripWasm: false,
        renderer: WebRendererMode.canvaskit,
        dryRun: true,
      ),
    ];

    final Iterable<String> buildKeys = testConfigs.map((WasmCompilerConfig config) {
      final target = Dart2WasmTarget(config, const NoOpAnalytics());
      return target.buildKey;
    });

    // Make sure all the build keys are unique.
    expect(buildKeys.toSet().length, buildKeys.length);
  });

  test('JsCompilerConfig minification based on release mode', () {
    // Explicit `minify: true` should always result in `--minify` in all modes.
    expect(
      const JsCompilerConfig(minify: true).toCommandOptions(BuildMode.debug),
      contains('--minify'),
    );
    expect(
      const JsCompilerConfig(minify: true).toCommandOptions(BuildMode.profile),
      contains('--minify'),
    );
    expect(
      const JsCompilerConfig(minify: true).toCommandOptions(BuildMode.release),
      contains('--minify'),
    );

    // Explicit `minify: false` should always result in `--no-minify` in all modes.
    expect(
      const JsCompilerConfig(minify: false).toCommandOptions(BuildMode.debug),
      contains('--no-minify'),
    );
    expect(
      const JsCompilerConfig(minify: false).toCommandOptions(BuildMode.profile),
      contains('--no-minify'),
    );
    expect(
      const JsCompilerConfig(minify: false).toCommandOptions(BuildMode.release),
      contains('--no-minify'),
    );

    // Default `minify` should result in `--minify` only in release mode.
    expect(const JsCompilerConfig().toCommandOptions(BuildMode.debug), contains('--no-minify'));
    expect(const JsCompilerConfig().toCommandOptions(BuildMode.profile), contains('--no-minify'));
    expect(const JsCompilerConfig().toCommandOptions(BuildMode.release), contains('--minify'));
  });

  test('WasmCompilerConfig minification based on release mode', () {
    // Explicit `minify: true` should always result in `--minify` in all modes.
    expect(
      const WasmCompilerConfig(minify: true).toCommandOptions(BuildMode.debug),
      contains('--minify'),
    );
    expect(
      const WasmCompilerConfig(minify: true).toCommandOptions(BuildMode.profile),
      contains('--minify'),
    );
    expect(
      const WasmCompilerConfig(minify: true).toCommandOptions(BuildMode.release),
      contains('--minify'),
    );

    // Explicit `minify: false` should always result in `--no-minify` in all modes.
    expect(
      const WasmCompilerConfig(minify: false).toCommandOptions(BuildMode.debug),
      contains('--no-minify'),
    );
    expect(
      const WasmCompilerConfig(minify: false).toCommandOptions(BuildMode.profile),
      contains('--no-minify'),
    );
    expect(
      const WasmCompilerConfig(minify: false).toCommandOptions(BuildMode.release),
      contains('--no-minify'),
    );

    // Default `minify` should result in `--minify` only in release mode.
    expect(const WasmCompilerConfig().toCommandOptions(BuildMode.debug), contains('--no-minify'));
    expect(const WasmCompilerConfig().toCommandOptions(BuildMode.profile), contains('--no-minify'));
    expect(const WasmCompilerConfig().toCommandOptions(BuildMode.release), contains('--minify'));
  });

  test(
    'Generated service worker is empty with none-strategy',
    () => testbed.run(() {
      final String fileGeneratorsPath = environment.artifacts.getArtifactPath(
        Artifact.flutterToolsFileGenerators,
      );
      final String result = generateServiceWorker(
        fileGeneratorsPath,
        serviceWorkerStrategy: ServiceWorkerStrategy.none,
      );

      expect(result, '');
    }),
  );

  test(
    'WebBuiltInAssets copies over canvaskit again if the web sdk changes',
    () => testbed.run(() async {
      final File canvasKitInput = globals.fs.file(
        'bin/cache/flutter_web_sdk/canvaskit/canvaskit.wasm',
      )..createSync(recursive: true);
      canvasKitInput.writeAsStringSync('foo', flush: true);

      await WebBuiltInAssets(globals.fs).build(environment);

      final File canvasKitOutputBefore = environment.outputDir
          .childDirectory('canvaskit')
          .childFile('canvaskit.wasm');
      expect(canvasKitOutputBefore.existsSync(), true);
      expect(canvasKitOutputBefore.readAsStringSync(), 'foo');

      canvasKitInput.writeAsStringSync('bar', flush: true);

      await WebBuiltInAssets(globals.fs).build(environment);

      final File canvasKitOutputAfter = environment.outputDir
          .childDirectory('canvaskit')
          .childFile('canvaskit.wasm');
      expect(canvasKitOutputAfter.existsSync(), true);
      expect(canvasKitOutputAfter.readAsStringSync(), 'bar');
    }),
  );
}
