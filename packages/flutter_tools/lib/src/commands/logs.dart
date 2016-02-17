// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class LogsCommand extends FlutterCommand {
  final String name = 'logs';
  final String description = 'Show log output for running Flutter apps.';

  LogsCommand() {
    argParser.addFlag('clear',
      negatable: false,
      abbr: 'c',
      help: 'Clear log history before reading from logs.'
    );
  }

  bool get requiresProjectRoot => false;

  Future<int> runInProject() async {
    List<Device> devices = await deviceManager.getDevices();

    if (devices.isEmpty && deviceManager.hasSpecifiedDeviceId) {
      printError("No device found with id '${deviceManager.specifiedDeviceId}'.");
      return 1;
    } else if (devices.isEmpty) {
      printStatus('No connected devices.');
      return 0;
    }

    bool clear = argResults['clear'];

    Set<DeviceLogReader> readers = new Set<DeviceLogReader>();
    for (Device device in devices) {
      readers.add(device.createLogReader());
    }

    printStatus('Showing logs for ${readers.join(', ')}:');

    List<int> results = await Future.wait(readers.map((DeviceLogReader reader) async {
      int result = await reader.logs(clear: clear);
      if (result != 0)
        printError('Error listening to $reader logs.');
      return result;
    }));

    // If all readers failed, return an error.
    return results.every((int result) => result != 0) ? 1 : 0;
  }
}
