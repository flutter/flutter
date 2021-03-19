// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../convert.dart';
import '../device.dart';
import '../features.dart';
import '../project.dart';
import '../protocol_discovery.dart';
import 'custom_device_config.dart';
import 'custom_device_workflow.dart';
import 'custom_devices_config.dart';

List<String> interpolateCommand(
  List<String> command,
  Map<String, String> replacementValues, {
  Map<String, String> additionalReplacementValues = const <String, String>{}
}) {
  return interpolateStringList(
      command,
      Map<String, String>.of(additionalReplacementValues)
        ..addAll(replacementValues)
  );
}


class CustomDeviceLogReader extends DeviceLogReader {
  CustomDeviceLogReader(this.name);

  /// The name of the device this log reader is associated with.
  @override
  final String name;

  final StreamController<String> _logLinesController = StreamController<String>.broadcast();

  /// Listen to [process]' stdout and stderr, decode them using [SystemEncoding]
  /// and add each decoded line to [logLines].
  ///
  /// However, [logLines] will not be done when the [process]' stdout and stderr
  /// streams are done. So [logLines] will still be alive after the process has
  /// finished.
  ///
  /// See [CustomDeviceLogReader.dispose] to end the [logLines] stream.
  void listenToProcessOutput(Process process, {Encoding encoding = systemEncoding}) {
    final Converter<List<int>, String> decoder = encoding.decoder;

    process.stdout.transform<String>(decoder)
      .transform<String>(const LineSplitter())
      .listen(
        (String stdoutLine) {
        _logLinesController.add(stdoutLine);
        }
      );

    process.stderr.transform<String>(decoder)
      .transform<String>(const LineSplitter())
      .listen((String stderrLine) => _logLinesController.add(stderrLine));
  }

  /// Add all lines emitted by [lines] to this [CustomDeviceLogReader]s [logLines]
  /// stream.
  ///
  /// Similiar to [listenToProcessOutput], [logLines] will not be marked as done
  /// when the argument stream is done.
  ///
  /// Useful when you want to combine the contents of multiple log readers.
  void listenToLinesStream(Stream<String> lines) {
    _logLinesController.addStream(lines);
  }

  /// Dispose this log reader, freeing all associated resources and marking
  /// [logLines] as done.
  @override
  void dispose() {
    _logLinesController.close();
  }

  @override
  Stream<String> get logLines => _logLinesController.stream;
}

class CustomDevicePortForwarder extends DevicePortForwarder {
  CustomDevicePortForwarder({
    @required String deviceName,
    @required List<String> forwardPortCommand,
    @required RegExp forwardPortSuccessRegex,
    this.numTries/*?*/,
    @required ProcessManager processManager,
    @required Logger logger,
    Map<String, String> additionalReplacementValues = const <String, String>{}
  }) : _deviceName = deviceName,
       _forwardPortCommand = forwardPortCommand,
       _forwardPortSuccessRegex = forwardPortSuccessRegex,
       _processManager = processManager,
       _processUtils = ProcessUtils(
         processManager: processManager,
         logger: logger
       ),
       _additionalReplacementValues = additionalReplacementValues;

  final String _deviceName;
  final List<String> _forwardPortCommand;
  final RegExp _forwardPortSuccessRegex;
  final ProcessManager _processManager;
  final ProcessUtils _processUtils;
  final int numTries;
  final Map<String, String> _additionalReplacementValues;
  final List<ForwardedPort> _forwardedPorts = <ForwardedPort>[];

  @override
  Future<void> dispose() async {
    // copy the list so we don't modify it concurrently
    List<ForwardedPort>.of(_forwardedPorts).forEach(unforward);
  }

