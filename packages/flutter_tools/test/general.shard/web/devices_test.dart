// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/net.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/tools/shader_compiler.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/context/web_context.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/web_debug_config.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:flutter_tools/src/web/workflow.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

WebDevices _createWebDevices({
  FeatureFlags? featureFlags,
  FileSystem? fileSystem,
  Logger? logger,
  Platform? platform,
  ProcessManager? processManager,
}) {
  final FeatureFlags resolvedFeatureFlags = featureFlags ?? TestFeatureFlags(isWebEnabled: true);
  final FileSystem resolvedFileSystem = fileSystem ?? MemoryFileSystem.test();
  final Logger resolvedLogger = logger ?? BufferLogger.test();
  final Platform resolvedPlatform = platform ?? FakePlatform(environment: <String, String>{});
  final ProcessManager resolvedProcessManager = processManager ?? FakeProcessManager.any();
  return WebDevices(
    featureFlags: resolvedFeatureFlags,
    fileSystem: resolvedFileSystem,
    logger: resolvedLogger,
    platform: resolvedPlatform,
    processManager: resolvedProcessManager,
    webContext: WebContext(
      chromiumLauncherBuilder: () => ChromiumLauncher(
        browserFinder: findChromeExecutable,
        fileSystem: resolvedFileSystem,
        logger: resolvedLogger,
        operatingSystemUtils: OperatingSystemUtils(
          fileSystem: resolvedFileSystem,
          logger: resolvedLogger,
          platform: resolvedPlatform,
          processManager: resolvedProcessManager,
        ),
        platform: resolvedPlatform,
        processManager: resolvedProcessManager,
      ),
      webWorkflowBuilder: () =>
          WebWorkflow(featureFlags: resolvedFeatureFlags, platform: resolvedPlatform),
    ),
  );
}

