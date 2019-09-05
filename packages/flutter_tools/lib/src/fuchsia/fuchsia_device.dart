// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../base/time.dart';
import '../build_info.dart';
import '../device.dart';
import '../globals.dart';
import '../project.dart';
import '../vmservice.dart';

import 'amber_ctl.dart';
import 'application_package.dart';
import 'fuchsia_build.dart';
import 'fuchsia_pm.dart';
import 'fuchsia_sdk.dart';
import 'fuchsia_workflow.dart';
import 'tiles_ctl.dart';

/// The [FuchsiaDeviceTools] instance.
FuchsiaDeviceTools get fuchsiaDeviceTools => context.get<FuchsiaDeviceTools>();

/// Fuchsia device-side tools.
class FuchsiaDeviceTools {
  FuchsiaAmberCtl _amberCtl;
  FuchsiaAmberCtl get amberCtl => _amberCtl ??= FuchsiaAmberCtl();

  FuchsiaTilesCtl _tilesCtl;
  FuchsiaTilesCtl get tilesCtl => _tilesCtl ??= FuchsiaTilesCtl();
}

final String _ipv4Loopback = InternetAddress.loopbackIPv4.address;
final String _ipv6Loopback = InternetAddress.loopbackIPv6.address;

// Enables testing the fuchsia isolate discovery
Future<VMService> _kDefaultFuchsiaIsolateDiscoveryConnector(Uri uri) {
  return VMService.connect(uri);
}

/// Read the log for a particular device.
class _FuchsiaLogReader extends DeviceLogReader {
  _FuchsiaLogReader(this._device, [this._app]);

  // \S matches non-whitespace characters.
  static final RegExp _flutterLogOutput = RegExp(r'INFO: \S+\(flutter\): ');

  final FuchsiaDevice _device;
  final ApplicationPackage _app;

  @override
  String get name => _device.name;

  Stream<String> _logLines;
  @override
  Stream<String> get logLines {
    final Stream<String> logStream = fuchsiaSdk.syslogs(_device.id);
    _logLines ??= _processLogs(logStream);
    return _logLines;
  }

  Stream<String> _processLogs(Stream<String> lines) {
    if (lines == null) {
      return null;
    }
    // Get the starting time of the log processor to filter logs from before
    // the process attached.
    final DateTime startTime = systemClock.now();
    // Determine if line comes from flutter, and optionally whether it matches
    // the correct fuchsia module.
    final RegExp matchRegExp = _app == null
        ? _flutterLogOutput
        : RegExp('INFO: ${_app.name}(\.cmx)?\\(flutter\\): ');
    return Stream<String>.eventTransformed(
      lines,
      (Sink<String> outout) => _FuchsiaLogSink(outout, matchRegExp, startTime),
    );
  }

  @override
  String toString() => name;
}

class _FuchsiaLogSink implements EventSink<String> {
  _FuchsiaLogSink(this._outputSink, this._matchRegExp, this._startTime);

  static final RegExp _utcDateOutput = RegExp(r'\d+\-\d+\-\d+ \d+:\d+:\d+');
  final EventSink<String> _outputSink;
  final RegExp _matchRegExp;
  final DateTime _startTime;

  @override
  void add(String line) {
    if (!_matchRegExp.hasMatch(line)) {
      return;
    }
    final String rawDate = _utcDateOutput.firstMatch(line)?.group(0);
    if (rawDate == null) {
      return;
    }
    final DateTime logTime = DateTime.parse(rawDate);
    if (logTime.millisecondsSinceEpoch < _startTime.millisecondsSinceEpoch) {
      return;
    }
    _outputSink.add(
        '[${logTime.toLocal()}] Flutter: ${line.split(_matchRegExp).last}');
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    _outputSink.addError(error, stackTrace);
  }

  @override
  void close() {
    _outputSink.close();
  }
}

class FuchsiaDevices extends PollingDeviceDiscovery {
  FuchsiaDevices() : super('Fuchsia devices');

  @override
  bool get supportsPlatform => platform.isLinux || platform.isMacOS;

