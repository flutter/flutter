// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../commands/daemon.dart';
import '../compile.dart';
import '../device.dart';
import '../project.dart';
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
    argParser
      ..addOption(
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
      )..addFlag('track-widget-creation',
        hide: !verboseHelp,
        help: 'Track widget creation locations.',
        defaultsTo: false,
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
      throwToolExit('No connected devices.');
    }
    if (debugUri == null && argResults.wasParsed(FlutterCommand.ipv6Flag)) {
      throwToolExit(
        'When --debug-uri is unknown, this command determines the value of '
        '--ipv6 on its own.',
      );
    }
    if (debugUri == null && argResults.wasParsed(FlutterCommand.observatoryPortOption)) {
      throwToolExit(
        'When --debug-uri is unknown, this command does not use the value of '
        '--observatory-port.',
      );
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject flutterProject = await FlutterProject.current();
    Cache.releaseLockEarly();
    await _validateArguments();

    writePidFile(argResults['pid-file']);

    final Device device = await findTargetDevice();
    Daemon daemon;
    if (argResults['machine']) {
      daemon = Daemon(
        stdinCommandStream, stdoutCommandResponse,
        notifyingLogger: NotifyingLogger(),
        logToStdout: true,
      );
    }

    Uri observatoryUri;
    if (debugUri == null) {
      observatoryUri = await device.attach(
        ipv6: ipv6,
        isolateFilter: argResults['module'],
        applicationId: appId,
      );
    } else {
      observatoryUri = await _buildObservatoryUri(device, debugUri?.host, debugUri.port, debugUri?.path);
    }
    try {
      final bool useHot = getBuildInfo().isDebug;
      final FlutterDevice flutterDevice = await FlutterDevice.create(
        device,
        flutterProject: flutterProject,
        trackWidgetCreation: argResults['track-widget-creation'],
        dillOutputPath: argResults['output-dill'],
        fileSystemRoots: argResults['filesystem-root'],
        fileSystemScheme: argResults['filesystem-scheme'],
        viewFilter: argResults['isolate-filter'],
        target: argResults['target'],
        targetModel: TargetModel(argResults['target-model']),
        buildMode: getBuildMode(),
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
            ipv6: ipv6,
            flutterProject: flutterProject,
          )
        : ColdRunner(
            flutterDevices,
            target: targetFile,
            debuggingOptions: debuggingOptions,
            ipv6: ipv6,
          );
      flutterDevice.startEchoingDeviceLog();

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
        result = await runner.attach();
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
    return null;
  }

  Future<void> _validateArguments() async { }

  Future<Uri> _buildObservatoryUri(Device device, String host, int devicePort, [String authCode]) async {
    String path = '/';
    if (authCode != null) {
      path = authCode;
    }
    // Not having a trailing slash can cause problems in some situations.
    // Ensure that there's one present.
    if (!path.endsWith('/')) {
      path += '/';
    }
    final int localPort = observatoryPort ?? await device.portForwarder.forward(devicePort);
    return Uri(scheme: 'http', host: host, port: localPort, path: path);
  }
}

class HotRunnerFactory {
  HotRunner build(
    List<FlutterDevice> devices, {
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
    FlutterProject flutterProject,
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
