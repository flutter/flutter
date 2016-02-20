// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
      printStatus('${devices.length} connected ${pluralize('device', devices.length)}:');

      for (Device device in devices) {
        printStatus('\t${_supportIndicator(device)}: ${device.name} (${device.id})');
        if (!device.isSupported()) {
          printStatus("\t\t${device.supportMessage()}");
        }
      }
    }

    return 0;
  }
}

String _supportIndicator(Device device) => device.isSupported() ? "[✔] Supported" : "[✘] Unsupported";

String pluralize(String word, int count) => count == 1 ? word : word + 's';
