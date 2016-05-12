// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../device.dart';
import '../globals.dart';
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
  bool installApp(ApplicationPackage app) {
    try {
      runCheckedSync(<String>[installerPath, '-i', app.localPath]);
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
  Future<LaunchResult> startApp(
    ApplicationPackage app, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs
  }) async {
    // TODO(chinmaygarde): Use checked, mainPath, route.
    // TODO(devoncarew): Handle startPaused, debugPort.
    printTrace('Building ${app.name} for $id');

    // Step 1: Install the precompiled application if necessary.
    bool buildResult = await buildIOSXcodeProject(app, buildForDevice: true);
    if (!buildResult) {
      printError('Could not build the precompiled application for the device.');
      return new LaunchResult.failed();
    }

    // Step 2: Check that the application exists at the specified path.
    Directory bundle = new Directory(path.join(app.localPath, 'build', 'Release-iphoneos', 'Runner.app'));
    bool bundleExists = bundle.existsSync();
    if (!bundleExists) {
      printError('Could not find the built application bundle at ${bundle.path}.');
      return new LaunchResult.failed();
    }

    // Step 3: Attempt to install the application on the device.
    int installationResult = await runCommandAndStreamOutput(<String>[
      '/usr/bin/env',
      'ios-deploy',
      '--id',
      id,
      '--bundle',
      bundle.path,
    ]);

    if (installationResult != 0) {
      printError('Could not install ${bundle.path} on $id.');
      return new LaunchResult.failed();
    }

    return new LaunchResult.succeeded();
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

  static final RegExp _runnerRegex = new RegExp(r'FlutterRunner');

  void _onLine(String line) {
    if (_runnerRegex.hasMatch(line))
      _linesController.add(line);
  }

  void _stop() {
    _process?.kill();
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
