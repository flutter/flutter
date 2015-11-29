// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../device.dart';
import '../runner/flutter_command.dart';

class ListCommand extends FlutterCommand {
  final String name = 'list';
  final String description = 'List all connected devices.';

  ListCommand() {
    argParser.addFlag('details',
        abbr: 'd',
        negatable: false,
        help: 'Log additional details about attached devices.');
  }

  @override
  Future<int> runInProject() async {
    connectToDevices();

    bool details = argResults['details'];

    if (details)
      print('Android Devices:');

    for (AndroidDevice device in AndroidDevice.getAttachedDevices(devices.android)) {
      if (details) {
        print('${device.id}\t'
            '${device.modelID}\t'
            '${device.productID}\t'
            '${device.deviceCodeName}');
      } else {
        print(device.id);
      }
    }

    if (details)
      print('iOS Devices:');

    for (IOSDevice device in IOSDevice.getAttachedDevices(devices.iOS)) {
      if (details) {
        print('${device.id}\t${device.name}');
      } else {
        print(device.id);
      }
    }

    if (details) {
      print('iOS Simulators:');
    }
    for (IOSSimulator device in IOSSimulator.getAttachedDevices(devices.iOSSimulator)) {
      if (details) {
        print('${device.id}\t${device.name}');
      } else {
        print(device.id);
      }
    }

    return 0;
  }
}
