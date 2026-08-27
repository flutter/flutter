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
    'hashAndRenameWebOutput renames the binary with its content hash and pairs the source map',
    () => testbed.run(() {
      const jsContent = 'console.log("hello");\n//# sourceMappingURL=main.dart.js.map\n';
      final File jsFile = environment.buildDir.childFile('main.dart.js')
        ..createSync(recursive: true)
        ..writeAsStringSync(jsContent);
      final File mapFile = environment.buildDir.childFile('main.dart.js.map')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"version":3,"sources":[]}');

      // The hash is computed from the compiler's output, before the
      // sourceMappingURL comment is rewritten to the hashed map name.
      final String expectedHash = crypto.sha256
          .convert(utf8.encode(jsContent))
          .toString()
          .substring(0, 8);

      final String newBasename = hashAndRenameWebOutput(file: jsFile, sourceMapFile: mapFile);

      expect(newBasename, 'main.dart.$expectedHash.js');
      final File renamedFile = environment.buildDir.childFile(newBasename);
      expect(renamedFile, exists);

      // The map shares the binary's hash so that '<binary>.map' resolves, and
      // the binary's sourceMappingURL comment points at the renamed map.
      expect(mapFile, isNot(exists));
      expect(environment.buildDir.childFile('$newBasename.map'), exists);
      expect(renamedFile.readAsStringSync(), contains('sourceMappingURL=$newBasename.map'));
    }),
  );

  test(
    'Dart2JSTarget buildFiles includes the renamed source map',
    () => testbed.run(() {
      // Binary and map contents differ, as in a real build; the map name must
      // still be discoverable from the binary name.
      final File jsFile = environment.buildDir.childFile('main.dart.js')
        ..createSync(recursive: true)
        ..writeAsStringSync('console.log("hello");\n//# sourceMappingURL=main.dart.js.map\n');
      final File mapFile = environment.buildDir.childFile('main.dart.js.map')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"version":3,"sources":["main.dart"]}');
      final String newBasename = hashAndRenameWebOutput(file: jsFile, sourceMapFile: mapFile);

      final target = Dart2JSTarget(const JsCompilerConfig(webContentHash: true));
      final List<String> files = target
          .buildFiles(environment)
          .map((File f) => f.basename)
          .toList();
      expect(files, containsAll(<String>[newBasename, '$newBasename.map']));
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
    'getBuildConfig falls back to unhashed names when no hashed output exists',
    () => testbed.run(() {
      final jsTarget = Dart2JSTarget(const JsCompilerConfig(webContentHash: true));
      expect(jsTarget.getBuildConfig(environment)['mainJsPath'], 'main.dart.js');

      final wasmTarget = Dart2WasmTarget(
        const WasmCompilerConfig(webContentHash: true),
        const NoOpAnalytics(),
      );
      final Map<String, Object?> wasmConfig = wasmTarget.getBuildConfig(environment);
      expect(wasmConfig['mainWasmPath'], 'main.dart.wasm');
      expect(wasmConfig['jsSupportRuntimePath'], 'main.dart.mjs');
    }),
  );

  test(
    'Dart2WasmTarget getBuildConfig returns an empty config in dry run mode',
    () => testbed.run(() {
      final target = Dart2WasmTarget(
        const WasmCompilerConfig(webContentHash: true, dryRun: true),
        const NoOpAnalytics(),
      );
      expect(target.getBuildConfig(environment), isEmpty);
    }),
  );

  test(
    'Dart2WasmTarget buildPatternStems keeps main.dart.wasm.map unhashed under webContentHash',
    () => testbed.run(() {
      final target = Dart2WasmTarget(
        const WasmCompilerConfig(webContentHash: true),
        const NoOpAnalytics(),
      );
      expect(target.buildPatternStems, contains('main.dart.wasm.map'));
      expect(target.buildPatternStems, isNot(contains('main.dart.*.wasm.map')));
      expect(target.buildPatternStems, contains('main.dart.*.mjs.map'));
    }),
  );

  test(
    'hashAndRenameWebOutput skips source map rename for wasm binary files',
    () => testbed.run(() {
      final File wasmFile = environment.buildDir.childFile('main.dart.wasm')
        ..createSync(recursive: true)
        ..writeAsBytesSync(<int>[0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00]);
      final File mapFile = environment.buildDir.childFile('main.dart.wasm.map')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"version":3}');

      final String newBasename = hashAndRenameWebOutput(file: wasmFile, sourceMapFile: mapFile);

      expect(newBasename, matches(r'^main\.dart\.[a-f0-9]{8}\.wasm$'));
      expect(
        mapFile.existsSync(),
        isTrue,
        reason: 'main.dart.wasm.map should remain unhashed on disk',
      );
      expect(environment.buildDir.childFile('$newBasename.map').existsSync(), isFalse);
    }),
  );

  test(
    'Dart2WasmTarget buildFiles discovers unhashed main.dart.wasm.map under webContentHash',
    () => testbed.run(() {
      environment.buildDir.childFile('main.dart.22222222.wasm').createSync(recursive: true);
      final File mapFile = environment.buildDir.childFile('main.dart.wasm.map')
        ..createSync(recursive: true);
      // Produce the mjs and its map with the real rename logic instead of
      // hand-picked names, so the discovery logic is tested against what the
      // build actually writes.
      final File mjsFile = environment.buildDir.childFile('main.dart.mjs')
        ..createSync(recursive: true)
        ..writeAsStringSync('export function main() {}\n//# sourceMappingURL=main.dart.mjs.map\n');
      final File mjsMapFile = environment.buildDir.childFile('main.dart.mjs.map')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"version":3,"sources":["main.dart"]}');
      final String newMjsBasename = hashAndRenameWebOutput(
        file: mjsFile,
        sourceMapFile: mjsMapFile,
      );

      final target = Dart2WasmTarget(
        const WasmCompilerConfig(webContentHash: true),
        const NoOpAnalytics(),
      );

      final List<String> files = target
          .buildFiles(environment)
          .map((File f) => f.basename)
          .toList();
      expect(files, contains(mapFile.basename));
      expect(files, contains('$newMjsBasename.map'));
    }),
  );

  test(
    'hashAndRenameWebOutput hashes names without a .dart segment or extension',
    () => testbed.run(() {
      final File plainJs = environment.buildDir.childFile('foo.js')
        ..createSync(recursive: true)
        ..writeAsStringSync('console.log(1);\n');
      expect(hashAndRenameWebOutput(file: plainJs), matches(r'^foo\.[a-f0-9]{8}\.js$'));

      final File noExtension = environment.buildDir.childFile('LICENSE')
        ..createSync(recursive: true)
        ..writeAsStringSync('license text');
      expect(hashAndRenameWebOutput(file: noExtension), matches(r'^LICENSE\.[a-f0-9]{8}$'));
    }),
  );

  test(
    'hashAndRenameWebOutput handles missing files and missing source maps',
    () => testbed.run(() {
      final File missing = environment.buildDir.childFile('main.dart.js');
      expect(hashAndRenameWebOutput(file: missing), 'main.dart.js');
      expect(missing, isNot(exists));

      const jsContent = 'console.log("hello");\n';
      final File jsFile = environment.buildDir.childFile('main.dart.js')
        ..createSync(recursive: true)
        ..writeAsStringSync(jsContent);
      final String newBasename = hashAndRenameWebOutput(
        file: jsFile,
        sourceMapFile: environment.buildDir.childFile('main.dart.js.map'),
      );
      expect(environment.buildDir.childFile(newBasename), exists);
      expect(environment.buildDir.childFile(newBasename).readAsStringSync(), jsContent);
      expect(environment.buildDir.childFile('$newBasename.map'), isNot(exists));
    }),
  );

  test(
    'Dart2JSTarget build with webContentHash renames output, updates dart2js.d, and removes stale hashed files',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      final File staleJs = environment.buildDir.childFile('main.dart.00000000.js')
        ..createSync(recursive: true);
      final File staleMap = environment.buildDir.childFile('main.dart.00000000.js.map')
        ..createSync(recursive: true);
      const jsContent = 'console.log("hello");\n//# sourceMappingURL=main.dart.js.map\n';
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
          onRun: (_) {
            environment.buildDir.childFile('main.dart.js').writeAsStringSync(jsContent);
            environment.buildDir
                .childFile('main.dart.js.map')
                .writeAsStringSync('{"version":3,"sources":["main.dart"]}');
          },
        ),
      );

      await Dart2JSTarget(const JsCompilerConfig(webContentHash: true)).build(environment);

      final String expectedHash = crypto.sha256
          .convert(utf8.encode(jsContent))
          .toString()
          .substring(0, 8);
      final expectedBasename = 'main.dart.$expectedHash.js';
      expect(staleJs, isNot(exists));
      expect(staleMap, isNot(exists));
      expect(environment.buildDir.childFile(expectedBasename), exists);
      expect(environment.buildDir.childFile('$expectedBasename.map'), exists);

      final Depfile depfile = environment.depFileService.parse(
        environment.buildDir.childFile('dart2js.d'),
      );
      expect(depfile.outputs.single.basename, expectedBasename);
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2JSTarget build with webContentHash tool-exits when deferred part files are present',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
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
          onRun: (_) {
            environment.buildDir.childFile('main.dart.js').writeAsStringSync('console.log(1);\n');
            environment.buildDir.childFile('main.dart.js_1.part.js').createSync();
          },
        ),
      );

      await expectLater(
        Dart2JSTarget(const JsCompilerConfig(webContentHash: true)).build(environment),
        throwsToolExit(message: 'deferred'),
      );
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'Dart2WasmTarget build with webContentHash renames outputs and rewrites dart2wasm.d',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      final File depFile = environment.buildDir.childFile('dart2wasm.d');
      final File wasmFile = environment.buildDir.childFile('main.dart.wasm');
      final File mjsFile = environment.buildDir.childFile('main.dart.mjs');
      final wasmBytes = <int>[0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00];
      const mjsContent = 'export function main() {}\n';
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ..._kDart2WasmLinuxArgs,
            '-Ddart.vm.profile=false',
            '-Ddart.vm.product=true',
            '--extra-compiler-option=--delete-tostring-package-uri=dart:ui',
            '--extra-compiler-option=--delete-tostring-package-uri=package:flutter',
            '--extra-compiler-option=--import-shared-memory',
            '--extra-compiler-option=--shared-memory-max-pages=32768',
            '-DFLUTTER_WEB_USE_SKIA=false',
            '-DFLUTTER_WEB_USE_SKWASM=true',
            '-DFLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/abcdefghijklmnopqrstuvwxyz/',
            '--extra-compiler-option=--depfile=${depFile.absolute.path}',
            '--recorded-uses=${environment.buildDir.childFile('recorded_uses_wasm.json').absolute.path}',
            '-O2',
            '--strip-wasm',
            '--minify',
            '-o',
            wasmFile.absolute.path,
            environment.buildDir.childFile('main.dart').absolute.path,
          ],
          onRun: (_) {
            wasmFile.writeAsBytesSync(wasmBytes);
            mjsFile.writeAsStringSync(mjsContent);
            depFile.writeAsStringSync(
              '${wasmFile.absolute.path} ${mjsFile.absolute.path}: /a.dart',
            );
          },
        ),
      );

      await Dart2WasmTarget(
        const WasmCompilerConfig(webContentHash: true),
        const NoOpAnalytics(),
      ).build(environment);

      final String wasmHash = crypto.sha256.convert(wasmBytes).toString().substring(0, 8);
      final String mjsHash = crypto.sha256
          .convert(utf8.encode(mjsContent))
          .toString()
          .substring(0, 8);
      expect(environment.buildDir.childFile('main.dart.$wasmHash.wasm'), exists);
      expect(environment.buildDir.childFile('main.dart.$mjsHash.mjs'), exists);

      final Depfile depfile = environment.depFileService.parse(depFile);
      expect(
        depfile.outputs.map((File f) => f.basename),
        containsAll(<String>['main.dart.$wasmHash.wasm', 'main.dart.$mjsHash.mjs']),
      );
    }, overrides: <Type, Generator>{ProcessManager: () => processManager}),
  );

  test(
    'WebReleaseBundle build removes stale hashed entrypoints from the output directory',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      environment.projectDir
          .childDirectory('web')
          .childFile('index.html')
          .createSync(recursive: true);
      environment.buildDir.childFile('main.dart.11111111.js').createSync(recursive: true);

      final File staleJs = environment.outputDir.childFile('main.dart.00000000.js')
        ..createSync(recursive: true);
      final File staleMap = environment.outputDir.childFile('main.dart.00000000.js.map')
        ..createSync(recursive: true);
      final File staleUnhashed = environment.outputDir.childFile('main.dart.js')
        ..createSync(recursive: true);
      final File unrelated = environment.outputDir.childFile('flutter.js')
        ..createSync(recursive: true);

      await WebReleaseBundle(<WebCompilerConfig>[
        const JsCompilerConfig(webContentHash: true),
      ], const NoOpAnalytics()).build(environment);

      expect(staleJs, isNot(exists));
      expect(staleMap, isNot(exists));
      expect(staleUnhashed, isNot(exists));
      expect(unrelated, exists);
      expect(environment.outputDir.childFile('main.dart.11111111.js'), exists);
    }),
  );

  test(
    'WebTemplatedFiles buildKey, dependencies, and inputs derive from compile targets when provided',
    () => testbed.run(() {
      final jsTarget = Dart2JSTarget(const JsCompilerConfig(webContentHash: true));
      final target = WebTemplatedFiles(
        <Map<String, Object?>>[],
        compileTargets: <Dart2WebTarget>[jsTarget],
      );
      expect(target.buildKey, jsonEncode(<String>[jsTarget.buildKey]));
      expect(target.dependencies, <Object>[jsTarget]);
      // Three static inputs plus one {BUILD_DIR} pattern per build stem.
      expect(target.inputs.length, 3 + jsTarget.buildPatternStems.length);
      expect(jsTarget.buildPatternStems, contains('main.dart.*.js'));

      final noHashTarget = WebTemplatedFiles(
        <Map<String, Object?>>[],
        compileTargets: <Dart2WebTarget>[Dart2JSTarget(const JsCompilerConfig())],
      );
      expect(noHashTarget.buildKey, isNot(target.buildKey));
    }),
  );

  test(
    'Dart2JSTarget and Dart2WasmTarget getBuildConfig safely handle multiple candidate files in buildDir',
    () => testbed.run(() {
      environment.buildDir.childFile('main.dart.js').createSync(recursive: true);
      environment.buildDir.childFile('main.dart.11111111.js').createSync(recursive: true);
      environment.buildDir.childFile('main.dart.wasm').createSync(recursive: true);
      environment.buildDir.childFile('main.dart.22222222.wasm').createSync(recursive: true);
      environment.buildDir.childFile('main.dart.mjs').createSync(recursive: true);
      environment.buildDir.childFile('main.dart.33333333.mjs').createSync(recursive: true);

      final jsTarget = Dart2JSTarget(const JsCompilerConfig(webContentHash: true));
      expect(jsTarget.getBuildConfig(environment)['mainJsPath'], 'main.dart.11111111.js');

      final wasmTarget = Dart2WasmTarget(
        const WasmCompilerConfig(webContentHash: true),
        const NoOpAnalytics(),
      );
      final Map<String, Object?> wasmConfig = wasmTarget.getBuildConfig(environment);
      expect(wasmConfig['mainWasmPath'], 'main.dart.22222222.wasm');
      expect(wasmConfig['jsSupportRuntimePath'], 'main.dart.33333333.mjs');
    }),
  );

  test(
    'hashAndRenameWebOutput only updates sourceMappingURL and does not replace matching string constants in code',
    () => testbed.run(() {
      const jsContent = '''
const mapName = "main.dart.js.map";
console.log(mapName);
//# sourceMappingURL=main.dart.js.map
''';
      final File jsFile = environment.buildDir.childFile('main.dart.js')
        ..createSync(recursive: true)
        ..writeAsStringSync(jsContent);
      final File mapFile = environment.buildDir.childFile('main.dart.js.map')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"version":3}');

      final String newBasename = hashAndRenameWebOutput(file: jsFile, sourceMapFile: mapFile);
      final File renamedJs = environment.buildDir.childFile(newBasename);
      expect(renamedJs.readAsStringSync(), contains('const mapName = "main.dart.js.map";'));
      expect(renamedJs.readAsStringSync(), contains('//# sourceMappingURL=$newBasename.map'));
    }),
  );

  test(
    'hashAndRenameWebOutput supports non-dart compound extensions like worker.js.map',
    () => testbed.run(() {
      final File workerJs = environment.buildDir.childFile('worker.js')
        ..createSync(recursive: true)
        ..writeAsStringSync('console.log("worker");\n//# sourceMappingURL=worker.js.map\n');
      final File workerMap = environment.buildDir.childFile('worker.js.map')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"version":3}');

      final String newBasename = hashAndRenameWebOutput(file: workerJs, sourceMapFile: workerMap);
      expect(newBasename, matches(r'^worker\.[a-f0-9]{8}\.js$'));
      expect(workerMap.existsSync(), isFalse);
      expect(environment.buildDir.childFile('$newBasename.map').existsSync(), isTrue);
    }),
  );

  test(
    'WebReleaseBundle build cleans up stale hashed files even when webContentHash is false',
    () => testbed.run(() async {
      environment.defines[kBuildMode] = 'release';
      environment.projectDir
          .childDirectory('web')
          .childFile('index.html')
          .createSync(recursive: true);
      environment.buildDir.childFile('main.dart.js').createSync(recursive: true);

      final File staleHashedJs = environment.outputDir.childFile('main.dart.11111111.js')
        ..createSync(recursive: true);

      await WebReleaseBundle(<WebCompilerConfig>[
        const JsCompilerConfig(),
      ], const NoOpAnalytics()).build(environment);

      expect(staleHashedJs, isNot(exists));
      expect(environment.outputDir.childFile('main.dart.js'), exists);
    }),
  );

  test(
    'WebTemplatedFiles populates wasmHashes from compileTargets on clean builds before outputDir is copied',
    () => testbed.run(() async {
      environment.projectDir.childDirectory('web').createSync(recursive: true);
      environment.buildDir.childFile('main.dart.89abcdef.wasm')
        ..createSync(recursive: true)
        ..writeAsBytesSync(<int>[0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00]);
      environment.buildDir.childFile('main.dart.01234567.mjs').createSync(recursive: true);

      final wasmTarget = Dart2WasmTarget(
        const WasmCompilerConfig(webContentHash: true),
        const NoOpAnalytics(),
      );
      final target = WebTemplatedFiles(
        <Map<String, Object?>>[],
        compileTargets: <Dart2WebTarget>[wasmTarget],
      );

      final String configString = target.buildConfigString(environment);
      final expectedHash = crypto.sha256.convert(<int>[
        0x00,
        0x61,
        0x73,
        0x6d,
        0x01,
        0x00,
        0x00,
        0x00,
      ]).toString();
      expect(configString, contains('"main.dart.89abcdef.wasm":"$expectedHash"'));
    }),
  );
}
