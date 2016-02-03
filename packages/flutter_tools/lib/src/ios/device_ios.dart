// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/process.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../toolchain.dart';

class IOSDeviceDiscovery extends DeviceDiscovery {
  List<Device> _devices = <Device>[];

  bool get supportsPlatform => Platform.isMacOS;

  Future init() {
    _devices = IOSDevice.getAttachedDevices();
    return new Future.value();
  }

  List<Device> get devices => _devices;
}

class IOSSimulatorDiscovery extends DeviceDiscovery {
  List<Device> _devices = <Device>[];

  bool get supportsPlatform => Platform.isMacOS;

  Future init() {
    _devices = IOSSimulator.getAttachedDevices();
    return new Future.value();
  }

  List<Device> get devices => _devices;
}

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
    return runSync([informerPath, '-k', 'DeviceName', '-u', deviceID]).trim();
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
    bool clearLogs: false,
    bool startPaused: false,
    int debugPort: observatoryDefaultPort,
    Map<String, dynamic> platformArgs
  }) async {
    // TODO(chinmaygarde): Use checked, mainPath, route, clearLogs.
    // TODO(devoncarew): Handle startPaused, debugPort.
    printTrace('Building ${app.name} for $id');

    // Step 1: Install the precompiled application if necessary
    bool buildResult = await _buildIOSXcodeProject(app, true);

    if (!buildResult) {
      printError('Could not build the precompiled application for the device');
      return false;
    }

    // Step 2: Check that the application exists at the specified path
    Directory bundle = new Directory(path.join(app.localPath, 'build', 'Release-iphoneos', 'Runner.app'));

    bool bundleExists = bundle.existsSync();
    if (!bundleExists) {
      printError('Could not find the built application bundle at ${bundle.path}');
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
      printError('Could not install ${bundle.path} on $id');
      return false;
    }

    printTrace('Installation successful');
    return true;
  }

  @override
  Future<bool> stopApp(ApplicationPackage app) async {
    // Currently we don't have a way to stop an app running on iOS.
    return false;
  }

  Future<bool> pushFile(ApplicationPackage app, String localFile, String targetFile) async {
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

  DeviceLogReader createLogReader() => new _IOSDeviceLogReader(this);
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
      printError('Multiple running simulators were detected, '
          'which is not supposed to happen.');
      for (Match match in matches) {
        if (match.groupCount > 0) {
          // TODO(devoncarew): We're killing simulator devices inside an accessor
          // method; we probably shouldn't be changing state here.
          printError('Killing simulator ${match.group(1)}');
          runSync([xcrunPath, 'simctl', 'shutdown', match.group(2)]);
        }
      }
    } else if (matches.length == 1) {
      match = matches.first;
    }

    if (match != null && match.groupCount > 0) {
      return new _IOSSimulatorInfo(match.group(2), match.group(1));
    } else {
      printTrace('No running simulators found');
      return null;
    }
  }

  String _getSimulatorPath() {
    String deviceID = id == defaultDeviceID ? _getRunningSimulatorInfo()?.id : id;
    if (deviceID == null)
      return null;
    return path.join(_homeDirectory, 'Library', 'Developer', 'CoreSimulator', 'Devices', deviceID);
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
          printStatus('Timed out waiting for iOS Simulator $id to boot.');
          return false;
        }
        if (!isConnected()) {
          printStatus('Waiting for iOS Simulator $id to boot...');
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
        printError('Unable to boot iOS Simulator $id: ', e);
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
    bool clearLogs: false,
    bool startPaused: false,
    int debugPort: observatoryDefaultPort,
    Map<String, dynamic> platformArgs
  }) async {
    // TODO(chinmaygarde): Use checked, mainPath, route.
    // TODO(devoncarew): Handle startPaused, debugPort.
    printTrace('Building ${app.name} for $id');

    if (clearLogs)
      this.clearLogs();

    // Step 1: Build the Xcode project
    bool buildResult = await _buildIOSXcodeProject(app, false);
    if (!buildResult) {
      printError('Could not build the application for the simulator');
      return false;
    }

    // Step 2: Assert that the Xcode project was successfully built
    Directory bundle = new Directory(path.join(app.localPath, 'build', 'Release-iphonesimulator', 'Runner.app'));
    bool bundleExists = await bundle.exists();
    if (!bundleExists) {
      printError('Could not find the built application bundle at ${bundle.path}');
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
      printError('Could not install the application bundle on the simulator');
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
      printError('Could not launch the freshly installed application on the simulator');
      return false;
    }

    printTrace('Successfully started ${app.name} on $id');
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

  String get logFilePath {
    return path.join(_homeDirectory, 'Library', 'Logs', 'CoreSimulator', id, 'system.log');
  }

  @override
  TargetPlatform get platform => TargetPlatform.iOSSimulator;

  DeviceLogReader createLogReader() => new _IOSSimulatorLogReader(this);

  void clearLogs() {
    File logFile = new File(logFilePath);
    if (logFile.existsSync())
      logFile.delete();
  }
}

