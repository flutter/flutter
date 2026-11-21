// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/flutter_web_platform.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:flutter_tools/src/web/memory_fs.dart';
import 'package:flutter_tools/src/web/module_metadata.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:stream_channel/stream_channel.dart';
import 'package:test_core/backend.dart';
import 'package:test_core/src/platform.dart'; // ignore: implementation_imports
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart' hide StackTrace;

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

/// A fake [ChromiumLauncher] that delegates [launch] failures to [onLaunch].
class _ThrowingChromiumLauncher extends ChromiumLauncher {
  _ThrowingChromiumLauncher({
    required super.fileSystem,
    required super.platform,
    required super.processManager,
    required super.operatingSystemUtils,
    required super.browserFinder,
    required super.logger,
    required this.onLaunch,
  });

  final FutureOr<Never> Function(int callCount) onLaunch;
  int launchCount = 0;

  @override
  Future<Chromium> launch(
    String url, {
    bool headless = false,
    int? debugPort,
    bool skipCheck = false,
    Directory? cacheDir,
    List<String> webBrowserFlags = const <String>[],
  }) async {
    return await onLaunch(++launchCount);
  }
}

/// A [WebSocketSink] that forwards to a plain [StreamSink].
class FakeWebSocketSink implements WebSocketSink {
  FakeWebSocketSink(this._sink);

  final StreamSink<Object?> _sink;

  @override
  void add(Object? data) => _sink.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) => _sink.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<Object?> stream) => _sink.addStream(stream);

  @override
  Future<void> close([int? closeCode, String? closeReason]) => _sink.close();

  @override
  Future<void> get done => _sink.done;
}

/// A [WebSocketChannel] whose incoming stream is driven by the test.
class FakeWebSocketChannel extends StreamChannelMixin<Object?> implements WebSocketChannel {
  FakeWebSocketChannel(this.controller) : sink = FakeWebSocketSink(controller.foreign.sink);

  final StreamChannelController<Object?> controller;

  @override
  Stream<Object?> get stream => controller.foreign.stream;

