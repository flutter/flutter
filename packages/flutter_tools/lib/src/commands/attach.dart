// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart';

import '../android/android_device.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/signals.dart';
import '../base/terminal.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/build_targets.dart';
import '../compile.dart';
import '../context/tool_context.dart';
import '../daemon.dart';
import '../device.dart';
import '../device_vm_service_discovery_for_attach.dart';
import '../features.dart';
import '../hook_runner.dart' show hookRunner;
import '../ios/devices.dart';
import '../ios/simulators.dart';
import '../macos/macos_ipad_device.dart';
import '../macos/xcode.dart';
import '../mdns_discovery.dart';
import '../resident_runner.dart';
import '../run_cold.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';
import '../vmservice.dart';
import 'daemon.dart';

/// A Flutter-command that attaches to applications that have been launched
/// without `flutter run`.
///
/// With an application already running, a HotRunner can be attached to it
/// with:
/// ```bash
/// $ flutter attach --debug-url http://127.0.0.1:12345/QqL7EFEDNG0=/
/// ```
///
/// If `--disable-service-auth-codes` was provided to the application at startup
/// time, a HotRunner can be attached with just a port:
/// ```bash
/// $ flutter attach --debug-port 12345
/// ```
///
/// Alternatively, the attach command can start listening and scan for new
/// programs that become active:
/// ```bash
/// $ flutter attach
/// ```
/// As soon as a new VM Service is detected the command attaches to it and
/// enables hot reloading.
///
/// To attach to a flutter mod running on a fuchsia device, `--module` must
/// also be provided.
class AttachCommand extends FlutterCommand {
  AttachCommand({
    required this._buildSystem,
    required this._buildTargets,
    required ToolContext super.toolContext,
    required this._xcode,
    HotRunnerFactory? hotRunnerFactory,
    super.verboseHelp = false,
  }) : _hotRunnerFactory = hotRunnerFactory ?? HotRunnerFactory(),
       _toolContext = toolContext {
    enableUsesTargetOption();
    registerOptionBundles(const <OptionBundle>[
      BuildModeOptionsBundle(defaultToRelease: false, excludeRelease: true),
      VmServicePortOptionsBundle(),
      FilesystemOptionsBundle(),
      DeviceDiscoveryOptionsBundle(includeDeviceUser: true),
      ResidentCompilerOptionsBundle(),
      DdsAndDevToolsOptionsBundle(),
    ]);
    argParser.addDescriptors(const <OptionDescriptor<Object?>>[
      CommonOptions.target,
      DebuggingOptionDescriptors.fuchsiaTargetModel,
      DebuggingOptionDescriptors.fuchsiaModule,
      CommonOptions.dartDefines,
      CommonOptions.dartDefineFromFile,
      CommonOptions.enableExperiment,
      _debugPort,
      _debugUrl,
      _appId,
      DebuggingOptionDescriptors.pidFile,
      DebuggingOptionDescriptors.reportReady,
      DebuggingOptionDescriptors.projectRoot,
      CommonOptions.machine,
      BuildInfoOptions.trackWidgetCreation,
      DebuggingOptionDescriptors.adbLogFiltering,
    ], verboseHelp: verboseHelp);
  }

  static const _debugPort = StringOptionDescriptor(
    name: 'debug-port',
    verboseOnly: true,
    help:
        '(deprecated) Device port where the Dart VM Service is listening. Requires '
        '"--disable-service-auth-codes" to also be provided to the Flutter '
        'application at launch, otherwise this command will fail to connect to '
        'the application. In general, "--debug-url" should be used instead.',
  );

  static const _debugUrl = StringOptionDescriptor(
    name: 'debug-url',
    aliases: <String>['debug-uri'], // supported for historical reasons
    help: 'The URL at which the Dart VM Service is listening.',
  );

  static const _appId = StringOptionDescriptor(
    name: 'app-id',
    help:
        'The package name (Android) or bundle identifier (iOS) for the app. '
        'This can be specified to avoid being prompted if multiple Dart VM Service ports '
        'are advertised.\n'
        'If you have multiple devices or emulators running, you should include the '
        'device hostname as well, e.g. "com.example.myApp@my-iphone".\n'
        'This parameter is case-insensitive.',
  );

  final HotRunnerFactory _hotRunnerFactory;
  final ToolContext _toolContext;
  final BuildSystem _buildSystem;
  final BuildTargets _buildTargets;
  final Xcode? _xcode;

