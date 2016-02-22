// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
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

const String _xcrunPath = '/usr/bin/xcrun';

const String _simulatorPath =
  '/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/Contents/MacOS/Simulator';

class IOSSimulators extends PollingDeviceDiscovery {
  IOSSimulators() : super('IOSSimulators');

  bool get supportsPlatform => Platform.isMacOS;
  List<Device> pollingGetDevices() => IOSSimulator.getAttachedDevices();
}

/// A wrapper around the `simctl` command line tool.
class SimControl {
  static Future<bool> boot({String deviceId}) async {
    if (_isAnyConnected())
      return true;

    if (deviceId == null) {
      runDetached([_simulatorPath]);
      Future<bool> checkConnection([int attempts = 20]) async {
        if (attempts == 0) {
          printStatus('Timed out waiting for iOS Simulator to boot.');
          return false;
        }
        if (!_isAnyConnected()) {
          printStatus('Waiting for iOS Simulator to boot...');
          return await new Future.delayed(new Duration(milliseconds: 500),
            () => checkConnection(attempts - 1)
          );
        }
        return true;
      }
      return await checkConnection();
    } else {
      try {
        runCheckedSync([_xcrunPath, 'simctl', 'boot', deviceId]);
        return true;
      } catch (e) {
        printError('Unable to boot iOS Simulator $deviceId: ', e);
        return false;
      }
    }

    return false;
  }

  /// Returns a list of all available devices, both potential and connected.
  static List<SimDevice> getDevices() {
    // {
    //   "devices" : {
    //     "com.apple.CoreSimulator.SimRuntime.iOS-8-2" : [
    //       {
    //         "state" : "Shutdown",
    //         "availability" : " (unavailable, runtime profile not found)",
    //         "name" : "iPhone 4s",
    //         "udid" : "1913014C-6DCB-485D-AC6B-7CD76D322F5B"
    //       },
    //       ...

    List<String> args = <String>['simctl', 'list', '--json', 'devices'];
    printTrace('$_xcrunPath ${args.join(' ')}');
    ProcessResult results = Process.runSync(_xcrunPath, args);
    if (results.exitCode != 0) {
      printError('Error executing simctl: ${results.exitCode}\n${results.stderr}');
      return <SimDevice>[];
    }

    List<SimDevice> devices = <SimDevice>[];

    Map<String, Map<String, dynamic>> data = JSON.decode(results.stdout);
    Map<String, dynamic> devicesSection = data['devices'];

    for (String deviceCategory in devicesSection.keys) {
      List<dynamic> devicesData = devicesSection[deviceCategory];

      for (Map<String, String> data in devicesData) {
        devices.add(new SimDevice(deviceCategory, data));
      }
    }

    return devices;
  }

  /// Returns all the connected simulator devices.
  static List<SimDevice> getConnectedDevices() {
    return getDevices().where((SimDevice device) => device.isBooted).toList();
  }

  static StreamController<List<SimDevice>> _trackDevicesControler;

  /// Listens to changes in the set of connected devices. The implementation
  /// currently uses polling. Callers should be careful to call cancel() on any
  /// stream subscription when finished.
  ///
  /// TODO(devoncarew): We could investigate using the usbmuxd protocol directly.
  static Stream<List<SimDevice>> trackDevices() {
    if (_trackDevicesControler == null) {
      Timer timer;
      Set<String> deviceIds = new Set<String>();

      _trackDevicesControler = new StreamController.broadcast(
        onListen: () {
          timer = new Timer.periodic(new Duration(seconds: 4), (Timer timer) {
            List<SimDevice> devices = getConnectedDevices();

            if (_updateDeviceIds(devices, deviceIds)) {
              _trackDevicesControler.add(devices);
            }
          });
        }, onCancel: () {
          timer?.cancel();
          deviceIds.clear();
        }
      );
    }

    return _trackDevicesControler.stream;
  }

  /// Update the cached set of device IDs and return whether there were any changes.
  static bool _updateDeviceIds(List<SimDevice> devices, Set<String> deviceIds) {
    Set<String> newIds = new Set<String>.from(devices.map((SimDevice device) => device.udid));

    bool changed = false;

    for (String id in newIds) {
      if (!deviceIds.contains(id))
        changed = true;
    }

    for (String id in deviceIds) {
      if (!newIds.contains(id))
        changed = true;
    }

    deviceIds.clear();
    deviceIds.addAll(newIds);

    return changed;
  }

