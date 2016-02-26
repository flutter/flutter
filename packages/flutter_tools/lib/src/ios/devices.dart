// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/common.dart';
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

  bool get supportsPlatform => Platform.isMacOS;
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

  final String name;

  bool get isLocalEmulator => false;

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

    printTrace('Installation successful.');
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
  TargetPlatform get platform => TargetPlatform.iOS;

  DeviceLogReader createLogReader() => new _IOSDeviceLogReader(this);
}

class _IOSDeviceLogReader extends DeviceLogReader {
  _IOSDeviceLogReader(this.device);

  final IOSDevice device;

  String get name => device.name;

  // TODO(devoncarew): Support [clear].
  Future<int> logs({ bool clear: false, bool showPrefix: false }) async {
    return await runCommandAndStreamOutput(
      <String>[device.loggerPath],
      prefix: showPrefix ? '[$name] ' : '',
      filter: new RegExp(r'Runner')
    );
  }

  int get hashCode => name.hashCode;

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! _IOSDeviceLogReader)
      return false;
    return other.name == name;
  }
}
