// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:multicast_dns/multicast_dns.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../commands/daemon.dart';
import '../device.dart';
import '../globals.dart';
import '../protocol_discovery.dart';
import '../resident_runner.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';

final String ipv4Loopback = InternetAddress.loopbackIPv4.address;
const String _kDartObservatoryName = '_dartobservatory._tcp.local';

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
    requiresPubspecYaml();
    addBuildModeFlags(defaultToRelease: false);
    usesIsolateFilterOption(hide: !verboseHelp);
    usesTargetOption();
    usesFilesystemOptions(hide: !verboseHelp);
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


  Future<int> mdnsQueryDartObservatoryPort() async {
    final MDnsClient client = MDnsClient();
    try {
      await client.start();
      final List<PtrResourceRecord> pointerRecords = await client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.ptr(_kDartObservatoryName),
          )
          .toList();
      if (pointerRecords.isEmpty) {
        return null;
      }
      // We have no guarantee that we won't get multiple hits from the same
      // service on this.
      final List<String> uniqueDomainNames = pointerRecords
          .map<String>((PtrResourceRecord record) => record.domainName)
          .toSet()
          .toList();
      String domainName;
      if (uniqueDomainNames.length > 1) {
        print('There are multiple observatory ports available:');
        print('');
        for (int i = 0; i < uniqueDomainNames.length; i++) {
          print('  ${i + 1}) '
              '${uniqueDomainNames[i].replaceAll('.$_kDartObservatoryName', '')}');
        }
        print('');
        int selection;
        while (selection == null) {
          stdout.write('Selection [1-${uniqueDomainNames.length}]: ');
          final String selectionString = io.stdin.readLineSync();
          selection = int.tryParse(selectionString);
          if (selection == null ||
              selection < 1 ||
              selection > pointerRecords.length) {
            print('Please enter a valid integer value between '
                '1 and ${uniqueDomainNames.length}.\n');
            selection = null;
          }
        }
        domainName = uniqueDomainNames[selection - 1];
      } else {
        domainName = pointerRecords[0].domainName;
      }
      // Here, if we get more than one, it should just be a duplicate.
      final List<SrvResourceRecord> srv = await client
          .lookup<SrvResourceRecord>(
            ResourceRecordQuery.srv(domainName),
          )
          .toList();
      if (srv.isEmpty) {
        return null;
      }
      return srv.first.port;
    } finally {
      client.stop();
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();

    await _validateArguments();

    writePidFile(argResults['pid-file']);

    final Device device = await findTargetDevice();
    final int devicePort = observatoryPort ?? await mdnsQueryDartObservatoryPort();

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
        viewFilter: argResults['isolate-filter'],
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
