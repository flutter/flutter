// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:fake_async/fake_async.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/flutter_web_platform.dart';
import 'package:flutter_tools/src/test/runner.dart';
import 'package:flutter_tools/src/test/test_compiler.dart';
import 'package:flutter_tools/src/test/test_golden_comparator.dart';
import 'package:flutter_tools/src/test/test_wrapper.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:flutter_tools/src/web/firefox.dart';
import 'package:flutter_tools/src/web/memory_fs.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/fake.dart';
import 'package:test_core/backend.dart' show SuiteConfiguration;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart' hide StackTrace;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart' hide FakeProcess;

class _TestBrowserLaunchException implements Exception {
  const _TestBrowserLaunchException();
}

class _RecordingWebTestBrowserLauncher implements WebTestBrowserLauncher {
  String? lastUrl;
  bool? lastHeadless;
  List<String>? lastWebBrowserFlags;

  @override
  Future<WebTestBrowser> launch(
    String url, {
    bool headless = false,
    List<String> webBrowserFlags = const <String>[],
  }) {
    lastUrl = url;
    lastHeadless = headless;
    lastWebBrowserFlags = List<String>.from(webBrowserFlags);
    throw const _TestBrowserLaunchException();
  }
}

class _FakeTestCompiler extends Fake implements TestCompiler {
  bool disposed = false;

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class _CloseTrackingBrowser implements WebTestBrowser {
  final _exitCompleter = Completer<int>();
  bool closed = false;

  @override
  String get name => 'Firefox';

  @override
  int? get pid => 4242;

  @override
  Future<int> get onExit => _exitCompleter.future;

  @override
  Uri? get remoteDebuggerUrl => null;

  @override
  Future<WipConnection?>? get wipConnection => null;

  @override
  Future<void> close() async {
    closed = true;
    if (!_exitCompleter.isCompleted) {
      _exitCompleter.complete(0);
    }
  }
}

class _FixedBrowserLauncher implements WebTestBrowserLauncher {
  _FixedBrowserLauncher(this.browser);

  final WebTestBrowser browser;

  @override
  Future<WebTestBrowser> launch(
    String url, {
    bool headless = false,
    List<String> webBrowserFlags = const <String>[],
  }) async => browser;
}

class _FakeServer implements shelf.Server {
  shelf.Handler? mountedHandler;

  @override
  Future<void> close() async {}

  @override
  void mount(shelf.Handler handler) {
    mountedHandler = handler;
  }

