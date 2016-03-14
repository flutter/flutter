// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../application_package.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../flx.dart' as flx;
import '../globals.dart';
import '../toolchain.dart';
import 'flutter_command_runner.dart';

typedef bool Validator();

abstract class FlutterCommand extends Command {
  @override
  FlutterCommandRunner get runner => super.runner;

  /// Whether this command needs to be run from the root of a project.
  bool get requiresProjectRoot => true;

  /// Whether this command requires a (single) Flutter target device to be connected.
  bool get requiresDevice => false;

  /// Whether this command only applies to Android devices.
  bool get androidOnly => false;

  /// Whether this command allows usage of the 'target' option.
  bool get allowsTarget => _targetOptionSpecified;
  bool _targetOptionSpecified = false;

  List<BuildConfiguration> get buildConfigurations => runner.buildConfigurations;

  Future<Null> downloadToolchain() async {
    toolchain ??= await Toolchain.forConfigs(buildConfigurations);
  }

  Future<Null> downloadApplicationPackages() async {
    applicationPackages ??= await ApplicationPackageStore.forConfigs(buildConfigurations);
  }

  @override
  Future<int> run() {
    Stopwatch stopwatch = new Stopwatch()..start();

    return _run().then((int exitCode) {
      int ms = stopwatch.elapsedMilliseconds;
      printTrace("'flutter $name' took ${ms}ms; exiting with code $exitCode.");
      return exitCode;
    });
  }

  Future<int> _run() async {
    bool _checkRoot = requiresProjectRoot && allowsTarget && !_targetSpecified;
    if (_checkRoot && !projectRootValidator())
      return 1;

    // Ensure at least one toolchain is installed.
    if (requiresDevice && !doctor.canLaunchAnything) {
      printError("Unable to locate a development device; please run 'flutter doctor' "
        "for information about installing additional components.");
      return 1;
    }

    // Validate devices.
    if (requiresDevice) {
      List<Device> devices = await deviceManager.getDevices();

      if (devices.isEmpty && deviceManager.hasSpecifiedDeviceId) {
        printError("No device found with id '${deviceManager.specifiedDeviceId}'.");
        return 1;
      } else if (devices.isEmpty) {
        printStatus('No connected devices.');
        return 1;
      }

      devices = devices.where((Device device) => device.isSupported()).toList();

      if (androidOnly)
        devices = devices.where((Device device) => device.platform == TargetPlatform.android_arm).toList();

      if (devices.isEmpty) {
        printStatus('No supported devices connected.');
        return 1;
      } else if (devices.length > 1) {
        printStatus("More than one device connected; please specify a device with "
          "the '-d <deviceId>' flag.");
        printStatus('');
        devices = await deviceManager.getAllConnectedDevices();
        Device.printDevices(devices);
        return 1;
      } else {
        _deviceForCommand = devices.single;
      }
    }

    return await runInProject();
  }

  // This is a field so that you can modify the value for testing.
  Validator projectRootValidator = () {
    if (!FileSystemEntity.isFileSync('pubspec.yaml')) {
      printError('Error: No pubspec.yaml file found.\n'
        'This command should be run from the root of your Flutter project.\n'
        'Do not run this command from the root of your git clone of Flutter.');
      return false;
    }
    return true;
  };

  Future<int> runInProject();

  // This is caculated in run() if the command has [requiresDevice] specified.
  Device _deviceForCommand;

  Device get deviceForCommand => _deviceForCommand;

  ApplicationPackageStore applicationPackages;
  Toolchain toolchain;

  bool _targetSpecified = false;

  void addTargetOption() {
    argParser.addOption('target',
      abbr: 't',
      callback: (dynamic val) => _targetSpecified = true,
      defaultsTo: flx.defaultMainPath,
      help: 'Target app path / main entry-point file.');
    _targetOptionSpecified = true;
  }
}
