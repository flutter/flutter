// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as path;

import '../android/android_device.dart' show AndroidDevice;
import '../application_package.dart';
import '../base/file_system.dart';
import '../base/common.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../cache.dart';
import '../dart/package_map.dart';
import '../dart/sdk.dart';
import '../device.dart';
import '../globals.dart';
import '../ios/simulators.dart' show SimControl, IOSSimulatorUtils;
import '../resident_runner.dart';
import 'build_apk.dart' as build_apk;
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
    usesPubOption();
    argParser.addFlag(
      'keep-app-running',
      negatable: true,
      defaultsTo: false,
      help:
        'Will keep the Flutter application running when done testing. By '
        'default Flutter Driver stops the application after tests are finished.'
    );

    argParser.addFlag(
      'use-existing-app',
      negatable: true,
      defaultsTo: false,
      help:
        'Will not start a new Flutter application but connect to an '
        'already running instance. This will also cause the driver to keep '
        'the application running after tests are done.'
    );

    argParser.addOption('debug-port',
      defaultsTo: kDefaultDrivePort.toString(),
      help: 'Listen to the given port for a debug connection.'
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

  int get debugPort => int.parse(argResults['debug-port']);

  @override
  Future<int> verifyThenRunCommand() async {
    if (!commandValidator())
      return 1;
    return super.verifyThenRunCommand();
  }

  @override
  Future<int> runCommand() async {
    String testFile = _getTestFile();
    if (testFile == null) {
      return 1;
    }

    this._device = await targetDeviceFinder();
    if (device == null) {
      return 1;
    }

    if (await fs.type(testFile) != FileSystemEntityType.FILE) {
      printError('Test file not found: $testFile');
      return 1;
    }

    if (!argResults['use-existing-app']) {
      printStatus('Starting application: ${argResults["target"]}');

      if (getBuildMode() == BuildMode.release) {
        // This is because we need VM service to be able to drive the app.
        printError(
          'Flutter Driver does not support running in release mode.\n'
          '\n'
          'Use --profile mode for testing application performance.\n'
          'Use --debug (default) mode for testing correctness (with assertions).'
        );
        return 1;
      }

      int result = await appStarter(this);
      if (result != 0) {
        printError('Application failed to start. Will not run test. Quitting.');
        return result;
      }
    } else {
      printStatus('Will connect to already running application instance.');
    }

    Cache.releaseLockEarly();

    try {
      return await testRunner(<String>[testFile])
        .catchError((dynamic error, dynamic stackTrace) {
          printError('CAUGHT EXCEPTION: $error\n$stackTrace');
          return 1;
        });
    } finally {
      if (!argResults['keep-app-running'] && !argResults['use-existing-app']) {
        printStatus('Stopping application instance.');
        try {
          await appStopper(this);
        } catch(error, stackTrace) {
          // TODO(yjbanov): remove this guard when this bug is fixed: https://github.com/dart-lang/sdk/issues/25862
          printTrace('Could not stop application: $error\n$stackTrace');
        }
      } else {
        printStatus('Leaving the application running.');
      }
    }
  }

  String _getTestFile() {
    String appFile = path.normalize(targetFile);

    // This command extends `flutter start` and therefore CWD == package dir
    String packageDir = getCurrentDirectory();

    // Make appFile path relative to package directory because we are looking
    // for the corresponding test file relative to it.
    if (!path.isRelative(appFile)) {
      if (!path.isWithin(packageDir, appFile)) {
        printError(
          'Application file $appFile is outside the package directory $packageDir'
        );
        return null;
      }

      appFile = path.relative(appFile, from: packageDir);
    }

    List<String> parts = path.split(appFile);

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
    String pathWithNoExtension = path.withoutExtension(path.joinAll(
      <String>[packageDir, 'test_driver']..addAll(parts.skip(1))));
    return '${pathWithNoExtension}_test${path.extension(appFile)}';
  }
}

/// Finds a device to test on. May launch a simulator, if necessary.
typedef Future<Device> TargetDeviceFinder();
TargetDeviceFinder targetDeviceFinder = findTargetDevice;
void restoreTargetDeviceFinder() {
  targetDeviceFinder = findTargetDevice;
}