  static bool _isAnyConnected() => getConnectedDevices().isNotEmpty;

  static void install(String deviceId, String appPath) {
    runCheckedSync([_xcrunPath, 'simctl', 'install', deviceId, appPath]);
  }

  static void launch(String deviceId, String appIdentifier, [List<String> launchArgs]) {
    List<String> args = [_xcrunPath, 'simctl', 'launch', deviceId, appIdentifier];
    if (launchArgs != null)
      args.addAll(launchArgs);
    runCheckedSync(args);
  }
}

class SimDevice {
  SimDevice(this.category, this.data);

  final String category;
  final Map<String, String> data;

  String get state => data['state'];
  String get availability => data['availability'];
  String get name => data['name'];
  String get udid => data['udid'];

  bool get isBooted => state == 'Booted';
}

class IOSSimulator extends Device {
  IOSSimulator(String id, { this.name }) : super(id);

  static List<IOSSimulator> getAttachedDevices() {
    if (!xcode.isInstalledAndMeetsVersionCheck)
      return <IOSSimulator>[];

    return SimControl.getConnectedDevices().map((SimDevice device) {
      return new IOSSimulator(device.udid, name: device.name);
    }).toList();
  }

  final String name;

  String get xcrunPath => path.join('/usr', 'bin', 'xcrun');

  String _getSimulatorPath() {
    return path.join(homeDirectory, 'Library', 'Developer', 'CoreSimulator', 'Devices', id);
  }

  String _getSimulatorAppHomeDirectory(ApplicationPackage app) {
    String simulatorPath = _getSimulatorPath();
    if (simulatorPath == null)
      return null;
    return path.join(simulatorPath, 'data');
  }

