// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/utils.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class DevicesCommand extends FlutterCommand {
  final String name = 'devices';
  final String description = 'List all connected devices.';
  final List<String> aliases = <String>['list'];

  bool get requiresProjectRoot => false;

  Future<int> runInProject() async {
    if (!doctor.canListAnything) {
      printError("Unable to locate a development device; please run 'flutter doctor' for "
        "information about installing additional components.");
      return 1;
    }

    List<Device> devices = await deviceManager.getAllConnectedDevices();

    if (devices.isEmpty) {
      printStatus('No connected devices.');
    } else {
      printStatus('${devices.length} connected ${pluralize('device', devices.length)}:\n');

      for (Device device in devices) {
        String supportIndicator = device.isSupported() ? '' : ' - unsupported';
        printStatus('${device.name} (${device.id})$supportIndicator');
      }
    }

    return 0;
  }
}
