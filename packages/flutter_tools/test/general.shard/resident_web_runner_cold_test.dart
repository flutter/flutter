// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/web.dart';
import 'package:flutter_tools/src/build_system/tools/shader_compiler.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/flutter_application_package.dart';
import 'package:flutter_tools/src/isolated/build_targets.dart';
import 'package:flutter_tools/src/isolated/devfs_web.dart';
import 'package:flutter_tools/src/isolated/web_flutter_device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_cold.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/compiler_config.dart';
import 'package:flutter_tools/src/web/devfs_config.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';
import '../src/fakes.dart' hide FakeProcess;
import '../src/package_config.dart';
import '../src/test_build_system.dart';

void main() {
  late FakeWebDevFS fakeWebDevFS;
  late FakeWebDevice fakeWebDevice;
  late MemoryFileSystem fileSystem;
  late BufferLogger logger;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    fakeWebDevFS = FakeWebDevFS();
    fakeWebDevice = FakeWebDevice();

    fileSystem.file('pubspec.yaml').writeAsStringSync('name: my_app\n');
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
    fileSystem.file(fileSystem.path.join('web', 'index.html')).createSync(recursive: true);
  });

  ColdRunner createWebColdRunner({
    required DebuggingOptions debuggingOptions,
    BuildSystem? buildSystem,
    Device? device,
    bool prePopulateDevFS = true,
    bool stayResident = true,
    Map<String, String> webDefines = const <String, String>{},
  }) {
    final toolContext = FakeToolContext(
      fs: fileSystem,
      logger: logger,
      processManager: FakeProcessManager.any(),
      systemClock: SystemClock.fixed(DateTime(2001)),
    );
    final FlutterProject project = toolContext.projectFactory.fromDirectory(
      fileSystem.currentDirectory,
    );
    final webFlutterDevice = WebFlutterDevice(
      device ?? fakeWebDevice,
      buildInfo: debuggingOptions.buildInfo,
      developmentShaderCompiler: const FakeShaderCompiler(),
      flutterProject: project,
      generator: null,
      targetPlatform: TargetPlatform.web_javascript,
      toolContext: toolContext,
      useWasm: debuggingOptions.webConfig.useWasm,
      webDefines: webDefines,
    );
    if (prePopulateDevFS) {
      webFlutterDevice.devFS = fakeWebDevFS;
    }
    return ColdRunner(
      <FlutterDevice>[webFlutterDevice],
      analytics: const NoOpAnalytics(),
      applicationPackageFactory: FlutterApplicationPackageFactory(
        androidSdkBuilder: () => null,
        plistParserBuilder: FakePlistParser.new,
        templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
        toolContext: toolContext,
      ),
      assetBundleFactory: AssetBundleFactory.defaultInstance(
        fileSystem: fileSystem,
        flutterRoot: '',
        logger: logger,
        platform: FakePlatform(),
      ),
      buildSystem: buildSystem ?? TestBuildSystem.all(BuildResult(success: true)),
      buildTargets: const BuildTargetsImpl(),
      debuggingOptions: debuggingOptions,
      featureFlags: TestFeatureFlags(),
      stayResident: stayResident,
      target: fileSystem.path.join('lib', 'main.dart'),
      toolContext: toolContext,
      xcode: null,
    );
  }

  testWithoutContext('Can successfully run and connect without vmservice', () async {
    final ColdRunner runner = createWebColdRunner(
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
    );

    expect(runner.canHotReload, false);
    expect(runner.reloadIsRestart, true);
    expect(runner.supportsRestart, true);
    expect(runner.supportsServiceProtocol, false);

    final appStartedCompleter = Completer<void>();
    final Future<int> runFuture = runner.run(appStartedCompleter: appStartedCompleter);
    await appStartedCompleter.future;

    expect(fakeWebDevFS.wasMarkedReady, true);

    await runner.exit();
    expect(await runFuture, 0);
    expect(fakeWebDevFS.wasDestroyed, true);
  });

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testWithoutContext('ColdRunner calls appFailedToStart if initial compilation fails', () async {
    final ColdRunner runner = createWebColdRunner(
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      buildSystem: TestBuildSystem.all(BuildResult(success: false)),
    );

    await expectLater(runner.run(), throwsToolExit());
    expect(await runner.waitForAppToFinish(), 1);
  });

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testWithoutContext(
    'ColdRunner calls appFailedToStart if error is thrown during startup',
    () async {
      final ColdRunner runner = createWebColdRunner(
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        buildSystem: TestBuildSystem.error(Exception('foo')),
      );

      await expectLater(runner.run(), throwsToolExit());
      expect(await runner.waitForAppToFinish(), 1);
    },
  );

  testWithoutContext('Can full restart after attaching and reloads Chrome page', () async {
    final chromeConnection = FakeChromeConnection();
    final chromeTab = FakeChromeTab('http://localhost:8080/index.html');
    chromeConnection.tabs.add(chromeTab);
    final chromiumLauncher = TestChromiumLauncher();
    final chrome = Chromium(
      1,
      chromeConnection,
      chromiumLauncher: chromiumLauncher,
      process: FakeProcess(),
      logger: logger,
    );
    chromiumLauncher.setInstance(chrome);
    final chromeDevice = GoogleChromeDevice(
      fileSystem: fileSystem,
      chromiumLauncher: chromiumLauncher,
      logger: logger,
      platform: FakePlatform(),
      processManager: FakeProcessManager.any(),
    );

    final ColdRunner runner = createWebColdRunner(
      device: chromeDevice,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
    );
    final appStartedCompleter = Completer<void>();
    final Future<int> runFuture = runner.run(appStartedCompleter: appStartedCompleter);
    await appStartedCompleter.future;

    final OperationResult result = await runner.restart(fullRestart: true);

    expect(result.code, 0);
    expect(chromeTab.connection.commands, <Map<String, Object?>>[
      <String, Object?>{
        'method': 'Page.reload',
        'params': <String, Object>{'ignoreCache': true},
      },
    ]);
    expect(logger.statusText, contains('Restarted application in'));

    await runner.exit();
    expect(await runFuture, 0);
    expect(chromeTab.connection.wasClosed, true);
    expect(fakeWebDevFS.wasDestroyed, true);
  });

  testWithoutContext('Fails on compilation errors in hot restart', () async {
    final ColdRunner runner = createWebColdRunner(
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      buildSystem: TestBuildSystem.list(<BuildResult>[
        BuildResult(success: true),
        BuildResult(success: false),
      ]),
    );
    final appStartedCompleter = Completer<void>();
    unawaited(runner.run(appStartedCompleter: appStartedCompleter));
    await appStartedCompleter.future;
    final OperationResult result = await runner.restart(fullRestart: true);

    expect(result.code, 1);
    expect(result.message, contains('Failed to recompile application.'));
  });

  testWithoutContext('profile does not support service protocol on web', () {
    final ColdRunner profileRunner = createWebColdRunner(
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.profile),
      stayResident: false,
    );

    expect(profileRunner.isRunningProfile, true);
    expect(profileRunner.supportsServiceProtocol, false);
    expect(profileRunner.canHotReload, false);
    expect(profileRunner.supportsRestart, true);
  });

  testWithoutContext('Wasm web builds disable debug/profile runtime and service protocol', () {
    for (final buildInfo in const <BuildInfo>[BuildInfo.debug, BuildInfo.profile]) {
      final ColdRunner wasmRunner = createWebColdRunner(
        debuggingOptions: DebuggingOptions.enabled(
          buildInfo,
          webConfig: const WebDebugConfig(useWasm: true),
        ),
        stayResident: false,
      );

      expect(wasmRunner.isRunningDebug, false);
      expect(wasmRunner.isRunningProfile, false);
      expect(wasmRunner.supportsServiceProtocol, false);
      expect(wasmRunner.supportsRestart, true);
    }
  });

  // Regression test for https://github.com/flutter/flutter/issues/167887.
  testWithoutContext('WASM builds report analysis without crashing', () async {
    final chromeConnection = FakeChromeConnection();
    final chromeTab = FakeChromeTab('http://localhost:8080/index.html');
    chromeConnection.tabs.add(chromeTab);
    final chromiumLauncher = TestChromiumLauncher();
    final chrome = Chromium(
      1,
      chromeConnection,
      chromiumLauncher: chromiumLauncher,
      process: FakeProcess(),
      logger: logger,
    );
    chromiumLauncher.setInstance(chrome);
    final chromeDevice = GoogleChromeDevice(
      fileSystem: fileSystem,
      chromiumLauncher: chromiumLauncher,
      logger: logger,
      platform: FakePlatform(),
      processManager: FakeProcessManager.any(),
    );

    final ColdRunner runner = createWebColdRunner(
      device: chromeDevice,
      debuggingOptions: DebuggingOptions.enabled(
        const BuildInfo(
          BuildMode.debug,
          null,
          trackWidgetCreation: true,
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
          extraFrontEndOptions: kDdcLibraryBundleFlags,
        ),
        webConfig: const WebDebugConfig(useWasm: true),
      ),
    );

    final appStartedCompleter = Completer<void>();
    unawaited(runner.run(appStartedCompleter: appStartedCompleter));
    await appStartedCompleter.future;

    final OperationResult result = await runner.restart();
    expect(logger.statusText, contains('Restarted application in'));
    expect(result.code, 0);
    expect(chromeTab.connection.commands, <Map<String, Object?>>[
      <String, Object?>{
        'method': 'Page.reload',
        'params': <String, Object>{'ignoreCache': false},
      },
    ]);
  });

  testWithoutContext('Turns HttpException from ChromeTab.connect into ToolExit', () async {
    final chromeConnection = FakeChromeConnection();
    chromeConnection.tabs.add(
      FakeChromeTab(
        'http://localhost:8080/index.html',
        connectException: HttpException(
          'Connection closed before full header was received',
          uri: Uri.parse('http://localhost:50094/devtools/page/123'),
        ),
      ),
    );
    final chromiumLauncher = TestChromiumLauncher();
    chromiumLauncher.setInstance(
      Chromium(
        1,
        chromeConnection,
        chromiumLauncher: chromiumLauncher,
        process: FakeProcess(),
        logger: logger,
      ),
    );
    final chromeDevice = GoogleChromeDevice(
      fileSystem: fileSystem,
      chromiumLauncher: chromiumLauncher,
      logger: logger,
      platform: FakePlatform(),
      processManager: FakeProcessManager.any(),
    );

    final ColdRunner runner = createWebColdRunner(
      device: chromeDevice,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
    );

    await expectLater(
      runner.run(),
      throwsToolExit(
        message: 'Failed to establish connection with the application instance in Chrome.',
      ),
    );
    expect(logger.errorText, contains('HttpException'));
  });

  testWithoutContext('logs hint and continues when project has no web directory', () async {
    fileSystem.directory('web').deleteSync(recursive: true);
    final ColdRunner runner = createWebColdRunner(
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      stayResident: false,
    );

    expect(await runner.run(), 0);
    expect(logger.statusText, contains('This application is not configured to build on the web.'));
    expect(logger.statusText, contains('To add web support to a project, run `flutter create .`.'));
  });

  testWithoutContext(
    'throws ToolExit when port is an integer outside the valid TCP range',
    () async {
      final ColdRunner highPortRunner = createWebColdRunner(
        debuggingOptions: DebuggingOptions.disabled(
          BuildInfo.release,
          webConfig: const WebDebugConfig(devServerConfig: WebDevServerConfig(port: 65536)),
        ),
        stayResident: false,
      );
      await expectToolExitLater(highPortRunner.run(), matches('Invalid port: 65536.*'));

      final ColdRunner negativePortRunner = createWebColdRunner(
        debuggingOptions: DebuggingOptions.disabled(
          BuildInfo.release,
          webConfig: const WebDebugConfig(devServerConfig: WebDevServerConfig(port: -1)),
        ),
        stayResident: false,
      );
      await expectToolExitLater(negativePortRunner.run(), matches('Invalid port: -1.*'));
    },
  );

  testWithoutContext(
    'WebDevice.createFlutterDevice skips ResidentCompiler in profile, release, and wasm modes',
    () async {
      final toolContext = FakeToolContext(
        fs: fileSystem,
        logger: logger,
        processManager: FakeProcessManager.any(),
      );
      final webDevice = WebServerDevice(
        logger: logger,
        webFlutterDeviceFactory: const DwdsWebFlutterDeviceFactory(),
      );

      final FlutterProject flutterProject = toolContext.projectFactory.fromDirectory(
        fileSystem.currentDirectory,
      );
      for (final (BuildInfo buildInfo, bool useWasm) in <(BuildInfo, bool)>[
        (BuildInfo.profile, false),
        (BuildInfo.release, false),
        (BuildInfo.debug, true),
      ]) {
        final FlutterDevice device = await webDevice.createFlutterDevice(
          buildInfo: buildInfo,
          flutterProject: flutterProject,
          toolContext: toolContext,
          useWasm: useWasm,
        );

        expect(device, isA<WebFlutterDevice>());
        expect(device.generator, isNull);
        expect(device.supportsColdRestart, isTrue);
      }

      await expectLater(
        WebServerDevice(logger: logger).createFlutterDevice(
          buildInfo: BuildInfo.release,
          flutterProject: flutterProject,
          toolContext: toolContext,
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            'webFlutterDeviceFactory is required for web devices.',
          ),
        ),
      );

      await expectLater(
        webDevice.createFlutterDevice(buildInfo: BuildInfo.release, toolContext: toolContext),
        throwsStateError,
      );
    },
  );

  group('web-defines', () {
    testWithoutContext('passes web-defines to the build in profile mode', () async {
      var sawDefines = false;
      final ColdRunner runner = createWebColdRunner(
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.profile),
        stayResident: false,
        webDefines: const <String, String>{'VERSION': 'v1.2.3'},
        buildSystem: TestBuildSystem.all(BuildResult(success: true), (
          Target target,
          Environment environment,
        ) {
          sawDefines = true;
          expect(environment.defines['webDefine:VERSION'], 'v1.2.3');
        }),
      );

      expect(await runner.run(), 0);
      expect(sawDefines, isTrue);
    });

    testWithoutContext(
      'passes web-defines to the rebuild after a hot restart in release mode',
      () async {
        var buildCount = 0;
        final ColdRunner runner = createWebColdRunner(
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
          webDefines: const <String, String>{'VERSION': 'v1.2.3'},
          buildSystem: TestBuildSystem.all(BuildResult(success: true), (
            Target target,
            Environment environment,
          ) {
            buildCount += 1;
            expect(environment.defines['webDefine:VERSION'], 'v1.2.3');
          }),
        );

        final appStartedCompleter = Completer<void>();
        unawaited(runner.run(appStartedCompleter: appStartedCompleter));
        await appStartedCompleter.future;

        final OperationResult result = await runner.restart(fullRestart: true);
        expect(result.code, 0);
        expect(buildCount, 2);
        expect(logger.statusText, contains('Recompile complete. Page requires refresh.'));
      },
    );

    testWithoutContext('passes web-defines to the build in debug --wasm mode', () async {
      var sawDefines = false;
      final ColdRunner runner = createWebColdRunner(
        debuggingOptions: DebuggingOptions.enabled(
          BuildInfo.debug,
          webConfig: const WebDebugConfig(useWasm: true),
        ),
        stayResident: false,
        webDefines: const <String, String>{'VERSION': 'v1.2.3'},
        buildSystem: TestBuildSystem.all(BuildResult(success: true), (
          Target target,
          Environment environment,
        ) {
          sawDefines = true;
          expect(environment.defines['webDefine:VERSION'], 'v1.2.3');
        }),
      );

      expect(await runner.run(), 0);
      expect(sawDefines, isTrue);
    });
  });

  group('WasmCompilerConfig defaults', () {
    testWithoutContext(
      'passes WasmCompilerConfig with dynamic cache-equivalent defaults in release mode',
      () async {
        WebCompilerConfig? capturedConfig;
        final ColdRunner runner = createWebColdRunner(
          debuggingOptions: DebuggingOptions.disabled(
            BuildInfo.release,
            webConfig: const WebDebugConfig(useWasm: true),
          ),
          stayResident: false,
          buildSystem: TestBuildSystem.all(BuildResult(success: true), (
            Target target,
            Environment environment,
          ) {
            if (target is WebServiceWorker) {
              capturedConfig = target.compileConfigs.first;
            }
          }),
        );

        expect(await runner.run(), 0);
        expect(capturedConfig, isA<WasmCompilerConfig>());
        final wasmConfig = capturedConfig! as WasmCompilerConfig;

        // Relies on `WasmCompilerConfig` native defaults to maintain cache key parity with `flutter build`.
        expect(wasmConfig.optimizationLevel, isNull);
        expect(wasmConfig.stripWasm, isTrue);

        final List<String> commandOptions = wasmConfig.toCommandOptions(BuildMode.release);
        expect(commandOptions, contains('-O2'));
        expect(commandOptions, contains('--strip-wasm'));
      },
    );

    testWithoutContext(
      'passes WasmCompilerConfig with dynamic cache-equivalent defaults in debug mode',
      () async {
        WebCompilerConfig? capturedConfig;
        final ColdRunner runner = createWebColdRunner(
          debuggingOptions: DebuggingOptions.enabled(
            BuildInfo.debug,
            webConfig: const WebDebugConfig(useWasm: true),
          ),
          stayResident: false,
          buildSystem: TestBuildSystem.all(BuildResult(success: true), (
            Target target,
            Environment environment,
          ) {
            if (target is WebServiceWorker) {
              capturedConfig = target.compileConfigs.first;
            }
          }),
        );

        expect(await runner.run(), 0);
        expect(capturedConfig, isA<WasmCompilerConfig>());
        final wasmConfig = capturedConfig! as WasmCompilerConfig;

        // Relies on `WasmCompilerConfig` native defaults to maintain cache key parity with `flutter build`.
        expect(wasmConfig.optimizationLevel, isNull);
        expect(wasmConfig.stripWasm, isTrue);

        final List<String> commandOptions = wasmConfig.toCommandOptions(BuildMode.debug);
        expect(commandOptions, contains('-O0'));
        expect(commandOptions, contains('--no-strip-wasm'));
      },
    );
  });

  group('JsCompilerConfig deprecated JS interop', () {
    for (final deprecatedJsInterop in <bool?>[null, true, false]) {
      testWithoutContext(
        'passes deprecatedJsInterop: $deprecatedJsInterop to dart2js in release mode',
        () async {
          WebCompilerConfig? capturedConfig;
          final ColdRunner runner = createWebColdRunner(
            debuggingOptions: DebuggingOptions.disabled(
              BuildInfo(
                BuildMode.release,
                null,
                treeShakeIcons: false,
                packageConfigPath: '.dart_tool/package_config.json',
                deprecatedJsInterop: deprecatedJsInterop,
              ),
            ),
            stayResident: false,
            buildSystem: TestBuildSystem.all(BuildResult(success: true), (
              Target target,
              Environment environment,
            ) {
              if (target is WebServiceWorker) {
                capturedConfig = target.compileConfigs.first;
              }
            }),
          );

          expect(await runner.run(), 0);
          expect(
            capturedConfig,
            isA<JsCompilerConfig>().having(
              (JsCompilerConfig config) => config.deprecatedJsInterop,
              'deprecatedJsInterop',
              deprecatedJsInterop,
            ),
          );
        },
      );
    }
  });
}

