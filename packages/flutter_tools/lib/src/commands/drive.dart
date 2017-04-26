// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/android_device.dart' show AndroidDevice;
import '../application_package.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../cache.dart';
import '../dart/package_map.dart';
import '../dart/sdk.dart';
import '../device.dart';
import '../globals.dart';
import '../ios/simulators.dart' show SimControl, IOSSimulatorUtils;
import '../resident_runner.dart';
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
/// `_test.dart` file would generall be a Dart program that uses
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
    argParser.addFlag(
      'keep-app-running',
      negatable: true,
      defaultsTo: false,
      help:
        'Will keep the Flutter application running when done testing.\n'
        'By default, Flutter drive stops the application after tests are finished.\n'
        'Ignored if --use-existing-app is specified.'
    );

    argParser.addOption(
      'use-existing-app',
      help:
        'Connect to an already running instance via the given observatory URL.\n'
        'If this option is given, the application will not be automatically started\n'
        'or stopped.'
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

  /// Subscription to log messages printed on the device or simulator.
  // ignore: cancel_subscriptions
  StreamSubscription<String> _deviceLogSubscription;

  @override
  Future<Null> verifyThenRunCommand() async {
    commandValidator();
    return super.verifyThenRunCommand();
  }

  @override
  Future<Null> runCommand() async {
    final String testFile = _getTestFile();
    if (testFile == null)
      throwToolExit(null);

    _device = await targetDeviceFinder();
    if (device == null)
      throwToolExit(null);

    if (await fs.type(testFile) != FileSystemEntityType.FILE)
      throwToolExit('Test file not found: $testFile');

    String observatoryUri;
    if (argResults['use-existing-app'] == null) {
      printStatus('Starting application: ${argResults["target"]}');

      if (getBuildMode() == BuildMode.release) {
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
      if (!argResults['keep-app-running'] && argResults['use-existing-app'] == null) {
        printStatus('Stopping application instance.');
        await appStopper(this);
      } else {
        printStatus('Leaving the application running.');
      }
    }
  }

  String _getTestFile() {
    String appFile = fs.path.normalize(targetFile);

    // This command extends `flutter start` and therefore CWD == package dir
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
      <String>[packageDir, 'test_driver']..addAll(parts.skip(1))));
    return '${pathWithNoExtension}_test${fs.path.extension(appFile)}';
  }
}

/// Finds a device to test on. May launch a simulator, if necessary.
typedef Future<Device> TargetDeviceFinder();
TargetDeviceFinder targetDeviceFinder = findTargetDevice;
void restoreTargetDeviceFinder() {
  targetDeviceFinder = findTargetDevice;
}

Future<Device> findTargetDevice() async {
  final List<Device> devices = await deviceManager.getDevices().toList();

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


  if (platform.isMacOS) {
    // On Mac we look for the iOS Simulator. If available, we use that. Then
    // we look for an Android device. If there's one, we use that. Otherwise,
    // we launch a new iOS Simulator.
    Device reusableDevice;
    for (Device device in devices) {
      if (await device.isLocalEmulator) {
        reusableDevice = device;
        break;
      }
    }
    if (reusableDevice == null) {
      for (Device device in devices) {
        if (device is AndroidDevice) {
          reusableDevice = device;
          break;
        }
      }
    }

    if (reusableDevice != null) {
      printStatus('Found connected ${await reusableDevice.isLocalEmulator ? "emulator" : "device"} "${reusableDevice.name}"; will reuse it.');
      return reusableDevice;
    }

    // No running emulator found. Attempt to start one.
    printStatus('Starting iOS Simulator, because did not find existing connected devices.');
    final bool started = await SimControl.instance.boot();
    if (started) {
      return IOSSimulatorUtils.instance.getAttachedDevices().first;
    } else {
      printError('Failed to start iOS Simulator.');
      return null;
    }
  } else if (platform.isLinux || platform.isWindows) {
    // On Linux and Windows, for now, we just grab the first connected device we can find.
    if (devices.isEmpty) {
      printError('No devices found.');
      return null;
    } else if (devices.length > 1) {
      printStatus('Found multiple connected devices:');
      printStatus(devices.map((Device d) => '  - ${d.name}\n').join(''));
    }
    printStatus('Using device ${devices.first.name}.');
    return devices.first;
  } else {
    printError('The operating system on this computer is not supported.');
    return null;
  }
}

/// Starts the application on the device given command configuration.
typedef Future<LaunchResult> AppStarter(DriveCommand command);

AppStarter appStarter = _startApp;
void restoreAppStarter() {
  appStarter = _startApp;
}

Future<LaunchResult> _startApp(DriveCommand command) async {
  final String mainPath = findMainDartFile(command.targetFile);
  if (await fs.type(mainPath) != FileSystemEntityType.FILE) {
    printError('Tried to run $mainPath, but that file does not exist.');
    return null;
  }

  printTrace('Stopping previously running application, if any.');
  await appStopper(command);

  printTrace('Installing application package.');
  final ApplicationPackage package = command.applicationPackages
      .getPackageForPlatform(await command.device.targetPlatform);
  if (await command.device.isAppInstalled(package))
    command.device.uninstallApp(package);
  command.device.installApp(package);

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
    command.getBuildMode(),
    mainPath: mainPath,
    route: command.route,
    debuggingOptions: new DebuggingOptions.enabled(
      command.getBuildMode(),
      startPaused: true,
      observatoryPort: command.observatoryPort,
      diagnosticPort: command.diagnosticPort,
    ),
    platformArgs: platformArgs
  );

  if (!result.started) {
    await command._deviceLogSubscription.cancel();
    return null;
  }

  return result;
}

/// Runs driver tests.
typedef Future<Null> TestRunner(List<String> testArgs, String observatoryUri);
TestRunner testRunner = _runTests;
void restoreTestRunner() {
  testRunner = _runTests;
}

Future<Null> _runTests(List<String> testArgs, String observatoryUri) async {
  printTrace('Running driver tests.');

  PackageMap.globalPackagesPath = fs.path.normalize(fs.path.absolute(PackageMap.globalPackagesPath));
  final List<String> args = testArgs.toList()
    ..add('--packages=${PackageMap.globalPackagesPath}')
    ..add('-rexpanded');
  final String dartVmPath = fs.path.join(dartSdkPath, 'bin', 'dart');
  final int result = await runCommandAndStreamOutput(
    <String>[dartVmPath]..addAll(args),
    environment: <String, String>{ 'VM_SERVICE_URL': observatoryUri }
  );
  if (result != 0)
    throwToolExit('Driver tests failed: $result', exitCode: result);
}


/// Stops the application.
typedef Future<bool> AppStopper(DriveCommand command);
AppStopper appStopper = _stopApp;
void restoreAppStopper() {
  appStopper = _stopApp;
}

Future<bool> _stopApp(DriveCommand command) async {
  printTrace('Stopping application.');
  final ApplicationPackage package = command.applicationPackages.getPackageForPlatform(await command.device.targetPlatform);
  final bool stopped = await command.device.stopApp(package);
  await command._deviceLogSubscription?.cancel();
  return stopped;
}