Future<Device> findTargetDevice() async {
  List<Device> devices = await deviceManager.getDevices();

  if (deviceManager.hasSpecifiedDeviceId) {
    if (devices.isEmpty) {
      printStatus("No devices found with name or id matching '${deviceManager.specifiedDeviceId}'");
      return null;
    }
    if (devices.length > 1) {
      printStatus("Found ${devices.length} devices with name or id matching '${deviceManager.specifiedDeviceId}':");
      Device.printDevices(devices);
      return null;
    }
    return devices.first;
  }


  if (os.isMacOS) {
    // On Mac we look for the iOS Simulator. If available, we use that. Then
    // we look for an Android device. If there's one, we use that. Otherwise,
    // we launch a new iOS Simulator.
    Device reusableDevice = devices.firstWhere(
      (Device d) => d.isLocalEmulator,
      orElse: () {
        return devices.firstWhere((Device d) => d is AndroidDevice,
            orElse: () => null);
      }
    );

    if (reusableDevice != null) {
      printStatus('Found connected ${reusableDevice.isLocalEmulator ? "emulator" : "device"} "${reusableDevice.name}"; will reuse it.');
      return reusableDevice;
    }

    // No running emulator found. Attempt to start one.
    printStatus('Starting iOS Simulator, because did not find existing connected devices.');
    bool started = await SimControl.instance.boot();
    if (started) {
      return IOSSimulatorUtils.instance.getAttachedDevices().first;
    } else {
      printError('Failed to start iOS Simulator.');
      return null;
    }
  } else if (os.isLinux) {
    // On Linux, for now, we just grab the first connected device we can find.
    if (devices.isEmpty) {
      printError('No devices found.');
      return null;
    } else if (devices.length > 1) {
      printStatus('Found multiple connected devices:');
      printStatus(devices.map((Device d) => '  - ${d.name}\n').join(''));
    }
    printStatus('Using device ${devices.first.name}.');
    return devices.first;
  } else if (os.isWindows) {
    printError('Windows is not yet supported.');
    return null;
  } else {
    printError('The operating system on this computer is not supported.');
    return null;
  }
}

/// Starts the application on the device given command configuration.
typedef Future<int> AppStarter(DriveCommand command);

AppStarter appStarter = startApp;
void restoreAppStarter() {
  appStarter = startApp;
}

Future<int> startApp(DriveCommand command) async {
  String mainPath = findMainDartFile(command.targetFile);
  if (await fs.type(mainPath) != FileSystemEntityType.FILE) {
    printError('Tried to run $mainPath, but that file does not exist.');
    return 1;
  }

  // TODO(devoncarew): We should remove the need to special case here.
  if (command.device is AndroidDevice) {
    printTrace('Building an APK.');
    int result = await build_apk.buildApk(
      command.device.platform,
      target: command.targetFile,
      buildMode: command.getBuildMode()
    );

    if (result != 0)
      return result;
  }

  printTrace('Stopping previously running application, if any.');
  await appStopper(command);

  printTrace('Installing application package.');
  ApplicationPackage package = command.applicationPackages
      .getPackageForPlatform(command.device.platform);
  if (command.device.isAppInstalled(package))
    command.device.uninstallApp(package);
  command.device.installApp(package);

  Map<String, dynamic> platformArgs = <String, dynamic>{};
  if (command.traceStartup)
    platformArgs['trace-startup'] = command.traceStartup;

  printTrace('Starting application.');

  // Forward device log messages to the terminal window running the "drive" command.
  command._deviceLogSubscription = command.device.logReader.logLines.listen(printStatus);

  LaunchResult result = await command.device.startApp(
    package,
    command.getBuildMode(),
    mainPath: mainPath,
    route: command.route,
    debuggingOptions: new DebuggingOptions.enabled(
      command.getBuildMode(),
      startPaused: true,
      observatoryPort: command.debugPort
    ),
    platformArgs: platformArgs
  );

  if (!result.started) {
    await command._deviceLogSubscription.cancel();
  }

  return result.started ? 0 : 2;
}

/// Runs driver tests.
typedef Future<int> TestRunner(List<String> testArgs);
TestRunner testRunner = runTests;
void restoreTestRunner() {
  testRunner = runTests;
}

Future<int> runTests(List<String> testArgs) async {
  printTrace('Running driver tests.');

  PackageMap.globalPackagesPath = path.normalize(path.absolute(PackageMap.globalPackagesPath));
  List<String> args = testArgs.toList()
    ..add('--packages=${PackageMap.globalPackagesPath}')
    ..add('-rexpanded');
  String dartVmPath = path.join(dartSdkPath, 'bin', 'dart');
  return await runCommandAndStreamOutput(<String>[dartVmPath]..addAll(args));
}


/// Stops the application.
typedef Future<int> AppStopper(DriveCommand command);
AppStopper appStopper = stopApp;
void restoreAppStopper() {
  appStopper = stopApp;
}

Future<int> stopApp(DriveCommand command) async {
  printTrace('Stopping application.');
  ApplicationPackage package = command.applicationPackages.getPackageForPlatform(command.device.platform);
  bool stopped = await command.device.stopApp(package);
  await command._deviceLogSubscription?.cancel();
  return stopped ? 0 : 1;
}