  @override
  bool get canListAnything => fuchsiaWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices() async {
    if (!fuchsiaWorkflow.canListDevices) {
      return <Device>[];
    }
    final String text = await fuchsiaSdk.listDevices();
    if (text == null || text.isEmpty) {
      return <Device>[];
    }
    final List<FuchsiaDevice> devices = parseListDevices(text);
    return devices;
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}

@visibleForTesting
List<FuchsiaDevice> parseListDevices(String text) {
  final List<FuchsiaDevice> devices = <FuchsiaDevice>[];
  for (String rawLine in text.trim().split('\n')) {
    final String line = rawLine.trim();
    // ['ip', 'device name']
    final List<String> words = line.split(' ');
    if (words.length < 2) {
      continue;
    }
    final String name = words[1];
    final String id = words[0];
    devices.add(FuchsiaDevice(id, name: name));
  }
  return devices;
}

class FuchsiaDevice extends Device {
  FuchsiaDevice(String id, {this.name}) : super(
      id,
      platformType: PlatformType.fuchsia,
      category: null,
      ephemeral: false,
  );

  @override
  bool get supportsHotReload => true;

  @override
  bool get supportsHotRestart => false;

  @override
  bool get supportsFlutterExit => false;

  @override
  final String name;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String> get emulatorId async => null;

  @override
  bool get supportsStartPaused => false;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> installApp(ApplicationPackage app) => Future<bool>.value(false);

  @override
  Future<bool> uninstallApp(ApplicationPackage app) async => false;

  @override
  bool isSupported() => true;

  @override
  Future<LaunchResult> startApp(
    covariant FuchsiaApp package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
  }) async {
    if (!prebuiltApplication) {
      await buildFuchsia(fuchsiaProject: FlutterProject.current().fuchsia,
                         target: mainPath,
                         buildInfo: debuggingOptions.buildInfo);
    }
    // Stop the app if it's currently running.
    await stopApp(package);
    // Find out who the device thinks we are.
    final String host = await fuchsiaSdk.fuchsiaDevFinder.resolve(name);
    if (host == null) {
      printError('Failed to resolve host for Fuchsia device');
      return LaunchResult.failed();
    }
    final int port = await os.findFreePort();
    if (port == 0) {
      printError('Failed to find a free port');
      return LaunchResult.failed();
    }
    final Directory packageRepo =
        fs.directory(fs.path.join(getFuchsiaBuildDirectory(), '.pkg-repo'));
    packageRepo.createSync(recursive: true);

    final String appName = FlutterProject.current().manifest.appName;

    final Status status = logger.startProgress(
      'Starting Fuchsia application...',
      timeout: null,
    );
    FuchsiaPackageServer fuchsiaPackageServer;
    bool serverRegistered = false;
    try {
      // Ask amber to pre-fetch some things we'll need before setting up our own
      // package server. This is to avoid relying on amber correctly using
      // multiple package servers, support for which is in flux.
      if (!await fuchsiaDeviceTools.amberCtl.getUp(this, 'tiles')) {
        printError('Failed to get amber to prefetch tiles');
        return LaunchResult.failed();
      }
      if (!await fuchsiaDeviceTools.amberCtl.getUp(this, 'tiles_ctl')) {
        printError('Failed to get amber to prefetch tiles_ctl');
        return LaunchResult.failed();
      }

      // Start up a package server.
      const String packageServerName = 'flutter_tool';
      fuchsiaPackageServer = FuchsiaPackageServer(
          packageRepo.path, packageServerName, host, port);
      if (!await fuchsiaPackageServer.start()) {
        printError('Failed to start the Fuchsia package server');
        return LaunchResult.failed();
      }
      final File farArchive = package.farArchive(
          debuggingOptions.buildInfo.mode);
      if (!await fuchsiaPackageServer.addPackage(farArchive)) {
        printError('Failed to add package to the package server');
        return LaunchResult.failed();
      }

      // Teach the package controller about the package server.
      if (!await fuchsiaDeviceTools.amberCtl.addRepoCfg(this, fuchsiaPackageServer)) {
        printError('Failed to teach amber about the package server');
        return LaunchResult.failed();
      }
      serverRegistered = true;

      // Tell the package controller to prefetch the app.
      if (!await fuchsiaDeviceTools.amberCtl.pkgCtlResolve(
          this, fuchsiaPackageServer, appName)) {
        printError('Failed to get pkgctl to prefetch the package');
        return LaunchResult.failed();
      }

      // Ensure tiles_ctl is started, and start the app.
      if (!await FuchsiaTilesCtl.ensureStarted(this)) {
        printError('Failed to ensure that tiles is started on the device');
        return LaunchResult.failed();
      }

      // Instruct tiles_ctl to start the app.
      final String fuchsiaUrl =
          'fuchsia-pkg://$packageServerName/$appName#meta/$appName.cmx';
      if (!await fuchsiaDeviceTools.tilesCtl.add(this, fuchsiaUrl, <String>[])) {
        printError('Failed to add the app to tiles');
        return LaunchResult.failed();
      }
    } finally {
      // Try to un-teach the package controller about the package server if
      // needed.
      if (serverRegistered) {
        await fuchsiaDeviceTools.amberCtl.pkgCtlRepoRemove(this, fuchsiaPackageServer);
      }
      // Shutdown the package server and delete the package repo;
      fuchsiaPackageServer?.stop();
      packageRepo.deleteSync(recursive: true);
      status.cancel();
    }

    if (!debuggingOptions.buildInfo.isDebug &&
        !debuggingOptions.buildInfo.isProfile) {
      return LaunchResult.succeeded();
    }

    // In a debug or profile build, try to find the observatory uri.
    final FuchsiaIsolateDiscoveryProtocol discovery =
        getIsolateDiscoveryProtocol(appName);
    try {
      final Uri observatoryUri = await discovery.uri;
      return LaunchResult.succeeded(observatoryUri: observatoryUri);
    } finally {
      discovery.dispose();
    }
  }

