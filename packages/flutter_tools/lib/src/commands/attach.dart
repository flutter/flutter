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
import '../compile.dart';
import '../device.dart';
import '../fuchsia/fuchsia_device.dart';
import '../globals.dart';
import '../protocol_discovery.dart';
import '../resident_runner.dart';
import '../run_cold.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';

final String ipv4Loopback = InternetAddress.loopbackIPv4.address;
const String _kDartObservatoryName = '_dartobservatory._tcp.local';

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
    requiresPubspecYaml();
    addBuildModeFlags(defaultToRelease: false);
    usesIsolateFilterOption(hide: !verboseHelp);
    usesTargetOption();
    usesPortOptions();
    usesIpv6Flag();
    usesFilesystemOptions(hide: !verboseHelp);
    usesFuchsiaOptions(hide: !verboseHelp);
    argParser
      ..addOption(
        'debug-port',
        help: 'Local port where the observatory is listening.',
      )..addOption(
        'app-id',
        help: 'The package name (Android) or bundle identifier (iOS) for the application. '
              'This can be specified to avoid being prompted if multiple observatory ports '
              'are advertised.\n'
              'If you have multiple devices or emulators running, you should include the '
              'device hostname as well, e.g. "com.example.myApp@my-iphone".\n'
              'This parameter is case-insensitive.',
      )..addOption(
        'pid-file',
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

  int get debugPort {
    if (argResults['debug-port'] == null)
      return null;
    try {
      return int.parse(argResults['debug-port']);
    } catch (error) {
      throwToolExit('Invalid port for `--debug-port`: $error');
    }
    return null;
  }

  String get appId {
    return argResults['app-id'];
  }

  @override
  Future<void> validateCommand() async {
    await super.validateCommand();
    if (await findTargetDevice() == null)
      throwToolExit(null);
    debugPort;
    if (debugPort == null && argResults.wasParsed(FlutterCommand.ipv6Flag)) {
      throwToolExit(
        'When the --debug-port is unknown, this command determines '
        'the value of --ipv6 on its own.',
      );
    }
    if (debugPort == null && argResults.wasParsed(FlutterCommand.observatoryPortOption)) {
      throwToolExit(
        'When the --debug-port is unknown, this command does not use '
        'the value of --observatory-port.',
      );
    }
  }


  Future<int> mdnsQueryDartObservatoryPort() async {
    final MDnsClient client = MDnsClient();
    printStatus('Checking for advertised Dart observatories...');
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
      if (appId != null) {
        for (String name in uniqueDomainNames) {
          if (name.toLowerCase().startsWith(appId.toLowerCase())) {
            domainName = name;
            break;
          }
        }
        throwToolExit('Did not find a observatory port advertised for $appId.');
      } else if (uniqueDomainNames.length > 1) {
        printStatus('There are multiple observatory ports available:');
        printStatus('');
        for (int i = 0; i < uniqueDomainNames.length; i++) {
          printStatus(
            '${i + 1}) ${uniqueDomainNames[i].replaceAll('.$_kDartObservatoryName', '')}',
            indent: 2,
          );
        }
        printStatus('');
        int selection;
        while (selection == null) {
          printStatus('Selection [1-${uniqueDomainNames.length}]: ', newline: false);
          final String selectionString = io.stdin.readLineSync();
          selection = int.tryParse(selectionString);
          if (selection == null ||
              selection < 1 ||
              selection > pointerRecords.length) {
            printStatus('Please enter a valid integer value between '
                '1 and ${uniqueDomainNames.length}.\n');
            selection = null;
          }
        }
        domainName = uniqueDomainNames[selection - 1];
      } else {
        domainName = pointerRecords[0].domainName;
      }
      printStatus('Checking for available port on $domainName');
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
    final int devicePort = debugPort ?? await mdnsQueryDartObservatoryPort();

    final Daemon daemon = argResults['machine']
      ? Daemon(stdinCommandStream, stdoutCommandResponse,
            notifyingLogger: NotifyingLogger(), logToStdout: true)
      : null;

    Uri observatoryUri;
    bool usesIpv6 = false;
    bool attachLogger = false;
    if (devicePort == null) {
      if (device is FuchsiaDevice) {
        attachLogger = true;
        final String module = argResults['module'];
        if (module == null)
          throwToolExit('\'--module\' is required for attaching to a Fuchsia device');
        usesIpv6 = device.ipv6;
        FuchsiaIsolateDiscoveryProtocol isolateDiscoveryProtocol;
        try {
          isolateDiscoveryProtocol = device.getIsolateDiscoveryProtocol(module);
          observatoryUri = await isolateDiscoveryProtocol.uri;
          printStatus('Done.'); // FYI, this message is used as a sentinel in tests.
        } catch (_) {
          isolateDiscoveryProtocol?.dispose();
          final List<ForwardedPort> ports = device.portForwarder.forwardedPorts.toList();
          for (ForwardedPort port in ports) {
            await device.portForwarder.unforward(port);
          }
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
          // Determine ipv6 status from the scanned logs.
          usesIpv6 = observatoryDiscovery.ipv6;
          printStatus('Done.'); // FYI, this message is used as a sentinel in tests.
        } finally {
          await observatoryDiscovery?.cancel();
        }
      }
    } else {
      usesIpv6 = ipv6;
      final int localPort = observatoryPort
        ?? await device.portForwarder.forward(devicePort);
      observatoryUri = usesIpv6
        ? Uri.parse('http://[$ipv6Loopback]:$localPort/')
        : Uri.parse('http://$ipv4Loopback:$localPort/');
    }
    try {
      final bool useHot = getBuildInfo().isDebug;
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
      final List<FlutterDevice> flutterDevices =  <FlutterDevice>[flutterDevice];
      final DebuggingOptions debuggingOptions = DebuggingOptions.enabled(getBuildInfo());
      final ResidentRunner runner = useHot ?
          hotRunnerFactory.build(
            flutterDevices,
            target: targetFile,
            debuggingOptions: debuggingOptions,
            packagesFilePath: globalResults['packages'],
            usesTerminalUI: daemon == null,
            projectRootPath: argResults['project-root'],
            dillOutputPath: argResults['output-dill'],
            ipv6: usesIpv6,
          )
        : ColdRunner(
            flutterDevices,
            target: targetFile,
            debuggingOptions: debuggingOptions,
            ipv6: usesIpv6,
          );
      if (attachLogger) {
        flutterDevice.startEchoingDeviceLog();
      }

      int result;
      if (daemon != null) {
        AppInstance app;
        try {
          app = await daemon.appDomain.launch(
            runner,
            runner.attach,
            device,
            null,
            true,
            fs.currentDirectory,
          );
        } catch (error) {
          throwToolExit(error.toString());
        }
        result = await app.runner.waitForAppToFinish();
        assert(result != null);
      } else {
        result = await runner.attach();
        assert(result != null);
      }
      if (result != 0)
        throwToolExit(null, exitCode: result);
    } finally {
      final List<ForwardedPort> ports = device.portForwarder.forwardedPorts.toList();
      for (ForwardedPort port in ports) {
        await device.portForwarder.unforward(port);
      }
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
