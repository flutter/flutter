// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../application_package.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../globals.dart';
import '../toolchain.dart';
import '../flx.dart' as flx;
import 'flutter_command_runner.dart';

typedef bool Validator();

abstract class FlutterCommand extends Command {
  FlutterCommandRunner get runner => super.runner;

  /// Whether this command needs to be run from the root of a project.
  bool get requiresProjectRoot => !_targetSpecified;

  /// Whether this command requires a (single) Flutter target device to be connected.
  bool get requiresDevice => false;

  /// Whether this command only applies to Android devices.
  bool get androidOnly => false;

  List<BuildConfiguration> get buildConfigurations => runner.buildConfigurations;

  Future downloadToolchain() async {
    toolchain ??= await Toolchain.forConfigs(buildConfigurations);
  }

  Future downloadApplicationPackagesAndConnectToDevices() async {
    await downloadApplicationPackages();
    _connectToDevices();
  }

  Future downloadApplicationPackages() async {
    applicationPackages ??= await ApplicationPackageStore.forConfigs(buildConfigurations);
  }

  void _connectToDevices() {
    devices ??= new DeviceStore.forConfigs(buildConfigurations);
  }

  Future<int> run() {
    Stopwatch stopwatch = new Stopwatch()..start();

    return _run().then((int exitCode) {
      printTrace("'flutter $name' exiting with code $exitCode; "
        "elasped time ${stopwatch.elapsedMilliseconds}ms.");
      return exitCode;
    });
  }

  Future<int> _run() async {
    if (requiresProjectRoot && !projectRootValidator())
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
        devices = devices.where((Device device) => device.platform == TargetPlatform.android).toList();

      // TODO(devoncarew): Switch this to just supporting one connected device?
      if (devices.isEmpty) {
        printStatus('No supported devices connected.');
        return 1;
      }

      _devicesForCommand = await _getDevicesForCommand();
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

  List<Device> get devicesForCommand => _devicesForCommand;

  Device get deviceForCommand {
    // TODO(devoncarew): Switch this to just supporting one connected device?
    return devicesForCommand.isNotEmpty ? devicesForCommand.first : null;
  }

  // This is caculated in run() if the command has [requiresDevice] specified.
  List<Device> _devicesForCommand;

  ApplicationPackageStore applicationPackages;
  Toolchain toolchain;
  DeviceStore devices;

  Future<List<Device>> _getDevicesForCommand() async {
    List<Device> devices = await deviceManager.getDevices();

    if (devices.isEmpty)
      return null;

    if (deviceManager.hasSpecifiedDeviceId) {
      Device device = await deviceManager.getDeviceById(deviceManager.specifiedDeviceId);
      return device == null ? <Device>[] : <Device>[device];
    }

    devices = devices.where((Device device) => device.isSupported()).toList();

    if (androidOnly)
      devices = devices.where((Device device) => device.platform == TargetPlatform.android).toList();

    return devices;
  }

  bool _targetSpecified = false;

  void addTargetOption() {
    argParser.addOption('target',
      abbr: 't',
      callback: (val) => _targetSpecified = true,
      defaultsTo: flx.defaultMainPath,
      help: 'Target app path / main entry-point file.');
  }
}