  @override
  final WebSocketSink sink;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready async {}
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

typedef _WebPlatformHarness = ({
  FlutterWebPlatform webPlatform,
  MultiChannel<Object?> hostChannel,
  List<Map<String, Object?>> hostMessages,
  Completer<int> exitCode,
});

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
        templateRenderer: const MustacheTemplateRenderer(),
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
        templateRenderer: const MustacheTemplateRenderer(),
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
    testWithoutContext(
      'FlutterWebPlatform sets Cache-Control headers on static and Wasm test assets ($os)',
      () async {
        final testFs = MemoryFileSystem.test(style: style);
        final testPlatform = FakePlatform(operatingSystem: os);
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

        final toolContext = FakeToolContext(
          artifacts: testArtifacts,
          cache: FakeCache(fileSystem: testFs, flutterRoot: testFs.directory('flutter').path),
          fs: testFs,
          logger: logger,
          platform: testPlatform,
          processManager: processManager,
        );
        final File ahemFile =
            testFs.file(
                testFs.path.join(
                  toolContext.cache.flutterRoot,
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
          templateRenderer: const MustacheTemplateRenderer(),
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
        templateRenderer: const MustacheTemplateRenderer(),
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

  BrowserManager createBrowserManager(
    StreamChannelController<Object?> controller,
    Process process,
  ) {
    final chromiumLauncher = ChromiumLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: operatingSystemUtils,
      browserFinder: (Platform platform, FileSystem fileSystem) => 'chrome',
      logger: logger,
    );
    final chromium = Chromium(
      0,
      ChromeConnection('localhost', 1234),
      chromiumLauncher: chromiumLauncher,
      process: process,
      logger: logger,
    );
    return BrowserManager.test(
      chromium,
      Runtime.chrome,
      FakeWebSocketChannel(controller),
      logger,
      const SystemClock(),
    );
  }

  testWithoutContext('BrowserManager reports a disconnect and starts cleanup at once', () {
    // Regression test for https://github.com/flutter/flutter/issues/191920.
    FakeAsync().run((FakeAsync time) {
      logger = BufferLogger.test(verbose: true);
      final exitCode = Completer<int>();
      final controller = StreamChannelController<Object?>();
      createBrowserManager(controller, FakeProcess(exitCode: exitCode.future));

      controller.local.sink.close();
      time.flushMicrotasks();

      expect(logger.errorText, contains('closed its connection to the test host unexpectedly'));
      expect(logger.traceText, contains('Shutting down Chromium.'));

      exitCode.complete(0);
      time.flushMicrotasks();
    });
  });

  testWithoutContext('BrowserManager reports an exit code delivered after cleanup starts', () {
    // Regression test for https://github.com/flutter/flutter/issues/191920.
    FakeAsync().run((FakeAsync time) {
      final exitCode = Completer<int>();
      final controller = StreamChannelController<Object?>();
      createBrowserManager(controller, FakeProcess(exitCode: exitCode.future));

      // A dying process takes its connection with it, and the connection is
      // seen to close before the exit code arrives.
      controller.local.sink.close();
      time.flushMicrotasks();
      // The exit notification can be delivered after cleanup starts. It must
      // not depend on an arbitrary grace period after the channel closes.
      time.elapse(const Duration(seconds: 2));
      exitCode.complete(-9);
      time.flushMicrotasks();

      expect(logger.errorText, contains('closed its connection to the test host unexpectedly'));
      expect(
        logger.errorText,
        contains('exited with code -9 after disconnecting from the test host'),
      );
    });
  });

  testWithoutContext('BrowserManager reports a process exit before the connection closes', () {
    FakeAsync().run((FakeAsync time) {
      final exitCode = Completer<int>();
      final controller = StreamChannelController<Object?>();
      createBrowserManager(controller, FakeProcess(exitCode: exitCode.future));

      exitCode.complete(-9);
      time.flushMicrotasks();

      expect(logger.errorText, contains('exited unexpectedly with code -9'));

      controller.local.sink.close();
      time.flushMicrotasks();

      expect(logger.errorText, contains('closed its connection to the test host unexpectedly'));
    });
  });

  testWithoutContext(
    'BrowserManager does not diagnose an intentional shutdown as a disconnect',
    () {
      FakeAsync().run((FakeAsync time) {
        final exitCode = Completer<int>();
        final controller = StreamChannelController<Object?>();
        final BrowserManager manager = createBrowserManager(
          controller,
          FakeProcess(exitCode: exitCode.future),
        );

        manager.close();
        controller.local.sink.close();
        time.flushMicrotasks();
        exitCode.complete(-15);
        time.flushMicrotasks();

        expect(logger.errorText, isEmpty);
      });
    },
  );

  testWithoutContext('BrowserManager does not report a clean exit after cleanup', () {
    FakeAsync().run((FakeAsync time) {
      final exitCode = Completer<int>();
      final controller = StreamChannelController<Object?>();
      createBrowserManager(controller, FakeProcess(exitCode: exitCode.future));

      controller.local.sink.close();
      time.flushMicrotasks();
      // A healthy browser may exit normally when closed after its page dies.
      exitCode.complete(0);
      time.flushMicrotasks();

      expect(logger.errorText, contains('closed its connection to the test host unexpectedly'));
      expect(logger.errorText, isNot(contains('exited with code')));
      expect(logger.errorText, isNot(contains('exited unexpectedly')));
    });
  });

  Future<FlutterWebPlatform> startPlatformWithLauncher(
    ChromiumLauncher chromiumLauncher, {
    BrowserManager? browserManager,
  }) {
    return FlutterWebPlatform.start(
      tempDir.path,
      buildDirectory: fileSystem.directory('build'),
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        packageConfigPath: '.dart_tool/package_config.json',
        treeShakeIcons: false,
      ),
      chromiumLauncher: chromiumLauncher,
      crossOriginIsolation: false,
      flutterProject: FlutterProject.fromDirectoryTest(tempDir),
      flutterTesterBinPath: artifacts.getArtifactPath(Artifact.flutterTester),
      toolContext: FakeToolContext(
        artifacts: artifacts,
        cache: FakeCache(fileSystem: fileSystem, flutterRoot: fileSystem.directory('flutter').path),
        fs: fileSystem,
        logger: logger,
        processManager: processManager,
      ),
      useWasm: true,
      webMemoryFS: WebMemoryFS(),
      webRenderer: WebRendererMode.canvaskit,
      serverFactory: () async => FakeServer(),
      testPackageUri: Uri.parse('test'),
      templateRenderer: const MustacheTemplateRenderer(),
      browserManager: browserManager,
    );
  }

  _WebPlatformHarness createWebPlatformHarness(FakeAsync time) {
    final exitCode = Completer<int>();
    final controller = StreamChannelController<Object?>();
    final hostChannel = MultiChannel<Object?>(
      controller.local.cast<String>().transform(jsonDocument),
    );
    final hostMessages = <Map<String, Object?>>[];
    hostChannel.stream.listen((Object? message) {
      hostMessages.add(message! as Map<String, Object?>);
    });

    final BrowserManager manager = createBrowserManager(
      controller,
      FakeProcess(exitCode: exitCode.future),
    );
    final chromiumLauncher = ChromiumLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: operatingSystemUtils,
      browserFinder: (Platform platform, FileSystem filesystem) => 'chrome',
      logger: logger,
    );
    late FlutterWebPlatform webPlatform;
    startPlatformWithLauncher(chromiumLauncher, browserManager: manager).then((
      FlutterWebPlatform value,
    ) {
      webPlatform = value;
    });
    time.flushMicrotasks();
    return (
      webPlatform: webPlatform,
      hostChannel: hostChannel,
      hostMessages: hostMessages,
      exitCode: exitCode,
    );
  }

  VirtualChannel<Object?> suiteChannelForLoad(
    MultiChannel<Object?> hostChannel,
    List<Map<String, Object?>> hostMessages,
    int suiteId,
  ) {
    final Map<String, Object?> loadMsg = hostMessages.singleWhere(
      (Map<String, Object?> m) => m['command'] == 'loadSuite' && m['id'] == suiteId,
    );
    final Uri suiteUrl = Uri.parse(loadMsg['url']! as String);
    final fragment = jsonDecode(Uri.decodeFull(suiteUrl.fragment)) as Map<String, Object?>;
    expect(fragment['id'], suiteId);
    return hostChannel.virtualChannel((loadMsg['channel']! as num).toInt());
  }

  Map<String, Object?> suiteSuccessMessage() {
    return <String, Object?>{
      'type': 'success',
      'root': <String, Object?>{
        'type': 'group',
        'name': '',
        'metadata': Metadata().serialize(),
        'entries': <Object?>[],
      },
    };
  }

  testWithoutContext(
    'FlutterWebPlatform.load releases _suiteLock and closes stalled iframe on 3m timeout',
    () {
      FakeAsync().run((FakeAsync time) {
        final _WebPlatformHarness harness = createWebPlatformHarness(time);

        Object? firstError;
        harness.webPlatform
            .load(
              tempDir.childDirectory('test').childFile('stalled_test.dart').path,
              SuitePlatform(Runtime.chrome),
              SuiteConfiguration.empty,
              <String, Object?>{},
            )
            .then<void>((_) {}, onError: (Object error) => firstError = error);
        time.flushMicrotasks();

        final VirtualChannel<Object?> firstSuiteChannel = suiteChannelForLoad(
          harness.hostChannel,
          harness.hostMessages,
          0,
        );

        time.elapse(const Duration(seconds: 45));
        expect(logger.statusText, contains('Chrome Web Test Timeout Diagnostic'));
        expect(firstError, isNull);

        time.elapse(const Duration(minutes: 2, seconds: 15));
        expect(
          firstError,
          isA<ToolExit>().having(
            (ToolExit e) => e.message,
            'message',
            contains('Failing this suite so the remaining suites can run.'),
          ),
        );
        expect(logger.errorText, contains('Hard timeout of 3 minutes reached for test suite'));
        expect(
          harness.hostMessages.where(
            (Map<String, Object?> m) => m['command'] == 'closeSuite' && m['id'] == 0,
          ),
          hasLength(1),
        );

        // Late frames sent by the stalled iframe before Chrome processes
        // closeSuite must be ignored because suiteChannel was closed on timeout.
        // deserializeSuite wraps suiteChannel in a nested MultiChannel whose
        // default channel 0 carries load messages.
        final firstRemoteChannel = MultiChannel<Object?>(firstSuiteChannel);
        firstRemoteChannel.sink.add(suiteSuccessMessage());
        firstRemoteChannel.sink.add(<String, Object?>{
          'type': 'error',
          'error': <String, Object?>{
            'type': 'StateError',
            'toString': 'Bad state: late error',
            'message': 'late error',
            'supertype': null,
            'stackChain': '',
          },
        });
        time.flushMicrotasks();

        // Next suite must acquire _suiteLock immediately rather than deadlocking.
        RunnerSuite? secondSuite;
        Object? secondError;
        harness.webPlatform
            .load(
              tempDir.childDirectory('test').childFile('healthy_test.dart').path,
              SuitePlatform(Runtime.chrome),
              SuiteConfiguration.empty,
              <String, Object?>{},
            )
            .then<void>(
              (RunnerSuite suite) => secondSuite = suite,
              onError: (Object error) => secondError = error,
            );
        time.flushMicrotasks();

        final VirtualChannel<Object?> secondSuiteChannel = suiteChannelForLoad(
          harness.hostChannel,
          harness.hostMessages,
          1,
        );
        MultiChannel<Object?>(secondSuiteChannel).sink.add(suiteSuccessMessage());
        time.flushMicrotasks();

        expect(secondError, isNull);
        expect(secondSuite, isNotNull);

        // A delayed channel close from the stalled suite must not double-release
        // _suiteLock or send a duplicate closeSuite command.
        firstSuiteChannel.sink.close();
        time.flushMicrotasks();
        expect(
          harness.hostMessages.where(
            (Map<String, Object?> m) => m['command'] == 'closeSuite' && m['id'] == 0,
          ),
          hasLength(1),
        );

        secondSuite!.close();
        harness.webPlatform.close();
        time.flushMicrotasks();
        harness.exitCode.complete(0);
        time.flushMicrotasks();
      });
    },
  );

  testWithoutContext('FlutterWebPlatform.load releases _suiteLock when suite load fails', () {
    FakeAsync().run((FakeAsync time) {
      final _WebPlatformHarness harness = createWebPlatformHarness(time);

      Object? firstError;
      harness.webPlatform
          .load(
            tempDir.childDirectory('test').childFile('failing_test.dart').path,
            SuitePlatform(Runtime.chrome),
            SuiteConfiguration.empty,
            <String, Object?>{},
          )
          .then<void>((_) {}, onError: (Object error) => firstError = error);
      time.flushMicrotasks();

      final VirtualChannel<Object?> firstSuiteChannel = suiteChannelForLoad(
        harness.hostChannel,
        harness.hostMessages,
        0,
      );
      MultiChannel<Object?>(firstSuiteChannel).sink
          .add(<String, Object?>{'type': 'loadException', 'message': 'boom'});
      time.flushMicrotasks();

      expect(firstError.toString(), contains('boom'));
      expect(
        harness.hostMessages.where(
          (Map<String, Object?> m) => m['command'] == 'closeSuite' && m['id'] == 0,
        ),
        hasLength(1),
      );

      // Confirm cancelWatchdogs() cleared the 45s and 3m timers for the failed suite.
      time.elapse(const Duration(minutes: 3));
      expect(logger.statusText, isEmpty);
      expect(logger.errorText, isEmpty);

      RunnerSuite? secondSuite;
      harness.webPlatform
          .load(
            tempDir.childDirectory('test').childFile('healthy_test.dart').path,
            SuitePlatform(Runtime.chrome),
            SuiteConfiguration.empty,
            <String, Object?>{},
          )
          .then<void>((RunnerSuite suite) => secondSuite = suite);
      time.flushMicrotasks();

      final VirtualChannel<Object?> secondSuiteChannel = suiteChannelForLoad(
        harness.hostChannel,
        harness.hostMessages,
        1,
      );
      MultiChannel<Object?>(secondSuiteChannel).sink.add(suiteSuccessMessage());
      time.flushMicrotasks();

      expect(secondSuite, isNotNull);

      firstSuiteChannel.sink.close();
      secondSuite!.close();
      harness.webPlatform.close();
      time.flushMicrotasks();
      harness.exitCode.complete(0);
      time.flushMicrotasks();
    });
  });

  testWithoutContext(
    'FlutterWebPlatform.load releases _suiteLock when _launchBrowser throws Exception',
    () async {
      final launcher = _ThrowingChromiumLauncher(
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
        operatingSystemUtils: operatingSystemUtils,
        browserFinder: (Platform platform, FileSystem filesystem) => 'chrome',
        logger: logger,
        onLaunch: (_) => throw const _TestBrowserLaunchException(),
      );
      final FlutterWebPlatform webPlatform = await startPlatformWithLauncher(launcher);

      await expectLater(
        webPlatform.load(
          tempDir.childDirectory('test').childFile('first_test.dart').path,
          SuitePlatform(Runtime.chrome),
          SuiteConfiguration.empty,
          <String, Object?>{},
        ),
        throwsA(isA<_TestBrowserLaunchException>()),
      );
      await expectLater(
        webPlatform.load(
          tempDir.childDirectory('test').childFile('second_test.dart').path,
          SuitePlatform(Runtime.chrome),
          SuiteConfiguration.empty,
          <String, Object?>{},
        ),
        throwsA(isA<_TestBrowserLaunchException>()),
      );
      expect(launcher.launchCount, 2);

      await webPlatform.close();
    },
  );

  testWithoutContext('FlutterWebPlatform.load releases _suiteLock before closing pool when _launchBrowser throws Error', () async {
    final launcher = _ThrowingChromiumLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: operatingSystemUtils,
      browserFinder: (Platform platform, FileSystem filesystem) => 'chrome',
      logger: logger,
      onLaunch: (_) => throw StateError('launch failed'),
    );
    final FlutterWebPlatform webPlatform = await startPlatformWithLauncher(launcher);

    await expectLater(
      webPlatform.load(
        tempDir.childDirectory('test').childFile('first_test.dart').path,
        SuitePlatform(Runtime.chrome),
        SuiteConfiguration.empty,
        <String, Object?>{},
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      webPlatform.load(
        tempDir.childDirectory('test').childFile('second_test.dart').path,
        SuitePlatform(Runtime.chrome),
        SuiteConfiguration.empty,
        <String, Object?>{},
      ),
      throwsA(isA<StateError>()),
    );
    expect(launcher.launchCount, 1);

    await webPlatform.close();
  });

  testWithoutContext(
    'FlutterWebPlatform.load releases _suiteLock if closed while load completes',
    () {
      FakeAsync().run((FakeAsync time) {
        final _WebPlatformHarness harness = createWebPlatformHarness(time);

        Object? firstError;
        harness.webPlatform
            .load(
              tempDir.childDirectory('test').childFile('first_test.dart').path,
              SuitePlatform(Runtime.chrome),
              SuiteConfiguration.empty,
              <String, Object?>{},
            )
            .then<void>((_) {}, onError: (Object error) => firstError = error);
        time.flushMicrotasks();

        Object? queuedError;
        harness.webPlatform
            .load(
              tempDir.childDirectory('test').childFile('queued_test.dart').path,
              SuitePlatform(Runtime.chrome),
              SuiteConfiguration.empty,
              <String, Object?>{},
            )
            .then<void>((_) {}, onError: (Object error) => queuedError = error);
        time.flushMicrotasks();

        final VirtualChannel<Object?> firstSuiteChannel = suiteChannelForLoad(
          harness.hostChannel,
          harness.hostMessages,
          0,
        );
        // Close the platform while first load is in-flight and second load is
        // queued on _suiteLock.request().
        harness.webPlatform.close();
        MultiChannel<Object?>(firstSuiteChannel).sink.add(suiteSuccessMessage());
        time.flushMicrotasks();

        expect(firstError, isA<StateError>());
        expect(queuedError, isA<StateError>());

        firstSuiteChannel.sink.close();
        harness.exitCode.complete(0);
        time.flushMicrotasks();
      });
    },
  );

  testWithoutContext(
    'FlutterWebPlatform.load does not launch browser for queued load after close',
    () async {
      final launchGate = Completer<void>();
      final launcher = _ThrowingChromiumLauncher(
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
        operatingSystemUtils: operatingSystemUtils,
        browserFinder: (Platform platform, FileSystem filesystem) => 'chrome',
        logger: logger,
        onLaunch: (_) async {
          await launchGate.future;
          throw const _TestBrowserLaunchException();
        },
      );
      final FlutterWebPlatform webPlatform = await startPlatformWithLauncher(launcher);

      final Future<RunnerSuite> firstLoad = webPlatform.load(
        tempDir.childDirectory('test').childFile('first_test.dart').path,
        SuitePlatform(Runtime.chrome),
        SuiteConfiguration.empty,
        <String, Object?>{},
      );
      final Future<RunnerSuite> queuedLoad = webPlatform.load(
        tempDir.childDirectory('test').childFile('queued_test.dart').path,
        SuitePlatform(Runtime.chrome),
        SuiteConfiguration.empty,
        <String, Object?>{},
      );
      // Let firstLoad reach _launchBrowser and queuedLoad wait on _suiteLock.
      await Future<void>.delayed(Duration.zero);
      await webPlatform.close();

      launchGate.complete();

      await expectLater(firstLoad, throwsA(isA<_TestBrowserLaunchException>()));
      await expectLater(queuedLoad, throwsA(isA<StateError>()));
      expect(launcher.launchCount, 1);
    },
  );
}
