// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart';

import '../android/android_device.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import  '../build_info.dart';
import '../commands/daemon.dart';
import '../compile.dart';
import '../device.dart';
import '../fuchsia/fuchsia_device.dart';
import '../globals.dart' as globals;
import '../ios/devices.dart';
import '../ios/simulators.dart';
import '../mdns_discovery.dart';
import '../project.dart';
import '../protocol_discovery.dart';
import '../resident_runner.dart';
import '../run_cold.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';
import '../vmservice.dart';

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
    addBuildModeFlags(verboseHelp: verboseHelp, defaultToRelease: false, excludeRelease: true);
    usesTargetOption();
    usesPortOptions(verboseHelp: verboseHelp);
    usesIpv6Flag(verboseHelp: verboseHelp);
    usesFilesystemOptions(hide: !verboseHelp);
    usesFuchsiaOptions(hide: !verboseHelp);
    usesDartDefineOption();
    usesDeviceUserOption();
    addEnableExperimentation(hide: !verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    argParser
      ..addOption(
        'debug-port',
        hide: !verboseHelp,
        help: '(deprecated) Device port where the observatory is listening. Requires '
              '"--disable-service-auth-codes" to also be provided to the Flutter '
              'application at launch, otherwise this command will fail to connect to '
              'the application. In general, "--debug-uri" should be used instead.',
      )..addOption(
        'debug-uri', // TODO(ianh): we should support --debug-url as well (leaving this as an alias).
        help: 'The URL at which the observatory is listening.',
      )..addOption(
        'app-id',
        help: 'The package name (Android) or bundle identifier (iOS) for the app. '
              'This can be specified to avoid being prompted if multiple observatory ports '
              'are advertised.\n'
              'If you have multiple devices or emulators running, you should include the '
              'device hostname as well, e.g. "com.example.myApp@my-iphone".\n'
              'This parameter is case-insensitive.',
      )..addOption(
        'pid-file',
        help: 'Specify a file to write the process ID to. '
              'You can send SIGUSR1 to trigger a hot reload '
              'and SIGUSR2 to trigger a hot restart. '
              'The file is created when the signal handlers '
              'are hooked and deleted when they are removed.',
      )..addFlag(
        'report-ready',
        help: 'Print "ready" to the console after handling a keyboard command.\n'
              'This is primarily useful for tests and other automation, but consider '
              'using "--machine" instead.',
        hide: !verboseHelp,
      )..addOption(
        'project-root',
        hide: !verboseHelp,
        help: 'Normally used only in run target.',
      )..addFlag('machine',
        hide: !verboseHelp,
        negatable: false,
        help: 'Handle machine structured JSON command input and provide output '
              'and progress in machine-friendly format.',
      );
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
    addDdsOptions(verboseHelp: verboseHelp);
    addDevToolsOptions(verboseHelp: verboseHelp);
    usesDeviceTimeoutOption();
    hotRunnerFactory ??= HotRunnerFactory();
  }

  HotRunnerFactory hotRunnerFactory;

  @override
  final String name = 'attach';

  @override
  final String description = r'''
Attach to a running app.

For attaching to Android or iOS devices, simply using `flutter attach` is
usually sufficient. The tool will search for a running Flutter app or module,
if available. Otherwise, the tool will wait for the next Flutter app or module
to launch before attaching.

For Fuchsia, the module name must be provided, e.g. `$flutter attach
--module=mod_name`. This can be called either before or after the application
is started.

If the app or module is already running and the specific observatory port is
known, it can be explicitly provided to attach via the command-line, e.g.
`$ flutter attach --debug-port 12345`''';

  int get debugPort {
    if (argResults['debug-port'] == null) {
      return null;
    }
    try {
      return int.parse(stringArg('debug-port'));
    } on Exception catch (error) {
      throwToolExit('Invalid port for `--debug-port`: $error');
    }
    return null;
  }

  Uri get debugUri {
    if (argResults['debug-uri'] == null) {
      return null;
    }
    final Uri uri = Uri.tryParse(stringArg('debug-uri'));
    if (uri == null) {
      throwToolExit('Invalid `--debug-uri`: ${stringArg('debug-uri')}');
    }
    if (!uri.hasPort) {
      throwToolExit('Port not specified for `--debug-uri`: $uri');
    }
    return uri;
  }

  String get appId {
    return stringArg('app-id');
  }

  String get userIdentifier => stringArg(FlutterOptions.kDeviceUser);

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

    if (userIdentifier != null) {
      final Device device = await findTargetDevice();
      if (device is! AndroidDevice) {
        throwToolExit('--${FlutterOptions.kDeviceUser} is only supported for Android');
      }
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    await _validateArguments();

    final Device device = await findTargetDevice();

    final Artifacts overrideArtifacts = device.artifactOverrides ?? globals.artifacts;
    await context.run<void>(
      body: () => _attachToDevice(device),
      overrides: <Type, Generator>{
        Artifacts: () => overrideArtifacts,
      },
    );

    return FlutterCommandResult.success();
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

    final Daemon daemon = boolArg('machine')
      ? Daemon(
          stdinCommandStream,
          stdoutCommandResponse,
          notifyingLogger: (globals.logger is NotifyingLogger)
            ? globals.logger as NotifyingLogger
            : NotifyingLogger(verbose: globals.logger.isVerbose, parent: globals.logger),
          logToStdout: true,
        )
      : null;

    Stream<Uri> observatoryUri;
    bool usesIpv6 = ipv6;
    final String ipv6Loopback = InternetAddress.loopbackIPv6.address;
    final String ipv4Loopback = InternetAddress.loopbackIPv4.address;
    final String hostname = usesIpv6 ? ipv6Loopback : ipv4Loopback;

    if (devicePort == null && debugUri == null) {
      if (device is FuchsiaDevice) {
        final String module = stringArg('module');
        if (module == null) {
          throwToolExit("'--module' is required for attaching to a Fuchsia device");
        }
        usesIpv6 = device.ipv6;
        FuchsiaIsolateDiscoveryProtocol isolateDiscoveryProtocol;
        try {
          isolateDiscoveryProtocol = device.getIsolateDiscoveryProtocol(module);
          observatoryUri = Stream<Uri>.value(await isolateDiscoveryProtocol.uri).asBroadcastStream();
        } on Exception {
          isolateDiscoveryProtocol?.dispose();
          final List<ForwardedPort> ports = device.portForwarder.forwardedPorts.toList();
          for (final ForwardedPort port in ports) {
            await device.portForwarder.unforward(port);
          }
          rethrow;
        }
      } else if ((device is IOSDevice) || (device is IOSSimulator)) {
        final Uri uriFromMdns =
          await MDnsObservatoryDiscovery.instance.getObservatoryUri(
            appId,
            device,
            usesIpv6: usesIpv6,
            deviceVmservicePort: deviceVmservicePort,
          );
        observatoryUri = uriFromMdns == null
          ? null
          : Stream<Uri>.value(uriFromMdns).asBroadcastStream();
      }
      // If MDNS discovery fails or we're not on iOS, fallback to ProtocolDiscovery.
      if (observatoryUri == null) {
        final ProtocolDiscovery observatoryDiscovery =
          ProtocolDiscovery.observatory(
            // If it's an Android device, attaching relies on past log searching
            // to find the service protocol.
            await device.getLogReader(includePastLogs: device is AndroidDevice),
            portForwarder: device.portForwarder,
            ipv6: ipv6,
            devicePort: deviceVmservicePort,
            hostPort: hostVmservicePort,
          );
        globals.printStatus('Waiting for a connection from Flutter on ${device.name}...');
        observatoryUri = observatoryDiscovery.uris;
        // Determine ipv6 status from the scanned logs.
        usesIpv6 = observatoryDiscovery.ipv6;
      }
    } else {
      observatoryUri = Stream<Uri>
        .fromFuture(
          buildObservatoryUri(
            device,
            debugUri?.host ?? hostname,
            devicePort ?? debugUri.port,
            hostVmservicePort,
            debugUri?.path,
          )
        ).asBroadcastStream();
    }

    globals.terminal.usesTerminalUi = daemon == null;

    try {
      int result;
      if (daemon != null) {
        final ResidentRunner runner = await createResidentRunner(
          observatoryUris: observatoryUri,
          device: device,
          flutterProject: flutterProject,
          usesIpv6: usesIpv6,
        );
        AppInstance app;
        try {
          app = await daemon.appDomain.launch(
            runner,
            ({Completer<DebugConnectionInfo> connectionInfoCompleter,
              Completer<void> appStartedCompleter}) {
              return runner.attach(
                connectionInfoCompleter: connectionInfoCompleter,
                appStartedCompleter: appStartedCompleter,
                allowExistingDdsInstance: true,
                enableDevTools: boolArg(FlutterCommand.kEnableDevTools),
              );
            },
            device,
            null,
            true,
            globals.fs.currentDirectory,
            LaunchMode.attach,
            globals.logger as AppRunLogger,
          );
        } on Exception catch (error) {
          throwToolExit(error.toString());
        }
        result = await app.runner.waitForAppToFinish();
        assert(result != null);
        return;
      }
      while (true) {
        final ResidentRunner runner = await createResidentRunner(
          observatoryUris: observatoryUri,
          device: device,
          flutterProject: flutterProject,
          usesIpv6: usesIpv6,
        );
        final Completer<void> onAppStart = Completer<void>.sync();
        TerminalHandler terminalHandler;
        unawaited(onAppStart.future.whenComplete(() {
          terminalHandler = TerminalHandler(
            runner,
            logger: globals.logger,
            terminal: globals.terminal,
            signals: globals.signals,
            processInfo: processInfo,
            reportReady: boolArg('report-ready'),
            pidFile: stringArg('pid-file'),
          )
            ..registerSignalHandlers()
            ..setupTerminal();
        }));
        result = await runner.attach(
          appStartedCompleter: onAppStart,
          allowExistingDdsInstance: true,
          enableDevTools: boolArg(FlutterCommand.kEnableDevTools),
        );
        if (result != 0) {
          throwToolExit(null, exitCode: result);
        }
        terminalHandler?.stop();
        assert(result != null);
        if (runner.exited || !runner.isWaitingForObservatory) {
          break;
        }
        globals.printStatus('Waiting for a new connection from Flutter on ${device.name}...');
      }
    } on RPCError catch (err) {
      if (err.code == RPCErrorCodes.kServiceDisappeared) {
        throwToolExit('Lost connection to device.');
      }
      rethrow;
    } finally {
      final List<ForwardedPort> ports = device.portForwarder.forwardedPorts.toList();
      for (final ForwardedPort port in ports) {
        await device.portForwarder.unforward(port);
      }
    }
  }

  Future<ResidentRunner> createResidentRunner({
    @required Stream<Uri> observatoryUris,
    @required Device device,
    @required FlutterProject flutterProject,
    @required bool usesIpv6,
  }) async {
    assert(observatoryUris != null);
    assert(device != null);
    assert(flutterProject != null);
    assert(usesIpv6 != null);
    final BuildInfo buildInfo = await getBuildInfo();

    final FlutterDevice flutterDevice = await FlutterDevice.create(
      device,
      fileSystemRoots: stringsArg(FlutterOptions.kFileSystemRoot),
      fileSystemScheme: stringArg(FlutterOptions.kFileSystemScheme),
      target: targetFile,
      targetModel: TargetModel(stringArg('target-model')),
      buildInfo: buildInfo,
      userIdentifier: userIdentifier,
      platform: globals.platform,
    );
    flutterDevice.observatoryUris = observatoryUris;
    final List<FlutterDevice> flutterDevices =  <FlutterDevice>[flutterDevice];
    final DebuggingOptions debuggingOptions = DebuggingOptions.enabled(
      buildInfo,
      disableDds: boolArg('disable-dds'),
      devToolsServerAddress: devToolsServerAddress,
    );

    return buildInfo.isDebug
      ? hotRunnerFactory.build(
          flutterDevices,
          target: targetFile,
          debuggingOptions: debuggingOptions,
          packagesFilePath: globalResults['packages'] as String,
          projectRootPath: stringArg('project-root'),
          dillOutputPath: stringArg('output-dill'),
          ipv6: usesIpv6,
          flutterProject: flutterProject,
        )
      : ColdRunner(
          flutterDevices,
          target: targetFile,
          debuggingOptions: debuggingOptions,
          ipv6: usesIpv6,
        );
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
    dillOutputPath: dillOutputPath,
    stayResident: stayResident,
    ipv6: ipv6,
  );
}
