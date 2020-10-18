// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:webdriver/async_io.dart' as async_io;

import '../application_package.dart';
import '../base/common.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../convert.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../resident_runner.dart';
import '../web/web_device.dart';
import '../web/web_runner.dart';
import 'drive_service.dart';

/// An implementation of the driver service for web debug and release applications.
class WebDriverService extends DriverService {
  WebDriverService({
    @required ApplicationPackageFactory applicationPackageFactory,
    @required ProcessUtils processUtils,
    @required String dartSdkPath,
  }) : _applicationPackageFactory = applicationPackageFactory,
       _processUtils = processUtils,
       _dartSdkPath = dartSdkPath;

  final ApplicationPackageFactory _applicationPackageFactory;
  final ProcessUtils _processUtils;
  final String _dartSdkPath;

  ResidentRunner _residentRunner;
  WebDriverDevice _webDriverDevice;
  Uri _vmServiecUri;
  ApplicationPackage _applicationPackage;

  @override
  Future<void> start(
    BuildInfo buildInfo,
    Device device,
    DebuggingOptions debuggingOptions,
    bool ipv6, {
    File applicationBinary,
    String route,
    String userIdentifier,
    String mainPath,
    Map<String, Object> platformArgs = const <String, Object>{},
  }) async {
    _applicationPackage = await _applicationPackageFactory.getPackageForPlatform(
      TargetPlatform.web_javascript,
      buildInfo: buildInfo,
      applicationBinary: applicationBinary,
    ) as WebApplicationPackage;
    if (device is WebDriverDevice) {
      _webDriverDevice = device;
    } else {
      throwToolExit('Expected a web driver device, but found $device');
    }
    final FlutterDevice flutterDevice = await FlutterDevice.create(
      device,
      target: mainPath,
      buildInfo: buildInfo,
      platform: globals.platform,
    );
    _residentRunner = webRunnerFactory.createWebRunner(
      flutterDevice,
      target: mainPath,
      ipv6: ipv6,
      debuggingOptions: debuggingOptions,
      stayResident: true,
      urlTunneller: null,
      flutterProject: FlutterProject.current(),
    );
    final Completer<void> appStartedCompleter = Completer<void>.sync();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    final int result = await _residentRunner.run(
      appStartedCompleter: appStartedCompleter,
      connectionInfoCompleter: connectionInfoCompleter,
      route: route,
    );
    if (result == 0 && buildInfo.isDebug) {
      final DebugConnectionInfo connectionInfo = await connectionInfoCompleter.future;
      _vmServiecUri = connectionInfo.httpUri;
    }
  }

  @override
  Future<int> startTest(String testFile, List<String> arguments, Map<String, String> environment) async {
    return _processUtils.stream(<String>[
      _dartSdkPath,
      ...arguments,
      testFile,
      '-rexpanded',
    ], environment: <String, String>{
      if (_vmServiecUri != null)
        'VM_SERVICE_URL': _vmServiecUri.toString(),
      ..._webDriverDevice._additionalDriverEnvironment(),
      ...environment,
    });
  }

  @override
  Future<void> stop({File writeSkslOnExit, String userIdentifier}) async {
    await _webDriverDevice.stopApp(_applicationPackage);
  }
}

/// A list of supported browsers.
enum Browser {
  /// Chrome on Android: https://developer.chrome.com/multidevice/android/overview
  androidChrome,
  /// Chrome: https://www.google.com/chrome/
  chrome,
  /// Edge: https://www.microsoft.com/en-us/windows/microsoft-edge
  edge,
  /// Firefox: https://www.mozilla.org/en-US/firefox/
  firefox,
  /// Safari in iOS: https://www.apple.com/safari/
  iosSafari,
  /// Safari in macOS: https://www.apple.com/safari/
  safari,
}

/// Returns desired capabilities for given [browser], [headless] and
/// [chromeBinary].
@visibleForTesting
Map<String, dynamic> getDesiredCapabilities(Browser browser, bool headless, [String chromeBinary]) {
  switch (browser) {
    case Browser.chrome:
      return <String, dynamic>{
        'acceptInsecureCerts': true,
        'browserName': 'chrome',
        'goog:loggingPrefs': <String, String>{ async_io.LogType.performance: 'ALL'},
        'chromeOptions': <String, dynamic>{
          if (chromeBinary != null)
            'binary': chromeBinary,
          'w3c': false,
          'args': <String>[
            '--bwsi',
            '--disable-background-timer-throttling',
            '--disable-default-apps',
            '--disable-extensions',
            '--disable-popup-blocking',
            '--disable-translate',
            '--no-default-browser-check',
            '--no-sandbox',
            '--no-first-run',
            if (headless) '--headless'
          ],
          'perfLoggingPrefs': <String, String>{
            'traceCategories':
            'devtools.timeline,'
                'v8,blink.console,benchmark,blink,'
                'blink.user_timing'
          }
        },
      };
      break;
    case Browser.firefox:
      return <String, dynamic>{
        'acceptInsecureCerts': true,
        'browserName': 'firefox',
        'moz:firefoxOptions' : <String, dynamic>{
          'args': <String>[
            if (headless) '-headless'
          ],
          'prefs': <String, dynamic>{
            'dom.file.createInChild': true,
            'dom.timeout.background_throttling_max_budget': -1,
            'media.autoplay.default': 0,
            'media.gmp-manager.url': '',
            'media.gmp-provider.enabled': false,
            'network.captive-portal-service.enabled': false,
            'security.insecure_field_warning.contextual.enabled': false,
            'test.currentTimeOffsetSeconds': 11491200
          },
          'log': <String, String>{'level': 'trace'}
        }
      };
      break;
    case Browser.edge:
      return <String, dynamic>{
        'acceptInsecureCerts': true,
        'browserName': 'edge',
      };
      break;
    case Browser.safari:
      return <String, dynamic>{
        'browserName': 'safari',
      };
      break;
    case Browser.iosSafari:
      return <String, dynamic>{
        'platformName': 'ios',
        'browserName': 'safari',
        'safari:useSimulator': true
      };
    case Browser.androidChrome:
      return <String, dynamic>{
        'browserName': 'chrome',
        'platformName': 'android',
        'goog:chromeOptions': <String, dynamic>{
          'androidPackage': 'com.android.chrome',
          'args': <String>['--disable-fullscreen']
        },
      };
    default:
      throw UnsupportedError('Browser $browser not supported.');
  }
}

