// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../application_package.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../device.dart';
import '../globals.dart';
import '../vmservice.dart';
import '../protocol_discovery.dart';
import 'mac.dart';

const String _ideviceinstallerInstructions =
    'To work with iOS devices, please install ideviceinstaller.\n'
    'If you use homebrew, you can install it with "\$ brew install ideviceinstaller".';

class IOSDevices extends PollingDeviceDiscovery {
  IOSDevices() : super('IOSDevices');

  @override
  bool get supportsPlatform => Platform.isMacOS;

  @override
  List<Device> pollingGetDevices() => IOSDevice.getAttachedDevices();
}

class IOSDevice extends Device {
  IOSDevice(String id, { this.name }) : super(id) {
    _installerPath = _checkForCommand('ideviceinstaller');
    _listerPath = _checkForCommand('idevice_id');
    _informerPath = _checkForCommand('ideviceinfo');
    _iproxyPath = _checkForCommand('iproxy');
    _debuggerPath = _checkForCommand('idevicedebug');
    _loggerPath = _checkForCommand('idevicesyslog');
    _pusherPath = _checkForCommand(
        'ios-deploy',
        'To copy files to iOS devices, please install ios-deploy. '
        'You can do this using homebrew as follows:\n'
        '\$ brew tap flutter/flutter\n'
        '\$ brew install ios-deploy');
  }

  String _installerPath;
  String get installerPath => _installerPath;

  String _listerPath;
  String get listerPath => _listerPath;

  String _informerPath;
  String get informerPath => _informerPath;

  String _iproxyPath;
  String get iproxyPath => _iproxyPath;

  String _debuggerPath;
  String get debuggerPath => _debuggerPath;

  String _loggerPath;
  String get loggerPath => _loggerPath;

  String _pusherPath;
  String get pusherPath => _pusherPath;

  @override
  bool get supportsHotMode => true;

  @override
  final String name;

  _IOSDeviceLogReader _logReader;

  _IOSDevicePortForwarder _portForwarder;

  @override
  bool get isLocalEmulator => false;

  @override
  bool get supportsStartPaused => false;

  static List<IOSDevice> getAttachedDevices([IOSDevice mockIOS]) {
    if (!doctor.iosWorkflow.hasIDeviceId)
      return <IOSDevice>[];

    List<IOSDevice> devices = <IOSDevice>[];
    for (String id in _getAttachedDeviceIDs(mockIOS)) {
      String name = _getDeviceName(id, mockIOS);
      devices.add(new IOSDevice(id, name: name));
    }
    return devices;
  }

  static Iterable<String> _getAttachedDeviceIDs([IOSDevice mockIOS]) {
    String listerPath = (mockIOS != null) ? mockIOS.listerPath : _checkForCommand('idevice_id');
    try {
      String output = runSync(<String>[listerPath, '-l']);
      return output.trim().split('\n').where((String s) => s != null && s.isNotEmpty);
    } catch (e) {
      return <String>[];
    }
  }

  static String _getDeviceName(String deviceID, [IOSDevice mockIOS]) {
    String informerPath = (mockIOS != null)
        ? mockIOS.informerPath
        : _checkForCommand('ideviceinfo');
    return runSync(<String>[informerPath, '-k', 'DeviceName', '-u', deviceID]).trim();
  }

  static final Map<String, String> _commandMap = <String, String>{};
  static String _checkForCommand(
    String command, [
    String macInstructions = _ideviceinstallerInstructions
  ]) {
    return _commandMap.putIfAbsent(command, () {
      try {
        command = runCheckedSync(<String>['which', command]).trim();
      } catch (e) {
        if (Platform.isMacOS) {
          printError('$command not found. $macInstructions');
        } else {
          printError('Cannot control iOS devices or simulators. $command is not available on your platform.');
        }
      }
      return command;
    });
  }