  Future<ForwardedPort> _tryForward(int devicePort, int hostPort) async {
    final List<String> interpolated = interpolateCommand(
      _forwardPortCommand,
      <String, String>{
        'devicePort': '$devicePort',
        'hostPort': '$hostPort'
      },
      additionalReplacementValues: _additionalReplacementValues
    );

    // launch the forwarding command
    final Process process = await _processUtils.start(interpolated);

    final Completer<ForwardedPort> completer = Completer<ForwardedPort>();

    // read the outputs of the process, if we find a line that matches
    // the configs forwardPortSuccessRegex, we complete with a successfully
    // forwarded port
    // Note that if that regex never matches, this will potentially run forever
    // and the forwarding will never complete
    final CustomDeviceLogReader reader = CustomDeviceLogReader(_deviceName)..listenToProcessOutput(process);
    final StreamSubscription<String> logLinesSubscription = reader.logLines.listen((String line) {
      if (_forwardPortSuccessRegex.hasMatch(line) && !completer.isCompleted) {
        completer.complete(
          ForwardedPort.withContext(hostPort, devicePort, process)
        );
      }
    });

    // if the process exits (even with exitCode == 0), that is considered
    // a port forwarding failure and we complete with a null value.
    unawaited(process.exitCode.then((int exitCode) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }));

    unawaited(completer.future.whenComplete(() {
      logLinesSubscription.cancel();
      reader.dispose();
    }));

    return completer.future;
  }

  @override
  Future<int> forward(int devicePort, {int hostPort}) async {
    int actualHostPort = (hostPort == 0 || hostPort == null) ? devicePort : hostPort;
    int tries = 0;

    while ((numTries == null) || (tries < numTries)) {
      // when the desired host port is already forwarded by this Forwarder,
      // choose another one
      while (_forwardedPorts.any((ForwardedPort port) => port.hostPort == actualHostPort)) {
        actualHostPort++;
      }

      final ForwardedPort port = await _tryForward(devicePort, actualHostPort);

      if (port != null) {
        _forwardedPorts.add(port);
        return actualHostPort;
      } else {
        // null value means the forwarding failed (for whatever reason)
        // increase port by one and try again
        actualHostPort++;
        tries++;
      }
    }

    throw ToolExit('Forwarding port for custom device $_deviceName failed after $tries tries.');
  }

  @override
  List<ForwardedPort> get forwardedPorts => List<ForwardedPort>.unmodifiable(_forwardedPorts);

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async {
    assert(_forwardedPorts.contains(forwardedPort));

    // since a forwarded port represents a running process launched with
    // the forwardPortCommand, unforwarding is as easy as killing the proces
    _processManager.killPid(forwardedPort.context.pid);
    _forwardedPorts.remove(forwardedPort);
  }
}

class CustomDeviceAppSession {
  CustomDeviceAppSession({
    @required this.name,
    @required CustomDevice device,
    @required ApplicationPackage appPackage,
    @required Logger logger,
    @required ProcessManager processManager
  }) : _appPackage = appPackage,
       _device = device,
       _logger = logger,
       _processManager = processManager,
       logReader = CustomDeviceLogReader(name);

  final String name;
  final CustomDevice _device;
  final ApplicationPackage _appPackage;
  final Logger _logger;
  final ProcessManager _processManager;
  final CustomDeviceLogReader logReader;

  Process _process;

  Future<LaunchResult> start({
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String userIdentifier
  }) async {
    final List<String> interpolated = interpolateCommand(
      _device._config.runDebugCommand,
      <String, String>{
        'remotePath': '/tmp/',
        'appName': _appPackage.name
      }
    );

    final Process process = await _processManager.start(interpolated);

    assert(_process == null);
    _process = process;

    final ProtocolDiscovery discovery = ProtocolDiscovery.observatory(
      logReader,
      portForwarder: _device._config.usesPortForwarding ? _device.portForwarder : null,
      hostPort: null,
      devicePort: null,
      logger: _logger,
      ipv6: ipv6,
    );

    logReader.listenToProcessOutput(process);

    final Uri observatoryUri = await discovery.uri;

    await discovery.cancel();

    return LaunchResult.succeeded(observatoryUri: observatoryUri);
  }

