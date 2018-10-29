// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/utils.dart';
import '../device.dart';
import '../doctor.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class DevicesCommand extends FlutterCommand {
  @override
  final String name = 'devices';

  @override
  final String description = 'List all connected devices.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!doctor.canListAnything) {
      throwToolExit(
        "Unable to locate a development device; please run 'flutter doctor' for "
        'information about installing additional components.',
        exitCode: 1);
    }

    final List<Device> devices = await deviceManager.getAllConnectedDevices().toList();

    if (devices.isEmpty) {
      printStatus(
        'No devices detected.\n\n'
        "Run 'flutter emulators' to list and start any available device emulators.\n\n"
        'Or, if you expected your device to be detected, please run "flutter doctor" to diagnose '
        'potential issues, or visit https://flutter.io/setup/ for troubleshooting tips.');
      final List<String> diagnostics = await deviceManager.getDeviceDiagnostics();
      if (diagnostics.isNotEmpty) {
        printStatus('');
        for (String diagnostic in diagnostics) {
          printStatus('• $diagnostic', hangingIndent: 2);
        }
      }
    } else {
      printStatus('${devices.length} connected ${pluralize('device', devices.length)}:\n');
      await Device.printDevices(devices);
    }

    return null;
  }
}
