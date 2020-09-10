// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:dds/dds.dart' as dds;
import 'package:vm_service/vm_service_io.dart' as vm_service;
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:meta/meta.dart';
import 'package:webdriver/async_io.dart' as async_io;

import '../android/android_device.dart';
import '../application_package.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../resident_runner.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult, FlutterOptions;
import '../vmservice.dart';
import '../web/web_runner.dart';
import 'run.dart';

/// Runs integration (a.k.a. end-to-end) tests.
///
/// An integration test is a program that runs in a separate process from your
/// Flutter application. It connects to the application and acts like a user,
/// performing taps, scrolls, reading out widget properties and verifying their
/// correctness.
///
/// This command takes a target Flutter application that you would like to test
/// as the `--target` option (defaults to `lib/main.dart`). It then looks for a
/// corresponding test file within the `test_driver` directory. The test file is
/// expected to have the same name but contain the `_test.dart` suffix. The
/// `_test.dart` file would generally be a Dart program that uses
/// `package:flutter_driver` and exercises your application. Most commonly it
/// is a test written using `package:test`, but you are free to use something
/// else.
///
/// The app and the test are launched simultaneously. Once the test completes
/// the application is stopped and the command exits. If all these steps are
/// successful the exit code will be `0`. Otherwise, you will see a non-zero
/// exit code.
class DriveCommand extends RunCommandBase {
  DriveCommand() {
    requiresPubspecYaml();

    argParser
      ..addFlag('keep-app-running',
        defaultsTo: null,
        help: 'Will keep the Flutter application running when done testing.\n'
              'By default, "flutter drive" stops the application after tests are finished, '
              'and --keep-app-running overrides this. On the other hand, if --use-existing-app '
              'is specified, then "flutter drive" instead defaults to leaving the application '
              'running, and --no-keep-app-running overrides it.',
      )
      ..addOption('use-existing-app',
        help: 'Connect to an already running instance via the given observatory URL. '
              'If this option is given, the application will not be automatically started, '
              'and it will only be stopped if --no-keep-app-running is explicitly set.',
        valueHelp: 'url',
      )
      ..addOption('driver',
        help: 'The test file to run on the host (as opposed to the target file to run on '
              'the device).\n'
              'By default, this file has the same base name as the target file, but in the '
              '"test_driver/" directory instead, and with "_test" inserted just before the '
              'extension, so e.g. if the target is "lib/main.dart", the driver will be '
              '"test_driver/main_test.dart".',
        valueHelp: 'path',
      )
      ..addFlag('build',
        defaultsTo: true,
        help: 'Build the app before running.',
      )
      ..addOption('driver-port',
        defaultsTo: '4444',
        help: 'The port where Webdriver server is launched at. Defaults to 4444.',
        valueHelp: '4444'
      )
      ..addFlag('headless',
        defaultsTo: true,
        help: 'Whether the driver browser is going to be launched in headless mode. Defaults to true.',
      )
      ..addOption('browser-name',
        defaultsTo: 'chrome',
        help: 'Name of browser where tests will be executed. \n'
              'Following browsers are supported: \n'
              'Chrome, Firefox, Safari (macOS and iOS) and Edge. Defaults to Chrome.',
        allowed: <String>[
          'android-chrome',
          'chrome',
          'edge',
          'firefox',
          'ios-safari',
          'safari',
        ]
      )
      ..addOption('browser-dimension',
        defaultsTo: '1600,1024',
        help: 'The dimension of browser when running Flutter Web test. \n'
              'This will affect screenshot and all offset-related actions. \n'
              'By default. it is set to 1600,1024 (1600 by 1024).',
      )
      ..addFlag('android-emulator',
        defaultsTo: true,
        help: 'Whether to perform Flutter Driver testing on Android Emulator.'
          'Works only if \'browser-name\' is set to \'android-chrome\'')
      ..addOption('chrome-binary',
        help: 'Location of Chrome binary. '
          'Works only if \'browser-name\' is set to \'chrome\'')
      ..addOption('write-sksl-on-exit',
        help:
          'Attempts to write an SkSL file when the drive process is finished '
          'to the provided file, overwriting it if necessary.',
      );
  }

  @override
  final String name = 'drive';

  @override
  final String description = 'Runs Flutter Driver tests for the current project.';

  @override
  final List<String> aliases = <String>['driver'];

  Device _device;
  Device get device => _device;
  bool get shouldBuild => boolArg('build');

  bool get verboseSystemLogs => boolArg('verbose-system-logs');
  String get userIdentifier => stringArg(FlutterOptions.kDeviceUser);

