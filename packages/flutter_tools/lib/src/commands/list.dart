// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.list;

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import '../device.dart';

final Logger _logging = new Logger('sky_tools.list');

class ListCommand extends Command {
  final name = 'list';
  final description = 'List all connected devices.';
  AndroidDevice android;
  IOSDevice ios;

  ListCommand({this.android, this.ios}) {
    argParser.addFlag('details',
        abbr: 'd',
        negatable: false,
        help: 'Log additional details about attached devices.');
  }

  @override
  Future<int> run() async {
    bool details = argResults['details'];
    if (details) {
      print('Android Devices:');
    }
    for (AndroidDevice device in AndroidDevice.getAttachedDevices(android)) {
      if (details) {
        print('${device.id}\t'
            '${device.modelID}\t'
            '${device.productID}\t'
            '${device.deviceCodeName}');
      } else {
        print(device.id);
      }
    }

    if (details) {
      print('iOS Devices:');
    }
    for (IOSDevice device in IOSDevice.getAttachedDevices(ios)) {
      if (details) {
        print('${device.id}\t${device.name}');
      } else {
        print(device.id);
      }
    }

    return 0;
  }
}
