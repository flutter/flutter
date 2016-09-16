// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/utils.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class DevicesCommand extends FlutterCommand {
  @override
  final String name = 'devices';

  @override
  final String description = 'List all connected devices.';

  @override
  Future<int> runCommand() async {
    if (!doctor.canListAnything) {
      printError("Unable to locate a development device; please run 'flutter doctor' for "
        "information about installing additional components.");
      return 1;
    }

    List<Device> devices = await deviceManager.getAllConnectedDevices();

    if (devices.isEmpty) {
      printStatus(
        'No devices detected.\n\n'
        'If you expected your device to be detected, please run "flutter doctor" to diagnose\n'
        'potential issues, or visit https://flutter.io/setup/ for troubleshooting tips.');
    } else {
      printStatus('${devices.length} connected ${pluralize('device', devices.length)}:\n');
      Device.printDevices(devices);
    }

    return 0;
  }
}