  Future<bool> stop() async {
    if (_process == null) {
      return false;
    } else {
      final bool result = _processManager.killPid(_process.pid);
      _process = null;

      return result;
    }
  }

  void dispose() {
    if (_process != null) {
      _processManager.killPid(_process.pid);
      _process = null;
    }

    logReader.dispose();
  }
}

/// A device that uses user-configured actions for the common device methods.
/// The exact actions are defined by the contents of the [CustomDeviceConfig]
/// used to construct it.
class CustomDevice extends Device {
  CustomDevice({
    @required CustomDeviceConfig config,
    @required Logger logger,
    @required ProcessManager processManager,
  }) : _config = config,
       _logger = logger,
       _processManager = processManager,
       _processUtils = ProcessUtils(
         processManager: processManager,
         logger: logger
       ),
       _globalLogReader = CustomDeviceLogReader(config.label),
       super(
         config.id,
         category: Category.mobile,
         ephemeral: true,
         platformType: PlatformType.linux
       );

  final CustomDeviceConfig _config;
  final Logger _logger;
  final ProcessManager _processManager;
  final ProcessUtils _processUtils;
  final Map<ApplicationPackage, CustomDeviceAppSession> _sessions = <ApplicationPackage, CustomDeviceAppSession>{};
  final CustomDeviceLogReader _globalLogReader;

  CustomDeviceAppSession _getOrCreateAppSession(covariant ApplicationPackage app) {
    return _sessions.putIfAbsent(
      app,
      () {
        /// create a new session and add its logging to the global log reader.
        /// (needed bc it's possible the infra requests a global log in [getLogReader]
        final CustomDeviceAppSession session = CustomDeviceAppSession(
          name: name,
          device: this,
          appPackage: app,
          logger: _logger,
          processManager: _processManager
        );

        _globalLogReader.listenToLinesStream(session.logReader.logLines);

        return session;
      }
    );
  }

  /// Tries to ping the device using the ping command given in the config.
  /// All string interpolation occurrences inside the ping command will be replaced
  /// using the entries in [replacementValues].
  ///
  /// If the process finishes with an exit code != 0, false will be returned and
  /// the error (with the process' stdout and stderr) will be logged using
  /// [_logger.printError].
  ///
  /// If [timeout] is not null and the process doesn't finish in time,
  /// it will be killed with a SIGTERM, false will be returned and the timeout
  /// will be reported in the log using [_logger.printError]. If [timeout]
  /// is null, it's treated as if it's an infinite timeout.
  Future<bool> _tryPing({
    Duration timeout,
    Map<String, String> replacementValues = const <String, String>{}
  }) async {
    final List<String> interpolated = interpolateCommand(
      _config.pingCommand,
      replacementValues
    );

    try {
      await _processUtils.run(
          interpolated,
          throwOnError: true,
          timeout: timeout
      );
      return true;
    } on ProcessException catch (e) {
      _logger.printError('Error executing ping command for custom device $id: $e');
      return false;
    }
  }

  /// Tries to execute the configs postBuild command using [appName] for the
  /// `${appName}` and [localPath] for the `${localPath}` interpolations,
  /// any additional string interpolation occurrences will be replaced using the
  /// entries in [additionalReplacementValues].
  ///
  /// Calling this when the config doesn't have a configured postBuild command
  /// is an error.
  ///
  /// If [timeout] is not null and the process doesn't finish in time, it
  /// will be killed with a SIGTERM, false will be returned and the timeout
  /// will be reported in the log using [_logger.printError]. If [timeout]
  /// is null, it's treated as if it's an infinite timeout.
  Future<bool> _tryPostBuild({
    @required String appName,
    @required String localPath,
    Duration timeout,
    Map<String, String> additionalReplacementValues = const <String, String>{}
  }) async {
    assert(_config.postBuildCommand != null);

    final List<String> interpolated = interpolateCommand(
      _config.postBuildCommand,
      <String, String>{
        'appName': appName,
        'localPath': localPath
      },
      additionalReplacementValues: additionalReplacementValues
    );

    try {
      await _processUtils.run(
        interpolated,
        throwOnError: true,
        timeout: timeout
      );
      return true;
    } on ProcessException catch (e) {
      _logger.printError('Error executing postBuild command for custom device $id: $e');
      return false;
    }
  }