  @override
  bool installApp(ApplicationPackage app) {
    if (!isConnected())
      return false;

    try {
      SimControl.install(id, app.localPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  bool isConnected() {
    if (!Platform.isMacOS)
      return false;
    return SimControl.getConnectedDevices().any((SimDevice device) => device.udid == id);
  }

  @override
  bool isSupported() {
    if (!Platform.isMacOS) {
      _supportMessage = "Not supported on a non Mac host";
      return false;
    }

    // Step 1: Check if the device is part of a blacklisted category.
    //         We do not support WatchOS or tvOS devices.

    RegExp blacklist = new RegExp(r'Apple (TV|Watch)', caseSensitive: false);

    if (blacklist.hasMatch(name)) {
      _supportMessage = "Flutter does not support either the Apple TV or Watch. Choose an iPhone 5s or above.";
      return false;
    }

    // Step 2: Check if the device must be rejected because of its version.
    //         There is an artitifical check on older simulators where arm64
    //         targetted applications cannot be run (even though the
    //         Flutter runner on the simulator is completely different).

    RegExp versionExp = new RegExp(r'iPhone ([0-9])+');
    Match match = versionExp.firstMatch(name);

    if (match == null) {
      // Not an iPhone. All available non-iPhone simulators are compatible.
      return true;
    }

    if (int.parse(match.group(1)) > 5) {
      // iPhones 6 and above are always fine.
      return true;
    }

    // The 's' subtype of 5 is compatible.
    if (name.contains('iPhone 5s')) {
      return true;
    }

    _supportMessage = "The simulator version is too old. Choose an iPhone 5s or above.";
    return false;
  }

  String _supportMessage;

  @override
  String supportMessage() {
    if (isSupported()) {
      return "Supported";
    }

    return _supportMessage != null ? _supportMessage : "Unknown";
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
    // TODO(chinmaygarde): Use mainPath, route.
    printTrace('Building ${app.name} for $id.');

    if (clearLogs)
      this.clearLogs();

    // Step 1: Build the Xcode project.
    bool buildResult = await buildIOSXcodeProject(app, buildForDevice: false);
    if (!buildResult) {
      printError('Could not build the application for the simulator.');
      return false;
    }

    // Step 2: Assert that the Xcode project was successfully built.
    Directory bundle = new Directory(path.join(app.localPath, 'build', 'Release-iphonesimulator', 'Runner.app'));
    bool bundleExists = await bundle.exists();
    if (!bundleExists) {
      printError('Could not find the built application bundle at ${bundle.path}.');
      return false;
    }

    // Step 3: Install the updated bundle to the simulator.
    SimControl.install(id, path.absolute(bundle.path));

    // Step 4: Prepare launch arguments.
    List<String> args = <String>[];

    if (checked)
      args.add("--enable-checked-mode");

    if (startPaused)
      args.add("--start-paused");

    if (debugPort != observatoryDefaultPort)
      args.add("--observatory-port=$debugPort");

    // Step 5: Launch the updated application in the simulator.
    try {
      SimControl.launch(id, app.id, args);
    } catch (error) {
      printError('$error');
      return false;
    }

    printTrace('Successfully started ${app.name} on $id.');

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
      runCheckedSync(<String>['cp', localFile, path.join(simulatorHomeDirectory, targetFile)]);
      return true;
    }
    return false;
  }

  String get logFilePath {
    return path.join(homeDirectory, 'Library', 'Logs', 'CoreSimulator', id, 'system.log');
  }

  @override
  TargetPlatform get platform => TargetPlatform.iOSSimulator;

  DeviceLogReader createLogReader() => new _IOSSimulatorLogReader(this);

  void clearLogs() {
    File logFile = new File(logFilePath);
    if (logFile.existsSync()) {
      RandomAccessFile randomFile = logFile.openSync(mode: FileMode.WRITE);
      randomFile.truncateSync(0);
      randomFile.closeSync();
    }
  }

  void ensureLogsExists() {
    File logFile = new File(logFilePath);
    if (!logFile.existsSync())
      logFile.writeAsBytesSync(<int>[]);
  }
}

class _IOSSimulatorLogReader extends DeviceLogReader {
  _IOSSimulatorLogReader(this.device);

  final IOSSimulator device;

  bool _lastWasFiltered = false;

  String get name => device.name;

  Future<int> logs({ bool clear: false, bool showPrefix: false }) async {
    if (!device.isConnected())
      return 2;

    if (clear)
      device.clearLogs();

    device.ensureLogsExists();

    // Match the log prefix (in order to shorten it):
    //   'Jan 29 01:31:44 devoncarew-macbookpro3 SpringBoard[96648]: ...'
    RegExp mapRegex = new RegExp(r'\S+ +\S+ +\S+ \S+ (.+)\[\d+\]\)?: (.*)$');
    // Jan 31 19:23:28 --- last message repeated 1 time ---
    RegExp lastMessageRegex = new RegExp(r'\S+ +\S+ +\S+ --- (.*) ---$');

    // This filter matches many Flutter lines in the log:
    // new RegExp(r'(FlutterRunner|flutter.runner.Runner|$id)'), but it misses
    // a fair number, including ones that would be useful in diagnosing crashes.
    // For now, we're not filtering the log file (but do clear it with each run).

    Future<int> result = runCommandAndStreamOutput(
      <String>['tail', '-n', '+0', '-F', device.logFilePath],
      prefix: showPrefix ? '[$name] ' : '',
      mapFunction: (String string) {
        Match match = mapRegex.matchAsPrefix(string);
        if (match != null) {
          _lastWasFiltered = true;

          // Filter out some messages that clearly aren't related to Flutter.
          if (string.contains(': could not find icon for representation -> com.apple.'))
            return null;
          String category = match.group(1);
          String content = match.group(2);
          if (category == 'Game Center' || category == 'itunesstored' || category == 'nanoregistrylaunchd' ||
              category == 'mstreamd' || category == 'syncdefaultsd' || category == 'companionappd' ||
              category == 'searchd')
            return null;

          _lastWasFiltered = false;

          if (category == 'Runner')
            return content;
          return '$category: $content';
        }
        match = lastMessageRegex.matchAsPrefix(string);
        if (match != null && !_lastWasFiltered)
          return '(${match.group(1)})';
        return string;
      }
    );

    // Track system.log crashes.
    // ReportCrash[37965]: Saved crash report for FlutterRunner[37941]...
    runCommandAndStreamOutput(
      <String>['tail', '-F', '/private/var/log/system.log'],
      prefix: showPrefix ? '[$name] ' : '',
      filter: new RegExp(r' FlutterRunner\[\d+\] '),
      mapFunction: (String string) {
        Match match = mapRegex.matchAsPrefix(string);
        return match == null ? string : '${match.group(1)}: ${match.group(2)}';
      }
    );

    return await result;
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
