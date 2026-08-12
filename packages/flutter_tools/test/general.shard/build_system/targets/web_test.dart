// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
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
  '--write-resources',
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
        globals.fs
            .file('engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf')
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
    'WebEntrypointTarget declares package_config.json, pubspec.yaml, and plugin dependencies as inputs',
    () => testbed.run(() async {
      const target = WebEntrypointTarget();
      expect(
        target.inputs,
        equals(<Source>[
          const Source.pattern(
            '{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/web.dart',
          ),
          const Source.pattern('{WORKSPACE_DIR}/.dart_tool/package_config.json'),
          const Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
          const Source.pattern('{PROJECT_DIR}/.flutter-plugins-dependencies', optional: true),
        ]),
      );
      expect(
        target.outputs,
        equals(<Source>[
          const Source.pattern('{BUILD_DIR}/main.dart'),
          const Source.pattern('{BUILD_DIR}/web_plugin_registrant.dart'),
        ]),
      );
    }),
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

  group('--web-define', () {
    test(
      'WebTemplatedFiles substitutes web-define variables in index.html',
      () => testbed.run(() async {
        environment.defines['${kWebDefinePrefix}VERSION'] = 'v1.2.3';
        environment.defines['${kWebDefinePrefix}API_URL'] = 'https://api.example.com';
        final Directory webResources = environment.projectDir.childDirectory('web');
        webResources.childFile('index.html').createSync(recursive: true);
        webResources.childFile('index.html').writeAsStringSync('''
<!DOCTYPE html><html><head><base href="/"></head><body>
<script>
  const version = '{{VERSION}}';
  const apiUrl = '{{API_URL}}';
</script>
</body></html>
    ''');
        environment.buildDir.childFile('main.dart.js').createSync();
        await WebTemplatedFiles(<Map<String, Object?>>[]).build(environment);

        final String outputHtml = environment.outputDir.childFile('index.html').readAsStringSync();
        expect(outputHtml, contains("const version = 'v1.2.3'"));
        expect(outputHtml, contains("const apiUrl = 'https://api.example.com'"));
      }),
    );

    test(
      'WebTemplatedFiles substitutes web-define variables in flutter_bootstrap.js',
      () => testbed.run(() async {
        environment.defines['${kWebDefinePrefix}APP_VERSION'] = 'test-build-42';
        final Directory webResources = environment.projectDir.childDirectory('web');
        webResources.childFile('index.html').createSync(recursive: true);
        webResources.childFile('flutter_bootstrap.js').createSync(recursive: true);
        webResources.childFile('flutter_bootstrap.js').writeAsStringSync('''
const appVersion = '{{APP_VERSION}}';
_flutter.loader.load();
''');
        environment.buildDir.childFile('main.dart.js').createSync();
        await WebTemplatedFiles(<Map<String, Object?>>[]).build(environment);

        final String outputBootstrap = environment.outputDir
            .childFile('flutter_bootstrap.js')
            .readAsStringSync();
        expect(outputBootstrap, contains("const appVersion = 'test-build-42'"));
      }),
    );

    test(
      'WebTemplatedFiles works with no web-define variables',
      () => testbed.run(() async {
        final Directory webResources = environment.projectDir.childDirectory('web');
        webResources.childFile('index.html').createSync(recursive: true);
        webResources.childFile('index.html').writeAsStringSync('''
<!DOCTYPE html><html><head><base href="/"></head><body></body></html>
    ''');
        environment.buildDir.childFile('main.dart.js').createSync();
        await WebTemplatedFiles(<Map<String, Object?>>[]).build(environment);

        expect(
          environment.outputDir.childFile('index.html').readAsStringSync(),
          contains('<base href="/">'),
        );
      }),
    );
  });

  test(
    'WebReleaseBundle bundles a local Roboto fallback when CDN assets are disabled',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      environment.defines[kUseLocalCanvasKitFlag] = 'true';
      final Directory webResources = environment.projectDir.childDirectory('web');
      webResources.childFile('index.html').createSync(recursive: true);
      environment.buildDir.childFile('main.dart.js').createSync();

      await WebReleaseBundle(<WebCompilerConfig>[
        const JsCompilerConfig(),
      ], const NoOpAnalytics()).build(environment);

      final fontManifest =
          jsonDecode(
                environment.outputDir
                    .childDirectory('assets')
                    .childFile('FontManifest.json')
                    .readAsStringSync(),
              )
              as List<dynamic>;
      expect(
        fontManifest,
        contains(
          predicate<dynamic>((dynamic entry) {
            if (entry is! Map<dynamic, dynamic>) {
              return false;
            }
            if (entry['family'] != 'Roboto') {
              return false;
            }
            final dynamic fonts = entry['fonts'];
            return fonts is List<dynamic> &&
                fonts.length == 1 &&
                fonts.single is Map<dynamic, dynamic> &&
                (fonts.single as Map<dynamic, dynamic>)['asset'] ==
                    'fonts/fallback/Roboto-Regular.ttf';
          }),
        ),
      );
      expect(
        environment.outputDir
            .childDirectory('assets')
            .childFile('fonts/fallback/Roboto-Regular.ttf'),
        exists,
      );
    }),
  );

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
        const JsCompilerConfig(useFrequencyBasedMinification: false, sourceMaps: false),
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
                          '--recorded-uses=${environment.buildDir.childFile('recorded_uses_wasm.json').absolute.path}',
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

  void addWasmCompilerErrorCommand(
    FakeProcessManager processManager,
    Environment environment,
    String stderr,
  ) {
    processManager.addCommand(
      FakeCommand(
        command: <String>[
          ..._kDart2WasmLinuxArgs,
          '-Ddart.vm.profile=true',
          '-Ddart.vm.product=false',
          '--extra-compiler-option=--delete-tostring-package-uri=dart:ui',
          '--extra-compiler-option=--delete-tostring-package-uri=package:flutter',
          '--extra-compiler-option=--import-shared-memory',
          '--extra-compiler-option=--shared-memory-max-pages=32768',
          '-DFLUTTER_WEB_USE_SKIA=false',
          '-DFLUTTER_WEB_USE_SKWASM=true',
          '-DFLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/abcdefghijklmnopqrstuvwxyz/',
          '--extra-compiler-option=--depfile=${environment.buildDir.childFile('dart2wasm.d').absolute.path}',
          '--recorded-uses=${environment.buildDir.childFile('recorded_uses_wasm.json').absolute.path}',
          '-O2',
          '--no-strip-wasm',
          '--no-source-maps',
          '--no-minify',
          '-o',
          environment.buildDir.childFile('main.dart.wasm').absolute.path,
          environment.buildDir.childFile('main.dart').absolute.path,
        ],
        exitCode: 254,
        stderr: stderr,
      ),
    );
  }

  test(
    'Dart2WasmTarget prints JS interop migration footer on dart:html library import failure',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'profile';
      addWasmCompilerErrorCommand(
        processManager,
        environment,
        "Error: Dart library 'dart:html' is not available on this platform.",
      );

      try {
        await Dart2WasmTarget(
          const WasmCompilerConfig(
            optimizationLevel: 2,
            stripWasm: false,
            sourceMaps: false,
            minify: false,
          ),
          const NoOpAnalytics(),
        ).build(environment);
        fail('Expected exception');
      } on Exception catch (e) {
        expect(e.toString(), contains('Failed to compile application for the Web.'));
      }

      final logger = globals.logger as BufferLogger;
      expect(
        logger.statusText,
        contains('Note: WebAssembly compilation failed due to legacy web imports.'),
      );
      expect(
        logger.statusText,
        contains(
          'Migrate your project from dart:html and package:js to package:web and dart:js_interop.',
        ),
      );
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2WasmTarget prints JS interop migration footer on dart:svg and dart:js_util failures',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'profile';
      addWasmCompilerErrorCommand(
        processManager,
        environment,
        "Context: The unavailable library 'dart:svg' is imported through these paths:\n"
        "Error: Dart library 'dart:js_util' is not available on this platform.",
      );

      try {
        await Dart2WasmTarget(
          const WasmCompilerConfig(
            optimizationLevel: 2,
            stripWasm: false,
            sourceMaps: false,
            minify: false,
          ),
          const NoOpAnalytics(),
        ).build(environment);
        fail('Expected exception');
      } on Exception catch (e) {
        expect(e.toString(), contains('Failed to compile application for the Web.'));
      }

      final logger = globals.logger as BufferLogger;
      expect(
        logger.statusText,
        contains('Note: WebAssembly compilation failed due to legacy web imports.'),
      );
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2WasmTarget does not print JS interop migration footer on incidental mentions of dart:html in unrelated errors',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'profile';
      addWasmCompilerErrorCommand(
        processManager,
        environment,
        "Error: Syntax error in file:///my_dart_html_test.dart at line 4: print('dart:html');",
      );

      try {
        await Dart2WasmTarget(
          const WasmCompilerConfig(
            optimizationLevel: 2,
            stripWasm: false,
            sourceMaps: false,
            minify: false,
          ),
          const NoOpAnalytics(),
        ).build(environment);
        fail('Expected exception');
      } on Exception catch (e) {
        expect(e.toString(), contains('Failed to compile application for the Web.'));
      }

      final logger = globals.logger as BufferLogger;
      expect(
        logger.statusText,
        isNot(contains('Note: WebAssembly compilation failed due to legacy web imports.')),
      );
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test('Dart2WasmTarget.buildFiles respects compilerConfig.sourceMaps and matches modules', () {
    final File wasmFile = environment.buildDir.childFile('main.dart.wasm')..createSync();
    final File mjsFile = environment.buildDir.childFile('main.dart.mjs')..createSync();
    final File mapFile = environment.buildDir.childFile('main.dart.wasm.map')..createSync();

    final File partWasmFile = environment.buildDir.childFile('main.dart_module1.wasm')
      ..createSync();
    final File partMapFile = environment.buildDir.childFile('main.dart_module1.wasm.map')
      ..createSync();

    final targetWithMaps = Dart2WasmTarget(const WasmCompilerConfig(), const NoOpAnalytics());
    expect(
      targetWithMaps.buildFiles(environment).map((f) => f.path),
      containsAll(<File>[wasmFile, mjsFile, mapFile, partWasmFile, partMapFile].map((f) => f.path)),
    );

    final targetWithoutMaps = Dart2WasmTarget(
      const WasmCompilerConfig(sourceMaps: false),
      const NoOpAnalytics(),
    );
    expect(
      targetWithoutMaps.buildFiles(environment).map((f) => f.path),
      containsAll(<File>[wasmFile, mjsFile, partWasmFile].map((f) => f.path)),
    );
    expect(targetWithoutMaps.buildFiles(environment), isNot(contains(mapFile)));
    expect(targetWithoutMaps.buildFiles(environment), isNot(contains(partMapFile)));
  });

  test('Dart2JSTarget has unique build keys for compiler configurations', () {
    const testConfigs = <JsCompilerConfig>[
      // Default values
      JsCompilerConfig(),

      // Each individual property being made non-default
      JsCompilerConfig(csp: true),
      JsCompilerConfig(dumpInfo: true),
      JsCompilerConfig(nativeNullAssertions: true),
      JsCompilerConfig(optimizationLevel: 0),
      JsCompilerConfig(useFrequencyBasedMinification: false),
      JsCompilerConfig(sourceMaps: false),
      JsCompilerConfig(minify: false),
      JsCompilerConfig(webContentHash: true),

      // All properties non-default
      JsCompilerConfig(
        csp: true,
        dumpInfo: true,
        nativeNullAssertions: true,
        optimizationLevel: 0,
        useFrequencyBasedMinification: false,
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
      WasmCompilerConfig(webContentHash: true),

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

  test(
    'Dart2JSTarget getBuildConfig dynamically discovers hashed output',
    () => testbed.run(() {
      environment.buildDir.childFile('main.dart.01234567.js').createSync();
      final target = Dart2JSTarget(const JsCompilerConfig(webContentHash: true));
      expect(target.getBuildConfig(environment)['mainJsPath'], 'main.dart.01234567.js');
      final List<String> files = target
          .buildFiles(environment)
          .map((File f) => f.basename)
          .toList();
      expect(files, contains('main.dart.01234567.js'));
    }),
  );

  test(
    'Dart2WasmTarget getBuildConfig dynamically discovers hashed output',
    () => testbed.run(() {
      environment.buildDir.childFile('main.dart.89abcdef.wasm').createSync();
      environment.buildDir.childFile('main.dart.01234567.mjs').createSync();
      final target = Dart2WasmTarget(
        const WasmCompilerConfig(webContentHash: true),
        const NoOpAnalytics(),
      );
      final Map<String, Object?> buildConfig = target.getBuildConfig(environment);
      expect(buildConfig['mainWasmPath'], 'main.dart.89abcdef.wasm');
      expect(buildConfig['jsSupportRuntimePath'], 'main.dart.01234567.mjs');
      final List<String> files = target
          .buildFiles(environment)
          .map((File f) => f.basename)
          .toList();
      expect(files, containsAll(<String>['main.dart.89abcdef.wasm', 'main.dart.01234567.mjs']));
    }),
  );

  test(
    'WebTemplatedFiles evaluates target getBuildConfig dynamically when compileTargets provided',
    () => testbed.run(() async {
      environment.projectDir.childDirectory('web').createSync(recursive: true);
      environment.buildDir.childFile('main.dart.01234567.js').createSync();
      final jsTarget = Dart2JSTarget(const JsCompilerConfig(webContentHash: true));
      final target = WebTemplatedFiles(
        <Map<String, Object?>>[],
        compileTargets: <Dart2WebTarget>[jsTarget],
      );
      await target.build(environment);
      final File bootstrapJs = environment.outputDir.childFile('flutter_bootstrap.js');
      expect(bootstrapJs.existsSync(), isTrue);
      expect(bootstrapJs.readAsStringSync(), contains('main.dart.01234567.js'));
    }),
  );

  test(
    'hashAndRenameWebOutput produces filename with SHA-256 matching on-disk file bytes after source map fixup',
    () => testbed.run(() {
      final File jsFile = environment.buildDir.childFile('main.dart.js')
        ..createSync(recursive: true)
        ..writeAsStringSync('console.log("hello");\n//# sourceMappingURL=main.dart.js.map\n');
      final File mapFile = environment.buildDir.childFile('main.dart.js.map')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"version":3,"sources":[]}');

      final String newBasename = hashAndRenameWebOutput(file: jsFile, sourceMapFile: mapFile);

      final File renamedFile = environment.buildDir.childFile(newBasename);
      expect(renamedFile.existsSync(), isTrue);

      final hashPattern = RegExp(r'^main\.dart\.([a-f0-9]{8})\.js$');
      final Match? match = hashPattern.firstMatch(newBasename);
      expect(match, isNotNull, reason: 'Filename must contain 8-char hex hash');
      final String filenameHash = match!.group(1)!;

      final String actualFileHash = crypto.sha256
          .convert(renamedFile.readAsBytesSync())
          .toString()
          .substring(0, 8);

      expect(
        actualFileHash,
        equals(filenameHash),
        reason:
            'The SHA-256 of the on-disk file bytes must match the hash embedded in the filename',
      );
    }),
  );

  test(
    'hashAndRenameWebOutput preserves custom entrypoint stems instead of hardcoding main.dart',
    () => testbed.run(() {
      final File appJs = environment.buildDir.childFile('app_shell.dart.js')
        ..createSync(recursive: true)
        ..writeAsStringSync('console.log("custom entrypoint");\n');

      final String newBasename = hashAndRenameWebOutput(file: appJs);
      expect(newBasename, matches(r'^app_shell\.dart\.[a-f0-9]{8}\.js$'));
      expect(newBasename, isNot(startsWith('main.dart')));
    }),
  );

  test(
    'Dart2WasmTarget getBuildConfig does not pair mismatched WASM and MJS binaries across incremental builds',
    () => testbed.run(() {
      // Simulate build 1 artifacts with older timestamp
      final File wasm1 = environment.buildDir.childFile('main.dart.11111111.wasm')..createSync();
      final File mjs1 = environment.buildDir.childFile('main.dart.11111111.mjs')..createSync();
      wasm1.setLastModifiedSync(DateTime(2026));
      mjs1.setLastModifiedSync(DateTime(2026));

      // Simulate build 2 artifacts with newer timestamp
      final File wasm2 = environment.buildDir.childFile('main.dart.22222222.wasm')..createSync();
      final File mjs2 = environment.buildDir.childFile('main.dart.22222222.mjs')..createSync();
      wasm2.setLastModifiedSync(DateTime(2026, 1, 2));
      mjs2.setLastModifiedSync(DateTime(2026, 1, 2));

      final target = Dart2WasmTarget(
        const WasmCompilerConfig(webContentHash: true),
        const NoOpAnalytics(),
      );

      final Map<String, Object?> config = target.getBuildConfig(environment);
      expect(config['mainWasmPath'], equals('main.dart.22222222.wasm'));
      expect(config['jsSupportRuntimePath'], equals('main.dart.22222222.mjs'));

      final List<String> files = target
          .buildFiles(environment)
          .map((File f) => f.basename)
          .toList();
      expect(files, isNot(contains('main.dart.11111111.wasm')));
      expect(files, isNot(contains('main.dart.11111111.mjs')));
      expect(files, containsAll(<String>['main.dart.22222222.wasm', 'main.dart.22222222.mjs']));
    }),
  );

  test(
    'Dart2JSTarget getBuildConfig does not select stale build artifacts across incremental builds',
    () => testbed.run(() {
      // Simulate build 1 artifacts with older timestamp
      final File js1 = environment.buildDir.childFile('main.dart.11111111.js')..createSync();
      js1.setLastModifiedSync(DateTime(2026));

      // Simulate build 2 artifacts with newer timestamp
      final File js2 = environment.buildDir.childFile('main.dart.22222222.js')..createSync();
      js2.setLastModifiedSync(DateTime(2026, 1, 2));

      final target = Dart2JSTarget(const JsCompilerConfig(webContentHash: true));

      final Map<String, Object?> config = target.getBuildConfig(environment);
      expect(config['mainJsPath'], equals('main.dart.22222222.js'));

      final List<String> files = target
          .buildFiles(environment)
          .map((File f) => f.basename)
          .toList();
      expect(files, isNot(contains('main.dart.11111111.js')));
      expect(files, contains('main.dart.22222222.js'));
    }),
  );
}
