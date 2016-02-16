// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/globals.dart';
import '../base/process.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../services.dart';
import '../toolchain.dart';
import '../ios/setup_xcodeproj.dart';
import 'simulator.dart';

const String _ideviceinstallerInstructions =
    'To work with iOS devices, please install ideviceinstaller.\n'
    'If you use homebrew, you can install it with "\$ brew install ideviceinstaller".';

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

  bool get supportsStartPaused => false;

  static List<IOSDevice> getAttachedDevices([IOSDevice mockIOS]) {
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
  bool isConnected() => _getAttachedDeviceIDs().contains(id);

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
    bool buildResult = await _buildIOSXcodeProject(app, buildForDevice: true);
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

class IOSSimulator extends Device {
  IOSSimulator(String id, { this.name }) : super(id);

  static List<IOSSimulator> getAttachedDevices() {
    return SimControl.getConnectedDevices().map((SimDevice device) {
      return new IOSSimulator(device.udid, name: device.name);
    }).toList();
  }

  final String name;

  String get xcrunPath => path.join('/usr', 'bin', 'xcrun');

  String _getSimulatorPath() {
    return path.join(_homeDirectory, 'Library', 'Developer', 'CoreSimulator', 'Devices', id);
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
    bool buildResult = await _buildIOSXcodeProject(app, buildForDevice: false);
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
    return path.join(_homeDirectory, 'Library', 'Logs', 'CoreSimulator', id, 'system.log');
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

class _IOSDeviceLogReader extends DeviceLogReader {
  _IOSDeviceLogReader(this.device);

  final IOSDevice device;

  String get name => device.name;

  // TODO(devoncarew): Support [clear].
  Future<int> logs({ bool clear: false }) async {
    if (!device.isConnected())
      return 2;

    // TODO(devoncarew): This regex should use the CFBundleIdentifier value from
    // the user's plist (instead of `flutter.runner.Runner`).
    return await runCommandAndStreamOutput(
      <String>[device.loggerPath],
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

  bool _lastWasFiltered = false;

  String get name => device.name;

  Future<int> logs({ bool clear: false }) async {
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
      prefix: '[$name] ',
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
              category == 'mstreamd' || category == 'syncdefaultsd' || category == 'companionappd' || category == 'searchd')
            return null;

          _lastWasFiltered = false;

          if (category == 'FlutterRunner' || category == 'Runner')
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
      prefix: '[$name] ',
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

final RegExp _xcodeVersionRegExp = new RegExp(r'Xcode (\d+)\..*');
final String _xcodeRequirement = 'Xcode 7.0 or greater is required to develop for iOS.';

String get _homeDirectory => path.absolute(Platform.environment['HOME']);

bool _checkXcodeVersion() {
  if (!Platform.isMacOS)
    return false;
  try {
    String version = runCheckedSync(<String>['xcodebuild', '-version']);
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

bool _validateEngineRevision(ApplicationPackage app) {
  String skyRevision = ArtifactStore.engineRevision;
  String iosRevision = _getIOSEngineRevision(app);

  if (iosRevision != skyRevision) {
    printError("Error: incompatible sky_engine revision; please run 'flutter ios --init' to update.");
    printStatus('sky_engine revision: $skyRevision, iOS engine revision: $iosRevision');
    return false;
  } else {
    printTrace('sky_engine revision: $skyRevision, iOS engine revision: $iosRevision');
    return true;
  }
}

String _getIOSEngineRevision(ApplicationPackage app) {
  File revisionFile = new File(path.join(app.localPath, 'REVISION'));
  if (revisionFile.existsSync()) {
    return revisionFile.readAsStringSync().trim();
  } else {
    return null;
  }
}

Future<bool> _buildIOSXcodeProject(ApplicationPackage app, { bool buildForDevice }) async {
  if (!FileSystemEntity.isDirectorySync(app.localPath)) {
    printTrace('Path "${path.absolute(app.localPath)}" does not exist. Initializing the Xcode project.');
    if ((await setupXcodeProjectHarness()) != 0) {
      printError('Could not initialize the Xcode project.');
      return false;
    }
  }

  if (!_validateEngineRevision(app))
    return false;

  if (!_checkXcodeVersion())
    return false;

  // Before the build, all service definitions must be updated and the dylibs
  // copied over to a location that is suitable for Xcodebuild to find them.

  await _addServicesToBundle(new Directory(app.localPath));

  List<String> commands = <String>[
    '/usr/bin/env', 'xcrun', 'xcodebuild', '-target', 'Runner', '-configuration', 'Release'
  ];

  if (buildForDevice) {
    commands.addAll(<String>['-sdk', 'iphoneos', '-arch', 'arm64']);
  } else {
    commands.addAll(<String>['-sdk', 'iphonesimulator', '-arch', 'x86_64']);
  }

  try {
    runCheckedSync(commands, workingDirectory: app.localPath);
    return true;
  } catch (error) {
    return false;
  }
}

Future _addServicesToBundle(Directory bundle) async {
  List<Map<String, String>> services = [];
  printTrace("Trying to resolve native pub services.");

  // Step 1: Parse the service configuration yaml files present in the service
  //         pub packages.
  await parseServiceConfigs(services);
  printTrace("Found ${services.length} service definition(s).");

  // Step 2: Copy framework dylibs to the correct spot for xcodebuild to pick up.
  Directory frameworksDirectory = new Directory(path.join(bundle.path, "Frameworks"));
  await _copyServiceFrameworks(services, frameworksDirectory);

  // Step 3: Copy the service definitions manifest at the correct spot for
  //         xcodebuild to pick up.
  File manifestFile = new File(path.join(bundle.path, "ServiceDefinitions.json"));
  _copyServiceDefinitionsManifest(services, manifestFile);
}

Future _copyServiceFrameworks(List<Map<String, String>> services, Directory frameworksDirectory) async {
  printTrace("Copying service frameworks to '${path.absolute(frameworksDirectory.path)}'.");
  frameworksDirectory.createSync(recursive: true);
  for (Map<String, String> service in services) {
    String dylibPath = await getServiceFromUrl(service['ios-framework'], service['root'], service['name']);
    File dylib = new File(dylibPath);
    printTrace("Copying ${dylib.path} into bundle.");
    if (!dylib.existsSync()) {
      printError("The service dylib '${dylib.path}' does not exist.");
      continue;
    }
    // Shell out so permissions on the dylib are preserved.
    runCheckedSync(['/bin/cp', dylib.path, frameworksDirectory.path]);
  }
}

void _copyServiceDefinitionsManifest(List<Map<String, String>> services, File manifest) {
  printTrace("Creating service definitions manifest at '${manifest.path}'");
  List<Map<String, String>> jsonServices = services.map((Map<String, String> service) => {
    'name': service['name'],
    // Since we have already moved it to the Frameworks directory. Strip away
    // the directory and basenames.
    'framework': path.basenameWithoutExtension(service['ios-framework'])
  }).toList();
  Map<String, dynamic> json = { 'services' : jsonServices };
  manifest.writeAsStringSync(JSON.encode(json), mode: FileMode.WRITE, flush: true);
}
