// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/process.dart';
import '../cache.dart';
import '../dart/package_map.dart';
import '../dart/sdk.dart';
import '../device.dart';
import '../globals.dart';
import '../project.dart';
import '../resident_runner.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
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
  bool get shouldBuild => argResults['build'];

  bool get verboseSystemLogs => argResults['verbose-system-logs'];

  /// Subscription to log messages printed on the device or simulator.
  // ignore: cancel_subscriptions
  StreamSubscription<String> _deviceLogSubscription;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String testFile = _getTestFile();
    if (testFile == null)
      throwToolExit(null);

    _device = await findTargetDevice();
    if (device == null)
      throwToolExit(null);

    if (await fs.type(testFile) != FileSystemEntityType.file)
      throwToolExit('Test file not found: $testFile');

    String observatoryUri;
    if (argResults['use-existing-app'] == null) {
      printStatus('Starting application: $targetFile');

      if (getBuildInfo().isRelease) {
        // This is because we need VM service to be able to drive the app.
        throwToolExit(
          'Flutter Driver does not support running in release mode.\n'
          '\n'
          'Use --profile mode for testing application performance.\n'
          'Use --debug (default) mode for testing correctness (with assertions).'
        );
      }

      final LaunchResult result = await appStarter(this);
      if (result == null)
        throwToolExit('Application failed to start. Will not run test. Quitting.', exitCode: 1);
      observatoryUri = result.observatoryUri.toString();
    } else {
      printStatus('Will connect to already running application instance.');
      observatoryUri = argResults['use-existing-app'];
    }

    Cache.releaseLockEarly();

    try {
      await testRunner(<String>[testFile], observatoryUri);
    } catch (error, stackTrace) {
      if (error is ToolExit)
        rethrow;
      throwToolExit('CAUGHT EXCEPTION: $error\n$stackTrace');
    } finally {
      if (argResults['keep-app-running'] ?? (argResults['use-existing-app'] != null)) {
        printStatus('Leaving the application running.');
      } else {
        printStatus('Stopping application instance.');
        await appStopper(this);
      }
    }

    return null;
  }

  String _getTestFile() {
    if (argResults['driver'] != null)
      return argResults['driver'];

    // If the --driver argument wasn't provided, then derive the value from
    // the target file.
    String appFile = fs.path.normalize(targetFile);

    // This command extends `flutter run` and therefore CWD == package dir
    final String packageDir = fs.currentDirectory.path;

    // Make appFile path relative to package directory because we are looking
    // for the corresponding test file relative to it.
    if (!fs.path.isRelative(appFile)) {
      if (!fs.path.isWithin(packageDir, appFile)) {
        printError(
          'Application file $appFile is outside the package directory $packageDir'
        );
        return null;
      }

      appFile = fs.path.relative(appFile, from: packageDir);
    }

    final List<String> parts = fs.path.split(appFile);

    if (parts.length < 2) {
      printError(
        'Application file $appFile must reside in one of the sub-directories '
        'of the package structure, not in the root directory.'
      );
      return null;
    }

    // Look for the test file inside `test_driver/` matching the sub-path, e.g.
    // if the application is `lib/foo/bar.dart`, the test file is expected to
    // be `test_driver/foo/bar_test.dart`.
    final String pathWithNoExtension = fs.path.withoutExtension(fs.path.joinAll(
      <String>[packageDir, 'test_driver', ...parts.skip(1)]));
    return '${pathWithNoExtension}_test${fs.path.extension(appFile)}';
  }
}

Future<Device> findTargetDevice() async {
  final List<Device> devices = await deviceManager.findTargetDevices(FlutterProject.current());

  if (deviceManager.hasSpecifiedDeviceId) {
    if (devices.isEmpty) {
      printStatus("No devices found with name or id matching '${deviceManager.specifiedDeviceId}'");
      return null;
    }
    if (devices.length > 1) {
      printStatus("Found ${devices.length} devices with name or id matching '${deviceManager.specifiedDeviceId}':");
      await Device.printDevices(devices);
      return null;
    }
    return devices.first;
  }

  if (devices.isEmpty) {
    printError('No devices found.');
    return null;
  } else if (devices.length > 1) {
    printStatus('Found multiple connected devices:');
    await Device.printDevices(devices);
  }
  printStatus('Using device ${devices.first.name}.');
  return devices.first;
}

/// Starts the application on the device given command configuration.
typedef AppStarter = Future<LaunchResult> Function(DriveCommand command);

AppStarter appStarter = _startApp; // (mutable for testing)
void restoreAppStarter() {
  appStarter = _startApp;
}

Future<LaunchResult> _startApp(DriveCommand command) async {
  final String mainPath = findMainDartFile(command.targetFile);
  if (await fs.type(mainPath) != FileSystemEntityType.file) {
    printError('Tried to run $mainPath, but that file does not exist.');
    return null;
  }

  printTrace('Stopping previously running application, if any.');
  await appStopper(command);

  final ApplicationPackage package = await command.applicationPackages
      .getPackageForPlatform(await command.device.targetPlatform);

  if (command.shouldBuild) {
    printTrace('Installing application package.');
    if (await command.device.isAppInstalled(package))
      await command.device.uninstallApp(package);
    await command.device.installApp(package);
  }

  final Map<String, dynamic> platformArgs = <String, dynamic>{};
  if (command.traceStartup)
    platformArgs['trace-startup'] = command.traceStartup;

  printTrace('Starting application.');

  // Forward device log messages to the terminal window running the "drive" command.
  command._deviceLogSubscription = command
      .device
      .getLogReader(app: package)
      .logLines
      .listen(printStatus);

  final LaunchResult result = await command.device.startApp(
    package,
    mainPath: mainPath,
    route: command.route,
    debuggingOptions: DebuggingOptions.enabled(
      command.getBuildInfo(),
      startPaused: true,
      observatoryPort: command.observatoryPort,
      verboseSystemLogs: command.verboseSystemLogs
    ),
    platformArgs: platformArgs,
    prebuiltApplication: !command.shouldBuild,
  );

  if (!result.started) {
    await command._deviceLogSubscription.cancel();
    return null;
  }

  return result;
}

/// Runs driver tests.
typedef TestRunner = Future<void> Function(List<String> testArgs, String observatoryUri);
TestRunner testRunner = _runTests;
void restoreTestRunner() {
  testRunner = _runTests;
}

Future<void> _runTests(List<String> testArgs, String observatoryUri) async {
  printTrace('Running driver tests.');

  PackageMap.globalPackagesPath = fs.path.normalize(fs.path.absolute(PackageMap.globalPackagesPath));
  final String dartVmPath = fs.path.join(dartSdkPath, 'bin', 'dart');
  final int result = await processUtils.stream(
    <String>[
      dartVmPath,
      ...dartVmFlags,
      ...testArgs,
      '--packages=${PackageMap.globalPackagesPath}',
      '-rexpanded',
    ],
    environment: <String, String>{'VM_SERVICE_URL': observatoryUri},
  );
  if (result != 0)
    throwToolExit('Driver tests failed: $result', exitCode: result);
}


/// Stops the application.
typedef AppStopper = Future<bool> Function(DriveCommand command);
AppStopper appStopper = _stopApp;
void restoreAppStopper() {
  appStopper = _stopApp;
}

Future<bool> _stopApp(DriveCommand command) async {
  printTrace('Stopping application.');
  final ApplicationPackage package = await command.applicationPackages.getPackageForPlatform(await command.device.targetPlatform);
  final bool stopped = await command.device.stopApp(package);
  await command._deviceLogSubscription?.cancel();
  return stopped;
}
