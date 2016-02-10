// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../device.dart';
import '../runner/flutter_command.dart';

class LogsCommand extends FlutterCommand {
  final String name = 'logs';
  final String description = 'Show logs for running Flutter apps.';

  LogsCommand() {
    argParser.addFlag('clear',
      negatable: false,
      abbr: 'c',
      help: 'Clear log history before reading from logs.'
    );
  }

  bool get requiresProjectRoot => false;

  Future<int> runInProject() async {
    DeviceManager deviceManager = new DeviceManager();
    List<Device> devices;

    String deviceId = globalResults['device-id'];
    if (deviceId != null) {
      Device device = await deviceManager.getDeviceById(deviceId);
      if (device == null) {
        printError("No device found with id '$deviceId'.");
        return 1;
      }
      devices = <Device>[device];
    } else {
      devices = await deviceManager.getDevices();
    }

    if (devices.isEmpty) {
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
