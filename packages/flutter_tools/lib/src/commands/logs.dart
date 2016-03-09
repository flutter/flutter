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

  bool get requiresDevice => true;

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

    List<DeviceLogReader> readers = new List<DeviceLogReader>();
    for (Device device in devices) {
      if (clear)
        device.clearLogs();

      readers.add(device.logReader);
    }

    printStatus('Showing ${readers.join(', ')} logs:');

    List<int> results = await Future.wait(readers.map((DeviceLogReader reader) async {
      if (!reader.isReading) {
        // Start reading.
        await reader.start();
      }
      StreamSubscription subscription = reader.lines.listen((String line) {
        if (devices.length > 1) {
          // Prefix with the name of the device.
          printStatus('[${reader.name}] $line');
        } else {
          printStatus(line);
        }
      });
      // Wait for the log reader to be finished.
      int result = await reader.finished;
      subscription.cancel();
      if (result != 0)
        printError('Error listening to $reader logs.');
      return result;
    }));

    // If all readers failed, return an error.
    return results.every((int result) => result != 0) ? 1 : 0;
  }
}