  /// Subscription to log messages printed on the device or simulator.
  // ignore: cancel_subscriptions
  StreamSubscription<String> _deviceLogSubscription;

  @override
  Future<void> validateCommand() async {
    if (userIdentifier != null) {
      final Device device = await findTargetDevice(timeout: deviceDiscoveryTimeout);
      if (device is! AndroidDevice) {
        throwToolExit('--${FlutterOptions.kDeviceUser} is only supported for Android');
      }
    }
    return super.validateCommand();
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String testFile = _getTestFile();
    if (testFile == null) {
      throwToolExit(null);
    }

    _device = await findTargetDevice(timeout: deviceDiscoveryTimeout);
    if (device == null) {
      throwToolExit(null);
    }

    if (await globals.fs.type(testFile) != FileSystemEntityType.file) {
      throwToolExit('Test file not found: $testFile');
    }

    String observatoryUri;
    ResidentRunner residentRunner;
    final BuildInfo buildInfo = getBuildInfo();
    final bool isWebPlatform = await device.targetPlatform == TargetPlatform.web_javascript;
    if (argResults['use-existing-app'] == null) {
      globals.printStatus('Starting application: $targetFile');

      if (buildInfo.isRelease && !isWebPlatform) {
        // This is because we need VM service to be able to drive the app.
        // For Flutter Web, testing in release mode is allowed.
        throwToolExit(
          'Flutter Driver (non-web) does not support running in release mode.\n'
          '\n'
          'Use --profile mode for testing application performance.\n'
          'Use --debug (default) mode for testing correctness (with assertions).'
        );
      }

      Uri webUri;

      if (isWebPlatform) {
        // Start Flutter web application for current test
        final FlutterProject flutterProject = FlutterProject.current();
        final FlutterDevice flutterDevice = await FlutterDevice.create(
          device,
          flutterProject: flutterProject,
          target: targetFile,
          buildInfo: buildInfo,
        );
        residentRunner = webRunnerFactory.createWebRunner(
          flutterDevice,
          target: targetFile,
          flutterProject: flutterProject,
          ipv6: ipv6,
          debuggingOptions: getBuildInfo().isRelease ?
            DebuggingOptions.disabled(
              getBuildInfo(),
              port: stringArg('web-port')
            )
            : DebuggingOptions.enabled(
              getBuildInfo(),
              port: stringArg('web-port')
            ),
          stayResident: false,
          urlTunneller: null,
        );
        final Completer<void> appStartedCompleter = Completer<void>.sync();
        final int result = await residentRunner.run(
          appStartedCompleter: appStartedCompleter,
          route: route,
        );
        if (result != 0) {
          throwToolExit(null, exitCode: result);
        }
        // Wait until the app is started.
        await appStartedCompleter.future;
        webUri = residentRunner.uri;
      }

      final LaunchResult result = await appStarter(this, webUri);
      if (result == null) {
        throwToolExit('Application failed to start. Will not run test. Quitting.', exitCode: 1);
      }
      observatoryUri = result.observatoryUri.toString();
      // TODO(bkonyi): add web support (https://github.com/flutter/flutter/issues/61259)
      if (!isWebPlatform) {
        try {
          // If there's another flutter_tools instance still connected to the target
          // application, DDS will already be running remotely and this call will fail.
          // We can ignore this and continue to use the remote DDS instance.
          await device.dds.startDartDevelopmentService(Uri.parse(observatoryUri), ipv6);
        } on dds.DartDevelopmentServiceException catch(_) {
          globals.printTrace('Note: DDS is already connected to $observatoryUri.');
        }
      }
    } else {
      globals.printStatus('Will connect to already running application instance.');
      observatoryUri = stringArg('use-existing-app');
    }

    final Map<String, String> environment = <String, String>{
      'VM_SERVICE_URL': observatoryUri,
    };

    async_io.WebDriver driver;
    // For web device, WebDriver session will be launched beforehand
    // so that FlutterDriver can reuse it.
    if (isWebPlatform) {
      final Browser browser = _browserNameToEnum(
          argResults['browser-name'].toString());
      final String driverPort = argResults['driver-port'].toString();
      // start WebDriver
      try {
        driver = await _createDriver(
          driverPort,
          browser,
          argResults['headless'].toString() == 'true',
          stringArg('chrome-binary'),
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
      final bool useEmulator = argResults['android-emulator'] as bool;
      // set window size
      // for android chrome, skip such action
      if (!isAndroidChrome) {
        final List<String> dimensions = argResults['browser-dimension'].split(
            ',') as List<String>;
        assert(dimensions.length == 2);
        int x, y;
        try {
          x = int.parse(dimensions[0]);
          y = int.parse(dimensions[1]);
        } on FormatException catch (ex) {
          throwToolExit('''
Dimension provided to --browser-dimension is invalid:
$ex
        ''');
        }
        final async_io.Window window = await driver.window;
        await window.setLocation(const math.Point<int>(0, 0));
        await window.setSize(math.Rectangle<int>(0, 0, x, y));
      }

      // add driver info to environment variables
      environment.addAll(<String, String> {
        'DRIVER_SESSION_ID': driver.id,
        'DRIVER_SESSION_URI': driver.uri.toString(),
        'DRIVER_SESSION_SPEC': driver.spec.toString(),
        'DRIVER_SESSION_CAPABILITIES': json.encode(driver.capabilities),
        'SUPPORT_TIMELINE_ACTION': (browser == Browser.chrome).toString(),
        'FLUTTER_WEB_TEST': 'true',
        'ANDROID_CHROME_ON_EMULATOR': (isAndroidChrome && useEmulator).toString(),
      });
    }

    try {
      await testRunner(<String>[testFile], environment);
    } on Exception catch (error, stackTrace) {
      if (error is ToolExit) {
        rethrow;
      }
      throw Exception('Unable to run test: $error\n$stackTrace');
    } finally {
      await residentRunner?.exit();
      await driver?.quit();
      if (stringArg('write-sksl-on-exit') != null) {
        final File outputFile = globals.fs.file(stringArg('write-sksl-on-exit'));
        final vm_service.VmService vmService = await connectToVmService(
          Uri.parse(observatoryUri),
        );
        final FlutterView flutterView = (await vmService.getFlutterViews()).first;
        final Map<String, Object> result = await vmService.getSkSLs(
          viewId: flutterView.id
        );
        await sharedSkSlWriter(_device, result, outputFile: outputFile);
      }
      if (boolArg('keep-app-running') ?? (argResults['use-existing-app'] != null)) {
        globals.printStatus('Leaving the application running.');
      } else {
        globals.printStatus('Stopping application instance.');
        await appStopper(this);
      }
    }

    return FlutterCommandResult.success();
  }

  String _getTestFile() {
    if (argResults['driver'] != null) {
      return stringArg('driver');
    }

    // If the --driver argument wasn't provided, then derive the value from
    // the target file.
    String appFile = globals.fs.path.normalize(targetFile);

    // This command extends `flutter run` and therefore CWD == package dir
    final String packageDir = globals.fs.currentDirectory.path;

    // Make appFile path relative to package directory because we are looking
    // for the corresponding test file relative to it.
    if (!globals.fs.path.isRelative(appFile)) {
      if (!globals.fs.path.isWithin(packageDir, appFile)) {
        globals.printError(
          'Application file $appFile is outside the package directory $packageDir'
        );
        return null;
      }

      appFile = globals.fs.path.relative(appFile, from: packageDir);
    }

    final List<String> parts = globals.fs.path.split(appFile);

    if (parts.length < 2) {
      globals.printError(
        'Application file $appFile must reside in one of the sub-directories '
        'of the package structure, not in the root directory.'
      );
      return null;
    }

    // Look for the test file inside `test_driver/` matching the sub-path, e.g.
    // if the application is `lib/foo/bar.dart`, the test file is expected to
    // be `test_driver/foo/bar_test.dart`.
    final String pathWithNoExtension = globals.fs.path.withoutExtension(globals.fs.path.joinAll(
      <String>[packageDir, 'test_driver', ...parts.skip(1)]));
    return '${pathWithNoExtension}_test${globals.fs.path.extension(appFile)}';
  }
}

Future<Device> findTargetDevice({ @required Duration timeout }) async {
  final DeviceManager deviceManager = globals.deviceManager;
  final List<Device> devices = await deviceManager.findTargetDevices(FlutterProject.current(), timeout: timeout);

  if (deviceManager.hasSpecifiedDeviceId) {
    if (devices.isEmpty) {
      globals.printStatus("No devices found with name or id matching '${deviceManager.specifiedDeviceId}'");
      return null;
    }
    if (devices.length > 1) {
      globals.printStatus("Found ${devices.length} devices with name or id matching '${deviceManager.specifiedDeviceId}':");
      await Device.printDevices(devices);
      return null;
    }
    return devices.first;
  }

  if (devices.isEmpty) {
    globals.printError('No devices found.');
    return null;
  } else if (devices.length > 1) {
    globals.printStatus('Found multiple connected devices:');
    await Device.printDevices(devices);
  }
  globals.printStatus('Using device ${devices.first.name}.');
  return devices.first;
}

/// Starts the application on the device given command configuration.
typedef AppStarter = Future<LaunchResult> Function(DriveCommand command, Uri webUri);

AppStarter appStarter = _startApp; // (mutable for testing)
void restoreAppStarter() {
  appStarter = _startApp;
}

Future<LaunchResult> _startApp(
  DriveCommand command,
  Uri webUri, {
  String userIdentifier,
}) async {
  final String mainPath = findMainDartFile(command.targetFile);
  if (await globals.fs.type(mainPath) != FileSystemEntityType.file) {
    globals.printError('Tried to run $mainPath, but that file does not exist.');
    return null;
  }

  globals.printTrace('Stopping previously running application, if any.');
  await appStopper(command);

  final ApplicationPackage package = await command.applicationPackages
      .getPackageForPlatform(await command.device.targetPlatform, command.getBuildInfo());

  if (command.shouldBuild) {
    globals.printTrace('Installing application package.');
    if (await command.device.isAppInstalled(package, userIdentifier: userIdentifier)) {
      await command.device.uninstallApp(package, userIdentifier: userIdentifier);
    }
    await command.device.installApp(package, userIdentifier: userIdentifier);
  }

  final Map<String, dynamic> platformArgs = <String, dynamic>{};
  if (command.traceStartup) {
    platformArgs['trace-startup'] = command.traceStartup;
  }

  if (webUri != null) {
    platformArgs['uri'] = webUri.toString();
    if (!command.getBuildInfo().isDebug) {
      // For web device, startApp will be triggered twice
      // and it will error out for chrome the second time.
      platformArgs['no-launch-chrome'] = true;
    }
  }

  globals.printTrace('Starting application.');

  // Forward device log messages to the terminal window running the "drive" command.
  final DeviceLogReader logReader = await command.device.getLogReader(app: package);
  command._deviceLogSubscription = logReader
    .logLines
    .listen(globals.printStatus);

  final LaunchResult result = await command.device.startApp(
    package,
    mainPath: mainPath,
    route: command.route,
    debuggingOptions: DebuggingOptions.enabled(
      command.getBuildInfo(),
      startPaused: true,
      hostVmServicePort: command.hostVmservicePort,
      verboseSystemLogs: command.verboseSystemLogs,
      cacheSkSL: command.cacheSkSL,
      dumpSkpOnShaderCompilation: command.dumpSkpOnShaderCompilation,
      purgePersistentCache: command.purgePersistentCache,
    ),
    platformArgs: platformArgs,
    prebuiltApplication: !command.shouldBuild,
    userIdentifier: userIdentifier,
  );

  if (!result.started) {
    await command._deviceLogSubscription.cancel();
    return null;
  }

  return result;
}

/// Runs driver tests.
typedef TestRunner = Future<void> Function(List<String> testArgs, Map<String, String> environment);
TestRunner testRunner = _runTests;
void restoreTestRunner() {
  testRunner = _runTests;
}

Future<void> _runTests(List<String> testArgs, Map<String, String> environment) async {
  globals.printTrace('Running driver tests.');

  globalPackagesPath = globals.fs.path.normalize(globals.fs.path.absolute(globalPackagesPath));
  final int result = await processUtils.stream(
    <String>[
      globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
      ...testArgs,
      '--packages=$globalPackagesPath',
      '-rexpanded',
    ],
    environment: environment,
  );
  if (result != 0) {
    throwToolExit('Driver tests failed: $result', exitCode: result);
  }
}


/// Stops the application.
typedef AppStopper = Future<bool> Function(DriveCommand command);
AppStopper appStopper = _stopApp;
void restoreAppStopper() {
  appStopper = _stopApp;
}

Future<bool> _stopApp(DriveCommand command) async {
  globals.printTrace('Stopping application.');
  final ApplicationPackage package = await command.applicationPackages.getPackageForPlatform(
    await command.device.targetPlatform,
    command.getBuildInfo(),
  );
  final bool stopped = await command.device.stopApp(package, userIdentifier: command.userIdentifier);
  await command._deviceLogSubscription?.cancel();
  return stopped;
}

/// A list of supported browsers.
@visibleForTesting
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

Future<async_io.WebDriver> _createDriver(String driverPort, Browser browser, bool headless, String chromeBinary) async {
  return async_io.createDriver(
      uri: Uri.parse('http://localhost:$driverPort/'),
      desired: getDesiredCapabilities(browser, headless, chromeBinary),
      spec: async_io.WebDriverSpec.Auto
  );
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