  @override
  Future<bool> stopApp(covariant FuchsiaApp app) async {
    final int appKey = await FuchsiaTilesCtl.findAppKey(this, app.id);
    if (appKey != -1) {
      if (!await fuchsiaDeviceTools.tilesCtl.remove(this, appKey)) {
        printError('tiles_ctl remove on ${app.id} failed.');
        return false;
      }
    }
    return true;
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.fuchsia;

  @override
  Future<String> get sdkNameAndVersion async {
    const String versionPath = '/pkgfs/packages/build-info/0/data/version';
    final RunResult catResult = await shell('cat $versionPath');
    if (catResult.exitCode != 0) {
      printTrace('Failed to cat $versionPath: ${catResult.stderr}');
      return 'Fuchsia';
    }
    final String version = catResult.stdout.trim();
    if (version.isEmpty) {
      printTrace('$versionPath was empty');
      return 'Fuchsia';
    }
    return 'Fuchsia $version';
  }

  @override
  DeviceLogReader getLogReader({ApplicationPackage app}) =>
      _logReader ??= _FuchsiaLogReader(this, app);
  _FuchsiaLogReader _logReader;

  @override
  DevicePortForwarder get portForwarder =>
      _portForwarder ??= _FuchsiaPortForwarder(this);
  _FuchsiaPortForwarder _portForwarder;

  @override
  void clearLogs() {}

  @override
  OverrideArtifacts get artifactOverrides {
    return _artifactOverrides ??= OverrideArtifacts(
      parent: Artifacts.instance,
      platformKernelDill: fuchsiaArtifacts.platformKernelDill,
      flutterPatchedSdk: fuchsiaArtifacts.flutterPatchedSdk,
    );
  }
  OverrideArtifacts _artifactOverrides;

  @override
  bool get supportsScreenshot => false;

  bool get ipv6 {
    // Workaround for https://github.com/dart-lang/sdk/issues/29456
    final String fragment = id.split('%').first;
    try {
      Uri.parseIPv6Address(fragment);
      return true;
    } on FormatException {
      return false;
    }
  }

  /// List the ports currently running a dart observatory.
  Future<List<int>> servicePorts() async {
    const String findCommand = 'find /hub -name vmservice-port';
    final RunResult findResult = await shell(findCommand);
    if (findResult.exitCode != 0) {
      throwToolExit("'$findCommand' on device $id failed. stderr: '${findResult.stderr}'");
      return null;
    }
    final String findOutput = findResult.stdout;
    if (findOutput.trim() == '') {
      throwToolExit(
          'No Dart Observatories found. Are you running a debug build?');
      return null;
    }
    final List<int> ports = <int>[];
    for (String path in findOutput.split('\n')) {
      if (path == '') {
        continue;
      }
      final String lsCommand = 'ls $path';
      final RunResult lsResult = await shell(lsCommand);
      if (lsResult.exitCode != 0) {
        throwToolExit("'$lsCommand' on device $id failed");
        return null;
      }
      final String lsOutput = lsResult.stdout;
      for (String line in lsOutput.split('\n')) {
        if (line == '') {
          continue;
        }
        final int port = int.tryParse(line);
        if (port != null) {
          ports.add(port);
        }
      }
    }
    return ports;
  }

  /// Run `command` on the Fuchsia device shell.
  Future<RunResult> shell(String command) async {
    if (fuchsiaArtifacts.sshConfig == null) {
      throwToolExit('Cannot interact with device. No ssh config.\n'
                    'Try setting FUCHSIA_SSH_CONFIG or FUCHSIA_BUILD_DIR.');
    }
    return await processUtils.run(<String>[
      'ssh',
      '-F',
      fuchsiaArtifacts.sshConfig.absolute.path,
      id,
      command
    ]);
  }

  /// Finds the first port running a VM matching `isolateName` from the
  /// provided set of `ports`.
  ///
  /// Returns null if no isolate port can be found.
  ///
  // TODO(jonahwilliams): replacing this with the hub will require an update
  // to the flutter_runner.
  Future<int> findIsolatePort(String isolateName, List<int> ports) async {
    for (int port in ports) {
      try {
        // Note: The square-bracket enclosure for using the IPv6 loopback
        // didn't appear to work, but when assigning to the IPv4 loopback device,
        // netstat shows that the local port is actually being used on the IPv6
        // loopback (::1).
        final Uri uri = Uri.parse('http://[$_ipv6Loopback]:$port');
        final VMService vmService = await VMService.connect(uri);
        await vmService.getVM();
        await vmService.refreshViews();
        for (FlutterView flutterView in vmService.vm.views) {
          if (flutterView.uiIsolate == null) {
            continue;
          }
          final Uri address = flutterView.owner.vmService.httpAddress;
          if (flutterView.uiIsolate.name.contains(isolateName)) {
            return address.port;
          }
        }
      } on SocketException catch (err) {
        printTrace('Failed to connect to $port: $err');
      }
    }
    throwToolExit('No ports found running $isolateName');
    return null;
  }

  FuchsiaIsolateDiscoveryProtocol getIsolateDiscoveryProtocol(
          String isolateName) =>
      FuchsiaIsolateDiscoveryProtocol(this, isolateName);

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.fuchsia.existsSync();
  }
}

