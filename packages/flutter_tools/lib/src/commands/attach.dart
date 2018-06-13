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
        help: 'Local port where the observatory is listening. Required.');
  }

  @override
  final String name = 'attach';

  @override
  final String description = 'Attach to a running application.';

  int get observatoryPort {
    try {
      return int.parse(argResults['debug-port']);
    } catch (error) {
      throwToolExit('Invalid port for `--debug-port`: $error');
    }
    return null;
  }

  @override
  Future<Null> runCommand() async {
    Cache.releaseLockEarly();

    await _validateArguments();

    final Device device = await findTargetDevice();
    final FlutterDevice flutterDevice =
        new FlutterDevice(device, trackWidgetCreation: false);
    flutterDevice.observatoryUris = [
      Uri.parse('http://$ipv4Loopback:$observatoryPort/')
    ]; // observatoryUris;
    final HotRunner hotRunner = new HotRunner(
      <FlutterDevice>[flutterDevice],
      debuggingOptions: new DebuggingOptions.enabled(getBuildInfo()),
      packagesFilePath: globalResults['packages'],
    );
    await hotRunner.attach();
  }

  Future<void> _validateArguments() async {
    if (argResults['debug-port'] == null) {
      throwToolExit("Missing required parameter --debug-port");
    }
  }
}
