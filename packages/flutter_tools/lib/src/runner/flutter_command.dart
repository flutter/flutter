// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../application_package.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../toolchain.dart';
import 'flutter_command_runner.dart';

abstract class FlutterCommand extends Command {
  FlutterCommandRunner get runner => super.runner;

  /// Whether this command needs to be run from the root of a project.
  bool get requiresProjectRoot => true;

  String get projectRootValidationErrorMessage {
    return 'Error: No pubspec.yaml file found.\n'
      'This command should be run from the root of your Flutter project. Do not run\n'
      'this command from the root of your git clone of Flutter.';
  }

  List<BuildConfiguration> get buildConfigurations => runner.buildConfigurations;

  Future downloadApplicationPackages() async {
    if (applicationPackages == null)
      applicationPackages = await ApplicationPackageStore.forConfigs(buildConfigurations);
  }

  Future downloadToolchain() async {
    if (toolchain == null)
      toolchain = await Toolchain.forConfigs(buildConfigurations);
  }

  void connectToDevices() {
    if (devices == null)
      devices = new DeviceStore.forConfigs(buildConfigurations);
  }

  Future downloadApplicationPackagesAndConnectToDevices() async {
    await downloadApplicationPackages();
    connectToDevices();
  }

  void inheritFromParent(FlutterCommand other) {
    applicationPackages = other.applicationPackages;
    toolchain = other.toolchain;
    devices = other.devices;
  }

  Future<int> run() async {
    if (requiresProjectRoot && !validateProjectRoot())
      return 1;
    return await runInProject();
  }

  bool validateProjectRoot() {
    if (!FileSystemEntity.isFileSync('pubspec.yaml')) {
      stderr.writeln(projectRootValidationErrorMessage);
      return false;
    }
    return true;
  }

  Future<int> runInProject();

  ApplicationPackageStore applicationPackages;
  Toolchain toolchain;
  DeviceStore devices;
}
