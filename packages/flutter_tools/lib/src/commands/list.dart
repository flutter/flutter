// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../device.dart';
import '../runner/flutter_command.dart';

class ListCommand extends FlutterCommand {
  final String name = 'list';
  final String description = 'List all connected devices.';

  bool get requiresProjectRoot => false;

  Future<int> runInProject() async {
    DeviceManager deviceManager = new DeviceManager();

    List<Device> devices = await deviceManager.getDevices();

    if (devices.isEmpty) {
      print('No connected devices.');
    } else {
      print('${devices.length} connected ${pluralize('device', devices.length)}:');
      print('');
      for (Device device in devices) {
        print('${device.name} (${device.id})');
      }
    }

    return 0;
  }
}

String pluralize(String word, int count) => count == 1 ? word : word + 's';