class FakeWebDevFS extends Fake implements WebDevFS {
  bool wasMarkedReady = false;
  bool wasDestroyed = false;

  @override
  Uri get baseUri => Uri.parse('http://localhost:8080/');

  @override
  List<Uri> get sources => <Uri>[];

  @override
  Future<Uri> create() async => baseUri;

  @override
  void markReady() {
    wasMarkedReady = true;
  }

  @override
  Future<void> destroy() async {
    wasDestroyed = true;
  }
}

class FakeWebDevice extends Fake implements Device {
  @override
  String get name => 'web';

  @override
  String get displayName => name;

  @override
  final DartDevelopmentService dds = FakeDartDevelopmentService();

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.web_javascript;

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async => true;

  @override
  Future<void> dispose() async {}

  @override
  Future<String> get sdkNameAndVersion async => 'Flutter Tools';

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    String? mainPath,
    String? route,
    DebuggingOptions? debuggingOptions,
    Map<String, Object?>? platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String? userIdentifier,
  }) async {
    return LaunchResult.succeeded();
  }
}

class FakeChromeConnection extends Fake implements ChromeConnection {
  final tabs = <ChromeTab>[];

  @override
  Future<ChromeTab> getTab(bool Function(ChromeTab tab) accept, {Duration? retryFor}) async {
    return tabs.firstWhere(accept);
  }

