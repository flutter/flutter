// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/tools/shader_compiler.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/drive/drive_service.dart';
import 'package:flutter_tools/src/drive/web_driver_service.dart';
import 'package:flutter_tools/src/flutter_application_package.dart';
import 'package:flutter_tools/src/isolated/build_targets.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_cold.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/devfs_config.dart';
import 'package:flutter_tools/src/web/web_debug_config.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:flutter_tools/src/web/web_flutter_device.dart';
import 'package:package_config/package_config.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:webdriver/sync_io.dart' as sync_io;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';

final kChromeArgs = <String>[
  '--bwsi',
  '--disable-background-timer-throttling',
  '--disable-renderer-backgrounding',
  '--disable-background-networking',
  '--disable-sync',
  '--disable-client-side-phishing-detection',
  '--disable-notifications',
  ...kGcmDisabledFlags,
  '--disable-default-apps',
  '--disable-extensions',
  '--disable-popup-blocking',
  '--disable-translate',
  '--no-default-browser-check',
  '--no-sandbox',
  '--no-first-run',
  '--password-store=basic',
  if (io.Platform.isMacOS) '--use-mock-keychain',
  '--disable-search-engine-choice-screen',
];

void main() {
  late FakeWebFlutterDeviceFactory fakeWebFlutterDeviceFactory;

  testWithoutContext('getDesiredCapabilities Chrome with headless on', () {
    final expected = <String, dynamic>{
      'acceptInsecureCerts': true,
      'browserName': 'chrome',
      'goog:loggingPrefs': <String, String>{
        sync_io.LogType.browser: 'INFO',
        sync_io.LogType.performance: 'ALL',
      },
      'goog:chromeOptions': <String, dynamic>{
        'w3c': true,
        'args': <String>[
          ...kChromeArgs,
          '--headless',
          if (io.Platform.isLinux) ...<String>[
            '--use-gl=angle',
            '--use-angle=swiftshader',
            '--enable-unsafe-swiftshader',
            '--disable-gpu-sandbox',
          ],
        ],
        'perfLoggingPrefs': <String, String>{
          'traceCategories':
              'devtools.timeline,'
              'v8,blink.console,benchmark,blink,'
              'blink.user_timing',
        },
      },
    };

    expect(getDesiredCapabilities(Browser.chrome, true, platform: const LocalPlatform()), expected);
  });

  testWithoutContext('getDesiredCapabilities Chrome with headless off', () {
    const chromeBinary = 'random-binary';
    final expected = <String, dynamic>{
      'acceptInsecureCerts': true,
      'browserName': 'chrome',
      'goog:loggingPrefs': <String, String>{
        sync_io.LogType.browser: 'INFO',
        sync_io.LogType.performance: 'ALL',
      },
      'goog:chromeOptions': <String, dynamic>{
        'binary': chromeBinary,
        'w3c': true,
        'args': kChromeArgs,
        'perfLoggingPrefs': <String, String>{
          'traceCategories':
              'devtools.timeline,'
              'v8,blink.console,benchmark,blink,'
              'blink.user_timing',
        },
      },
    };

    expect(
      getDesiredCapabilities(
        Browser.chrome,
        false,
        platform: const LocalPlatform(),
        chromeBinary: chromeBinary,
      ),
      expected,
    );
  });

  testWithoutContext('getDesiredCapabilities Chrome with browser flags', () {
    const webBrowserFlags = <String>[
      '--autoplay-policy=no-user-gesture-required',
      '--incognito',
      '--auto-select-desktop-capture-source="Entire screen"',
    ];
    final expected = <String, dynamic>{
      'acceptInsecureCerts': true,
      'browserName': 'chrome',
      'goog:loggingPrefs': <String, String>{
        sync_io.LogType.browser: 'INFO',
        sync_io.LogType.performance: 'ALL',
      },
      'goog:chromeOptions': <String, dynamic>{
        'w3c': true,
        'args': <String>[
          ...kChromeArgs,
          '--autoplay-policy=no-user-gesture-required',
          '--incognito',
          '--auto-select-desktop-capture-source="Entire screen"',
        ],
        'perfLoggingPrefs': <String, String>{
          'traceCategories':
              'devtools.timeline,'
              'v8,blink.console,benchmark,blink,'
              'blink.user_timing',
        },
      },
    };

    expect(
      getDesiredCapabilities(
        Browser.chrome,
        false,
        platform: const LocalPlatform(),
        webBrowserFlags: webBrowserFlags,
      ),
      expected,
    );
  });

  testWithoutContext('getDesiredCapabilities Firefox with headless on', () {
    final expected = <String, dynamic>{
      'acceptInsecureCerts': true,
      'browserName': 'firefox',
      'moz:firefoxOptions': <String, dynamic>{
        'args': <String>['-headless'],
        'prefs': <String, dynamic>{
          'dom.file.createInChild': true,
          'dom.timeout.background_throttling_max_budget': -1,
          'media.autoplay.default': 0,
          'media.gmp-manager.url': '',
          'media.gmp-provider.enabled': false,
          'network.captive-portal-service.enabled': false,
          'security.insecure_field_warning.contextual.enabled': false,
          'test.currentTimeOffsetSeconds': 11491200,
        },
        'log': <String, String>{'level': 'trace'},
      },
    };

    expect(
      getDesiredCapabilities(Browser.firefox, true, platform: const LocalPlatform()),
      expected,
    );
  });

  testWithoutContext('getDesiredCapabilities Firefox with headless off', () {
    final expected = <String, dynamic>{
      'acceptInsecureCerts': true,
      'browserName': 'firefox',
      'moz:firefoxOptions': <String, dynamic>{
        'args': <String>[],
        'prefs': <String, dynamic>{
          'dom.file.createInChild': true,
          'dom.timeout.background_throttling_max_budget': -1,
          'media.autoplay.default': 0,
          'media.gmp-manager.url': '',
          'media.gmp-provider.enabled': false,
          'network.captive-portal-service.enabled': false,
          'security.insecure_field_warning.contextual.enabled': false,
          'test.currentTimeOffsetSeconds': 11491200,
        },
        'log': <String, String>{'level': 'trace'},
      },
    };

    expect(
      getDesiredCapabilities(Browser.firefox, false, platform: const LocalPlatform()),
      expected,
    );
  });

  testWithoutContext('getDesiredCapabilities Firefox with browser flags', () {
    const webBrowserFlags = <String>['-url=https://example.com', '-private'];
    final expected = <String, dynamic>{
      'acceptInsecureCerts': true,
      'browserName': 'firefox',
      'moz:firefoxOptions': <String, dynamic>{
        'args': <String>['-url=https://example.com', '-private'],
        'prefs': <String, dynamic>{
          'dom.file.createInChild': true,
          'dom.timeout.background_throttling_max_budget': -1,
          'media.autoplay.default': 0,
          'media.gmp-manager.url': '',
          'media.gmp-provider.enabled': false,
          'network.captive-portal-service.enabled': false,
          'security.insecure_field_warning.contextual.enabled': false,
          'test.currentTimeOffsetSeconds': 11491200,
        },
        'log': <String, String>{'level': 'trace'},
      },
    };

    expect(
      getDesiredCapabilities(
        Browser.firefox,
        false,
        platform: const LocalPlatform(),
        webBrowserFlags: webBrowserFlags,
      ),
      expected,
    );
  });

  testWithoutContext('getDesiredCapabilities Edge', () {
    final expected = <String, dynamic>{'acceptInsecureCerts': true, 'browserName': 'edge'};

    expect(getDesiredCapabilities(Browser.edge, false, platform: const LocalPlatform()), expected);
  });

  testWithoutContext('getDesiredCapabilities macOS Safari', () {
    final expected = <String, dynamic>{'browserName': 'safari'};

    expect(
      getDesiredCapabilities(Browser.safari, false, platform: const LocalPlatform()),
      expected,
    );
  });

  testWithoutContext('getDesiredCapabilities iOS Safari', () {
    final expected = <String, dynamic>{
      'platformName': 'ios',
      'browserName': 'safari',
      'safari:useSimulator': true,
    };

    expect(
      getDesiredCapabilities(Browser.iosSafari, false, platform: const LocalPlatform()),
      expected,
    );
  });

  testWithoutContext('getDesiredCapabilities android chrome', () {
    const webBrowserFlags = <String>['--autoplay-policy=no-user-gesture-required', '--incognito'];
    final expected = <String, dynamic>{
      'browserName': 'chrome',
      'platformName': 'android',
      'goog:chromeOptions': <String, dynamic>{
        'androidPackage': 'com.android.chrome',
        'args': <String>[
          '--disable-fullscreen',
          '--autoplay-policy=no-user-gesture-required',
          '--incognito',
        ],
      },
    };

    expect(
      getDesiredCapabilities(
        Browser.androidChrome,
        false,
        platform: const LocalPlatform(),
        webBrowserFlags: webBrowserFlags,
      ),
      expected,
    );
  });

  // Uses testUsingContext because WebDevice.createFlutterDevice reads the
  // context-scoped ResidentCompilerFactory when constructing a debug non-wasm generator.
  testUsingContext('WebDriverService starts and stops a debug hot app', () async {
    fakeWebFlutterDeviceFactory = FakeWebFlutterDeviceFactory();
    final WebDriverService service = setUpDriverService();
    final device = WebServerDevice(
      logger: BufferLogger.test(),
      webFlutterDeviceFactory: fakeWebFlutterDeviceFactory,
    );
    await service.start(
      BuildInfo.debug,
      device,
      DebuggingOptions.enabled(BuildInfo.debug, ipv6: true),
    );
    await service.stop();
    expect(fakeWebFlutterDeviceFactory.lastDevice!.callLog, <String>[
      'runHot',
      'attachDeferredConnection',
      'exitApps',
      'dispose',
      'destroyDevFS',
    ]);
  });

  testWithoutContext('WebDriverService starts and stops a cold app', () async {
    fakeWebFlutterDeviceFactory = FakeWebFlutterDeviceFactory();
    final WebDriverService service = setUpDriverService();
    final device = WebServerDevice(
      logger: BufferLogger.test(),
      webFlutterDeviceFactory: fakeWebFlutterDeviceFactory,
    );
    await service.start(
      BuildInfo.profile,
      device,
      DebuggingOptions.enabled(BuildInfo.profile, ipv6: true),
    );
    await service.stop();
    expect(fakeWebFlutterDeviceFactory.lastDevice!.callLog, <String>[
      'runCold',
      'exitApps',
      'dispose',
      'destroyDevFS',
    ]);
  });

  testWithoutContext(
    'WebDriverService forwards platform args to WebFlutterDeviceFactory',
    () async {
      fakeWebFlutterDeviceFactory = FakeWebFlutterDeviceFactory();
      final WebDriverService service = setUpDriverService();
      final device = WebServerDevice(
        logger: BufferLogger.test(),
        webFlutterDeviceFactory: fakeWebFlutterDeviceFactory,
      );
      await service.start(
        BuildInfo.profile,
        device,
        DebuggingOptions.enabled(BuildInfo.profile, ipv6: true),
        platformArgs: <String, Object>{'no-launch-chrome': true},
      );
      await service.stop();
      expect(fakeWebFlutterDeviceFactory.lastPlatformArgs, <String, Object?>{
        'no-launch-chrome': true,
      });
    },
  );

  testWithoutContext('WebDriverService forwards web-defines to WebFlutterDeviceFactory', () async {
    fakeWebFlutterDeviceFactory = FakeWebFlutterDeviceFactory();
    final WebDriverService service = setUpDriverService();
    final device = WebServerDevice(
      logger: BufferLogger.test(),
      webFlutterDeviceFactory: fakeWebFlutterDeviceFactory,
    );
    await service.start(
      BuildInfo.profile,
      device,
      DebuggingOptions.enabled(
        BuildInfo.profile,
        platformOptions: const <PlatformDebuggingOptions>[
          WebDebugConfig(webDefines: <String, String>{'VERSION': 'v1.2.3'}),
        ],
        ipv6: true,
      ),
    );
    await service.stop();
    expect(fakeWebFlutterDeviceFactory.lastWebDefines, <String, String>{'VERSION': 'v1.2.3'});
  });

  testWithoutContext('WebDriverService can start an app with a launch url provided', () async {
    fakeWebFlutterDeviceFactory = FakeWebFlutterDeviceFactory();
    final WebDriverService service = setUpDriverService();
    final device = WebServerDevice(
      logger: BufferLogger.test(),
      webFlutterDeviceFactory: fakeWebFlutterDeviceFactory,
    );
    const testUrl = 'http://localhost:1234/test';
    await service.start(
      BuildInfo.profile,
      device,
      DebuggingOptions.enabled(
        BuildInfo.profile,
        platformOptions: const <PlatformDebuggingOptions>[WebDebugConfig(launchUrl: testUrl)],
        ipv6: true,
      ),
    );
    await service.stop();
    expect(service.webUri, Uri.parse(testUrl));
  });

  testWithoutContext('WebDriverService starts an app with provided web headers', () async {
    fakeWebFlutterDeviceFactory = FakeWebFlutterDeviceFactory();
    final WebDriverService service = setUpDriverService();
    final device = WebServerDevice(
      logger: BufferLogger.test(),
      webFlutterDeviceFactory: fakeWebFlutterDeviceFactory,
    );
    final webHeaders = <String, String>{'test-header': 'test-value'};
    final webDevServerConfig = WebDevServerConfig(headers: webHeaders);
    await service.start(
      BuildInfo.profile,
      device,
      DebuggingOptions.enabled(
        BuildInfo.profile,
        platformOptions: <PlatformDebuggingOptions>[
          WebDebugConfig(devServerConfig: webDevServerConfig),
        ],
        ipv6: true,
      ),
    );
    await service.stop();
    expect(
      fakeWebFlutterDeviceFactory
          .lastDevice!
          .lastDebuggingOptions
          ?.webConfig
          .devServerConfig
          ?.headers,
      equals(webHeaders),
    );
  });

  testWithoutContext(
    'WebDriverService will throw when an invalid launch url is provided',
    () async {
      fakeWebFlutterDeviceFactory = FakeWebFlutterDeviceFactory();
      final WebDriverService service = setUpDriverService();
      final device = WebServerDevice(
        logger: BufferLogger.test(),
        webFlutterDeviceFactory: fakeWebFlutterDeviceFactory,
      );
      const invalidTestUrl = '::INVALID_URL::';
      await expectLater(
        service.start(
          BuildInfo.profile,
          device,
          DebuggingOptions.enabled(
            BuildInfo.profile,
            platformOptions: const <PlatformDebuggingOptions>[
              WebDebugConfig(launchUrl: invalidTestUrl),
            ],
            ipv6: true,
          ),
        ),
        throwsA(isA<FormatException>()),
      );
      await service.stop();
    },
  );

  testWithoutContext(
    'WebDriverService forwards exception when run future fails before app starts',
    () async {
      final WebDriverService service = setUpDriverService();
      final Device device = WebServerDevice(
        logger: BufferLogger.test(),
        webFlutterDeviceFactory: FakeWebFlutterDeviceFactory(doResolveToError: true),
      );
      await expectLater(
        service.start(
          BuildInfo.profile,
          device,
          DebuggingOptions.enabled(BuildInfo.profile, ipv6: true),
        ),
        throwsA('This is a test error'),
      );
    },
  );

  testWithoutContext(
    'WebDriverService exits the tool when the WebDriver server cannot create a session',
    () async {
      // A fake WebDriver server that rejects every session request, the way
      // chromedriver does when it cannot launch the browser.
      final io.HttpServer driverServer = await io.HttpServer.bind(
        io.InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(() => driverServer.close(force: true));
      driverServer.listen((io.HttpRequest request) {
        request.response
          ..statusCode = io.HttpStatus.internalServerError
          ..headers.contentType = io.ContentType.json
          ..write(
            json.encode(<String, Object?>{
              'value': <String, Object?>{
                'error': 'session not created',
                'message': "session not created: DevToolsActivePort file doesn't exist",
                'stacktrace': '',
              },
            }),
          );
        unawaited(request.response.close());
      });

      final toolContext = FakeToolContext();
      final ToolContext(:FileSystem fs, :Logger logger, :Platform platform) = toolContext;
      final service = WebDriverService(
        analytics: const NoOpAnalytics(),
        applicationPackageFactory: FlutterApplicationPackageFactory(
          androidSdkBuilder: () => null,
          plistParserBuilder: FakePlistParser.new,
          templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
          toolContext: toolContext,
        ),
        assetBundleFactory: AssetBundleFactory.defaultInstance(
          fileSystem: fs,
          flutterRoot: '',
          logger: logger,
          platform: platform,
        ),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        buildTargets: const BuildTargetsImpl(),
        dartSdkPath: 'dart',
        featureFlags: TestFeatureFlags(isWebEnabled: true),
        toolContext: toolContext,
      );
      await expectLater(
        service.startTest(
          'test_driver/app_test.dart',
          DriveTestSpecification(
            packageConfig: PackageConfig.empty,
            browserName: 'chrome',
            headless: true,
            driverPort: driverServer.port,
          ),
        ),
        throwsToolExit(message: "DevToolsActivePort file doesn't exist"),
      );
    },
  );
}

class FakeWebFlutterDeviceFactory implements WebFlutterDeviceFactory {
  FakeWebFlutterDeviceFactory({this.doResolveToError = false});

  final bool doResolveToError;
  Map<String, Object?>? lastPlatformArgs;
  Map<String, String>? lastWebDefines;
  FakeColdWebFlutterDevice? lastDevice;

  @override
  FlutterDevice createWebFlutterDevice(
    Device device, {
    required BuildInfo buildInfo,
    required DevelopmentShaderCompiler developmentShaderCompiler,
    required FlutterProject flutterProject,
    required ResidentCompiler? generator,
    required TargetPlatform targetPlatform,
    required ToolContext toolContext,
    Map<String, Object?> platformArgs = const <String, Object?>{},
    String? userIdentifier,
    WebDebugConfig webConfig = const WebDebugConfig(),
  }) {
    lastPlatformArgs = platformArgs;
    lastWebDefines = webConfig.webDefines;
    return lastDevice = FakeColdWebFlutterDevice(
      device,
      buildInfo: buildInfo,
      doResolveToError: doResolveToError,
      useWasm: webConfig.useWasm,
    );
  }
}

class FakeDriverDevFS extends Fake implements DevFS {
  FakeDriverDevFS(this._callLog);

  final List<String> _callLog;

  @override
  Uri get baseUri => Uri.parse('http://localhost:8080/');

  @override
  Future<void> destroy() async {
    if (!_callLog.contains('destroyDevFS')) {
      _callLog.add('destroyDevFS');
    }
  }
}

class FakeColdWebFlutterDevice extends Fake implements FlutterDevice {
  FakeColdWebFlutterDevice(
    this.device, {
    required this.buildInfo,
    required this.doResolveToError,
    this._useWasm = false,
  }) {
    devFS = FakeDriverDevFS(callLog);
  }

  @override
  final Device device;

  @override
  final BuildInfo buildInfo;

  final bool _useWasm;
  final bool doResolveToError;
  final callLog = <String>[];
  DebuggingOptions? lastDebuggingOptions;

  @override
  DevFS? devFS;

  @override
  Future<Uri>? get vmServiceUri => null;

  @override
  FlutterVmService? get vmService => null;

  @override
  TargetPlatform get targetPlatform => TargetPlatform.web_javascript;

  @override
  bool get defersServiceProtocolConnection => true;

  @override
  bool get supportsColdRestart => true;

  @override
  bool get supportsDebugRuntime => !_useWasm;

  @override
  bool get supportsProfileServiceProtocol => false;

  @override
  bool get usesSharedDartPluginRegistry => false;

  @override
  bool usesHotRunner({required bool hotMode}) => buildInfo.isDebug && !_useWasm;

  @override
  Future<int> runHot({required HotRunner hotRunner, String? route}) async {
    expect(hotRunner.stayResident, isTrue);
    callLog.add('runHot');
    lastDebuggingOptions = hotRunner.debuggingOptions;
    if (doResolveToError) {
      return Future<int>.error('This is a test error');
    }
    return 0;
  }

  @override
  void attachDeferredConnection({
    required HotRunner hotRunner,
    Completer<DebugConnectionInfo>? connectionInfoCompleter,
  }) {
    callLog.add('attachDeferredConnection');
    connectionInfoCompleter?.complete(
      DebugConnectionInfo(wsUri: Uri.parse('ws://localhost:8080/ws')),
    );
  }

  @override
  Future<int> runCold({required ColdRunner coldRunner, String? route}) async {
    expect(coldRunner.stayResident, isTrue);
    callLog.add('runCold');
    lastDebuggingOptions = coldRunner.debuggingOptions;
    if (doResolveToError) {
      return Future<int>.error('This is a test error');
    }
    return 0;
  }

  @override
  Future<void> exitApps({Duration timeoutDelay = const Duration(seconds: 10)}) async {
    if (!callLog.contains('exitApps')) {
      callLog.add('exitApps');
    }
  }

  @override
  Future<void> dispose() async {
    if (!callLog.contains('dispose')) {
      callLog.add('dispose');
    }
  }

  @override
  Future<void> stopEchoingDeviceLog() async {}
}

WebDriverService setUpDriverService() {
  final toolContext = FakeToolContext();
  final ToolContext(:FileSystem fs, :Logger logger, :Platform platform) = toolContext;
  return WebDriverService(
    analytics: const NoOpAnalytics(),
    applicationPackageFactory: FlutterApplicationPackageFactory(
      androidSdkBuilder: () => null,
      plistParserBuilder: FakePlistParser.new,
      templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
      toolContext: toolContext,
    ),
    assetBundleFactory: AssetBundleFactory.defaultInstance(
      fileSystem: fs,
      flutterRoot: '',
      logger: logger,
      platform: platform,
    ),
    buildSystem: TestBuildSystem.all(BuildResult(success: true)),
    buildTargets: const BuildTargetsImpl(),
    dartSdkPath: 'dart',
    featureFlags: TestFeatureFlags(isWebEnabled: true),
    toolContext: toolContext,
  );
}