void main() {
  testWithoutContext('No web devices listed if feature is disabled', () async {
    final WebDevices webDevices = _createWebDevices(featureFlags: TestFeatureFlags());

    expect(await webDevices.pollingGetDevices(), isEmpty);
  });

  _FakeChromiumDevice getFakeChromiumDevice() {
    final launcher = TestChromiumLauncher(launcher: () => _OnceClosableChromium());

    return _FakeChromiumDevice(
      chromiumLauncher: launcher,
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
    );
  }

  testWithoutContext(
    'Successive calls of ChromiumDevice.stopApp() do not try to close chrome',
    () async {
      final _FakeChromiumDevice chromiumDevice = getFakeChromiumDevice();

      await chromiumDevice.startApp(
        null,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        platformArgs: <String, Object?>{'uri': '/'},
      );

      await chromiumDevice.stopApp(null);
      await chromiumDevice.stopApp(null);
    },
  );

  testWithoutContext('GoogleChromeDevice defaults', () async {
    final launcher = TestChromiumLauncher();

    final chromeDevice = GoogleChromeDevice(
      chromiumLauncher: launcher,
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      platform: FakePlatform(),
      processManager: FakeProcessManager.any(),
    );

    expect(chromeDevice.name, 'Chrome');
    expect(chromeDevice.id, 'chrome');
    expect(chromeDevice.supportsHotReload, true);
    expect(chromeDevice.supportsHotRestart, true);
    expect(chromeDevice.supportsStartPaused, true);
    expect(chromeDevice.supportsFlutterExit, false);
    expect(chromeDevice.supportsScreenshot, false);
    expect(await chromeDevice.isLocalEmulator, false);
    final DeviceLogReader logReader = chromeDevice.getLogReader();
    expect(logReader, isA<WebDeviceLogReader>());
    expect(chromeDevice.getLogReader(), same(logReader));
    expect(await chromeDevice.portForwarder!.forward(1), 1);

    expect(chromeDevice.supportsRuntimeMode(BuildMode.debug), true);
    expect(chromeDevice.supportsRuntimeMode(BuildMode.profile), true);
    expect(chromeDevice.supportsRuntimeMode(BuildMode.release), true);
    expect(chromeDevice.supportsRuntimeMode(BuildMode.jitRelease), false);
  });

  testWithoutContext('MicrosoftEdge defaults', () async {
    final launcher = TestChromiumLauncher();

    final chromeDevice = MicrosoftEdgeDevice(
      chromiumLauncher: launcher,
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
    );

    expect(chromeDevice.name, 'Edge');
    expect(chromeDevice.id, 'edge');
    expect(chromeDevice.supportsHotReload, true);
    expect(chromeDevice.supportsHotRestart, true);
    expect(chromeDevice.supportsStartPaused, true);
    expect(chromeDevice.supportsFlutterExit, false);
    expect(chromeDevice.supportsScreenshot, false);
    expect(await chromeDevice.isLocalEmulator, false);
    final DeviceLogReader logReader = chromeDevice.getLogReader();
    expect(logReader, isA<WebDeviceLogReader>());
    expect(chromeDevice.getLogReader(), same(logReader));
    expect(await chromeDevice.portForwarder!.forward(1), 1);

    expect(chromeDevice.supportsRuntimeMode(BuildMode.debug), true);
    expect(chromeDevice.supportsRuntimeMode(BuildMode.profile), true);
    expect(chromeDevice.supportsRuntimeMode(BuildMode.release), true);
    expect(chromeDevice.supportsRuntimeMode(BuildMode.jitRelease), false);
  });

  testWithoutContext('Server defaults', () async {
    final device = WebServerDevice(logger: BufferLogger.test());

    expect(device.name, 'Web Server');
    expect(device.id, 'web-server');
    expect(device.supportsHotReload, true);
    expect(device.supportsHotRestart, true);
    expect(device.supportsStartPaused, true);
    expect(device.supportsFlutterExit, false);
    expect(device.supportsScreenshot, false);
    expect(await device.isLocalEmulator, false);
    final DeviceLogReader logReader = device.getLogReader();
    expect(logReader, isA<WebDeviceLogReader>());
    expect(device.getLogReader(), same(logReader));
    expect(await device.portForwarder!.forward(1), 1);

    expect(device.supportsRuntimeMode(BuildMode.debug), true);
    expect(device.supportsRuntimeMode(BuildMode.profile), true);
    expect(device.supportsRuntimeMode(BuildMode.release), true);
    expect(device.supportsRuntimeMode(BuildMode.jitRelease), false);
  });

  testWithoutContext('ChromiumDevice accepts null package', () async {
    final fs = MemoryFileSystem.test();
    final platform = FakePlatform();
    final pm = FakeProcessManager.any();
    final logger = BufferLogger.test();
    final device = GoogleChromeDevice(
      fileSystem: fs,
      processManager: pm,
      platform: platform,
      chromiumLauncher: ChromiumLauncher(
        fileSystem: fs,
        platform: platform,
        processManager: pm,
        operatingSystemUtils: FakeOperatingSystemUtils(),
        browserFinder: findChromeExecutable,
        logger: logger,
      ),
      logger: logger,
    );
    await expectLater(
      () => device.startApp(
        null,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        platformArgs: <String, Object?>{'uri': 'localhost:1234'},
      ),
      // The tool exit here is irrelevant, this test simply ensures ChromiumDevice.startApp
      // will accept a null value for a package.
      throwsToolExit(message: 'Failed to launch browser'),
    );
  });

  testWithoutContext('Chrome device is listed when Chrome can be run', () async {
    final WebDevices webDevices = _createWebDevices();

    expect(await webDevices.pollingGetDevices(), contains(isA<GoogleChromeDevice>()));
  });

  testWithoutContext('Has well known device ids chrome, edge, and web-server', () async {
    final WebDevices webDevices = _createWebDevices();

    expect(webDevices.wellKnownIds, <String>['chrome', 'web-server', 'edge']);
  });

  testWithoutContext('Chrome device is not listed when Chrome cannot be run', () async {
    final processManager = FakeProcessManager.empty();
    processManager.excludedExecutables = <String>{kLinuxExecutable};
    final WebDevices webDevices = _createWebDevices(processManager: processManager);

    expect(await webDevices.pollingGetDevices(), isNot(contains(isA<GoogleChromeDevice>())));
  });

  testWithoutContext('Web Server device is listed if enabled via showWebServerDevice', () async {
    WebServerDevice.showWebServerDevice = true;
    final WebDevices webDevices = _createWebDevices();

    expect(await webDevices.pollingGetDevices(), contains(isA<WebServerDevice>()));
  });

  testWithoutContext(
    'Web Server device is not listed if disabled via showWebServerDevice',
    () async {
      WebServerDevice.showWebServerDevice = false;
      final WebDevices webDevices = _createWebDevices();

      expect(await webDevices.pollingGetDevices(), isNot(contains(isA<WebServerDevice>())));
    },
  );

  testWithoutContext('Chrome invokes version command on non-Windows platforms', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[kLinuxExecutable, '--version'], stdout: 'ABC'),
    ]);
    final WebDevices webDevices = _createWebDevices(processManager: processManager);

    final GoogleChromeDevice chromeDevice = (await webDevices.pollingGetDevices())
        .whereType<GoogleChromeDevice>()
        .first;

    expect(await chromeDevice.isSupported(), true);
    expect(await chromeDevice.sdkNameAndVersion, 'ABC');

    // Verify caching works correctly.
    expect(await chromeDevice.sdkNameAndVersion, 'ABC');
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Chrome and Edge version check invokes registry query on windows.', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'reg',
          'query',
          r'HKEY_CURRENT_USER\Software\Microsoft\Edge\BLBeacon',
          '/v',
          'version',
        ],
        stdout: r'HKEY_CURRENT_USER\Software\Microsoft\Edge\BLBeacon\ version REG_SZ 83.0.478.44 ',
      ),
      const FakeCommand(
        command: <String>[
          'reg',
          'query',
          r'HKEY_CURRENT_USER\Software\Google\Chrome\BLBeacon',
          '/v',
          'version',
        ],
        stdout: r'HKEY_CURRENT_USER\Software\Google\Chrome\BLBeacon\ version REG_SZ 74.0.0 A',
      ),
    ]);
    final WebDevices webDevices = _createWebDevices(
      platform: FakePlatform(operatingSystem: 'windows', environment: <String, String>{}),
      processManager: processManager,
    );

    final GoogleChromeDevice chromeDevice = (await webDevices.pollingGetDevices())
        .whereType<GoogleChromeDevice>()
        .first;

    expect(await chromeDevice.isSupported(), true);
    expect(await chromeDevice.sdkNameAndVersion, 'Google Chrome 74.0.0');

    // Verify caching works correctly.
    expect(await chromeDevice.sdkNameAndVersion, 'Google Chrome 74.0.0');
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Chrome and Edge version check handles missing registry on Windows', () async {
    final processManager = FakeProcessManager.empty();
    processManager.excludedExecutables.add('reg');

    final Platform platform = FakePlatform(
      operatingSystem: 'windows',
      environment: <String, String>{},
    );
    final chromeLauncher = ChromiumLauncher(
      fileSystem: MemoryFileSystem.test(),
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: FakeOperatingSystemUtils(),
      browserFinder: findChromeExecutable,
      logger: BufferLogger.test(),
    );
    final edgeDevice = MicrosoftEdgeDevice(
      chromiumLauncher: chromeLauncher,
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      processManager: processManager,
    );

    expect(await edgeDevice.isSupported(), true);
    expect(await edgeDevice.sdkNameAndVersion, '');

    final chromeDevice = GoogleChromeDevice(
      chromiumLauncher: chromeLauncher,
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      processManager: processManager,
      platform: platform,
    );

    expect(await chromeDevice.isSupported(), true);
    expect(await chromeDevice.sdkNameAndVersion, 'unknown');
  });

  testWithoutContext('Edge is not supported on versions less than 73', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'reg',
          'query',
          r'HKEY_CURRENT_USER\Software\Microsoft\Edge\BLBeacon',
          '/v',
          'version',
        ],
        stdout: r'HKEY_CURRENT_USER\Software\Microsoft\Edge\BLBeacon\ version REG_SZ 72.0.478.44 ',
      ),
    ]);
    final WebDevices webDevices = _createWebDevices(
      platform: FakePlatform(operatingSystem: 'windows', environment: <String, String>{}),
      processManager: processManager,
    );

    expect((await webDevices.pollingGetDevices()).whereType<MicrosoftEdgeDevice>(), isEmpty);
  });

  testWithoutContext('Edge is not support on non-windows platform', () async {
    final WebDevices webDevices = _createWebDevices(processManager: FakeProcessManager.empty());

    expect((await webDevices.pollingGetDevices()).whereType<MicrosoftEdgeDevice>(), isEmpty);

    final WebDevices macosWebDevices = _createWebDevices(
      platform: FakePlatform(operatingSystem: 'macos', environment: <String, String>{}),
      processManager: FakeProcessManager.empty(),
    );

    expect((await macosWebDevices.pollingGetDevices()).whereType<MicrosoftEdgeDevice>(), isEmpty);
  });

  @isTest
  void testWebLaunchUrl(String description, {required String url, required Matcher matcher}) {
    // ignore: unnecessary_parenthesis – Prevent IDEs from showing a run button.
    (testWithoutContext)(description, () async {
      final _FakeChromiumDevice chromiumDevice = getFakeChromiumDevice();

      await expectLater(
        () => chromiumDevice.startApp(
          null,
          debuggingOptions: DebuggingOptions.enabled(
            BuildInfo.debug,
            platformOptions: <PlatformDebuggingOptions>[WebDebugConfig(launchUrl: url)],
          ),
          platformArgs: <String, Object?>{'uri': url},
        ),
        matcher,
      );
    });
  }

  testWebLaunchUrl(
    'HTTP web launch url is not invalid',
    url: 'http://localhost:3000',
    matcher: returnsNormally,
  );

  testWebLaunchUrl(
    'HTTPS web launch url is not invalid',
    url: 'https://localhost:3000',
    matcher: returnsNormally,
  );

  testWebLaunchUrl(
    'Non-HTTP web launch url scheme is invalid',
    url: 'file://path',
    matcher: throwsToolExit(message: '"file://path" is not a valid HTTP URL.'),
  );

  group('WebDeviceLogReader', () {
    testWithoutContext(
      'provideVmService streams Stdout and Stderr preserving whitespace and cleans up on dispose',
      () async {
        final stdoutController = StreamController<vm_service.Event>.broadcast();
        final stderrController = StreamController<vm_service.Event>.broadcast();
        final listenedStreams = <String>[];
        final vmService = _FakeVmService(
          onStdoutEvent: stdoutController.stream,
          onStderrEvent: stderrController.stream,
          onStreamListen: (String streamId) {
            listenedStreams.add(streamId);
            if (streamId == vm_service.EventStreams.kStderr) {
              // Verify RPCError when already subscribed is ignored.
              throw vm_service.RPCError('streamListen', 103, 'Stream already subscribed');
            }
          },
        );
        final flutterVmService = _FakeFlutterVmService(vmService);

        final logReader = WebDeviceLogReader('test-app');
        expect(logReader.name, 'test-app');

        final received = <String>[];
        var streamClosed = false;
        logReader.logLines.listen(received.add, onDone: () => streamClosed = true);

        await logReader.provideVmService(flutterVmService);
        expect(listenedStreams, <String>[
          vm_service.EventStreams.kStdout,
          vm_service.EventStreams.kStderr,
        ]);

        stdoutController.add(
          vm_service.Event(bytes: base64.encode(utf8.encode('  leading and trailing  \n'))),
        );
        stderrController.add(
          vm_service.Event(bytes: base64.encode(utf8.encode('\terror output \t'))),
        );
        await pumpEventQueue();

        expect(received, <String>['  leading and trailing  ', '\terror output \t']);

        await logReader.dispose();
        expect(streamClosed, isTrue);
        expect(stdoutController.hasListener, isFalse);
        expect(stderrController.hasListener, isFalse);

        // Emitting after dispose does not throw or deliver messages.
        stdoutController.add(vm_service.Event(bytes: base64.encode(utf8.encode('after dispose'))));
        await pumpEventQueue();
        expect(received, hasLength(2));

        await stdoutController.close();
        await stderrController.close();
      },
    );
  });

  group('WebDevice.createFlutterDevice', () {
    // Uses testUsingContext because FlutterDevice.createCompilers reads the
    // ambient residentCompilerFactory.
    testUsingContext('falls back to default FlutterDevice when builder is null', () async {
      final toolContext = FakeToolContext(
        artifacts: Artifacts.test(),
        processManager: FakeProcessManager.any(),
      );
      final device = WebServerDevice(logger: BufferLogger.test());

      final FlutterDevice flutterDevice = await device.createFlutterDevice(
        buildInfo: BuildInfo.debug,
        toolContext: toolContext,
      );

      expect(flutterDevice.device, same(device));
      expect(flutterDevice.targetPlatform, TargetPlatform.web_javascript);
      expect(flutterDevice.generator, isNotNull);
    });

    testWithoutContext(
      'throws StateError when builder is provided without flutterProject',
      () async {
        final toolContext = FakeToolContext(
          artifacts: Artifacts.test(),
          processManager: FakeProcessManager.any(),
        );
        final device = WebServerDevice(
          logger: BufferLogger.test(),
          webFlutterDeviceBuilder: (
            Device device, {
            required BuildInfo buildInfo,
            required DevelopmentShaderCompiler developmentShaderCompiler,
            required FlutterProject flutterProject,
            required ResidentCompiler? generator,
            required TargetPlatform targetPlatform,
            required ToolContext toolContext,
            Map<String, Object?> platformArgs = const <String, Object?>{},
            UrlTunneller? urlTunneller,
            String? userIdentifier,
            WebDebugConfig webConfig = const WebDebugConfig(),
          }) => throw AssertionError('Should not be called'),
        );

        await expectLater(
          () => device.createFlutterDevice(buildInfo: BuildInfo.debug, toolContext: toolContext),
          throwsA(
            isA<StateError>().having(
              (StateError error) => error.message,
              'message',
              'flutterProject is required when webFlutterDeviceBuilder is provided.',
            ),
          ),
        );
      },
    );

    // Uses testUsingContext because FlutterDevice.createCompilers reads the
    // ambient residentCompilerFactory.
    testUsingContext('invokes builder with generator and urlTunneller gated by buildMode, useWasm, and enableExposeUrl', () async {
      final toolContext = FakeToolContext(
        artifacts: Artifacts.test(),
        processManager: FakeProcessManager.any(),
      );
      final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(
        toolContext.fs.currentDirectory,
      );
      Future<String> fakeTunneller(String url) async => url;

      ResidentCompiler? capturedGenerator;
      UrlTunneller? capturedTunneller;
      WebDebugConfig? capturedWebConfig;
      final device = WebServerDevice(
        logger: BufferLogger.test(),
        webFlutterDeviceBuilder:
            (
              Device device, {
              required BuildInfo buildInfo,
              required DevelopmentShaderCompiler developmentShaderCompiler,
              required FlutterProject flutterProject,
              required ResidentCompiler? generator,
              required TargetPlatform targetPlatform,
              required ToolContext toolContext,
              Map<String, Object?> platformArgs = const <String, Object?>{},
              UrlTunneller? urlTunneller,
              String? userIdentifier,
              WebDebugConfig webConfig = const WebDebugConfig(),
            }) {
              capturedGenerator = generator;
              capturedTunneller = urlTunneller;
              capturedWebConfig = webConfig;
              return FlutterDevice(
                device,
                buildInfo: buildInfo,
                developmentShaderCompiler: developmentShaderCompiler,
                generator: generator,
                targetPlatform: targetPlatform,
                toolContext: toolContext,
                userIdentifier: userIdentifier,
              );
            },
      );

      // Debug JS with enableExposeUrl: true -> generator created and urlTunneller forwarded.
      await device.createFlutterDevice(
        buildInfo: BuildInfo.debug,
        debuggingOptions: DebuggingOptions.enabled(
          BuildInfo.debug,
          platformOptions: const <PlatformDebuggingOptions>[WebDebugConfig(enableExposeUrl: true)],
        ),
        flutterProject: flutterProject,
        toolContext: toolContext,
        urlTunneller: fakeTunneller,
      );
      expect(capturedGenerator, isNotNull);
      expect(capturedTunneller, same(fakeTunneller));
      expect(capturedWebConfig?.enableExposeUrl, isTrue);

      // Debug Wasm with enableExposeUrl: false -> no generator and urlTunneller withheld.
      await device.createFlutterDevice(
        buildInfo: BuildInfo.debug,
        debuggingOptions: DebuggingOptions.enabled(
          BuildInfo.debug,
          platformOptions: const <PlatformDebuggingOptions>[WebDebugConfig(useWasm: true)],
        ),
        flutterProject: flutterProject,
        toolContext: toolContext,
        urlTunneller: fakeTunneller,
      );
      expect(capturedGenerator, isNull);
      expect(capturedTunneller, isNull);
      expect(capturedWebConfig?.useWasm, isTrue);
    });
  });
}