class _IOSDeviceLogReader extends DeviceLogReader {
  _IOSDeviceLogReader(this.device);

  final IOSDevice device;

  String get name => device.name;

  // TODO(devoncarew): Support [clear].
  Future<int> logs({ bool clear: false }) async {
    if (!device.isConnected())
      return 2;

    return await runCommandAndStreamOutput(
      [device.loggerPath],
      prefix: '[$name] ',
      filter: new RegExp(r'(FlutterRunner|flutter.runner.Runner)')
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

class _IOSSimulatorLogReader extends DeviceLogReader {
  _IOSSimulatorLogReader(this.device);

  final IOSSimulator device;

  String get name => device.name;

  Future<int> logs({bool clear: false}) {
    if (!device.isConnected())
      return new Future<int>.value(2);

    if (clear)
      device.clearLogs();

    // Match the log prefix (in order to shorten it):
    //   'Jan 29 01:31:44 devoncarew-macbookpro3 SpringBoard[96648]: ...'
    RegExp mapRegex = new RegExp(r'\S+ +\S+ +\S+ \S+ (.+)\[\d+\]\)?: (.*)$');
    // Jan 31 19:23:28 --- last message repeated 1 time ---
    RegExp lastMessageRegex = new RegExp(r'\S+ +\S+ +\S+ (--- .* ---)$');

    // This filter matches many Flutter lines in the log:
    // new RegExp(r'(FlutterRunner|flutter.runner.Runner|$id)'), but it misses
    // a fair number, including ones that would be useful in diagnosing crashes.
    // For now, we're not filtering the log file (but do clear it with each run).

    Future<int> result = runCommandAndStreamOutput(
      <String>['tail', '-n', '+0', '-F', device.logFilePath],
      prefix: '[$name] ',
      mapFunction: (String string) {
        Match match = mapRegex.matchAsPrefix(string);
        if (match != null) {
          // Filter out some messages that clearly aren't related to Flutter.
          if (string.contains(': could not find icon for representation -> com.apple.'))
            return null;
          String category = match.group(1);
          String content = match.group(2);
          if (category == 'Game Center' || category == 'itunesstored' || category == 'nanoregistrylaunchd')
            return null;
          return '$category: $content';
        }
        match = lastMessageRegex.matchAsPrefix(string);
        if (match != null)
          return match.group(1);
        return string;
      }
    );

    // Track system.log crashes.
    // ReportCrash[37965]: Saved crash report for FlutterRunner[37941]...
    runCommandAndStreamOutput(
      <String>['tail', '-F', '/private/var/log/system.log'],
      prefix: '[$name] ',
      filter: new RegExp(r' FlutterRunner\[\d+\] '),
      mapFunction: (String string) {
        Match match = mapRegex.matchAsPrefix(string);
        return match == null ? string : '${match.group(1)}: ${match.group(2)}';
      }
    );

    return result;
  }

  int get hashCode => device.logFilePath.hashCode;

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! _IOSSimulatorLogReader)
      return false;
    return other.device.logFilePath == device.logFilePath;
  }
}

class _IOSSimulatorInfo {
  final String id;
  final String name;

  _IOSSimulatorInfo(this.id, this.name);
}

final RegExp _xcodeVersionRegExp = new RegExp(r'Xcode (\d+)\..*');
final String _xcodeRequirement = 'Xcode 7.0 or greater is required to develop for iOS.';

String get _homeDirectory => path.absolute(Platform.environment['HOME']);

bool _checkXcodeVersion() {
  if (!Platform.isMacOS)
    return false;
  try {
    String version = runCheckedSync(['xcodebuild', '-version']);
    Match match = _xcodeVersionRegExp.firstMatch(version);
    if (int.parse(match[1]) < 7) {
      printError('Found "${match[0]}". $_xcodeRequirement');
      return false;
    }
  } catch (e) {
    printError('Cannot find "xcodebuid". $_xcodeRequirement');
    return false;
  }
  return true;
}

Future<bool> _buildIOSXcodeProject(ApplicationPackage app, bool isDevice) async {
  if (!FileSystemEntity.isDirectorySync(app.localPath)) {
    printError('Path "${path.absolute(app.localPath)}" does not exist.\nDid you run `flutter ios --init`?');
    return false;
  }

  if (!_checkXcodeVersion())
    return false;

  List<String> commands = [
    '/usr/bin/env', 'xcrun', 'xcodebuild', '-target', 'Runner', '-configuration', 'Release'
  ];

  if (!isDevice) {
    commands.addAll(['-sdk', 'iphonesimulator']);
  }

  try {
    runCheckedSync(commands, workingDirectory: app.localPath);
    return true;
  } catch (error) {
    return false;
  }
}
