// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/process.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../flx.dart' as flx;
import '../globals.dart';
import '../service_protocol.dart';
import '../toolchain.dart';
import 'mac.dart';

const String _xcrunPath = '/usr/bin/xcrun';

/// Test device created by Flutter when no other device is available.
const String _kFlutterTestDeviceSuffix = '(Flutter)';

class IOSSimulators extends PollingDeviceDiscovery {
  IOSSimulators() : super('IOSSimulators');

  @override
  bool get supportsPlatform => Platform.isMacOS;

  @override
  List<Device> pollingGetDevices() => IOSSimulatorUtils.instance.getAttachedDevices();
}

class IOSSimulatorUtils {
  /// Returns [IOSSimulatorUtils] active in the current app context (i.e. zone).
  static IOSSimulatorUtils get instance {
    return context[IOSSimulatorUtils] ?? (context[IOSSimulatorUtils] = new IOSSimulatorUtils());
  }

  List<IOSSimulator> getAttachedDevices() {
    if (!XCode.instance.isInstalledAndMeetsVersionCheck)
      return <IOSSimulator>[];

    return SimControl.instance.getConnectedDevices().map((SimDevice device) {
      return new IOSSimulator(device.udid, name: device.name);
    }).toList();
  }
}

/// A wrapper around the `simctl` command line tool.
class SimControl {
  /// Returns [SimControl] active in the current app context (i.e. zone).
  static SimControl get instance => context[SimControl] ?? (context[SimControl] = new SimControl());

  Future<bool> boot({String deviceName}) async {
    if (_isAnyConnected())
      return true;

    if (deviceName == null) {
      SimDevice testDevice = _createTestDevice();
      if (testDevice == null) {
        return false;
      }
      deviceName = testDevice.name;
    }

    // `xcrun instruments` requires a template (-t). @yjbanov has no idea what
    // "template" is but the built-in 'Blank' seems to work. -l causes xcrun to
    // quit after a time limit without killing the simulator. We quit after
    // 1 second.
    List<String> args = [_xcrunPath, 'instruments', '-w', deviceName, '-t', 'Blank', '-l', '1'];
    printTrace(args.join(' '));
    runDetached(args);
    printStatus('Waiting for iOS Simulator to boot...');

    bool connected = false;
    int attempted = 0;
    while (!connected && attempted < 20) {
      connected = await _isAnyConnected();
      if (!connected) {
        printStatus('Still waiting for iOS Simulator to boot...');
        await new Future<Null>.delayed(new Duration(seconds: 1));
      }
      attempted++;
    }

    if (connected) {
      printStatus('Connected to iOS Simulator.');
      return true;
    } else {
      printStatus('Timed out waiting for iOS Simulator to boot.');
      return false;
    }
  }

  SimDevice _createTestDevice() {
    SimDeviceType deviceType = _findSuitableDeviceType();
    if (deviceType == null)
      return null;

    String runtime = _findSuitableRuntime();
    if (runtime == null)
      return null;

    // Delete any old test devices
    getDevices()
      .where((SimDevice d) => d.name.endsWith(_kFlutterTestDeviceSuffix))
      .forEach(_deleteDevice);

    // Create new device
    String deviceName = '${deviceType.name} $_kFlutterTestDeviceSuffix';
    List<String> args = [_xcrunPath, 'simctl', 'create', deviceName, deviceType.identifier, runtime];
    printTrace(args.join(' '));
    runCheckedSync(args);

    return getDevices().firstWhere((SimDevice d) => d.name == deviceName);
  }

  SimDeviceType _findSuitableDeviceType() {
    List<Map<String, dynamic>> allTypes = _list(SimControlListSection.devicetypes);
    List<Map<String, dynamic>> usableTypes = allTypes
      .where((Map<String, dynamic> info) => info['name'].startsWith('iPhone'))
      .toList()
      ..sort((Map<String, dynamic> r1, Map<String, dynamic> r2) => -compareIphoneVersions(r1['identifier'], r2['identifier']));

    if (usableTypes.isEmpty) {
      printError(
        'No suitable device type found.\n'
        'You may launch an iOS Simulator manually and Flutter will attempt to use it.'
      );
    }

    return new SimDeviceType(
      usableTypes.first['name'],
      usableTypes.first['identifier']
    );
  }