  /// Tries to execute the configs uninstall command.
  ///
  /// [appName] is the name of the app to be installed.
  ///
  /// If [timeout] is not null and the process doesn't finish in time, it
  /// will be killed with a SIGTERM, false will be returned and the timeout
  /// will be reported in the log using [_logger.printError]. If [timeout]
  /// is null, it's treated as if it's an infinite timeout.
  Future<bool> _tryUninstall({
    @required String appName,
    Duration timeout,
    Map<String, String> additionalReplacementValues = const <String, String>{}
  }) async {
    final List<String> interpolated = interpolateCommand(
      _config.uninstallCommand,
      <String, String>{
        'appName': appName
      },
      additionalReplacementValues: additionalReplacementValues
    );

    try {
      await _processUtils.run(
        interpolated,
        throwOnError: true,
        timeout: timeout
      );
      return true;
    } on ProcessException catch (e) {
      _logger.printError('Error executing uninstall command for custom device $id: $e');
      return false;
    }
  }

  /// Tries to install the app to the custom device.
  ///
  /// [localPath] is the file / directory on the local device that will be
  /// copied over to the target custom device. This is substituted for any occurrence
  /// of `${localPath}` in the custom device configs `install` command.
  ///
  /// [appName] is the name of the app to be installed. Substituted for any occurrence
  /// of `${appName}` in the custom device configs `install` command.
  Future<bool> _tryInstall({
    @required String localPath,
    @required String appName,
    Duration timeout,
    Map<String, String> additionalReplacementValues = const <String, String>{}
  }) async {
    final List<String> interpolated = interpolateCommand(
      _config.installCommand,
      <String, String>{
        'localPath': localPath,
        'appName': appName
      },
      additionalReplacementValues: additionalReplacementValues
    );

    try {
      await _processUtils.run(
        interpolated,
        throwOnError: true,
        timeout: timeout
      );

      return true;
    } on ProcessException catch (e) {
      _logger.printError('Error executing install command for custom device $id: $e');
      return false;
    }
  }

  @override
  void clearLogs() {}

  @override
  Future<void> dispose() async {
    _sessions
      ..forEach((_, CustomDeviceAppSession session) => session.dispose())
      ..clear();
  }

  @override
  Future<String> get emulatorId async => null;

  @override
  FutureOr<DeviceLogReader> getLogReader({
    covariant ApplicationPackage app,
    bool includePastLogs = false
  }) {
    if (app != null) {
      return _getOrCreateAppSession(app).logReader;
    } else {
      return _globalLogReader;
    }
  }

  @override
  Future<bool> installApp(covariant ApplicationPackage app, {String userIdentifier}) async {
    if (!await _tryUninstall(appName: app.name)) {
      return false;
    }

    final bool result = await _tryInstall(
      localPath: getAssetBuildDirectory(),
      appName: app.name
    );

    return result;
  }

  @override
  Future<bool> isAppInstalled(covariant ApplicationPackage app, {String userIdentifier}) async {
    return false;
  }