class FuchsiaIsolateDiscoveryProtocol {
  FuchsiaIsolateDiscoveryProtocol(
    this._device,
    this._isolateName, [
    this._vmServiceConnector = _kDefaultFuchsiaIsolateDiscoveryConnector,
    this._pollOnce = false,
  ]);

  static const Duration _pollDuration = Duration(seconds: 10);
  final Map<int, VMService> _ports = <int, VMService>{};
  final FuchsiaDevice _device;
  final String _isolateName;
  final Completer<Uri> _foundUri = Completer<Uri>();
  final Future<VMService> Function(Uri) _vmServiceConnector;
  // whether to only poll once.
  final bool _pollOnce;
  Timer _pollingTimer;
  Status _status;

  FutureOr<Uri> get uri {
    if (_uri != null) {
      return _uri;
    }
    _status ??= logger.startProgress(
      'Waiting for a connection from $_isolateName on ${_device.name}...',
      timeout: null, // could take an arbitrary amount of time
    );
    _pollingTimer ??= Timer(_pollDuration, _findIsolate);
    return _foundUri.future.then((Uri uri) {
      _uri = uri;
      return uri;
    });
  }

  Uri _uri;

  void dispose() {
    if (!_foundUri.isCompleted) {
      _status?.cancel();
      _status = null;
      _pollingTimer?.cancel();
      _pollingTimer = null;
      _foundUri.completeError(Exception('Did not complete'));
    }
  }

