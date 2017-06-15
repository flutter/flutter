// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/port_scanner.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../device.dart';
import '../doctor.dart';
import '../globals.dart';
import '../protocol_discovery.dart';
import 'mac.dart';

const String _kIdeviceinstallerInstructions =
    'To work with iOS devices, please install ideviceinstaller. To install, run:\n'
    'brew update\n'
    'brew install ideviceinstaller.';

const Duration kPortForwardTimeout = const Duration(seconds: 10);

class IOSDevices extends PollingDeviceDiscovery {
  IOSDevices() : super('iOS devices');

  @override
  bool get supportsPlatform => platform.isMacOS;

  @override
  bool get canListAnything => doctor.iosWorkflow.canListDevices;

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
    _screenshotPath = _checkForCommand('idevicescreenshot');
    _pusherPath = _checkForCommand(
      'ios-deploy',
      'To copy files to iOS devices, please install ios-deploy. To install, run:\n'
      'brew update\n'
      'brew install ios-deploy'
    );
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

  String _screenshotPath;
  String get screenshotPath => _screenshotPath;

  String _pusherPath;
  String get pusherPath => _pusherPath;

  @override
  bool get supportsHotMode => true;

  @override
  final String name;

  Map<ApplicationPackage, _IOSDeviceLogReader> _logReaders;

  _IOSDevicePortForwarder _portForwarder;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  bool get supportsStartPaused => false;

  static List<IOSDevice> getAttachedDevices() {
    if (!doctor.iosWorkflow.hasIDeviceId)
      return <IOSDevice>[];

    final List<IOSDevice> devices = <IOSDevice>[];
    for (String id in _getAttachedDeviceIDs()) {
      final String name = IOSDevice._getDeviceInfo(id, 'DeviceName');
      devices.add(new IOSDevice(id, name: name));
    }
    return devices;
  }

  static Iterable<String> _getAttachedDeviceIDs() {
    final String listerPath = _checkForCommand('idevice_id');
    try {
      final String output = runSync(<String>[listerPath, '-l']);
      return output.trim().split('\n').where((String s) => s != null && s.isNotEmpty);
    } catch (e) {
      return <String>[];
    }
  }

  static String _getDeviceInfo(String deviceID, String infoKey) {
    final String informerPath = _checkForCommand('ideviceinfo');
    return runSync(<String>[informerPath, '-k', infoKey, '-u', deviceID]).trim();
  }

  static String _checkForCommand(
    String command, [
    String macInstructions = _kIdeviceinstallerInstructions
  ]) {
    try {
      command = runCheckedSync(<String>['which', command]).trim();
    } catch (e) {
      if (platform.isMacOS) {
        printError('$command not found. $macInstructions');
      } else {
        printError('Cannot control iOS devices or simulators. $command is not available on your platform.');
      }
      return null;
    }
    return command;
  }