  @override
  Future<bool> isLatestBuildInstalled(covariant ApplicationPackage app) async {
    return false;
  }

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  bool isSupported() {
    return true;
  }

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return true;
  }

  @override
  FutureOr<bool> supportsRuntimeMode(BuildMode buildMode) {
    return buildMode == BuildMode.debug;
  }

  @override
  String get name => _config.label;

  @override
  DevicePortForwarder get portForwarder {
    if (_config.usesPortForwarding) {
      return CustomDevicePortForwarder(
        deviceName: name,
        forwardPortCommand: _config.forwardPortCommand,
        forwardPortSuccessRegex: _config.forwardPortSuccessRegex,
        processManager: _processManager,
        logger: _logger,
      );
    }

    return const NoOpDevicePortForwarder();
  }

  @override
  Future<String> get sdkNameAndVersion => Future<String>.value(_config.sdkNameAndVersion);

  @override
  Future<LaunchResult> startApp(
    covariant ApplicationPackage package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String userIdentifier
  }) async {
    final String assetBundleDir = getAssetBuildDirectory();

    // build the asset bundle
    await BundleBuilder().build(
      platform: await targetPlatform,
      buildInfo: debuggingOptions.buildInfo,
      mainPath: mainPath,
      depfilePath: defaultDepfilePath,
      assetDirPath: assetBundleDir,
      treeShakeIcons: false,
    );

    // if we have a post build step (needed for some embedders), execute it
    if (_config.postBuildCommand != null) {
      await _tryPostBuild(
        appName: package.name,
        localPath: assetBundleDir,
      );
    }

    // install the app on the device
    // (will invoke the uninstall and then the install command internally)
    await installApp(package, userIdentifier: userIdentifier);

    // finally launch the app
    return _getOrCreateAppSession(package).start(
      mainPath: mainPath,
      route: route,
      debuggingOptions: debuggingOptions,
      platformArgs: platformArgs,
      prebuiltApplication: prebuiltApplication,
      ipv6: ipv6,
      userIdentifier: userIdentifier,
    );
  }

  @override
  Future<bool> stopApp(covariant ApplicationPackage app, {String userIdentifier}) {
    return _getOrCreateAppSession(app).stop();
  }

  @override
  // TODO(ardera): Allow configuring or auto-detecting the target platform, https://github.com/flutter/flutter/issues/78151
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.linux_arm64;

  @override
  Future<bool> uninstallApp(covariant ApplicationPackage app, {String userIdentifier}) {
    return _tryUninstall(appName: app.name);
  }
}

class CustomDevices extends PollingDeviceDiscovery {
  CustomDevices({
    @required FeatureFlags featureFlags,
    @required ProcessManager processManager,
    @required Logger logger,
  }) : _customDeviceWorkflow = CustomDeviceWorkflow(
        featureFlags: featureFlags,
      ),
       _logger = logger,
       _processManager = processManager,
       _config = null,
       super('custom devices');

  CustomDevices.test({
    @required FeatureFlags featureFlags,
    @required ProcessManager processManager,
    @required Logger logger,
    @required CustomDevicesConfig config
  }) : _customDeviceWorkflow = CustomDeviceWorkflow(
        featureFlags: featureFlags,
      ),
      _logger = logger,
      _processManager = processManager,
      _config = config,
      super('custom devices');

  final CustomDeviceWorkflow  _customDeviceWorkflow;
  final ProcessManager _processManager;
  final Logger _logger;
  final CustomDevicesConfig _config;

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => _customDeviceWorkflow.canListDevices;

  CustomDevicesConfig get customDevicesConfig => _config ?? context.get<CustomDevicesConfig>();

  List<CustomDevice> get enabledCustomDevices {
    return customDevicesConfig.devices
      .where((CustomDeviceConfig element) => !element.disabled)
      .map(
        (CustomDeviceConfig config) => CustomDevice(
          config: config,
          logger: _logger,
          processManager: _processManager
        )
      ).toList();
  }

  @override
  Future<List<Device>> pollingGetDevices({Duration timeout}) async {
    if (!canListAnything) {
      return const <Device>[];
    }

    final List<CustomDevice> devices = enabledCustomDevices;

    // maps any custom device to whether its reachable or not.
    final Map<CustomDevice, bool> pingedDevices = Map<CustomDevice, bool>.fromIterables(
      devices,
      await Future.wait(devices.map((CustomDevice e) => e._tryPing(timeout: timeout)))
    );

    // remove all the devices we couldn't reach.
    pingedDevices.removeWhere((_, bool value) => value == false);

    // return only the devices.
    return pingedDevices.keys.toList();
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}
