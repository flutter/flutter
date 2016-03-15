// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/common.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../globals.dart';
import '../toolchain.dart';
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

  String _debuggerPath;
  String get debuggerPath => _debuggerPath;

  String _loggerPath;
  String get loggerPath => _loggerPath;

  String _pusherPath;
  String get pusherPath => _pusherPath;

  @override
  final String name;

  _IOSDeviceLogReader _logReader;

  _IOSDevicePortForwarder _portForwarder;

  @override
  bool get isLocalEmulator => false;

  @override
  bool get supportsStartPaused => false;

  static List<IOSDevice> getAttachedDevices([IOSDevice mockIOS]) {
    if (!doctor.iosWorkflow.hasIdeviceId)
      return <IOSDevice>[];

    List<IOSDevice> devices = [];
    for (String id in _getAttachedDeviceIDs(mockIOS)) {
      String name = _getDeviceName(id, mockIOS);
      devices.add(new IOSDevice(id, name: name));
    }
    return devices;
  }

  static Iterable<String> _getAttachedDeviceIDs([IOSDevice mockIOS]) {
    String listerPath = (mockIOS != null) ? mockIOS.listerPath : _checkForCommand('idevice_id');
    try {
      String output = runSync([listerPath, '-l']);
      return output.trim().split('\n').where((String s) => s != null && s.isNotEmpty);
    } catch (e) {
      return <String>[];
    }
  }

  static String _getDeviceName(String deviceID, [IOSDevice mockIOS]) {
    String informerPath = (mockIOS != null)
        ? mockIOS.informerPath
        : _checkForCommand('ideviceinfo');
    return runSync([informerPath, '-k', 'DeviceName', '-u', deviceID]).trim();
  }

  static final Map<String, String> _commandMap = {};
  static String _checkForCommand(
    String command, [
    String macInstructions = _ideviceinstallerInstructions
  ]) {
    return _commandMap.putIfAbsent(command, () {
      try {
        command = runCheckedSync(['which', command]).trim();
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
  bool installApp(ApplicationPackage app) {
    try {
      runCheckedSync([installerPath, '-i', app.localPath]);
      return true;
    } catch (e) {
      return false;
    }
    return false;
  }

  @override
  bool isSupported() => true;

  @override
  bool isAppInstalled(ApplicationPackage app) {
    try {
      String apps = runCheckedSync([installerPath, '--list-apps']);
      if (new RegExp(app.id, multiLine: true).hasMatch(apps)) {
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  @override
  Future<bool> startApp(
    ApplicationPackage app,
    Toolchain toolchain, {
    String mainPath,
    String route,
    bool checked: true,
    bool clearLogs: false,
    bool startPaused: false,
    int debugPort: observatoryDefaultPort,
    Map<String, dynamic> platformArgs
  }) async {
    // TODO(chinmaygarde): Use checked, mainPath, route, clearLogs.
    // TODO(devoncarew): Handle startPaused, debugPort.
    printTrace('Building ${app.name} for $id');

    // Step 1: Install the precompiled application if necessary.
    bool buildResult = await buildIOSXcodeProject(app, buildForDevice: true);
    if (!buildResult) {
      printError('Could not build the precompiled application for the device.');
      return false;
    }

    // Step 2: Check that the application exists at the specified path.
    Directory bundle = new Directory(path.join(app.localPath, 'build', 'Release-iphoneos', 'Runner.app'));
    bool bundleExists = bundle.existsSync();
    if (!bundleExists) {
      printError('Could not find the built application bundle at ${bundle.path}.');
      return false;
    }

    // Step 3: Attempt to install the application on the device.
    int installationResult = await runCommandAndStreamOutput([
      '/usr/bin/env',
      'ios-deploy',
      '--id',
      id,
      '--bundle',
      bundle.path,
    ]);

    if (installationResult != 0) {
      printError('Could not install ${bundle.path} on $id.');
      return false;
    }

    return true;
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
    return false;
  }

  @override
  TargetPlatform get platform => TargetPlatform.ios_arm;

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
}

class _IOSDeviceLogReader extends DeviceLogReader {
  _IOSDeviceLogReader(this.device);

  final IOSDevice device;

  final StreamController<String> _linesStreamController =
      new StreamController<String>.broadcast();

  Process _process;
  StreamSubscription<String> _stdoutSubscription;
  StreamSubscription<String> _stderrSubscription;

  @override
  Stream<String> get lines => _linesStreamController.stream;

  @override
  String get name => device.name;

  @override
  bool get isReading => _process != null;

  @override
  Future<int> get finished {
    return _process != null ? _process.exitCode : new Future<int>.value(0);
  }

  @override
  Future<Null> start() async {
    if (_process != null) {
      throw new StateError(
        '_IOSDeviceLogReader must be stopped before it can be started.'
      );
    }
    _process = await runCommand(<String>[device.loggerPath]);
    _stdoutSubscription =
        _process.stdout.transform(UTF8.decoder)
                       .transform(const LineSplitter()).listen(_onLine);
    _stderrSubscription =
        _process.stderr.transform(UTF8.decoder)
                       .transform(const LineSplitter()).listen(_onLine);
    _process.exitCode.then(_onExit);
  }

  @override
  Future<Null> stop() async {
    if (_process == null) {
      throw new StateError(
        '_IOSDeviceLogReader must be started before it can be stopped.'
      );
    }
    _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription?.cancel();
    _stderrSubscription = null;
    await _process.kill();
    _process = null;
  }

  void _onExit(int exitCode) {
    _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription?.cancel();
    _stderrSubscription = null;
    _process = null;
  }

  RegExp _runnerRegex = new RegExp(r'Runner');

  void _onLine(String line) {
    if (!_runnerRegex.hasMatch(line))
      return;

    _linesStreamController.add(line);
  }

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! _IOSDeviceLogReader)
      return false;
    return other.name == name;
  }
}

class _IOSDevicePortForwarder extends DevicePortForwarder {
  _IOSDevicePortForwarder(this.device);

  final IOSDevice device;

  @override
  List<ForwardedPort> get forwardedPorts {
    final List<ForwardedPort> ports = <ForwardedPort>[];
    // TODO(chinmaygarde): Implement.
    return ports;
  }

  @override
  Future<int> forward(int devicePort, {int hostPort: null}) async {
    if ((hostPort == null) || (hostPort == 0)) {
      // Auto select host port.
      hostPort = await findAvailablePort();
    }
    // TODO(chinmaygarde): Implement.
    return hostPort;
  }

  @override
  Future<Null> unforward(ForwardedPort forwardedPort) async {
    // TODO(chinmaygarde): Implement.
  }
}