  @override
  Future<bool> isAppInstalled(ApplicationPackage app) async {
    try {
      final RunResult apps = await runCheckedAsync(<String>[installerPath, '--list-apps']);
      if (new RegExp(app.id, multiLine: true).hasMatch(apps.stdout)) {
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> installApp(ApplicationPackage app) async {
    final IOSApp iosApp = app;
    final Directory bundle = fs.directory(iosApp.deviceBundlePath);
    if (!bundle.existsSync()) {
      printError('Could not find application bundle at ${bundle.path}; have you run "flutter build ios"?');
      return false;
    }

    try {
      await runCheckedAsync(<String>[installerPath, '-i', iosApp.deviceBundlePath]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> uninstallApp(ApplicationPackage app) async {
    try {
      await runCheckedAsync(<String>[installerPath, '-U', app.id]);
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
    bool prebuiltApplication: false,
    String kernelPath,
    bool applicationNeedsRebuild: false,
  }) async {
    if (!prebuiltApplication) {
      // TODO(chinmaygarde): Use mainPath, route.
      printTrace('Building ${app.name} for $id');

      // Step 1: Build the precompiled/DBC application if necessary.
      final XcodeBuildResult buildResult = await buildXcodeProject(app: app, mode: mode, target: mainPath, buildForDevice: true);
      if (!buildResult.success) {
        printError('Could not build the precompiled application for the device.');
        await diagnoseXcodeBuildFailure(buildResult, app);
        printError('');
        return new LaunchResult.failed();
      }
    } else {
      if (!await installApp(app))
        return new LaunchResult.failed();
    }

    // Step 2: Check that the application exists at the specified path.
    final IOSApp iosApp = app;
    final Directory bundle = fs.directory(iosApp.deviceBundlePath);
    if (!bundle.existsSync()) {
      printError('Could not find the built application bundle at ${bundle.path}.');
      return new LaunchResult.failed();
    }

    // Step 3: Attempt to install the application on the device.
    final List<String> launchArguments = <String>['--enable-dart-profiling'];

    if (debuggingOptions.startPaused)
      launchArguments.add('--start-paused');

    if (debuggingOptions.useTestFonts)
      launchArguments.add('--use-test-fonts');

    if (debuggingOptions.debuggingEnabled) {
      launchArguments.add('--enable-checked-mode');

      // Note: We do NOT need to set the observatory port since this is going to
      // be setup on the device. Let it pick a port automatically. We will check
      // the port picked and scrape that later.
    }

    if (debuggingOptions.enableSoftwareRendering)
      launchArguments.add('--enable-software-rendering');

    if (platformArgs['trace-startup'] ?? false)
      launchArguments.add('--trace-startup');

    final List<String> launchCommand = <String>[
      '/usr/bin/env',
      'ios-deploy',
      '--id',
      id,
      '--bundle',
      bundle.path,
      '--no-wifi',
      '--justlaunch',
    ];

    if (launchArguments.isNotEmpty) {
      launchCommand.add('--args');
      launchCommand.add('${launchArguments.join(" ")}');
    }

    int installationResult = -1;
    Uri localObservatoryUri;
    Uri localDiagnosticUri;

    if (!debuggingOptions.debuggingEnabled) {
      // If debugging is not enabled, just launch the application and continue.
      printTrace('Debugging is not enabled');
      installationResult = await runCommandAndStreamOutput(launchCommand, trace: true);
    } else {
      // Debugging is enabled, look for the observatory and diagnostic server
      // ports post launch.
      printTrace('Debugging is enabled, connecting to observatory and the diagnostic server');

      // TODO(danrubel): The Android device class does something similar to this code below.
      // The various Device subclasses should be refactored and common code moved into the superclass.
      final ProtocolDiscovery observatoryDiscovery = new ProtocolDiscovery.observatory(
        getLogReader(app: app), portForwarder: portForwarder, hostPort: debuggingOptions.observatoryPort);
      final ProtocolDiscovery diagnosticDiscovery = new ProtocolDiscovery.diagnosticService(
        getLogReader(app: app), portForwarder: portForwarder, hostPort: debuggingOptions.diagnosticPort);

      final Future<Uri> forwardObservatoryUri = observatoryDiscovery.uri;
      Future<Uri> forwardDiagnosticUri;
      if (debuggingOptions.buildMode == BuildMode.debug) {
        forwardDiagnosticUri = diagnosticDiscovery.uri;
      } else {
        forwardDiagnosticUri = new Future<Uri>.value(null);
      }

      final Future<int> launch = runCommandAndStreamOutput(launchCommand, trace: true);

      final List<Uri> uris = await launch.then<List<Uri>>((int result) async {
        installationResult = result;

        if (result != 0) {
          printTrace('Failed to launch the application on device.');
          return <Uri>[null, null];
        }

        printTrace('Application launched on the device. Attempting to forward ports.');
        return await Future.wait(<Future<Uri>>[forwardObservatoryUri, forwardDiagnosticUri]);
      }).whenComplete(() {
        observatoryDiscovery.cancel();
        diagnosticDiscovery.cancel();
      });

      localObservatoryUri = uris[0];
      localDiagnosticUri = uris[1];
    }

    if (installationResult != 0) {
      printError('Could not install ${bundle.path} on $id.');
      printError('Try launching Xcode and selecting "Product > Run" to fix the problem:');
      printError('  open ios/Runner.xcworkspace');
      printError('');
      return new LaunchResult.failed();
    }

    return new LaunchResult.succeeded(observatoryUri: localObservatoryUri, diagnosticUri: localDiagnosticUri);
  }

  @override
  Future<bool> stopApp(ApplicationPackage app) async {
    // Currently we don't have a way to stop an app running on iOS.
    return false;
  }

  Future<bool> pushFile(ApplicationPackage app, String localFile, String targetFile) async {
    if (platform.isMacOS) {
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
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  Future<String> get sdkNameAndVersion async => 'iOS $_sdkVersion ($_buildVersion)';

  String get _sdkVersion => _getDeviceInfo(id, 'ProductVersion');

  String get _buildVersion => _getDeviceInfo(id, 'BuildVersion');

  @override
  DeviceLogReader getLogReader({ApplicationPackage app}) {
    _logReaders ??= <ApplicationPackage, _IOSDeviceLogReader>{};
    return _logReaders.putIfAbsent(app, () => new _IOSDeviceLogReader(this, app));
  }

  @override
  DevicePortForwarder get portForwarder => _portForwarder ??= new _IOSDevicePortForwarder(this);

  @override
  void clearLogs() {
  }

  @override
  bool get supportsScreenshot => screenshotPath != null && screenshotPath.isNotEmpty;

  @override
  Future<Null> takeScreenshot(File outputFile) {
    return runCheckedAsync(<String>[screenshotPath, outputFile.path]);
  }
}

class _IOSDeviceLogReader extends DeviceLogReader {
  RegExp _lineRegex;

  _IOSDeviceLogReader(this.device, ApplicationPackage app) {
    _linesController = new StreamController<String>.broadcast(
      onListen: _start,
      onCancel: _stop
    );

    // Match for lines for the runner in syslog.
    //
    // iOS 9 format:  Runner[297] <Notice>:
    // iOS 10 format: Runner(libsystem_asl.dylib)[297] <Notice>:
    final String appName = app == null ? '' : app.name.replaceAll('.app', '');
    _lineRegex = new RegExp(appName + r'(\(.*\))?\[[\d]+\] <[A-Za-z]+>: ');
  }

  final IOSDevice device;

  StreamController<String> _linesController;
  Process _process;

  @override
  Stream<String> get logLines => _linesController.stream;

  @override
  String get name => device.name;

  void _start() {
    runCommand(<String>[device.loggerPath]).then<Null>((Process process) {
      _process = process;
      _process.stdout.transform(UTF8.decoder).transform(const LineSplitter()).listen(_onLine);
      _process.stderr.transform(UTF8.decoder).transform(const LineSplitter()).listen(_onLine);
      _process.exitCode.whenComplete(() {
        if (_linesController.hasListener)
          _linesController.close();
      });
    });
  }

  void _onLine(String line) {
    final Match match = _lineRegex.firstMatch(line);

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
  _IOSDevicePortForwarder(this.device) : _forwardedPorts = <ForwardedPort>[];

  final IOSDevice device;

  final List<ForwardedPort> _forwardedPorts;

  @override
  List<ForwardedPort> get forwardedPorts => _forwardedPorts;

  @override
  Future<int> forward(int devicePort, {int hostPort: null}) async {
    if ((hostPort == null) || (hostPort == 0)) {
      // Auto select host port.
      hostPort = await portScanner.findAvailablePort();
    }

    // Usage: iproxy LOCAL_TCP_PORT DEVICE_TCP_PORT UDID
    final Process process = await runCommand(<String>[
      device.iproxyPath,
      hostPort.toString(),
      devicePort.toString(),
      device.id,
    ]);

    final ForwardedPort forwardedPort = new ForwardedPort.withContext(hostPort,
        devicePort, process);

    printTrace('Forwarded port $forwardedPort');

    _forwardedPorts.add(forwardedPort);

    return hostPort;
  }

  @override
  Future<Null> unforward(ForwardedPort forwardedPort) async {
    if (!_forwardedPorts.remove(forwardedPort)) {
      // Not in list. Nothing to remove.
      return null;
    }

    printTrace('Unforwarding port $forwardedPort');

    final Process process = forwardedPort.context;

    if (process != null) {
      processManager.killPid(process.pid);
    } else {
      printError('Forwarded port did not have a valid process');
    }

    return null;
  }
}