/// A test implementation of the [ChromiumLauncher] that launches a fixed instance.
class TestChromiumLauncher implements ChromiumLauncher {
  TestChromiumLauncher({Chromium Function()? launcher}) {
    _launcher = launcher ?? () => _UnimplementedChromium();
  }

  late Chromium Function() _launcher;

  @override
  Completer<Chromium> currentCompleter = Completer<Chromium>();

  @override
  bool canFindExecutable() {
    return true;
  }

  @override
  Future<Chromium> get connectedInstance => currentCompleter.future;

  @override
  String findExecutable() {
    return 'chrome';
  }

  @override
  bool get hasChromeInstance => false;

  @override
  Future<Chromium> launch(
    String url, {
    bool headless = false,
    int? debugPort,
    bool skipCheck = false,
    Directory? cacheDir,
    List<String> webBrowserFlags = const <String>[],
  }) async {
    currentCompleter.complete(_launcher());
    return currentCompleter.future;
  }

  @override
  Future<Chromium> connect(Chromium chrome, bool skipCheck) {
    return currentCompleter.future;
  }
}

class _FakeChromiumDevice extends ChromiumDevice {
  _FakeChromiumDevice({
    required ChromiumLauncher chromiumLauncher,
    required super.fileSystem,
    required super.logger,
  }) : super(name: 'fake name', chromeLauncher: chromiumLauncher);

  @override
  Future<String> get sdkNameAndVersion async => 'fake sdkNameAndVersion';

  @override
  String get name => 'fake name';
}

class _OnceClosableChromium extends Fake implements Chromium {
  var _closed = false;

  @override
  Future<void> close() async {
    if (_closed) {
      throw Exception('Already closed');
    }
    _closed = true;
  }
}

class _UnimplementedChromium extends Fake implements Chromium {}

class _FakeFlutterVmService extends Fake implements FlutterVmService {
  _FakeFlutterVmService(this.service);

  @override
  final vm_service.VmService service;
}

class _FakeVmService extends Fake implements vm_service.VmService {
  _FakeVmService({
    required this.onStdoutEvent,
    required this.onStderrEvent,
    required this._onStreamListen,
  });

  final void Function(String streamId) _onStreamListen;

  @override
  final Stream<vm_service.Event> onStdoutEvent;

  @override
  final Stream<vm_service.Event> onStderrEvent;

  @override
  Future<vm_service.Success> streamListen(String streamId) async {
    _onStreamListen(streamId);
    return vm_service.Success();
  }
}
