// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../commands/daemon.dart';
import '../compile.dart';
import '../device.dart';
import '../fuchsia/fuchsia_device.dart';
import '../globals.dart';
import '../ios/devices.dart';
import '../ios/simulators.dart';
import '../mdns_discovery.dart';
import '../project.dart';
import '../protocol_discovery.dart';
import '../resident_runner.dart';
import '../run_cold.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';

/// A Flutter-command that attaches to applications that have been launched
/// without `flutter run`.
///
/// With an application already running, a HotRunner can be attached to it
/// with:
/// ```
/// $ flutter attach --debug-uri http://127.0.0.1:12345/QqL7EFEDNG0=/
/// ```
///
/// If `--disable-service-auth-codes` was provided to the application at startup
/// time, a HotRunner can be attached with just a port:
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
    usesPortOptions();
    usesIpv6Flag();
    usesFilesystemOptions(hide: !verboseHelp);
    usesFuchsiaOptions(hide: !verboseHelp);
    usesDartDefines();
    argParser
      ..addOption(
        'debug-port',
        hide: !verboseHelp,
        help: 'Device port where the observatory is listening. Requires '
        '--disable-service-auth-codes to also be provided to the Flutter '
        'application at launch, otherwise this command will fail to connect to '
        'the application. In general, --debug-uri should be used instead.',
      )..addOption(
        'debug-uri',
        help: 'The URI at which the observatory is listening.',
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
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
    hotRunnerFactory ??= HotRunnerFactory();
  }

  HotRunnerFactory hotRunnerFactory;

  @override
  final String name = 'attach';

  @override
  final String description = 'Attach to a running application.';

  int get debugPort {
    if (argResults['debug-port'] == null) {
      return null;
    }
    try {
      return int.parse(argResults['debug-port']);
    } catch (error) {
      throwToolExit('Invalid port for `--debug-port`: $error');
    }
    return null;
  }

  Uri get debugUri {
    if (argResults['debug-uri'] == null) {
      return null;
    }
    final Uri uri = Uri.parse(argResults['debug-uri']);
    if (!uri.hasPort) {
      throwToolExit('Port not specified for `--debug-uri`: $uri');
    }
    return uri;
  }

  String get appId {
    return argResults['app-id'];
  }

  @override
  Future<void> validateCommand() async {
    await super.validateCommand();
    if (await findTargetDevice() == null) {
      throwToolExit(null);
    }
    debugPort;
    if (debugPort == null && debugUri == null && argResults.wasParsed(FlutterCommand.ipv6Flag)) {
      throwToolExit(
        'When the --debug-port or --debug-uri is unknown, this command determines '
        'the value of --ipv6 on its own.',
      );
    }
    if (debugPort == null && debugUri == null && argResults.wasParsed(FlutterCommand.observatoryPortOption)) {
      throwToolExit(
        'When the --debug-port or --debug-uri is unknown, this command does not use '
        'the value of --observatory-port.',
      );
    }
    if (debugPort != null && debugUri != null) {
      throwToolExit(
        'Either --debugPort or --debugUri can be provided, not both.');
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();

    await _validateArguments();

    writePidFile(argResults['pid-file']);

    final Device device = await findTargetDevice();

    final Artifacts artifacts = device.artifactOverrides ?? Artifacts.instance;
    await context.run<void>(
      body: () => _attachToDevice(device),
      overrides: <Type, Generator>{
        Artifacts: () => artifacts,
    });

    return null;
  }

  Future<void> _attachToDevice(Device device) async {
    final FlutterProject flutterProject = FlutterProject.current();
    Future<int> getDevicePort() async {
      if (debugPort != null) {
        return debugPort;
      }
      // This call takes a non-trivial amount of time, and only iOS devices and
      // simulators support it.
      // If/when we do this on Android or other platforms, we can update it here.
      if (device is IOSDevice || device is IOSSimulator) {
      }
      return null;
    }
    final int devicePort = await getDevicePort();

    final Daemon daemon = argResults['machine']
      ? Daemon(stdinCommandStream, stdoutCommandResponse,
            notifyingLogger: NotifyingLogger(), logToStdout: true)
      : null;

    Uri observatoryUri;
    bool usesIpv6 = ipv6;
    final String ipv6Loopback = InternetAddress.loopbackIPv6.address;
    final String ipv4Loopback = InternetAddress.loopbackIPv4.address;
    final String hostname = usesIpv6 ? ipv6Loopback : ipv4Loopback;

    bool attachLogger = false;
    if (devicePort == null && debugUri == null) {
      if (device is FuchsiaDevice) {
        attachLogger = true;
        final String module = argResults['module'];
        if (module == null) {
          throwToolExit('\'--module\' is required for attaching to a Fuchsia device');
        }
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
      } else if ((device is IOSDevice) || (device is IOSSimulator)) {
        observatoryUri = await MDnsObservatoryDiscovery.instance.getObservatoryUri(
          appId,
          device,
          usesIpv6,
        );
      }
      // If MDNS discovery fails or we're not on iOS, fallback to ProtocolDiscovery.
      if (observatoryUri == null) {
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
        } catch (error) {
          throwToolExit('Failed to establish a debug connection with ${device.name}: $error');
        } finally {
          await observatoryDiscovery?.cancel();
        }
      }
    } else {
      observatoryUri = await buildObservatoryUri(
        device,
        debugUri?.host ?? hostname,
        devicePort ?? debugUri.port,
        observatoryPort,
        debugUri?.path,
      );
    }
    try {
      final bool useHot = getBuildInfo().isDebug;
      final FlutterDevice flutterDevice = await FlutterDevice.create(
        device,
        flutterProject: flutterProject,
        trackWidgetCreation: argResults['track-widget-creation'],
        fileSystemRoots: argResults['filesystem-root'],
        fileSystemScheme: argResults['filesystem-scheme'],
        viewFilter: argResults['isolate-filter'],
        target: argResults['target'],
        targetModel: TargetModel(argResults['target-model']),
        buildMode: getBuildMode(),
        dartDefines: dartDefines,
      );
      flutterDevice.observatoryUris = <Uri>[ observatoryUri ];
      final List<FlutterDevice> flutterDevices =  <FlutterDevice>[flutterDevice];
      final DebuggingOptions debuggingOptions = DebuggingOptions.enabled(getBuildInfo());
      terminal.usesTerminalUi = daemon == null;
      final ResidentRunner runner = useHot ?
          hotRunnerFactory.build(
            flutterDevices,
            target: targetFile,
            debuggingOptions: debuggingOptions,
            packagesFilePath: globalResults['packages'],
            projectRootPath: argResults['project-root'],
            dillOutputPath: argResults['output-dill'],
            ipv6: usesIpv6,
            flutterProject: flutterProject,
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
            LaunchMode.attach,
          );
        } catch (error) {
          throwToolExit(error.toString());
        }
        result = await app.runner.waitForAppToFinish();
        assert(result != null);
      } else {
        final Completer<void> onAppStart = Completer<void>.sync();
        unawaited(onAppStart.future.whenComplete(() {
          TerminalHandler(runner)
            ..setupTerminal()
            ..registerSignalHandlers();
        }));
        result = await runner.attach(
          appStartedCompleter: onAppStart,
        );
        assert(result != null);
      }
      if (result != 0) {
        throwToolExit(null, exitCode: result);
      }
    } finally {
      final List<ForwardedPort> ports = device.portForwarder.forwardedPorts.toList();
      for (ForwardedPort port in ports) {
        await device.portForwarder.unforward(port);
      }
    }
  }

  Future<void> _validateArguments() async { }
}

class HotRunnerFactory {
  HotRunner build(
    List<FlutterDevice> devices, {
    String target,
    DebuggingOptions debuggingOptions,
    bool benchmarkMode = false,
    File applicationBinary,
    bool hostIsIde = false,
    String projectRootPath,
    String packagesFilePath,
    String dillOutputPath,
    bool stayResident = true,
    bool ipv6 = false,
    FlutterProject flutterProject,
  }) => HotRunner(
    devices,
    target: target,
    debuggingOptions: debuggingOptions,
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