  @override
  bool isAppInstalled(ApplicationPackage app) {
    try {
      String apps = runCheckedSync(<String>[installerPath, '--list-apps']);
      if (new RegExp(app.id, multiLine: true).hasMatch(apps)) {
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  @override
  bool installApp(ApplicationPackage app) {
    IOSApp iosApp = app;
    Directory bundle = new Directory(iosApp.deviceBundlePath);
    if (!bundle.existsSync()) {
      printError("Could not find application bundle at ${bundle.path}; have you run 'flutter build ios'?");
      return false;
    }

    try {
      runCheckedSync(<String>[installerPath, '-i', iosApp.deviceBundlePath]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  bool uninstallApp(ApplicationPackage app) {
    try {
      runCheckedSync(<String>[installerPath, '-U', app.id]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  bool isSupported() => true;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage app,
    BuildMode mode, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication: false
  }) async {
    if (!prebuiltApplication) {
      // TODO(chinmaygarde): Use checked, mainPath, route.
      // TODO(devoncarew): Handle startPaused, debugPort.
      printTrace('Building ${app.name} for $id');

      // Step 1: Build the precompiled/DBC application if necessary.
      XcodeBuildResult buildResult = await buildXcodeProject(app: app, mode: mode, target: mainPath, buildForDevice: true);
      if (!buildResult.success) {
        printError('Could not build the precompiled application for the device.');
        diagnoseXcodeBuildFailure(buildResult);
        printError('');
        return new LaunchResult.failed();
      }
    }

    // Step 2: Check that the application exists at the specified path.
    IOSApp iosApp = app;
    Directory bundle = new Directory(iosApp.deviceBundlePath);
    if (!bundle.existsSync()) {
      printError('Could not find the built application bundle at ${bundle.path}.');
      return new LaunchResult.failed();
    }

    // Step 3: Attempt to install the application on the device.
    List<String> launchArguments = <String>[];

    if (debuggingOptions.startPaused)
      launchArguments.add("--start-paused");

    if (debuggingOptions.debuggingEnabled) {
      launchArguments.add("--enable-checked-mode");

      // Note: We do NOT need to set the observatory port since this is going to
      // be setup on the device. Let it pick a port automatically. We will check
      // the port picked and scrape that later.
    }

    if (platformArgs['trace-startup'] ?? false)
      launchArguments.add('--trace-startup');

    List<String> launchCommand = <String>[
      '/usr/bin/env',
      'ios-deploy',
      '--id',
      id,
      '--bundle',
      bundle.path,
      '--justlaunch',
    ];

    if (launchArguments.length > 0) {
      launchCommand.add('--args');
      launchCommand.add('${launchArguments.join(" ")}');
    }

    int installationResult = -1;
    int localObsPort;
    int localDiagPort;

    if (!debuggingOptions.debuggingEnabled) {
      // If debugging is not enabled, just launch the application and continue.
      printTrace("Debugging is not enabled");
      installationResult = await runCommandAndStreamOutput(launchCommand, trace: true);
    } else {
      // Debugging is enabled, look for the observatory and diagnostic server
      // ports post launch.
      printTrace("Debugging is enabled, connecting to observatory and the diagnostic server");

      Future<int> forwardObsPort = _acquireAndForwardPort(ProtocolDiscovery.kObservatoryService,
                                                          debuggingOptions.observatoryPort);
      Future<int> forwardDiagPort;
      if (debuggingOptions.buildMode == BuildMode.debug) {
        forwardDiagPort = _acquireAndForwardPort(ProtocolDiscovery.kDiagnosticService,
                                                 debuggingOptions.diagnosticPort);
      } else {
        forwardDiagPort = new Future<int>.value(null);
      }

      Future<int> launch = runCommandAndStreamOutput(launchCommand, trace: true);

      List<int> ports = await launch.then((int result) async {
        installationResult = result;

        if (result != 0) {
          printTrace("Failed to launch the application on device.");
          return <int>[null, null];
        }

        printTrace("Application launched on the device. Attempting to forward ports.");
        return Future.wait(<Future<int>>[forwardObsPort, forwardDiagPort]);
      });

      printTrace("Local Observatory Port: ${ports[0]}");
      printTrace("Local Diagnostic Server Port: ${ports[1]}");

      localObsPort = ports[0];
      localDiagPort = ports[1];
    }

    if (installationResult != 0) {
      printError('Could not install ${bundle.path} on $id.');
      printError("Try launching XCode and selecting 'Product > Run' to fix the problem:");
      printError("  open ios/Runner.xcodeproj");
      printError('');
      return new LaunchResult.failed();
    }

    return new LaunchResult.succeeded(observatoryPort: localObsPort, diagnosticPort: localDiagPort);
  }

  Future<int> _acquireAndForwardPort(String serviceName, int localPort) async {
    Duration stepTimeout = const Duration(seconds: 10);

    Future<int> remote = new ProtocolDiscovery(logReader, serviceName).nextPort();

    int remotePort = await remote.timeout(stepTimeout,
        onTimeout: () {
      printTrace("Timeout while attempting to retrieve remote port for $serviceName");
      return null;
    });

    if (remotePort == null) {
      printTrace("Could not read port on device for $serviceName");
      return null;
    }

    if ((localPort == null) || (localPort == 0)) {
      localPort = await findAvailablePort();
      printTrace("Auto selected local port to $localPort");
    }

    int forwardResult = await portForwarder.forward(remotePort,
        hostPort: localPort).timeout(stepTimeout, onTimeout: () {
      printTrace("Timeout while atempting to foward port for $serviceName");
      return null;
    });

    if (forwardResult == null) {
      printTrace("Could not foward remote $serviceName port $remotePort to local port $localPort");
      return null;
    }

    printStatus('$serviceName listening on http://127.0.0.1:$localPort');
    return localPort;
  }

  @override
  Future<bool> restartApp(
    ApplicationPackage package,
    LaunchResult result, {
    String mainPath,
    VMService observatory,
    bool prebuiltApplication: false
  }) async {
    throw 'unsupported';
  }

  @override
  Future<bool> stopApp(ApplicationPackage app) async {
    // Currently we don't have a way to stop an app running on iOS.
    return false;
  }

  Future<bool> pushFile(ApplicationPackage app, String localFile, String targetFile) async {
    if (Platform.isMacOS) {
      runSync(<String>[
        pusherPath,
        '-t',
        '1',
        '--bundle_id',
        app.id,
        '--upload',
        localFile,
        '--to',
        targetFile
      ]);
      return true;
    } else {
      return false;
    }
  }

  @override
  TargetPlatform get platform => TargetPlatform.ios;

  @override
  DeviceLogReader get logReader {
    if (_logReader == null)
      _logReader = new _IOSDeviceLogReader(this);

    return _logReader;
  }

  @override
  DevicePortForwarder get portForwarder {
    if (_portForwarder == null)
      _portForwarder = new _IOSDevicePortForwarder(this);

    return _portForwarder;
  }

  @override
  void clearLogs() {
  }

  @override
  bool get supportsScreenshot => false;

  @override
  Future<bool> takeScreenshot(File outputFile) {
    // We could use idevicescreenshot here (installed along with the brew
    // ideviceinstaller tools). It however requires a developer disk image on
    // the device.

    return new Future<bool>.value(false);
  }
}

class _IOSDeviceLogReader extends DeviceLogReader {
  _IOSDeviceLogReader(this.device) {
    _linesController = new StreamController<String>.broadcast(
     onListen: _start,
     onCancel: _stop
   );
  }

  final IOSDevice device;

  StreamController<String> _linesController;
  Process _process;

  @override
  Stream<String> get logLines => _linesController.stream;

  @override
  String get name => device.name;

  void _start() {
    runCommand(<String>[device.loggerPath]).then((Process process) {
      _process = process;
      _process.stdout.transform(UTF8.decoder).transform(const LineSplitter()).listen(_onLine);
      _process.stderr.transform(UTF8.decoder).transform(const LineSplitter()).listen(_onLine);

      _process.exitCode.then((int code) {
        if (_linesController.hasListener)
          _linesController.close();
      });
    });
  }

  // Match for lines for the runner in syslog.
  //
  // iOS 9 format:  Runner[297] <Notice>:
  // iOS 10 format: Runner(libsystem_asl.dylib)[297] <Notice>:
  static final RegExp _runnerRegex = new RegExp(r'Runner(\(.*\))?\[[\d]+\] <[A-Za-z]+>: ');

  void _onLine(String line) {
    Match match = _runnerRegex.firstMatch(line);

    if (match != null) {
      // Only display the log line after the initial device and executable information.
      _linesController.add(line.substring(match.end));
    }
  }

  void _stop() {
    _process?.kill();
  }
}

class _IOSDevicePortForwarder extends DevicePortForwarder {
  _IOSDevicePortForwarder(this.device) : _forwardedPorts = new List<ForwardedPort>();

  final IOSDevice device;

  final List<ForwardedPort> _forwardedPorts;

  @override
  List<ForwardedPort> get forwardedPorts => _forwardedPorts;

  @override
  Future<int> forward(int devicePort, {int hostPort: null}) async {
    if ((hostPort == null) || (hostPort == 0)) {
      // Auto select host port.
      hostPort = await findAvailablePort();
    }

    // Usage: iproxy LOCAL_TCP_PORT DEVICE_TCP_PORT UDID
    Process process = await runCommand(<String>[
      device.iproxyPath,
      hostPort.toString(),
      devicePort.toString(),
      device.id,
    ]);

    ForwardedPort forwardedPort = new ForwardedPort.withContext(hostPort,
        devicePort, process);

    printTrace("Forwarded port $forwardedPort");

    _forwardedPorts.add(forwardedPort);

    return 1;
  }

  @override
  Future<Null> unforward(ForwardedPort forwardedPort) async {
    if (!_forwardedPorts.remove(forwardedPort)) {
      // Not in list. Nothing to remove.
      return null;
    }

    printTrace("Unforwarding port $forwardedPort");

    Process process = forwardedPort.context;

    if (process != null) {
      Process.killPid(process.pid);
    } else {
      printError("Forwarded port did not have a valid process");
    }

    return null;
  }
}