  String _findSuitableRuntime() {
    List<Map<String, dynamic>> allRuntimes = _list(SimControlListSection.runtimes);
    List<Map<String, dynamic>> usableRuntimes = allRuntimes
      .where((Map<String, dynamic> info) => info['name'].startsWith('iOS'))
      .toList()
      ..sort((Map<String, dynamic> r1, Map<String, dynamic> r2) => -compareIosVersions(r1['version'], r2['version']));

    if (usableRuntimes.isEmpty) {
      printError(
        'No suitable iOS runtime found.\n'
        'You may launch an iOS Simulator manually and Flutter will attempt to use it.'
      );
    }

    return usableRuntimes.first['identifier'];
  }

  void _deleteDevice(SimDevice device) {
    try {
      List<String> args = <String>[_xcrunPath, 'simctl', 'delete', device.name];
      printTrace(args.join(' '));
      runCheckedSync(args);
    } catch(e) {
      printError(e);
    }
  }

  /// Runs `simctl list --json` and returns the JSON of the corresponding
  /// [section].
  ///
  /// The return type depends on the [section] being listed but is usually
  /// either a [Map] or a [List].
  dynamic _list(SimControlListSection section) {
    // Sample output from `simctl list --json`:
    //
    // {
    //   "devicetypes": { ... },
    //   "runtimes": { ... },
    //   "devices" : {
    //     "com.apple.CoreSimulator.SimRuntime.iOS-8-2" : [
    //       {
    //         "state" : "Shutdown",
    //         "availability" : " (unavailable, runtime profile not found)",
    //         "name" : "iPhone 4s",
    //         "udid" : "1913014C-6DCB-485D-AC6B-7CD76D322F5B"
    //       },
    //       ...
    //   },
    //   "pairs": { ... },

    List<String> args = <String>['simctl', 'list', '--json', section.name];
    printTrace('$_xcrunPath ${args.join(' ')}');
    ProcessResult results = Process.runSync(_xcrunPath, args);
    if (results.exitCode != 0) {
      printError('Error executing simctl: ${results.exitCode}\n${results.stderr}');
      return <String, Map<String, dynamic>>{};
    }

    return JSON.decode(results.stdout)[section.name];
  }

  /// Returns a list of all available devices, both potential and connected.
  List<SimDevice> getDevices() {
    List<SimDevice> devices = <SimDevice>[];

    Map<String, dynamic> devicesSection = _list(SimControlListSection.devices);

    for (String deviceCategory in devicesSection.keys) {
      List<Map<String, String>> devicesData = devicesSection[deviceCategory];

      for (Map<String, String> data in devicesData) {
        devices.add(new SimDevice(deviceCategory, data));
      }
    }

    return devices;
  }

  /// Returns all the connected simulator devices.
  List<SimDevice> getConnectedDevices() {
    return getDevices().where((SimDevice device) => device.isBooted).toList();
  }

  StreamController<List<SimDevice>> _trackDevicesControler;

