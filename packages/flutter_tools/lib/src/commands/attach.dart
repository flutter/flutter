// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/io.dart';
import '../cache.dart';
import '../device.dart';
import '../globals.dart';
import '../protocol_discovery.dart';
import '../resident_runner.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';

final String ipv4Loopback = InternetAddress.loopbackIPv4.address;

/// A Flutter-command that attaches to applications that have been launched
/// without `flutter run`.
///
/// With an application already running, a HotRunner can be attached to it
/// with:
/// ```
/// $ flutter attach --debug-port 12345
/// ```
///
/// Alternatively, the attach command can start listening and scan for new
/// programs that become active:
/// ```
/// $ flutter attach
/// ```
/// As soon as a new observatory is detected the command attaches to it and
/// enables hot reloading.
class AttachCommand extends FlutterCommand {
  AttachCommand({bool verboseHelp = false}) {
    addBuildModeFlags(defaultToRelease: false);
    argParser.addOption(
        'debug-port',
        help: 'Local port where the observatory is listening.',
    );
    argParser.addFlag(
      'preview-dart-2',
      defaultsTo: true,
      hide: !verboseHelp,
      help: 'Preview Dart 2.0 functionality.',
    );
  }

  @override
  final String name = 'attach';

  @override
  final String description = 'Attach to a running application.';

  int get observatoryPort {
    if (argResults['debug-port'] == null)
      return null;
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
    if (device == null)
      throwToolExit(null);
    final int devicePort = observatoryPort;
    Uri observatoryUri;
    if (devicePort == null) {
      ProtocolDiscovery observatoryDiscovery;
      try {
        observatoryDiscovery = new ProtocolDiscovery.observatory(
            device.getLogReader(), portForwarder: device.portForwarder);
        printStatus('Listening.');
        observatoryUri = await observatoryDiscovery.uri;
      } finally {
        await observatoryDiscovery?.cancel();
      }
    } else {
      final int localPort = await device.portForwarder.forward(devicePort);
      observatoryUri = Uri.parse('http://$ipv4Loopback:$localPort/');
    }
    try {
      final FlutterDevice flutterDevice =
          new FlutterDevice(device, trackWidgetCreation: false, previewDart2: argResults['preview-dart-2']);
      flutterDevice.observatoryUris = <Uri>[ observatoryUri ];
      final HotRunner hotRunner = new HotRunner(
        <FlutterDevice>[flutterDevice],
        debuggingOptions: new DebuggingOptions.enabled(getBuildInfo()),
        packagesFilePath: globalResults['packages'],
      );
      await hotRunner.attach();
    } finally {
      device.portForwarder.forwardedPorts.forEach(device.portForwarder.unforward);
    }
  }

  Future<void> _validateArguments() async {}
}
