// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../commands/daemon.dart';
import '../compile.dart';
import '../device.dart';
import '../fuchsia/fuchsia_device.dart';
import '../globals.dart';
import '../protocol_discovery.dart';
import '../resident_runner.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';

final String ipv4Loopback = InternetAddress.loopbackIPv4.address;

final String ipv6Loopback = InternetAddress.loopbackIPv6.address;

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
///
/// To attach to a flutter mod running on a fuchsia device, `--module` must
/// also be provided.
class AttachCommand extends FlutterCommand {
  AttachCommand({bool verboseHelp = false, this.hotRunnerFactory}) {
    addBuildModeFlags(defaultToRelease: false);
    usesIsolateFilterOption(hide: !verboseHelp);
    usesTargetOption();
    usesFilesystemOptions(hide: !verboseHelp);
    usesFuchsiaOptions(hide: !verboseHelp);
    argParser
      ..addOption(
        'debug-port',
        help: 'Local port where the observatory is listening.',
      )..addOption('pid-file',
        help: 'Specify a file to write the process id to. '
              'You can send SIGUSR1 to trigger a hot reload '
              'and SIGUSR2 to trigger a hot restart.',
      )..addOption(
        'project-root',
        hide: !verboseHelp,
        help: 'Normally used only in run target',
      )..addFlag('machine',
        hide: !verboseHelp,
        negatable: false,
        help: 'Handle machine structured JSON command input and provide output '
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

    writePidFile(argResults['pid-file']);

    final Device device = await findTargetDevice();
    final int devicePort = observatoryPort;

    final Daemon daemon = argResults['machine']
      ? Daemon(stdinCommandStream, stdoutCommandResponse,
            notifyingLogger: NotifyingLogger(), logToStdout: true)
      : null;

    Uri observatoryUri;
    bool ipv6 = false;
    bool attachLogger = false;
    if (devicePort == null) {
      if (device is FuchsiaDevice) {
        attachLogger = true;
        final String module = argResults['module'];
        if (module == null) {
          throwToolExit('\'--module\' is requried for attaching to a Fuchsia device');
        }
        ipv6 = _isIpv6(device.id);
        final List<int> ports = await device.servicePorts();
        if (ports.isEmpty) {
          throwToolExit('No active service ports on ${device.name}');
        }
        final List<int> localPorts = <int>[];
        for (int port in ports) {
          localPorts.add(await device.portForwarder.forward(port));
        }
        final Status status = logger.startProgress(
          'Waiting for a connection from Flutter on ${device.name}...',
          expectSlowOperation: true,
        );
        try {
          final int localPort = await device.findIsolatePort(module, localPorts);
          if (localPort == null) {
            throwToolExit('No active Observatory running module \'$module\' on ${device.name}');
          }
          observatoryUri = ipv6
            ? Uri.parse('http://[$ipv6Loopback]:$localPort/')
            : Uri.parse('http://$ipv4Loopback:$localPort/');
          status.stop();
        } catch (_) {
          status.cancel();
          rethrow;
        }
      } else {
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
        viewFilter: argResults['isolate-filter'],
        targetModel: TargetModel(argResults['target-model']),
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
        ipv6: ipv6,
      );
      if (attachLogger) {
        flutterDevice.startEchoingDeviceLog();
      }

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
      for (ForwardedPort port in ports) {
        await device.portForwarder.unforward(port);
      }
    }
    return null;
  }

  Future<void> _validateArguments() async {}

  bool _isIpv6(String address) {
    // Workaround for https://github.com/dart-lang/sdk/issues/29456
    final String fragment = address.split('%').first;
    try {
      Uri.parseIPv6Address(fragment);
      return true;
    } on FormatException {
      return false;
    }
  }
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