  @override
  Future<List<ChromeTab>> getTabs({Duration? retryFor}) async => tabs;

  @override
  void close() {}
}

class FakeChromeTab extends Fake implements ChromeTab {
  FakeChromeTab(this.url, {this._connectException});

  @override
  final String url;

  final Exception? _connectException;
  final connection = FakeWipConnection();

  @override
  Future<WipConnection> connect({Function? onError}) async {
    if (_connectException != null) {
      throw _connectException;
    }
    return connection;
  }
}

class FakeWipConnection extends Fake implements WipConnection {
  final commands = <Map<String, Object?>>[];
  bool wasClosed = false;

  @override
  Future<WipResponse> sendCommand(String method, [Map<String, Object?>? params]) async {
    commands.add(<String, Object?>{'method': method, 'params': params});
    return WipResponse(<String, Object?>{'id': 0, 'result': <String, Object?>{}});
  }

  @override
  Future<void> close() async {
    wasClosed = true;
  }
}

class TestChromiumLauncher implements ChromiumLauncher {
  var _hasInstance = false;

  void setInstance(Chromium chromium) {
    _hasInstance = true;
    currentCompleter.complete(chromium);
  }

  @override
  Completer<Chromium> currentCompleter = Completer<Chromium>();

  @override
  bool canFindExecutable() => true;

  @override
  Future<Chromium> get connectedInstance => currentCompleter.future;

  @override
  String findExecutable() => 'chrome';

  @override
  bool get hasChromeInstance => _hasInstance;

  @override
  Future<Chromium> launch(
    String url, {
    bool headless = false,
    int? debugPort,
    bool skipCheck = false,
    Directory? cacheDir,
    List<String> webBrowserFlags = const <String>[],
  }) async {
    return currentCompleter.future;
  }

  @override
  Future<Chromium> connect(Chromium chrome, bool skipCheck) => currentCompleter.future;
}

class FakeShaderCompiler implements DevelopmentShaderCompiler {
  const FakeShaderCompiler();

  @override
  void configureCompiler(TargetPlatform? platform) {}

  @override
  Future<DevFSContent> recompileShader(DevFSContent inputShader) {
    throw UnimplementedError();
  }

  @override
  bool areDependenciesModified(DevFSContent shaderContent) => false;
}

class FakeDartDevelopmentService extends Fake implements DartDevelopmentService {
  @override
  Future<void> shutdown() async {}
}