  @override
  Uri get url => Uri.parse('http://localhost');
}

void main() {
  group('findFirefoxExecutable', () {
    testWithoutContext('respects FIREFOX_EXECUTABLE environment variable', () {
      final fs = MemoryFileSystem.test();
      final platform = FakePlatform(
        environment: <String, String>{kFirefoxEnvironment: '/custom/firefox'},
      );

      expect(findFirefoxExecutable(platform, fs), '/custom/firefox');
    });

    testWithoutContext('defaults to platform-specific executable when unset', () {
      final fs = MemoryFileSystem.test();

      expect(findFirefoxExecutable(FakePlatform(), fs), kLinuxFirefoxExecutable);
      expect(
        findFirefoxExecutable(FakePlatform(operatingSystem: 'macos'), fs),
        kMacOSFirefoxExecutable,
      );
    });
  });

  group('FirefoxLauncher and Firefox', () {
    late MemoryFileSystem fileSystem;
    late BufferLogger logger;
    late FakeProcessManager processManager;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      logger = BufferLogger.test();
      processManager = FakeProcessManager.empty();
    });

    testWithoutContext('creates isolated user.js profile, passes headless and custom flags, and deletes profile on close', () async {
      final exitCompleter = Completer<void>();
      const profilePath = '/.tmp_rand0/flutter_tools_firefox_profile.rand0';
      final platform = FakePlatform(
        environment: <String, String>{kFirefoxEnvironment: '/opt/firefox/firefox'},
      );
      processManager.addCommand(
        FakeCommand(
          command: const <String>[
            '/opt/firefox/firefox',
            '--profile',
            profilePath,
            '--headless',
            '-width',
            '1280',
            '-height',
            '800',
            '-no-remote',
            '-new-instance',
            '--devtools',
            'http://localhost:8080/index.html',
          ],
          environment: const <String, String>{
            kFirefoxEnvironment: '/opt/firefox/firefox',
            'MOZ_CRASHREPORTER_DISABLE': '1',
            'LANG': 'en_US.UTF-8',
            'MOZ_HEADLESS': '1',
            'LIBGL_ALWAYS_SOFTWARE': '1',
            'MOZ_DISABLE_CONTENT_SANDBOX': '1',
            'MOZ_DISABLE_GPU_SANDBOX': '1',
            'MOZ_DISABLE_RDD_SANDBOX': '1',
            'MOZ_DISABLE_SOCKET_PROCESS_SANDBOX': '1',
          },
          completer: exitCompleter,
        ),
      );

      final launcher = FirefoxLauncher(
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
        logger: logger,
      );
      final Firefox firefox = await launcher.launch(
        'http://localhost:8080/index.html',
        headless: true,
        webBrowserFlags: const <String>['--devtools'],
      );

      expect(firefox.name, 'Firefox');
      expect(firefox.profileDirectory, exists);
      final File userJs = firefox.profileDirectory.childFile('user.js');
      expect(userJs, exists);
      final String prefs = userJs.readAsStringSync();
      expect(prefs, contains('user_pref("webgl.force-enabled", true);'));
      expect(prefs, contains('user_pref("intl.accept_languages", "en-US, en");'));
      expect(
        prefs,
        contains('user_pref("network.proxy.no_proxies_on", "localhost, 127.0.0.1, ::1");'),
      );

      exitCompleter.complete();
      await firefox.close();

      expect(firefox.profileDirectory, isNot(exists));
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('omits --headless and MOZ_HEADLESS when headless is false', () async {
      final exitCompleter = Completer<void>();
      const profilePath = '/.tmp_rand0/flutter_tools_firefox_profile.rand0';
      final platform = FakePlatform(
        operatingSystem: 'macos',
        environment: <String, String>{
          kFirefoxEnvironment: '/Applications/Firefox',
          'LANG': 'en_US.UTF-8',
        },
      );
      processManager.addCommand(
        FakeCommand(
          command: const <String>[
            '/Applications/Firefox',
            '--profile',
            profilePath,
            '-width',
            '1280',
            '-height',
            '800',
            '-no-remote',
            '-new-instance',
            'http://localhost:8080/index.html',
          ],
          environment: const <String, String>{
            kFirefoxEnvironment: '/Applications/Firefox',
            'LANG': 'en_US.UTF-8',
            'MOZ_CRASHREPORTER_DISABLE': '1',
          },
          completer: exitCompleter,
        ),
      );

      final launcher = FirefoxLauncher(
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
        logger: logger,
      );
      final Firefox firefox = await launcher.launch('http://localhost:8080/index.html');
      exitCompleter.complete();
      await firefox.close();
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('escalates from SIGTERM to SIGKILL if Firefox does not exit promptly', () {
      FakeAsync().run((FakeAsync time) {
        final Directory profileDir = fileSystem.systemTempDirectory.createTempSync('ff.');
        final process = FakeProcess(duration: const Duration(seconds: 7));
        final firefox = Firefox(process: process, profileDirectory: profileDir, logger: logger);

        var closed = false;
        firefox.close().then((_) => closed = true);
        time.elapse(const Duration(seconds: 8));

        expect(closed, isTrue);
        expect(process.signals, <io.ProcessSignal>[
          io.ProcessSignal.sigterm,
          io.ProcessSignal.sigkill,
        ]);
        expect(profileDir, isNot(exists));
      });
    });
  });

  group('matchesWebSuitePlatform', () {
    testWithoutContext('filters @TestOn selectors accurately for Firefox and Chrome', () {
      final fs = MemoryFileSystem.test();
      final File vmOnlyTest = fs.file('vm_only_test.dart')
        ..writeAsStringSync("@TestOn('!browser')\nlibrary;\nvoid main() {}\n");
      final File browserTest = fs.file('browser_test.dart')
        ..writeAsStringSync("@TestOn('browser')\nlibrary;\nvoid main() {}\n");
      final File notFirefoxTest = fs.file('not_firefox_test.dart')
        ..writeAsStringSync("@TestOn('!firefox')\nlibrary;\nvoid main() {}\n");
      final File plainTest = fs.file('plain_test.dart')..writeAsStringSync('void main() {}\n');

      final firefoxPlatform = SuitePlatform(Runtime.firefox, compiler: Compiler.dart2wasm);
      final chromePlatform = SuitePlatform(Runtime.chrome, compiler: Compiler.dart2js);

      expect(matchesWebSuitePlatform(vmOnlyTest, firefoxPlatform), isFalse);
      expect(matchesWebSuitePlatform(vmOnlyTest, chromePlatform), isFalse);
      expect(matchesWebSuitePlatform(browserTest, firefoxPlatform), isTrue);
      expect(matchesWebSuitePlatform(browserTest, chromePlatform), isTrue);
      expect(matchesWebSuitePlatform(notFirefoxTest, firefoxPlatform), isFalse);
      expect(matchesWebSuitePlatform(notFirefoxTest, chromePlatform), isTrue);
      expect(matchesWebSuitePlatform(plainTest, firefoxPlatform), isTrue);
    });
  });

  group('FlutterWebPlatform Firefox wiring', () {
    testUsingContext('serves full CanvasKit variant, wasmAllowList, require-corp COI headers, and forwards Firefox flags without Chrome flags', () async {
      final fs = MemoryFileSystem.test();
      final logger = BufferLogger.test();
      final artifacts = Artifacts.test(fileSystem: fs);
      final processManager = FakeProcessManager.empty();
      final Directory projectDir = fs.systemTempDirectory.createTempSync('project.');
      final server = _FakeServer();
      final recordingLauncher = _RecordingWebTestBrowserLauncher();

      final Directory flutterJsDir = fs.directory(
        artifacts.getHostArtifact(HostArtifact.flutterJsDirectory).path,
      )..createSync(recursive: true);
      flutterJsDir.childFile('flutter.js').writeAsStringSync('// flutter.js');

      final FlutterWebPlatform webPlatform = await FlutterWebPlatform.start(
        projectDir.path,
        buildDirectory: projectDir.childDirectory('build'),
        buildInfo: const BuildInfo(
          BuildMode.debug,
          '',
          packageConfigPath: '.dart_tool/package_config.json',
          treeShakeIcons: false,
        ),
        browserLauncher: recordingLauncher,
        runtime: Runtime.firefox,
        headless: false,
        webBrowserFlags: const <String>['--custom-ff-flag'],
        crossOriginIsolation: true,
        flutterProject: FlutterProject.fromDirectoryTest(projectDir),
        flutterTesterBinPath: artifacts.getArtifactPath(Artifact.flutterTester),
        toolContext: FakeToolContext(
          artifacts: artifacts,
          fs: fs,
          logger: logger,
          processManager: processManager,
        ),
        useWasm: true,
        webMemoryFS: WebMemoryFS(),
        webRenderer: WebRendererMode.skwasm,
        serverFactory: () async => server,
        testPackageUri: Uri.parse('test'),
        templateRenderer: const MustacheTemplateRenderer(),
      );

      final shelf.Handler handler = server.mountedHandler!;
      final shelf.Response wrapperResponse = await handler(
        shelf.Request('GET', Uri.parse('http://localhost/widgets/basic_test.html')),
      );
      expect(wrapperResponse.statusCode, HttpStatus.ok);
      expect(wrapperResponse.headers['Cross-Origin-Opener-Policy'], 'same-origin');
      expect(wrapperResponse.headers['Cross-Origin-Embedder-Policy'], 'require-corp');
      final String wrapperHtml = await wrapperResponse.readAsString();
      expect(wrapperHtml, contains('canvasKitVariant: "full"'));
      expect(wrapperHtml, contains('gecko: true'));
      expect(wrapperHtml, contains('webkit: true'));

      final shelf.Response flutterJsResponse = await handler(
        shelf.Request('GET', Uri.parse('http://localhost/flutter.js')),
      );
      expect(flutterJsResponse.headers['Cross-Origin-Embedder-Policy'], 'require-corp');
      await flutterJsResponse.read().drain<void>();

      try {
        await webPlatform.load(
          'test/widgets/basic_test.dart',
          SuitePlatform(Runtime.firefox),
          SuiteConfiguration.empty,
          Object(),
        );
      } on _TestBrowserLaunchException catch (_) {}

      expect(recordingLauncher.lastHeadless, isFalse);
      expect(recordingLauncher.lastWebBrowserFlags, <String>['--custom-ff-flag']);

      await webPlatform.close();
    });

    testWithoutContext(
      'BrowserManager.start closes browser and throws ToolExit when WebSocket connection times out',
      () {
        FakeAsync().run((FakeAsync time) {
          final browser = _CloseTrackingBrowser();
          final neverSocket = Completer<WebSocketChannel>();
          Object? caughtError;

          BrowserManager.start(
            _FixedBrowserLauncher(browser),
            Runtime.firefox,
            Uri.parse('http://localhost/static/index.html'),
            neverSocket.future,
            connectTimeout: const Duration(seconds: 10),
            logger: BufferLogger.test(),
            systemClock: const SystemClock(),
          ).then<void>((_) {}, onError: (Object error) => caughtError = error);

          time.elapse(const Duration(seconds: 11));

          expect(browser.closed, isTrue);
          expect(caughtError, isA<ToolExit>());
          expect(
            (caughtError! as ToolExit).message,
            contains('Timed out waiting for Firefox to connect to the test host'),
          );
        });
      },
    );

    testWithoutContext(
      'TestGoldenComparator.close tolerates pre-deleted temp directory during concurrent shutdown',
      () async {
        final fs = MemoryFileSystem.test();
        final compiler = _FakeTestCompiler();
        final comparator = TestGoldenComparator(
          compilerFactory: () => compiler,
          flutterTesterBinPath: 'flutter_tester',
          toolContext: FakeToolContext(
            fs: fs,
            logger: BufferLogger.test(),
            processManager: FakeProcessManager.empty(),
          ),
        );

        // Simulate LocalFileSystem.dispose() deleting systemTempDirectory concurrently.
        for (final FileSystemEntity entity in fs.systemTempDirectory.listSync()) {
          entity.deleteSync(recursive: true);
        }

        await comparator.close();
        expect(compiler.disposed, isTrue);
      },
    );
  });
}
