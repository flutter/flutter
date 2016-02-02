// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../application_package.dart';
import '../base/context.dart';
import '../build_configuration.dart';
import '../artifacts.dart';
import '../device.dart';
import '../toolchain.dart';
import 'flutter_command_runner.dart';

typedef bool Validator();

abstract class FlutterCommand extends Command {
  FlutterCommandRunner get runner => super.runner;

  /// Whether this command needs to be run from the root of a project.
  bool get requiresProjectRoot => true;

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

  Future<int> run() async {
    if (requiresProjectRoot && !projectRootValidator())
      return 1;
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
    ArtifactStore.validateSkyEnginePackage();
    return true;
  };

  Future<int> runInProject();

  ApplicationPackageStore applicationPackages;
  Toolchain toolchain;
  DeviceStore devices;
}
