// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../cache.dart';
import '../commands/daemon.dart';
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
  AttachCommand({bool verboseHelp = false, this.hotRunnerFactory}) {
    addBuildModeFlags(defaultToRelease: false);
    usesTargetOption();
    usesFilesystemOptions(hide: !verboseHelp);
    argParser
      ..addOption(
        'debug-port',
        help: 'Local port where the observatory is listening.',
      )..addOption(
        'project-root',
        hide: !verboseHelp,
        help: 'Normally used only in run target',
      )..addFlag('machine',
          hide: !verboseHelp,
          negatable: false,
          help: 'Handle machine structured JSON command input and provide output\n'
                'and progress in machine friendly format.',
      );
    hotRunnerFactory ??= HotRunnerFactory();
  }

  HotRunnerFactory hotRunnerFactory;

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
  Future<void> validateCommand() async {
    await super.validateCommand();
    if (await findTargetDevice() == null)
      throwToolExit(null);
    observatoryPort;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();

    await _validateArguments();

    final Device device = await findTargetDevice();
    final int devicePort = observatoryPort;

    final Daemon daemon = argResults['machine']
      ? Daemon(stdinCommandStream, stdoutCommandResponse,
            notifyingLogger: NotifyingLogger(), logToStdout: true)
      : null;

    Uri observatoryUri;
    if (devicePort == null) {
      ProtocolDiscovery observatoryDiscovery;
      try {
        observatoryDiscovery = ProtocolDiscovery.observatory(
          device.getLogReader(),
          portForwarder: device.portForwarder,
        );
        printStatus('Waiting for a connection from Flutter on ${device.name}...');
        observatoryUri = await observatoryDiscovery.uri;
        printStatus('Done.');
      } finally {
        await observatoryDiscovery?.cancel();
      }
    } else {
      final int localPort = await device.portForwarder.forward(devicePort);
      observatoryUri = Uri.parse('http://$ipv4Loopback:$localPort/');
    }
    try {
      final FlutterDevice flutterDevice = FlutterDevice(
        device,
        trackWidgetCreation: false,
        dillOutputPath: argResults['output-dill'],
        fileSystemRoots: argResults['filesystem-root'],
        fileSystemScheme: argResults['filesystem-scheme'],
      );
      flutterDevice.observatoryUris = <Uri>[ observatoryUri ];
      final HotRunner hotRunner = hotRunnerFactory.build(
        <FlutterDevice>[flutterDevice],
        target: targetFile,
        debuggingOptions: DebuggingOptions.enabled(getBuildInfo()),
        packagesFilePath: globalResults['packages'],
        usesTerminalUI: daemon == null,
        projectRootPath: argResults['project-root'],
        dillOutputPath: argResults['output-dill'],
      );

      if (daemon != null) {
        AppInstance app;
        try {
          app = await daemon.appDomain.launch(hotRunner, hotRunner.attach,
              device, null, true, fs.currentDirectory);
        } catch (error) {
          throwToolExit(error.toString());
        }
        final int result = await app.runner.waitForAppToFinish();
        if (result != 0)
          throwToolExit(null, exitCode: result);
      } else {
        await hotRunner.attach();
      }
    } finally {
      final List<ForwardedPort> ports = device.portForwarder.forwardedPorts.toList();
      ports.forEach(device.portForwarder.unforward);
    }
    return null;
  }

  Future<void> _validateArguments() async {}
}

class HotRunnerFactory {
  HotRunner build(List<FlutterDevice> devices, {
      String target,
      DebuggingOptions debuggingOptions,
      bool usesTerminalUI = true,
      bool benchmarkMode = false,
      File applicationBinary,
      bool hostIsIde = false,
      String projectRootPath,
      String packagesFilePath,
      String dillOutputPath,
      bool stayResident = true,
      bool ipv6 = false,
  }) => HotRunner(
    devices,
    target: target,
    debuggingOptions: debuggingOptions,
    usesTerminalUI: usesTerminalUI,
    benchmarkMode: benchmarkMode,
    applicationBinary: applicationBinary,
    hostIsIde: hostIsIde,
    projectRootPath: projectRootPath,
    packagesFilePath: packagesFilePath,
    dillOutputPath: dillOutputPath,
    stayResident: stayResident,
    ipv6: ipv6,
  );
}
