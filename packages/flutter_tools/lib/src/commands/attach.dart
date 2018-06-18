// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process_manager.dart';
import '../base/utils.dart';
import '../bundle.dart' as bundle;
import '../cache.dart';
import '../device.dart';
import '../fuchsia/fuchsia_device.dart';
import '../globals.dart';
import '../resident_runner.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';
import '../vmservice.dart';

// Usage:
// With an application already running, a HotRunner can be attached to it
// with:
// $ flutter attach --debug-port 12345

final String ipv4Loopback = InternetAddress.loopbackIPv4.address;

class AttachCommand extends FlutterCommand {
  AttachCommand({bool verboseHelp = false}) {
    addBuildModeFlags(defaultToRelease: false);
    argParser.addOption('debug-port',
        help: 'Local port where the observatory is listening.');
  }

  @override
  final String name = 'attach';

  @override
  final String description = 'Attach to a running application.';

  int get observatoryPort {
    if (argResults['debug-port'] == null) return null;
    try {
      return int.parse(argResults['debug-port']);
    } catch (error) {
      throwToolExit('Invalid port for `--debug-port`: $error');
    }
    return null;
  }

  Future<int> listenForObservatoryStart(Device device) async {
    await for (String line in device.getLogReader().logLines) {
      if (line.contains('Observatory listening on http')) {
        Match match = new RegExp(
                r'Observatory listening on http://127\.0\.0\.1:([0-9]+)')
            .firstMatch(line);
        if (match == null) {
          throwToolExit("Couldn't extract observatory port: $line");
          return 0;
        }
        return int.parse(match[1]);
      }
    }
    throwToolExit("Unexpected end of log.");
    return -1;
  }

  @override
  Future<Null> runCommand() async {
    Cache.releaseLockEarly();

    await _validateArguments();

    final Device device = await findTargetDevice();
    var devicePort = observatoryPort;
    if (devicePort == null) {
      devicePort = await listenForObservatoryStart(device);
    }
    int localPort = await device.portForwarder.forward(devicePort);
    device.getLogReader();
    try {
      final FlutterDevice flutterDevice =
          new FlutterDevice(device, trackWidgetCreation: false);
      flutterDevice.observatoryUris = [
        Uri.parse('http://$ipv4Loopback:$localPort/')
      ]; // observatoryUris;
      final HotRunner hotRunner = new HotRunner(
        <FlutterDevice>[flutterDevice],
        debuggingOptions: new DebuggingOptions.enabled(getBuildInfo()),
        packagesFilePath: globalResults['packages'],
      );
      await hotRunner.attach();
    } finally {
      device.portForwarder
          .unforward(new ForwardedPort(localPort, observatoryPort));
    }
  }

  Future<void> _validateArguments() async {}
}