  /// Listens to changes in the set of connected devices. The implementation
  /// currently uses polling. Callers should be careful to call cancel() on any
  /// stream subscription when finished.
  ///
  /// TODO(devoncarew): We could investigate using the usbmuxd protocol directly.
  Stream<List<SimDevice>> trackDevices() {
    if (_trackDevicesControler == null) {
      Timer timer;
      Set<String> deviceIds = new Set<String>();
      _trackDevicesControler = new StreamController<List<SimDevice>>.broadcast(
        onListen: () {
          timer = new Timer.periodic(new Duration(seconds: 4), (Timer timer) {
            List<SimDevice> devices = getConnectedDevices();
            if (_updateDeviceIds(devices, deviceIds))
              _trackDevicesControler.add(devices);
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
  bool _updateDeviceIds(List<SimDevice> devices, Set<String> deviceIds) {
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

  bool _isAnyConnected() => getConnectedDevices().isNotEmpty;

  void install(String deviceId, String appPath) {
    runCheckedSync([_xcrunPath, 'simctl', 'install', deviceId, appPath]);
  }

  void launch(String deviceId, String appIdentifier, [List<String> launchArgs]) {
    List<String> args = [_xcrunPath, 'simctl', 'launch', deviceId, appIdentifier];
    if (launchArgs != null)
      args.addAll(launchArgs);
    runCheckedSync(args);
  }
}

/// Enumerates all data sections of `xcrun simctl list --json` command.
class SimControlListSection {
  const SimControlListSection._(this.name);

  final String name;

  static const SimControlListSection devices = const SimControlListSection._('devices');
  static const SimControlListSection devicetypes = const SimControlListSection._('devicetypes');
  static const SimControlListSection runtimes = const SimControlListSection._('runtimes');
  static const SimControlListSection pairs = const SimControlListSection._('pairs');
}

/// A simulated device type.
///
/// Simulated device types can be listed using the command
/// `xcrun simctl list devicetypes`.
class SimDeviceType {
  SimDeviceType(this.name, this.identifier);

  /// The name of the device type.
  ///
  /// Examples:
  ///
  ///     "iPhone 6s"
  ///     "iPhone 6 Plus"
  final String name;

  /// The identifier of the device type.
  ///
  /// Examples:
  ///
  ///     "com.apple.CoreSimulator.SimDeviceType.iPhone-6s"
  ///     "com.apple.CoreSimulator.SimDeviceType.iPhone-6-Plus"
  final String identifier;
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

  @override
  final String name;

  @override
  bool get isLocalEmulator => true;

  _IOSSimulatorLogReader _logReader;
  _IOSSimulatorDevicePortForwarder _portForwarder;

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
    try {
      SimControl.instance.install(id, app.localPath);
      return true;
    } catch (e) {
      return false;
    }
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
    if (isSupported())
      return "Supported";

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
    printTrace('Building ${app.name} for $id.');

    if (clearLogs)
      this.clearLogs();

    if (!(await _setupUpdatedApplicationBundle(app, toolchain)))
      return false;

    ServiceProtocolDiscovery serviceProtocolDiscovery =
        new ServiceProtocolDiscovery(logReader);

    // We take this future here but do not wait for completion until *after*
    // we start the application.
    Future<int> serviceProtocolPort = serviceProtocolDiscovery.nextPort();

    // Prepare launch arguments.
    List<String> args = <String>[
      "--flx=${path.absolute(path.join('build', 'app.flx'))}",
      "--dart-main=${path.absolute(mainPath)}",
      "--package-root=${path.absolute('packages')}",
    ];

    if (checked)
      args.add("--enable-checked-mode");

    if (startPaused)
      args.add("--start-paused");

    if (debugPort != observatoryDefaultPort)
      args.add("--observatory-port=$debugPort");

    // Launch the updated application in the simulator.
    try {
      SimControl.instance.launch(id, app.id, args);
    } catch (error) {
      printError('$error');
      return false;
    }

    // Wait for the service protocol port here. This will complete once
    // the device has printed "Observatory is listening on..."
    int devicePort = await serviceProtocolPort;
    printTrace('service protocol port = $devicePort');
    printTrace('Successfully started ${app.name} on $id.');
    printStatus('Observatory listening on http://127.0.0.1:$devicePort');

    return true;
  }

  bool _applicationIsInstalledAndRunning(ApplicationPackage app) {
    bool isInstalled = exitsHappy([
      'xcrun',
      'simctl',
      'get_app_container',
      'booted',
      app.id,
    ]);

    bool isRunning = exitsHappy([
      '/usr/bin/killall',
      'Runner',
    ]);

    return isInstalled && isRunning;
  }

  Future<bool> _setupUpdatedApplicationBundle(ApplicationPackage app, Toolchain toolchain) async {
    bool sideloadResult = await _sideloadUpdatedAssetsForInstalledApplicationBundle(app, toolchain);

    if (!sideloadResult)
      return false;

    if (!_applicationIsInstalledAndRunning(app))
      return _buildAndInstallApplicationBundle(app);

    return true;
  }

  Future<bool> _buildAndInstallApplicationBundle(ApplicationPackage app) async {
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
    SimControl.instance.install(id, path.absolute(bundle.path));
    return true;
  }

  Future<bool> _sideloadUpdatedAssetsForInstalledApplicationBundle(
      ApplicationPackage app, Toolchain toolchain) async {
    return (await flx.build(toolchain, precompiledSnapshot: true)) == 0;
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
  TargetPlatform get platform => TargetPlatform.ios;

  @override
  DeviceLogReader get logReader {
    if (_logReader == null)
      _logReader = new _IOSSimulatorLogReader(this);

    return _logReader;
  }

  @override
  DevicePortForwarder get portForwarder {
    if (_portForwarder == null)
      _portForwarder = new _IOSSimulatorDevicePortForwarder(this);

    return _portForwarder;
  }

  @override
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

  final StreamController<String> _linesStreamController =
      new StreamController<String>.broadcast();

  bool _lastWasFiltered = false;

  // We log from two logs: the device and the system log.
  Process _deviceProcess;
  StreamSubscription<String> _deviceStdoutSubscription;
  StreamSubscription<String> _deviceStderrSubscription;

  Process _systemProcess;
  StreamSubscription<String> _systemStdoutSubscription;
  StreamSubscription<String> _systemStderrSubscription;

  @override
  Stream<String> get lines => _linesStreamController.stream;

  @override
  String get name => device.name;

  @override
  bool get isReading => (_deviceProcess != null) && (_systemProcess != null);

  @override
  Future<int> get finished {
    return (_deviceProcess != null) ? _deviceProcess.exitCode : new Future<int>.value(0);
  }

  @override
  Future<Null> start() async {
    if (isReading) {
      throw new StateError(
        '_IOSSimulatorLogReader must be stopped before it can be started.'
      );
    }

    // TODO(johnmccutchan): Add a ProcessSet abstraction that handles running
    // N processes and merging their output.

    // Device log.
    device.ensureLogsExists();
    _deviceProcess = await runCommand(
        <String>['tail', '-n', '+0', '-F', device.logFilePath]);
    _deviceStdoutSubscription =
        _deviceProcess.stdout.transform(UTF8.decoder)
                             .transform(const LineSplitter()).listen(_onDeviceLine);
    _deviceStderrSubscription =
        _deviceProcess.stderr.transform(UTF8.decoder)
                             .transform(const LineSplitter()).listen(_onDeviceLine);
    _deviceProcess.exitCode.then(_onDeviceExit);

    // Track system.log crashes.
    // ReportCrash[37965]: Saved crash report for FlutterRunner[37941]...
    _systemProcess = await runCommand(
        <String>['tail', '-F', '/private/var/log/system.log']);
    _systemStdoutSubscription =
        _systemProcess.stdout.transform(UTF8.decoder)
                             .transform(const LineSplitter()).listen(_onSystemLine);
    _systemStderrSubscription =
        _systemProcess.stderr.transform(UTF8.decoder)
                             .transform(const LineSplitter()).listen(_onSystemLine);
    _systemProcess.exitCode.then(_onSystemExit);
  }

  @override
  Future<Null> stop() async {
    if (!isReading) {
      throw new StateError(
        '_IOSSimulatorLogReader must be started before it can be stopped.'
      );
    }
    if (_deviceProcess != null) {
      await _deviceProcess.kill();
      _deviceProcess = null;
    }
    _onDeviceExit(0);
    if (_systemProcess != null) {
      await _systemProcess.kill();
      _systemProcess = null;
    }
    _onSystemExit(0);
  }

  void _onDeviceExit(int exitCode) {
    _deviceStdoutSubscription?.cancel();
    _deviceStdoutSubscription = null;
    _deviceStderrSubscription?.cancel();
    _deviceStderrSubscription = null;
    _deviceProcess = null;
  }

  void _onSystemExit(int exitCode) {
    _systemStdoutSubscription?.cancel();
    _systemStdoutSubscription = null;
    _systemStderrSubscription?.cancel();
    _systemStderrSubscription = null;
    _systemProcess = null;
  }

  // Match the log prefix (in order to shorten it):
  //   'Jan 29 01:31:44 devoncarew-macbookpro3 SpringBoard[96648]: ...'
  final RegExp _mapRegex =
      new RegExp(r'\S+ +\S+ +\S+ \S+ (.+)\[\d+\]\)?: (.*)$');

  // Jan 31 19:23:28 --- last message repeated 1 time ---
  final RegExp _lastMessageRegex = new RegExp(r'\S+ +\S+ +\S+ --- (.*) ---$');

  final RegExp _flutterRunnerRegex = new RegExp(r' FlutterRunner\[\d+\] ');

  String _filterDeviceLine(String string) {
    Match match = _mapRegex.matchAsPrefix(string);
    if (match != null) {
      _lastWasFiltered = true;

      // Filter out some messages that clearly aren't related to Flutter.
      if (string.contains(': could not find icon for representation -> com.apple.'))
        return null;

      String category = match.group(1);
      String content = match.group(2);
      if (category == 'Game Center' || category == 'itunesstored' ||
          category == 'nanoregistrylaunchd' || category == 'mstreamd' ||
          category == 'syncdefaultsd' || category == 'companionappd' ||
          category == 'searchd')
        return null;

      _lastWasFiltered = false;

      if (category == 'Runner')
        return content;
      return '$category: $content';
    }
    match = _lastMessageRegex.matchAsPrefix(string);
    if (match != null && !_lastWasFiltered)
      return '(${match.group(1)})';
    return string;
  }

  void _onDeviceLine(String line) {
    String filteredLine = _filterDeviceLine(line);
    if (filteredLine == null)
      return;

    _linesStreamController.add(filteredLine);
  }

  String _filterSystemLog(String string) {
    Match match = _mapRegex.matchAsPrefix(string);
    return match == null ? string : '${match.group(1)}: ${match.group(2)}';
  }

  void _onSystemLine(String line) {
    if (!_flutterRunnerRegex.hasMatch(line))
      return;

    String filteredLine = _filterSystemLog(line);
    if (filteredLine == null)
      return;

    _linesStreamController.add(filteredLine);
  }

  @override
  int get hashCode => device.logFilePath.hashCode;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! _IOSSimulatorLogReader)
      return false;
    return other.device.logFilePath == device.logFilePath;
  }
}

int compareIosVersions(String v1, String v2) {
  List<int> v1Fragments = v1.split('.').map(int.parse).toList();
  List<int> v2Fragments = v2.split('.').map(int.parse).toList();

  int i = 0;
  while(i < v1Fragments.length && i < v2Fragments.length) {
    int v1Fragment = v1Fragments[i];
    int v2Fragment = v2Fragments[i];
    if (v1Fragment != v2Fragment)
      return v1Fragment.compareTo(v2Fragment);
    i++;
  }
  return v1Fragments.length.compareTo(v2Fragments.length);
}

/// Matches on device type given an identifier.
///
/// Example device type identifiers:
///   ✓ com.apple.CoreSimulator.SimDeviceType.iPhone-5
///   ✓ com.apple.CoreSimulator.SimDeviceType.iPhone-6
///   ✓ com.apple.CoreSimulator.SimDeviceType.iPhone-6s-Plus
///   ✗ com.apple.CoreSimulator.SimDeviceType.iPad-2
///   ✗ com.apple.CoreSimulator.SimDeviceType.Apple-Watch-38mm
final RegExp _iosDeviceTypePattern =
    new RegExp(r'com.apple.CoreSimulator.SimDeviceType.iPhone-(\d+)(.*)');

int compareIphoneVersions(String id1, String id2) {
  Match m1 = _iosDeviceTypePattern.firstMatch(id1);
  Match m2 = _iosDeviceTypePattern.firstMatch(id2);

  int v1 = int.parse(m1[1]);
  int v2 = int.parse(m2[1]);

  if (v1 != v2)
    return v1.compareTo(v2);

  // Sorted in the least preferred first order.
  const List<String> qualifiers = const <String>['-Plus', '', 's-Plus', 's'];

  int q1 = qualifiers.indexOf(m1[2]);
  int q2 = qualifiers.indexOf(m2[2]);
  return q1.compareTo(q2);
}

class _IOSSimulatorDevicePortForwarder extends DevicePortForwarder {
  _IOSSimulatorDevicePortForwarder(this.device);

  final IOSSimulator device;

  final List<ForwardedPort> _ports = <ForwardedPort>[];

  @override
  List<ForwardedPort> get forwardedPorts {
    return _ports;
  }

  @override
  Future<int> forward(int devicePort, {int hostPort: null}) async {
    if ((hostPort == null) || (hostPort == 0)) {
      hostPort = devicePort;
    }
    assert(devicePort == hostPort);
    _ports.add(new ForwardedPort(devicePort, hostPort));
    return hostPort;
  }

  @override
  Future<Null> unforward(ForwardedPort forwardedPort) async {
    _ports.remove(forwardedPort);
  }
}
