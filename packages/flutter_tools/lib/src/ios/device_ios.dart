// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/logging.dart';
import '../base/process.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../toolchain.dart';

class IOSDevice extends Device {
  static final String defaultDeviceID = 'default_ios_id';

  static const String _macInstructions =
      'To work with iOS devices, please install ideviceinstaller. '
      'If you use homebrew, you can install it with '
      '"\$ brew install ideviceinstaller".';

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

  String _name;
  String get name => _name;

  factory IOSDevice({String id, String name}) {
    IOSDevice device = Device.unique(id ?? defaultDeviceID, (String id) => new IOSDevice.fromId(id));
    device._name = name;
    return device;
  }

  IOSDevice.fromId(String id) : super.fromId(id) {
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

  static List<IOSDevice> getAttachedDevices([IOSDevice mockIOS]) {
    List<IOSDevice> devices = [];
    for (String id in _getAttachedDeviceIDs(mockIOS)) {
      String name = _getDeviceName(id, mockIOS);
      devices.add(new IOSDevice(id: id, name: name));
    }
    return devices;
  }

  static Iterable<String> _getAttachedDeviceIDs([IOSDevice mockIOS]) {
    String listerPath =
        (mockIOS != null) ? mockIOS.listerPath : _checkForCommand('idevice_id');
    String output;
    try {
      output = runSync([listerPath, '-l']);
    } catch (e) {
      return [];
    }
    return output.trim()
                 .split('\n')
                 .where((String s) => s != null && s.length > 0);
  }

  static String _getDeviceName(String deviceID, [IOSDevice mockIOS]) {
    String informerPath = (mockIOS != null)
        ? mockIOS.informerPath
        : _checkForCommand('ideviceinfo');
    return runSync([informerPath, '-k', 'DeviceName', '-u', deviceID]);
  }

  static final Map<String, String> _commandMap = {};
  static String _checkForCommand(
    String command, [
    String macInstructions = _macInstructions
  ]) {
    return _commandMap.putIfAbsent(command, () {
      try {
        command = runCheckedSync(['which', command]).trim();
      } catch (e) {
        if (Platform.isMacOS) {
          logging.severe('$command not found. $macInstructions');
        } else {
          logging.severe('Cannot control iOS devices or simulators.  $command is not available on your platform.');
        }
      }
      return command;
    });
  }

  @override
  bool installApp(ApplicationPackage app) {
    try {
      if (id == defaultDeviceID) {
        runCheckedSync([installerPath, '-i', app.localPath]);
      } else {
        runCheckedSync([installerPath, '-u', id, '-i', app.localPath]);
      }
      return true;
    } catch (e) {
      return false;
    }
    return false;
  }

  @override
  bool isConnected() {
    Iterable<String> ids = _getAttachedDeviceIDs();
    for (String id in ids) {
      if (id == this.id || this.id == defaultDeviceID) {
        return true;
      }
    }
    return false;
  }

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
    Map<String, dynamic> platformArgs
  }) async {
    // TODO: Use checked, mainPath, route
    logging.fine('Building ${app.name} for $id');

    // Step 1: Install the precompiled application if necessary
    bool buildResult = await _buildIOSXcodeProject(app, true);

    if (!buildResult) {
      logging.severe('Could not build the precompiled application for the device');
      return false;
    }

    // Step 2: Check that the application exists at the specified path
    Directory bundle = new Directory(path.join(app.localPath, 'build', 'Release-iphoneos', 'Runner.app'));

    bool bundleExists = await bundle.exists();
    if (!bundleExists) {
      logging.severe('Could not find the built application bundle at ${bundle.path}');
      return false;
    }

    // Step 3: Attempt to install the application on the device
    int installationResult = await runCommandAndStreamOutput([
      '/usr/bin/env',
      'ios-deploy',
      '--id',
      id,
      '--bundle',
      bundle.path,
    ]);

    if (installationResult != 0) {
      logging.severe('Could not install ${bundle.path} on $id');
      return false;
    }

    logging.fine('Installation successful');
    return true;
  }

  @override
  Future<bool> stopApp(ApplicationPackage app) async {
    // Currently we don't have a way to stop an app running on iOS.
    return false;
  }

  Future<bool> pushFile(
      ApplicationPackage app, String localFile, String targetFile) async {
    if (Platform.isMacOS) {
      runSync([
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

  /// Note that clear is not supported on iOS at this time.
  Future<int> logs({bool clear: false}) async {
    if (!isConnected()) {
      return 2;
    }
    return await runCommandAndStreamOutput([loggerPath],
        prefix: 'iOS dev: ', filter: new RegExp(r'.*SkyShell.*'));
  }
}

class IOSSimulator extends Device {
  static final String defaultDeviceID = 'default_ios_sim_id';

  static const String _macInstructions =
      'To work with iOS devices, please install ideviceinstaller. '
      'If you use homebrew, you can install it with '
      '"\$ brew install ideviceinstaller".';

  static String _xcrunPath = path.join('/usr', 'bin', 'xcrun');

  String _iOSSimPath;
  String get iOSSimPath => _iOSSimPath;

  String get xcrunPath => _xcrunPath;

  String _name;
  String get name => _name;

  factory IOSSimulator({String id, String name, String iOSSimulatorPath}) {
    IOSSimulator device = Device.unique(id ?? defaultDeviceID, (String id) => new IOSSimulator.fromId(id));
    device._name = name;
    if (iOSSimulatorPath == null) {
      iOSSimulatorPath = path.join(
        '/Applications', 'iOS Simulator.app', 'Contents', 'MacOS', 'iOS Simulator'
      );
    }
    device._iOSSimPath = iOSSimulatorPath;
    return device;
  }

  IOSSimulator.fromId(String id) : super.fromId(id);

  static _IOSSimulatorInfo _getRunningSimulatorInfo([IOSSimulator mockIOS]) {
    String xcrunPath = mockIOS != null ? mockIOS.xcrunPath : _xcrunPath;
    String output = runCheckedSync([xcrunPath, 'simctl', 'list', 'devices']);

    Match match;
    // iPhone 6s Plus (8AC808E1-6BAE-4153-BBC5-77F83814D414) (Booted)
    Iterable<Match> matches = new RegExp(
      r'[\W]*(.*) \(([^\)]+)\) \(Booted\)',
      multiLine: true
    ).allMatches(output);
    if (matches.length > 1) {
      // More than one simulator is listed as booted, which is not allowed but
      // sometimes happens erroneously.  Kill them all because we don't know
      // which one is actually running.
      logging.warning('Multiple running simulators were detected, '
          'which is not supposed to happen.');
      for (Match match in matches) {
        if (match.groupCount > 0) {
          // TODO: We're killing simulator devices inside an accessor method;
          // we probably shouldn't be changing state here.
          logging.warning('Killing simulator ${match.group(1)}');
          runSync([xcrunPath, 'simctl', 'shutdown', match.group(2)]);
        }
      }
    } else if (matches.length == 1) {
      match = matches.first;
    }

    if (match != null && match.groupCount > 0) {
      return new _IOSSimulatorInfo(match.group(2), match.group(1));
    } else {
      logging.info('No running simulators found');
      return null;
    }
  }

  String _getSimulatorPath() {
    String deviceID = id == defaultDeviceID ? _getRunningSimulatorInfo()?.id : id;
    String homeDirectory = path.absolute(Platform.environment['HOME']);
    if (deviceID == null)
      return null;
    return path.join(homeDirectory, 'Library', 'Developer', 'CoreSimulator', 'Devices', deviceID);
  }

  String _getSimulatorAppHomeDirectory(ApplicationPackage app) {
    String simulatorPath = _getSimulatorPath();
    if (simulatorPath == null)
      return null;
    return path.join(simulatorPath, 'data');
  }

  static List<IOSSimulator> getAttachedDevices([IOSSimulator mockIOS]) {
    List<IOSSimulator> devices = [];
    try {
      _IOSSimulatorInfo deviceInfo = _getRunningSimulatorInfo(mockIOS);
      if (deviceInfo != null)
        devices.add(new IOSSimulator(id: deviceInfo.id, name: deviceInfo.name));
    } catch (e) {
    }
    return devices;
  }

  Future<bool> boot() async {
    if (!Platform.isMacOS)
      return false;
    if (isConnected())
      return true;
    if (id == defaultDeviceID) {
      runDetached([iOSSimPath]);
      Future<bool> checkConnection([int attempts = 20]) async {
        if (attempts == 0) {
          logging.info('Timed out waiting for iOS Simulator $id to boot.');
          return false;
        }
        if (!isConnected()) {
          logging.info('Waiting for iOS Simulator $id to boot...');
          return await new Future.delayed(new Duration(milliseconds: 500),
              () => checkConnection(attempts - 1));
        }
        return true;
      }
      return await checkConnection();
    } else {
      try {
        runCheckedSync([xcrunPath, 'simctl', 'boot', id]);
      } catch (e) {
        logging.warning('Unable to boot iOS Simulator $id: ', e);
        return false;
      }
    }
    return false;
  }

  @override
  bool installApp(ApplicationPackage app) {
    if (!isConnected())
      return false;

    try {
      if (id == defaultDeviceID) {
        runCheckedSync([xcrunPath, 'simctl', 'install', 'booted', app.localPath]);
      } else {
        runCheckedSync([xcrunPath, 'simctl', 'install', id, app.localPath]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  bool isConnected() {
    if (!Platform.isMacOS)
      return false;
    _IOSSimulatorInfo deviceInfo = _getRunningSimulatorInfo();
    if (deviceInfo == null) {
      return false;
    } else if (deviceInfo.id == defaultDeviceID) {
      return true;
    } else {
      return _getRunningSimulatorInfo()?.id == id;
    }
  }

  @override
  bool isAppInstalled(ApplicationPackage app) {
    try {
      String simulatorHomeDirectory = _getSimulatorAppHomeDirectory(app);
      return FileSystemEntity.isDirectorySync(simulatorHomeDirectory);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> startApp(
    ApplicationPackage app,
    Toolchain toolchain, {
    String mainPath,
    String route,
    bool checked: true,
    Map<String, dynamic> platformArgs
  }) async {
    // TODO: Use checked, mainPath, route
    logging.fine('Building ${app.name} for $id');

    // Step 1: Build the Xcode project
    bool buildResult = await _buildIOSXcodeProject(app, false);
    if (!buildResult) {
      logging.severe('Could not build the application for the simulator');
      return false;
    }

    // Step 2: Assert that the Xcode project was successfully built
    Directory bundle = new Directory(path.join(app.localPath, 'build', 'Release-iphonesimulator', 'Runner.app'));
    bool bundleExists = await bundle.exists();
    if (!bundleExists) {
      logging.severe('Could not find the built application bundle at ${bundle.path}');
      return false;
    }

    // Step 3: Install the updated bundle to the simulator
    int installResult = await runCommandAndStreamOutput([
      xcrunPath,
      'simctl',
      'install',
      id == defaultDeviceID ? 'booted' : id,
      path.absolute(bundle.path)
    ]);

    if (installResult != 0) {
      logging.severe('Could not install the application bundle on the simulator');
      return false;
    }

    // Step 4: Launch the updated application in the simulator
    int launchResult = await runCommandAndStreamOutput([
      xcrunPath,
      'simctl',
      'launch',
      id == defaultDeviceID ? 'booted' : id,
      app.id
    ]);

    if (launchResult != 0) {
      logging.severe('Could not launch the freshly installed application on the simulator');
      return false;
    }

    logging.fine('Successfully started ${app.name} on $id');
    return true;
  }

  @override
  Future<bool> stopApp(ApplicationPackage app) async {
    // Currently we don't have a way to stop an app running on iOS.
    return false;
  }

  Future<bool> pushFile(
      ApplicationPackage app, String localFile, String targetFile) async {
    if (Platform.isMacOS) {
      String simulatorHomeDirectory = _getSimulatorAppHomeDirectory(app);
      runCheckedSync(['cp', localFile, path.join(simulatorHomeDirectory, targetFile)]);
      return true;
    }
    return false;
  }

  @override
  TargetPlatform get platform => TargetPlatform.iOSSimulator;

  Future<int> logs({bool clear: false}) async {
    if (!isConnected())
      return 2;

    String homeDirectory = path.absolute(Platform.environment['HOME']);
    String simulatorDeviceID = _getRunningSimulatorInfo().id;
    String logFilePath = path.join(
      homeDirectory, 'Library', 'Logs', 'CoreSimulator', simulatorDeviceID, 'system.log'
    );
    if (clear)
      runSync(['rm', logFilePath]);
    return await runCommandAndStreamOutput(
      ['tail', '-f', logFilePath],
      prefix: 'iOS sim: ',
      filter: new RegExp(r'.*SkyShell.*')
    );
  }
}

class _IOSSimulatorInfo {
  final String id;
  final String name;

  _IOSSimulatorInfo(this.id, this.name);
}

final RegExp _xcodeVersionRegExp = new RegExp(r'Xcode (\d+)\..*');
final String _xcodeRequirement = 'Xcode 7.0 or greater is required to develop for iOS.';

bool _checkXcodeVersion() {
  if (!Platform.isMacOS)
    return false;
  try {
    String version = runCheckedSync(['xcodebuild', '-version']);
    Match match = _xcodeVersionRegExp.firstMatch(version);
    if (int.parse(match[1]) < 7) {
      logging.severe('Found "${match[0]}". $_xcodeRequirement');
      return false;
    }
  } catch (e) {
    logging.severe('Cannot find "xcodebuid". $_xcodeRequirement');
    return false;
  }
  return true;
}

Future<bool> _buildIOSXcodeProject(ApplicationPackage app, bool isDevice) async {
  if (!FileSystemEntity.isDirectorySync(app.localPath)) {
    logging.severe('Path "${path.absolute(app.localPath)}" does not exist.\nDid you run `flutter ios --init`?');
    return false;
  }

  if (!_checkXcodeVersion())
    return false;

  List<String> command = [
    'xcrun', 'xcodebuild', '-target', 'Runner', '-configuration', 'Release'
  ];

  if (!isDevice) {
    command.addAll(['-sdk', 'iphonesimulator']);
  }

  ProcessResult result = await Process.runSync('/usr/bin/env', command,
      workingDirectory: app.localPath);
  return result.exitCode == 0;
}
