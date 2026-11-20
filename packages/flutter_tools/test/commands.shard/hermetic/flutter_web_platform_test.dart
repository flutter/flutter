// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/flutter_web_platform.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:flutter_tools/src/web/memory_fs.dart';
import 'package:flutter_tools/src/web/module_metadata.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test_core/backend.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';

/// Thrown by [_RecordingChromiumLauncher] to terminate the browser startup early
/// once browser launch arguments have been intercepted and recorded.
class _TestBrowserLaunchException implements Exception {
  const _TestBrowserLaunchException();
}

/// A test fake [ChromiumLauncher] that captures the `webBrowserFlags` passed to [ChromiumLauncher.launch]
/// for verification in hermetic tests.
class _RecordingChromiumLauncher extends ChromiumLauncher {
  _RecordingChromiumLauncher({
    required super.fileSystem,
    required super.platform,
    required super.processManager,
    required super.operatingSystemUtils,
    required super.browserFinder,
    required super.logger,
  });

  List<String>? lastWebBrowserFlags;

  @override
  Future<Chromium> launch(
    String url, {
    bool headless = false,
    int? debugPort,
    bool skipCheck = false,
    Directory? cacheDir,
    List<String> webBrowserFlags = const <String>[],
  }) async {
    lastWebBrowserFlags = List<String>.from(webBrowserFlags);
    throw const _TestBrowserLaunchException();
  }
}

class FakeServer implements shelf.Server {
  shelf.Handler? mountedHandler;

  @override
  Future<void> close() async {}

  @override
  void mount(shelf.Handler handler) {
    mountedHandler = handler;
  }

  @override
  Uri get url => Uri.parse('');
}