  @override
  ToolContext get toolContext => _toolContext;

  @override
  final name = 'attach';

  @override
  final description = r'''
Attach to a running app.

For attaching to Android or iOS devices, simply using `flutter attach` is
usually sufficient. The tool will search for a running Flutter app or module,
if available. Otherwise, the tool will wait for the next Flutter app or module
to launch before attaching.

For Fuchsia, the module name must be provided, e.g. `$flutter attach
--module=mod_name`. This can be called either before or after the application
is started.

If the app or module is already running and the specific vmService port is
known, it can be explicitly provided to attach via the command-line, e.g.
`$ flutter attach --debug-port 12345`''';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  bool get refreshWirelessDevices => true;

  int? get debugPort {
    final String? port = getValue(_debugPort);
    if (port == null) {
      return null;
    }
    try {
      return int.parse(port);
    } on Exception catch (error) {
      throwToolExit('Invalid port for `--debug-port`: $error');
    }
  }

  Uri? get debugUri {
    final String? debugUrl = getValue(_debugUrl);
    if (debugUrl == null) {
      return null;
    }
    final Uri? uri = Uri.tryParse(debugUrl);
    if (uri == null) {
      throwToolExit('Invalid `--debug-url`: $debugUrl');
    }
    if (!uri.hasPort) {
      throwToolExit('Port not specified for `--debug-url`: $uri');
    }
    return uri;
  }

  String? get appId => getValue(_appId);

  String? get userIdentifier => getValue(CommonOptions.deviceUser);

