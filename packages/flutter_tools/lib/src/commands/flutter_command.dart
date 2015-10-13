// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';

import '../application_package.dart';
import '../device.dart';
import '../toolchain.dart';
import 'flutter_command_runner.dart';

abstract class FlutterCommand extends Command {
  FlutterCommandRunner get runner => super.runner;

  Future downloadApplicationPackages() async {
    if (applicationPackages == null)
      applicationPackages = await ApplicationPackageStore.forConfigs(runner.buildConfigurations);
  }

  Future downloadToolchain() async {
    if (toolchain == null)
      toolchain = await Toolchain.forConfigs(runner.buildConfigurations);
  }

  void connectToDevices() {
    if (devices == null)
      devices = new DeviceStore.forConfigs(runner.buildConfigurations);
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

  ApplicationPackageStore applicationPackages;
  Toolchain toolchain;
  DeviceStore devices;
}