void main() {
  late FileSystem fileSystem;
  late BufferLogger logger;
  late Platform platform;
  late Artifacts artifacts;
  late ProcessManager processManager;
  late FakeOperatingSystemUtils operatingSystemUtils;
  late Directory tempDir;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    platform = FakePlatform();
    artifacts = Artifacts.test(fileSystem: fileSystem);
    processManager = FakeProcessManager.empty();
    operatingSystemUtils = FakeOperatingSystemUtils();
    tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_web_platform_test.');

    for (final artifact in <HostArtifact>[
      HostArtifact.webPrecompiledDDCCanarySdk,
      HostArtifact.webPrecompiledDDCCanarySdkSourcemaps,
    ]) {
      final artifactFile = artifacts.getHostArtifact(artifact) as File;
      artifactFile.createSync();
      artifactFile.writeAsStringSync(artifact.name);
    }
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  testUsingContext(
    'FlutterWebPlatform serves the correct dart_sdk.js (ddc library bundle module system) for the passed web renderer',
    () async {
      final chromiumLauncher = ChromiumLauncher(
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
        operatingSystemUtils: operatingSystemUtils,
        browserFinder: (Platform platform, FileSystem filesystem) => 'chrome',
        logger: logger,
      );
      final server = FakeServer();
      final FlutterWebPlatform webPlatform = await FlutterWebPlatform.start(
        'ProjectRoot',
        buildDirectory: fileSystem.directory('build'),
        buildInfo: const BuildInfo(
          BuildMode.debug,
          '',
          packageConfigPath: '.dart_tool/package_config.json',
          treeShakeIcons: false,
          extraFrontEndOptions: <String>['--dartdevc-module-format=ddc', '--canary'],
          webEnableHotReload: true,
        ),
        chromiumLauncher: chromiumLauncher,
        crossOriginIsolation: false,
        flutterProject: FlutterProject.fromDirectoryTest(tempDir),
        flutterTesterBinPath: artifacts.getArtifactPath(Artifact.flutterTester),
        toolContext: FakeToolContext(
          artifacts: artifacts,
          fs: fileSystem,
          logger: logger,
          processManager: processManager,
        ),
        useWasm: false,
        webMemoryFS: WebMemoryFS(),
        webRenderer: WebRendererMode.canvaskit,
        serverFactory: () async => server,
        testPackageUri: Uri.parse('test'),
      );
      final shelf.Handler? handler = server.mountedHandler;
      expect(handler, isNotNull);
      handler!;
      final shelf.Response response = await handler(
        shelf.Request('GET', Uri.parse('http://localhost/dart_sdk.js')),
      );
      expect(response.headers[HttpHeaders.cacheControlHeader], 'public, max-age=3600');
      expect(
        response.headers[HttpHeaders.contentLengthHeader],
        HostArtifact.webPrecompiledDDCCanarySdk.name.length.toString(),
      );
      final String contents = await response.readAsString();
      expect(contents, HostArtifact.webPrecompiledDDCCanarySdk.name);

      final shelf.Response sourcemapResponse = await handler(
        shelf.Request('GET', Uri.parse('http://localhost/dart_sdk.js.map')),
      );
      expect(sourcemapResponse.headers[HttpHeaders.cacheControlHeader], 'public, max-age=3600');
      expect(
        sourcemapResponse.headers[HttpHeaders.contentLengthHeader],
        HostArtifact.webPrecompiledDDCCanarySdkSourcemaps.name.length.toString(),
      );
      expect(
        await sourcemapResponse.readAsString(),
        HostArtifact.webPrecompiledDDCCanarySdkSourcemaps.name,
      );

      final shelf.Response missingWasmResponse = await handler(
        shelf.Request('GET', Uri.parse('http://localhost/main.dart.wasm')),
      );
      expect(missingWasmResponse.statusCode, HttpStatus.notFound);
      await missingWasmResponse.read().drain<void>();

      await webPlatform.close();
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Logger: () => logger,
    },
  );

  testWithoutContext(
    'createDirectoryHandler sets Cache-Control and cross-origin isolation headers',
    () async {
      final Directory dir = tempDir.childDirectory('dir')..createSync();
      dir.childFile('index.html').writeAsStringSync('<html></html>');
      dir.childFile('asset.js').writeAsStringSync('// asset');

      final shelf.Handler handler = createDirectoryHandler(dir, crossOriginIsolated: true);

      final shelf.Response htmlResponse = await handler(
        shelf.Request('GET', Uri.parse('http://localhost/index.html')),
      );
      expect(htmlResponse.statusCode, HttpStatus.ok);
      expect(htmlResponse.headers[HttpHeaders.cacheControlHeader], 'public, max-age=3600');
      expect(
        htmlResponse.headers[HttpHeaders.contentLengthHeader],
        '<html></html>'.length.toString(),
      );
      expect(htmlResponse.headers['Cross-Origin-Opener-Policy'], 'same-origin');
      expect(htmlResponse.headers['Cross-Origin-Embedder-Policy'], 'credentialless');
      await htmlResponse.read().drain<void>();

      final shelf.Response jsResponse = await handler(
        shelf.Request('GET', Uri.parse('http://localhost/asset.js')),
      );
      expect(jsResponse.statusCode, HttpStatus.ok);
      expect(jsResponse.headers[HttpHeaders.cacheControlHeader], 'public, max-age=3600');
      expect(jsResponse.headers[HttpHeaders.contentLengthHeader], '// asset'.length.toString());
      expect(jsResponse.headers['Cross-Origin-Opener-Policy'], isNull);
      await jsResponse.read().drain<void>();
    },
  );

  testUsingContext(
    'FlutterWebPlatform serves the correct bootstrap files (ddc library bundle module system)',
    () async {
      final chromiumLauncher = ChromiumLauncher(
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
        operatingSystemUtils: operatingSystemUtils,
        browserFinder: (Platform platform, FileSystem filesystem) => 'chrome',
        logger: logger,
      );
      // Generating the bootstrap requires a merged metadata file written during
      // the initial compile to build and inject the correct scripts object.
      final server = FakeServer();
      final webMemoryFS = WebMemoryFS();
      final File source = fileSystem.file('source')..writeAsStringSync('main() {}');
      final File sourcemap = fileSystem.file('sourcemap')..writeAsStringSync('{}');
      final fakeMetadata = ModuleMetadata(
        'main',
        'unused',
        'main.dart.lib.js.map',
        'main.dart.lib.js',
      );
      final File metadata = fileSystem.file('metadata')
        ..writeAsStringSync(jsonEncode(fakeMetadata.toJson()));
      final File manifest = fileSystem.file('manifest')
        ..writeAsStringSync(
          '{"main.dart.lib.js":{"code":[0,${source.lengthSync()}],"sourcemap":[0,${sourcemap.lengthSync()}],"metadata":[0,${metadata.lengthSync()}]}}',
        );
      webMemoryFS.write(source, manifest, sourcemap, metadata);

      final FlutterWebPlatform webPlatform = await FlutterWebPlatform.start(
        'ProjectRoot',
        buildDirectory: fileSystem.directory('build'),
        buildInfo: const BuildInfo(
          BuildMode.debug,
          '',
          packageConfigPath: '.dart_tool/package_config.json',
          treeShakeIcons: false,
          extraFrontEndOptions: <String>['--dartdevc-module-format=ddc', '--canary'],
          webEnableHotReload: true,
        ),
        chromiumLauncher: chromiumLauncher,
        crossOriginIsolation: false,
        flutterProject: FlutterProject.fromDirectoryTest(tempDir),
        flutterTesterBinPath: artifacts.getArtifactPath(Artifact.flutterTester),
        toolContext: FakeToolContext(
          artifacts: artifacts,
          fs: fileSystem,
          logger: logger,
          processManager: processManager,
        ),
        useWasm: false,
        webMemoryFS: webMemoryFS,
        webRenderer: WebRendererMode.canvaskit,
        serverFactory: () async => server,
        testPackageUri: Uri.parse('test'),
      );
      final shelf.Handler? handler = server.mountedHandler;
      expect(handler, isNotNull);
      handler!;

      final shelf.Response responseBootstrap = await handler(
        shelf.Request('GET', Uri.parse('http://localhost/main.dart.browser_test.dart.js')),
      );
      expect(responseBootstrap.headers[HttpHeaders.cacheControlHeader], 'public, max-age=3600');
      final String contentsBootstrap = await responseBootstrap.readAsString();
      expect(contentsBootstrap, contains('ddc_module_loader.js'));
      expect(contentsBootstrap, contains('dart_stack_trace_mapper.js'));
      expect(contentsBootstrap, contains('main_module.bootstrap.js'));

      final shelf.Response responseMainModule = await handler(
        shelf.Request('GET', Uri.parse('http://localhost/main_module.bootstrap.js')),
      );
      expect(responseMainModule.headers[HttpHeaders.cacheControlHeader], 'public, max-age=3600');
      final String contentsMainModule = await responseMainModule.readAsString();
      expect(contentsMainModule, contains('on_load_end_bootstrap.js'));
      expect(contentsMainModule, contains('org-dartlang-app:///main.dart'));

      final shelf.Response responseOnLoadEnd = await handler(
        shelf.Request('GET', Uri.parse('http://localhost/on_load_end_bootstrap.js')),
      );
      expect(responseOnLoadEnd.headers[HttpHeaders.cacheControlHeader], 'public, max-age=3600');
      final String contentsOnLoadEnd = await responseOnLoadEnd.readAsString();
      expect(contentsOnLoadEnd, contains(r'window.$onLoadEndCallback();'));

      final shelf.Response responseModule = await handler(
        shelf.Request('GET', Uri.parse('http://localhost/main.dart.lib.js')),
      );
      expect(responseModule.headers[HttpHeaders.cacheControlHeader], 'public, max-age=3600');
      expect(await responseModule.readAsString(), 'main() {}');

      final shelf.Response responseSourcemap = await handler(
        shelf.Request('GET', Uri.parse('http://localhost/main.dart.lib.js.map')),
      );
      expect(responseSourcemap.headers[HttpHeaders.cacheControlHeader], 'public, max-age=3600');
      expect(await responseSourcemap.readAsString(), '{}');

      await webPlatform.close();
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Logger: () => logger,
    },
  );

  for (final style in <FileSystemStyle>[FileSystemStyle.posix, FileSystemStyle.windows]) {
    final os = style == FileSystemStyle.windows ? 'windows' : 'linux';
    final testFs = MemoryFileSystem.test(style: style);
    final testPlatform = FakePlatform(operatingSystem: os);
    testUsingContext(
      'FlutterWebPlatform sets Cache-Control headers on static and Wasm test assets ($os)',
      () async {
        final testArtifacts = Artifacts.test(fileSystem: testFs);
        final Directory projectDir = testFs.systemTempDirectory.createTempSync(
          'flutter_web_platform_test.',
        );
        final chromiumLauncher = ChromiumLauncher(
          fileSystem: testFs,
          platform: testPlatform,
          processManager: processManager,
          operatingSystemUtils: operatingSystemUtils,
          browserFinder: (Platform platform, FileSystem filesystem) => 'chrome',
          logger: logger,
        );
        final server = FakeServer();
        final Directory buildDirectory = testFs.directory('build')..createSync(recursive: true);
        buildDirectory.childFile('main.dart.mjs').writeAsStringSync('export default {}');
        buildDirectory.childFile('main.dart.wasm').writeAsBytesSync(<int>[0, 97, 115, 109]);

        final Directory flutterJsDir = testFs.directory(
          testArtifacts.getHostArtifact(HostArtifact.flutterJsDirectory).path,
        )..createSync(recursive: true);
        flutterJsDir.childFile('flutter.js').writeAsStringSync('// flutter.js');

        final String dartSdkPath = testArtifacts.getArtifactPath(
          Artifact.engineDartSdkPath,
          platform: TargetPlatform.web_javascript,
        );
        testFs.file(
            testFs.path.join(dartSdkPath, 'lib', 'dev_compiler', 'ddc', 'ddc_module_loader.js'),
          )
          ..createSync(recursive: true)
          ..writeAsStringSync('// ddc_module_loader.js');
        testFs.file(
            testFs.path.join(
              dartSdkPath,
              'lib',
              'dev_compiler',
              'web',
              'dart_stack_trace_mapper.js',
            ),
          )
          ..createSync(recursive: true)
          ..writeAsStringSync('// mapper.js');

        final Directory testPkgDir = testFs.directory('test_pkg')..createSync(recursive: true);
        testPkgDir.childFile('dart.js').writeAsStringSync('// dart.js');
        testPkgDir.childFile(testFs.path.join('src', 'runner', 'browser', 'static', 'host.dart.js'))
          ..createSync(recursive: true)
          ..writeAsStringSync('// host.dart.js');

        final String? previousFlutterRoot = Cache.flutterRoot;
        Cache.flutterRoot = testFs.directory('flutter').path;
        addTearDown(() => Cache.flutterRoot = previousFlutterRoot);
        final toolContext = FakeToolContext(
          artifacts: testArtifacts,
          fs: testFs,
          logger: logger,
          platform: testPlatform,
          processManager: processManager,
        );
        final File ahemFile =
            testFs.file(
                testFs.path.join(
                  Cache.flutterRoot!,
                  'packages',
                  'flutter_tools',
                  'static',
                  'Ahem.ttf',
                ),
              )
              ..createSync(recursive: true)
              ..writeAsBytesSync(<int>[1, 2, 3]);

        final FlutterWebPlatform webPlatform = await FlutterWebPlatform.start(
          'ProjectRoot',
          buildDirectory: buildDirectory,
          buildInfo: const BuildInfo(
            BuildMode.debug,
            '',
            packageConfigPath: '.dart_tool/package_config.json',
            treeShakeIcons: false,
          ),
          chromiumLauncher: chromiumLauncher,
          crossOriginIsolation: true,
          flutterProject: FlutterProject.fromDirectoryTest(projectDir),
          flutterTesterBinPath: testArtifacts.getArtifactPath(Artifact.flutterTester),
          toolContext: toolContext,
          useWasm: true,
          webMemoryFS: WebMemoryFS(),
          webRenderer: WebRendererMode.skwasm,
          serverFactory: () async => server,
          testPackageUri: testPkgDir.uri,
        );
        final shelf.Handler handler = server.mountedHandler!;

        for (final assetPath in <String>[
          'flutter.js',
          'ddc_module_loader.js',
          'dart_stack_trace_mapper.js',
          'static/dart.js',
          'host.dart.js',
          'ahem.ttf',
          'main.dart.mjs',
          'main.dart.wasm',
        ]) {
          final shelf.Response response = await handler(
            shelf.Request('GET', Uri.parse('http://localhost/$assetPath')),
          );
          expect(response.statusCode, HttpStatus.ok, reason: assetPath);
          expect(
            response.headers[HttpHeaders.cacheControlHeader],
            'public, max-age=3600',
            reason: assetPath,
          );
          await response.read().drain<void>();
        }

        final shelf.Response ahemResponse = await handler(
          shelf.Request('GET', Uri.parse('http://localhost/ahem.ttf')),
        );
        expect(
          ahemResponse.headers[HttpHeaders.contentLengthHeader],
          ahemFile.lengthSync().toString(),
        );
        await ahemResponse.read().drain<void>();

        final shelf.Response wrapperResponse = await handler(
          shelf.Request('GET', Uri.parse('http://localhost/rendering/sample_test.html')),
        );
        expect(wrapperResponse.statusCode, HttpStatus.ok);
        expect(wrapperResponse.headers[HttpHeaders.cacheControlHeader], isNull);
        final String wrapperHtml = await wrapperResponse.readAsString();
        expect(wrapperHtml, contains('mainWasmPath: "/main.dart.wasm"'));
        expect(wrapperHtml, contains('jsSupportRuntimePath: "/main.dart.mjs"'));

        await webPlatform.close();
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFs,
        Platform: () => testPlatform,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );
  }

  testUsingContext(
    'FlutterWebPlatform launches Chrome with scale factor and window size flags for goldens alignment',
    () async {
      final recordingLauncher = _RecordingChromiumLauncher(
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
        operatingSystemUtils: operatingSystemUtils,
        browserFinder: (Platform platform, FileSystem filesystem) => 'chrome',
        logger: logger,
      );
      final server = FakeServer();
      final FlutterWebPlatform webPlatform = await FlutterWebPlatform.start(
        'ProjectRoot',
        buildDirectory: fileSystem.directory('build'),
        buildInfo: const BuildInfo(
          BuildMode.debug,
          '',
          packageConfigPath: '.dart_tool/package_config.json',
          treeShakeIcons: false,
          webEnableHotReload: true,
        ),
        chromiumLauncher: recordingLauncher,
        crossOriginIsolation: false,
        flutterProject: FlutterProject.fromDirectoryTest(tempDir),
        flutterTesterBinPath: artifacts.getArtifactPath(Artifact.flutterTester),
        toolContext: FakeToolContext(
          artifacts: artifacts,
          fs: fileSystem,
          logger: logger,
          processManager: processManager,
        ),
        useWasm: false,
        webMemoryFS: WebMemoryFS(),
        webRenderer: WebRendererMode.canvaskit,
        serverFactory: () async => server,
        testPackageUri: Uri.parse('test'),
      );

      final suitePlatform = SuitePlatform(Runtime.chrome);
      try {
        await webPlatform.load(
          'test/foo_test.dart',
          suitePlatform,
          SuiteConfiguration.empty,
          Object(),
        );
      } on _TestBrowserLaunchException catch (_) {}

      expect(
        recordingLauncher.lastWebBrowserFlags,
        containsAll(<String>['--force-device-scale-factor=3', '--window-size=800,600']),
      );

      await webPlatform.close();
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Logger: () => logger,
    },
  );
}