  Future<void> _findIsolate() async {
    final List<int> ports = await _device.servicePorts();
    for (int port in ports) {
      VMService service;
      if (_ports.containsKey(port)) {
        service = _ports[port];
      } else {
        final int localPort = await _device.portForwarder.forward(port);
        try {
          final Uri uri = Uri.parse('http://[$_ipv6Loopback]:$localPort');
          service = await _vmServiceConnector(uri);
          _ports[port] = service;
        } on SocketException catch (err) {
          printTrace('Failed to connect to $localPort: $err');
          continue;
        }
      }
      await service.getVM();
      await service.refreshViews();
      for (FlutterView flutterView in service.vm.views) {
        if (flutterView.uiIsolate == null) {
          continue;
        }
        final Uri address = flutterView.owner.vmService.httpAddress;
        if (flutterView.uiIsolate.name.contains(_isolateName)) {
          _foundUri.complete(_device.ipv6
              ? Uri.parse('http://[$_ipv6Loopback]:${address.port}/')
              : Uri.parse('http://$_ipv4Loopback:${address.port}/'));
          _status.stop();
          return;
        }
      }
    }
    if (_pollOnce) {
      _foundUri.completeError(Exception('Max iterations exceeded'));
      _status.stop();
      return;
    }
    _pollingTimer = Timer(_pollDuration, _findIsolate);
  }
}

class _FuchsiaPortForwarder extends DevicePortForwarder {
  _FuchsiaPortForwarder(this.device);

  final FuchsiaDevice device;
  final Map<int, Process> _processes = <int, Process>{};

  @override
  Future<int> forward(int devicePort, {int hostPort}) async {
    hostPort ??= await os.findFreePort();
    if (hostPort == 0) {
      throwToolExit('Failed to forward port $devicePort. No free host-side ports');
    }
    // Note: the provided command works around a bug in -N, see US-515
    // for more explanation.
    final List<String> command = <String>[
      'ssh',
      '-6',
      '-F',
      fuchsiaArtifacts.sshConfig.absolute.path,
      '-nNT',
      '-vvv',
      '-f',
      '-L',
      '$hostPort:$_ipv4Loopback:$devicePort',
      device.id,
      'true',
    ];
    final Process process = await processManager.start(command);
    unawaited(process.exitCode.then((int exitCode) {
      if (exitCode != 0) {
        throwToolExit('Failed to forward port:$devicePort');
      }
    }));
    _processes[hostPort] = process;
    _forwardedPorts.add(ForwardedPort(hostPort, devicePort));
    return hostPort;
  }

  @override
  List<ForwardedPort> get forwardedPorts => _forwardedPorts;
  final List<ForwardedPort> _forwardedPorts = <ForwardedPort>[];

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async {
    _forwardedPorts.remove(forwardedPort);
    final Process process = _processes.remove(forwardedPort.hostPort);
    process?.kill();
    final List<String> command = <String>[
      'ssh',
      '-F',
      fuchsiaArtifacts.sshConfig.absolute.path,
      '-O',
      'cancel',
      '-vvv',
      '-L',
      '${forwardedPort.hostPort}:$_ipv4Loopback:${forwardedPort.devicePort}',
      device.id
    ];
    final ProcessResult result = await processManager.run(command);
    if (result.exitCode != 0) {
      throwToolExit(result.stderr);
    }
  }
}