class WebDriverDevice extends Device {
  WebDriverDevice({
    @required this.headless,
    @required this.chromeBinary,
    @required this.browserName,
    @required this.androidEmulator,
    @required this.driverPort,
    @required this.browserDimension,
 }) : super('web-driver', platformType: PlatformType.web, category: Category.web, ephemeral: true);

  final bool headless;
  final String chromeBinary;
  final String browserName;
  final bool androidEmulator;
  final String driverPort;
  final List<String> browserDimension;

  async_io.WebDriver _webDriver;

  Map<String, String> _additionalDriverEnvironment() {
    return <String, String>{
      'DRIVER_SESSION_ID': _webDriver.id,
      'DRIVER_SESSION_URI': _webDriver.uri.toString(),
      'DRIVER_SESSION_SPEC': _webDriver.spec.toString(),
      'DRIVER_SESSION_CAPABILITIES': json.encode(_webDriver.capabilities),
      'SUPPORT_TIMELINE_ACTION': (_browserNameToEnum(browserName) == Browser.chrome).toString(),
      'FLUTTER_WEB_TEST': 'true',
      'ANDROID_CHROME_ON_EMULATOR': (_browserNameToEnum(browserName) == Browser.androidChrome && androidEmulator).toString(),
    };
  }

  @override
  void clearLogs() { }

  @override
  Future<void> dispose() async { }

  @override
  Future<String> get emulatorId => null;

  @override
  FutureOr<DeviceLogReader> getLogReader({covariant ApplicationPackage app, bool includePastLogs = false}) => NoOpDeviceLogReader('web-driver');

  @override
  Future<bool> installApp(covariant ApplicationPackage app, {String userIdentifier}) async {
    return true;
  }

  @override
  Future<bool> isAppInstalled(covariant ApplicationPackage app, {String userIdentifier}) async {
    return false;
  }

  @override
  Future<bool> isLatestBuildInstalled(covariant ApplicationPackage app) async {
    return false;
  }

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  bool isSupported() {
    return true;
  }

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.web.existsSync();
  }

  @override
  String get name => 'web-driver';

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => 'web-driver';

  @override
  Future<LaunchResult> startApp(
    covariant WebApplicationPackage package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String userIdentifier,
  }) async {
    final Browser browser = _browserNameToEnum(browserName);
    try {
      _webDriver = await async_io.createDriver(
        uri: Uri.parse('http://localhost:$driverPort/'),
        desired: getDesiredCapabilities(browser, headless, chromeBinary),
        spec: async_io.WebDriverSpec.Auto
      );
    } on Exception catch (ex) {
      throwToolExit(
        'Unable to start WebDriver Session for Flutter for Web testing. \n'
        'Make sure you have the correct WebDriver Server running at $driverPort. \n'
        'Make sure the WebDriver Server matches option --browser-name. \n'
        '$ex'
      );
    }

    final bool isAndroidChrome = browser == Browser.androidChrome;
    // Do not set the window size for android chrome browser.
    if (!isAndroidChrome) {
      assert(browserDimension.length == 2);
      int x;
      int y;
      try {
        x = int.parse(browserDimension[0]);
        y = int.parse(browserDimension[1]);
      } on FormatException catch (ex) {
        throwToolExit('Dimension provided to --browser-dimension is invalid: $ex');
      }
      final async_io.Window window = await _webDriver.window;
      await window.setLocation(const math.Point<int>(0, 0));
      await window.setSize(math.Rectangle<int>(0, 0, x, y));
    }
    return LaunchResult.succeeded();
  }

  @override
  Future<bool> stopApp(covariant ApplicationPackage app, {String userIdentifier}) async {
    await _webDriver.quit(closeSession: true);
    return true;
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.web_javascript;

  @override
  Future<bool> uninstallApp(covariant ApplicationPackage app, {String userIdentifier}) async {
    return true;
  }
}

/// Converts [browserName] string to [Browser]
Browser _browserNameToEnum(String browserName){
  switch (browserName) {
    case 'android-chrome': return Browser.androidChrome;
    case 'chrome': return Browser.chrome;
    case 'edge': return Browser.edge;
    case 'firefox': return Browser.firefox;
    case 'ios-safari': return Browser.iosSafari;
    case 'safari': return Browser.safari;
  }
  throw UnsupportedError('Browser $browserName not supported');
}