  @override
  Future<void> validateCommand() async {
    // ARM macOS as an iOS target is hidden, except for attach.
    MacOSDesignedForIPadDevices.allowDiscovery = true;

    await super.validateCommand();

    final Device? targetDevice = await findTargetDevice();
    if (targetDevice == null) {
      throwToolExit(null);
    }

    debugPort;
    // Allow --ipv6 for iOS devices even if --debug-port and --debug-url
    // are unknown.
    if (!_isIOSDevice(targetDevice) &&
        debugPort == null &&
        debugUri == null &&
        wasParsed(DebuggingOptionDescriptors.ipv6)) {
      throwToolExit(
        'When the --debug-port or --debug-url is unknown, this command determines '
        'the value of --ipv6 on its own.',
      );
    }
    if (debugPort == null &&
        debugUri == null &&
        wasParsed(DebuggingOptionDescriptors.vmServicePort)) {
      throwToolExit(
        'When the --debug-port or --debug-url is unknown, this command does not use '
        'the value of --vm-service-port.',
      );
    }
    if (debugPort != null && debugUri != null) {
      throwToolExit('Either --debug-port or --debug-url can be provided, not both.');
    }

    if (userIdentifier != null) {
      final Device? device = await findTargetDevice();
      if (device is! AndroidDevice) {
        throwToolExit('--${CommonOptions.deviceUser.name} is only supported for Android');
      }
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Device? device = await findTargetDevice();

    if (device == null) {
      throwToolExit('Did not find any valid target devices.');
    }

    final bool machineMode = getValue(CommonOptions.machine);

    try {
      await (machineMode ? _attachDaemon(device: device) : _attach(device: device));
    } on RPCError catch (err) {
      if (err.isConnectionDisposedException) {
        throwToolExit('Lost connection to device.');
      }
      rethrow;
    } finally {
      // However we exited from the runner, ensure the terminal has line mode
      // and echo mode enabled before we return the user to the shell.
      try {
        toolContext.terminal.singleCharMode = false;
      } on StdinException {
        // Do nothing, if the STDIN handle is no longer available, there is nothing actionable for us to do at this point
      }
    }

    return FlutterCommandResult.success();
  }

  Future<void> _attach({required Device device}) async {
    final ToolContext(
      :Logger logger,
      :ProcessInfo processInfo,
      :Signals signals,
      :Terminal terminal,
    ) = toolContext;
    terminal.usesTerminalUi = true;
    final ResidentRunner runner = await _discoverVmServiceAndCreateResidentRunner(device: device);
    final onAppStart = Completer<void>.sync();
    TerminalHandler? terminalHandler;
    unawaited(
      onAppStart.future.whenComplete(() {
        terminalHandler =
            TerminalHandler(
                runner,
                logger: logger,
                terminal: terminal,
                signals: signals,
                processInfo: processInfo,
                reportReady: getValue(DebuggingOptionDescriptors.reportReady),
                pidFile: getValue(DebuggingOptionDescriptors.pidFile),
              )
              ..registerSignalHandlers()
              ..setupTerminal();
      }),
    );
    final int result = await runner.attach(appStartedCompleter: onAppStart);
    if (result != 0) {
      throwToolExit(null, exitCode: result);
    }
    terminalHandler?.stop();
  }

  Future<void> _attachDaemon({required Device device}) async {
    final ToolContext(:FileSystem fs, :Logger logger, :Stdio stdio) = toolContext;
    final daemon = Daemon(
      DaemonConnection(
        daemonStreams: DaemonStreams.fromStdio(stdio, logger: logger),
        logger: logger,
      ),
      analytics: analytics,
      buildSystem: _buildSystem,
      buildTargets: _buildTargets,
      toolContext: toolContext,
      xcode: _xcode,
      notifyingLogger: (logger is NotifyingLogger)
          ? logger
          : NotifyingLogger(verbose: logger.isVerbose, parent: logger),
      logToStdout: true,
      featureFlags: featureFlags,
    );

    final ResidentRunner runner = await _discoverVmServiceAndCreateResidentRunner(device: device);
    late AppInstance app;
    try {
      app = await daemon.appDomain.launch(
        runner,
        ({
          Completer<DebugConnectionInfo>? connectionInfoCompleter,
          Completer<void>? appStartedCompleter,
        }) {
          return runner.attach(
            connectionInfoCompleter: connectionInfoCompleter,
            appStartedCompleter: appStartedCompleter,
          );
        },
        device,
        null,
        true,
        fs.currentDirectory,
        LaunchMode.attach,
        logger as MachineOutputLogger,
      );
    } on Exception catch (error) {
      throwToolExit(error.toString());
    }
    await app.runner.waitForAppToFinish();
  }

  Future<ResidentRunner> _discoverVmServiceAndCreateResidentRunner({required Device device}) async {
    final Future<Uri> vmServiceUri = _discoverVmService(device: device);
    vmServiceUri.ignore();

    final BuildInfo buildInfo = await getBuildInfo();

    final FlutterDevice flutterDevice = await FlutterDevice.create(
      device,
      toolContext: toolContext,
      buildInfo: buildInfo,
      target: targetFile,
      targetModelOverride: TargetModel(getValue(DebuggingOptionDescriptors.fuchsiaTargetModel)),
      userIdentifier: userIdentifier,
    );
    flutterDevice.vmServiceUri = vmServiceUri;
    final flutterDevices = <FlutterDevice>[flutterDevice];
    final debuggingOptions = DebuggingOptions.enabled(
      buildInfo,
      enableDds: enableDds,
      ddsPort: ddsPort,
      devToolsServerAddress: devToolsServerAddress,
      usingCISystem: usingCISystem,
      debugLogsDirectoryPath: debugLogsDirectoryPath,
      enableDevTools: getValue(DebuggingOptionDescriptors.enableDevTools),
      ipv6: ipv6!,
      printDtd: getValue(CommonOptions.printDtd),
      adbLogFiltering:
          hasOption(DebuggingOptionDescriptors.adbLogFiltering) &&
          getValue(DebuggingOptionDescriptors.adbLogFiltering),
    );

    return buildInfo.isDebug
        ? _hotRunnerFactory.build(
            flutterDevices,
            target: targetFile,
            debuggingOptions: debuggingOptions,
            projectRootPath: getValue(DebuggingOptionDescriptors.projectRoot),
            dillOutputPath: getValue(BuildInfoOptions.outputDill),
            nativeAssetsYamlFile: getValue(BuildInfoOptions.nativeAssetsYamlFile),
            analytics: analytics,
            buildSystem: _buildSystem,
            buildTargets: _buildTargets,
            toolContext: toolContext,
            xcode: _xcode,
          )
        : ColdRunner(
            flutterDevices,
            target: targetFile,
            debuggingOptions: debuggingOptions,
            dartBuilder: hookRunner,
            analytics: analytics,
            buildSystem: _buildSystem,
            buildTargets: _buildTargets,
            toolContext: toolContext,
            xcode: _xcode,
          );
  }

  Future<Uri> _discoverVmService({required Device device}) async {
    final Logger logger = toolContext.logger;
    final bool usesIpv6 = ipv6!;
    final String ipv6Loopback = InternetAddress.loopbackIPv6.address;
    final String ipv4Loopback = InternetAddress.loopbackIPv4.address;
    final hostname = usesIpv6 ? ipv6Loopback : ipv4Loopback;
    final bool isWirelessIOSDevice = (device is IOSDevice) && device.isWirelesslyConnected;

    if (!isWirelessIOSDevice && (debugPort != null || debugUri != null)) {
      return buildVMServiceUri(
        device,
        debugUri?.host ?? hostname,
        debugPort ?? debugUri!.port,
        hostVmservicePort,
        debugUri?.path,
      );
    }

    // The device port we expect to have the debug port be listening
    final int? devicePort = debugPort ?? debugUri?.port ?? deviceVmservicePort;

    final VMServiceDiscoveryForAttach vmServiceDiscovery = device.getVMServiceDiscoveryForAttach(
      appId: appId,
      fuchsiaModule: getValue(DebuggingOptionDescriptors.fuchsiaModule),
      filterDevicePort: devicePort,
      expectedHostPort: hostVmservicePort,
      ipv6: usesIpv6,
      logger: logger,
    );

    logger.printStatus('Waiting for a connection from Flutter on ${device.displayName}...');
    final Status discoveryStatus = logger.startSpinner(
      timeout: const Duration(seconds: 30),
      slowWarningCallback: () {
        // On iOS we rely on mDNS to find Dart VM Service.
        if (device is IOSSimulator) {
          // mDNS on simulators stopped working in macOS 15.4.
          // See https://github.com/flutter/flutter/issues/166333.
          return 'The Dart VM Service was not discovered after 30 seconds. '
              'This may be due to limited mDNS support in the iOS Simulator.\n\n'
              'Click "Allow" to the prompt on your device asking if you would like to find and connect devices on your local network. '
              'If you selected "Don\'t Allow", you can turn it on in Settings > Your App Name > Local Network. '
              "If you don't see your app in the Settings, uninstall the app and rerun to see the prompt again.\n\n"
              'If you do not receive a prompt, either run "flutter attach" before starting the '
              'app or use the Dart VM service URL from the Xcode console with '
              '"flutter attach --debug-url=<URL>".\n';
        } else if (_isIOSDevice(device)) {
          // Remind the user to allow local network permissions on the device.
          return 'The Dart VM Service was not discovered after 30 seconds. This is taking much longer than expected...\n\n'
              'Click "Allow" to the prompt on your device asking if you would like to find and connect devices on your local network. '
              'If you selected "Don\'t Allow", you can turn it on in Settings > Your App Name > Local Network. '
              "If you don't see your app in the Settings, uninstall the app and rerun to see the prompt again.\n";
        }

        return 'The Dart VM Service was not discovered after 30 seconds. This is taking much longer than expected...\n';
      },
      warningColor: TerminalColor.cyan,
    );

    try {
      return await vmServiceDiscovery.firstValidUri();
    } finally {
      discoveryStatus.stop();
    }
  }

  bool _isIOSDevice(Device device) {
    return (device.platformType == PlatformType.ios) || (device is MacOSDesignedForIPadDevice);
  }
}

class HotRunnerFactory {
  HotRunner build(
    List<FlutterDevice> devices, {
    required Analytics analytics,
    required BuildSystem buildSystem,
    required BuildTargets buildTargets,
    required DebuggingOptions debuggingOptions,
    required String target,
    required ToolContext toolContext,
    required Xcode? xcode,
    File? applicationBinary,
    bool benchmarkMode = false,
    String? dillOutputPath,
    bool hostIsIde = false,
    String? nativeAssetsYamlFile,
    String? projectRootPath,
    bool stayResident = true,
  }) => HotRunner(
    devices,
    analytics: analytics,
    buildSystem: buildSystem,
    buildTargets: buildTargets,
    debuggingOptions: debuggingOptions,
    target: target,
    toolContext: toolContext,
    xcode: xcode,
    benchmarkMode: benchmarkMode,
    applicationBinary: applicationBinary,
    hostIsIde: hostIsIde,
    projectRootPath: projectRootPath,
    dillOutputPath: dillOutputPath,
    stayResident: stayResident,
    nativeAssetsYamlFile: nativeAssetsYamlFile,
    dartBuilder: hookRunner,
  );
}

@visibleForTesting
Stream<T> streamWithCallbackOnFirstItem<T>(Stream<T> stream, void Function() callback) {
  var called = false;
  return stream.map((i) {
    if (!called) {
      callback();
      called = true;
    }
    return i;
  });
}
