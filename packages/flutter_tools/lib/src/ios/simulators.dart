// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import '../application_package.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../device.dart';
import '../doctor.dart';
import '../flx.dart' as flx;
import '../globals.dart';
import '../protocol_discovery.dart';
import 'mac.dart';

const String _xcrunPath = '/usr/bin/xcrun';

/// Test device created by Flutter when no other device is available.
const String _kFlutterTestDeviceSuffix = '(Flutter)';

class IOSSimulators extends PollingDeviceDiscovery {
  IOSSimulators() : super('iOS simulators');

  @override
  bool get supportsPlatform => platform.isMacOS;

  @override
  bool get canListAnything => doctor.iosWorkflow.canListDevices;

  @override
  List<Device> pollingGetDevices() => IOSSimulatorUtils.instance.getAttachedDevices();
}

class IOSSimulatorUtils {
  /// Returns [IOSSimulatorUtils] active in the current app context (i.e. zone).
  static IOSSimulatorUtils get instance => context[IOSSimulatorUtils];

  List<IOSSimulator> getAttachedDevices() {
    if (!Xcode.instance.isInstalledAndMeetsVersionCheck)
      return <IOSSimulator>[];

    return SimControl.instance.getConnectedDevices().map((SimDevice device) {
      return new IOSSimulator(device.udid, name: device.name, category: device.category);
    }).toList();
  }
}

/// A wrapper around the `simctl` command line tool.
class SimControl {
  /// Returns [SimControl] active in the current app context (i.e. zone).
  static SimControl get instance => context[SimControl];

  Future<bool> boot({ String deviceName }) async {
    if (_isAnyConnected())
      return true;

    if (deviceName == null) {
      final SimDevice testDevice = _createTestDevice();
      if (testDevice == null) {
        return false;
      }
      deviceName = testDevice.name;
    }

    // `xcrun instruments` requires a template (-t). @yjbanov has no idea what
    // "template" is but the built-in 'Blank' seems to work. -l causes xcrun to
    // quit after a time limit without killing the simulator. We quit after
    // 1 second.
    final List<String> args = <String>[_xcrunPath, 'instruments', '-w', deviceName, '-t', 'Blank', '-l', '1'];
    printTrace(args.join(' '));
    runDetached(args);
    printStatus('Waiting for iOS Simulator to boot...');

    bool connected = false;
    int attempted = 0;
    while (!connected && attempted < 20) {
      connected = _isAnyConnected();
      if (!connected) {
        printStatus('Still waiting for iOS Simulator to boot...');
        await new Future<Null>.delayed(const Duration(seconds: 1));
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
    final SimDeviceType deviceType = _findSuitableDeviceType();
    if (deviceType == null)
      return null;

    final String runtime = _findSuitableRuntime();
    if (runtime == null)
      return null;

    // Delete any old test devices
    getDevices()
      .where((SimDevice d) => d.name.endsWith(_kFlutterTestDeviceSuffix))
      .forEach(_deleteDevice);

    // Create new device
    final String deviceName = '${deviceType.name} $_kFlutterTestDeviceSuffix';
    final List<String> args = <String>[_xcrunPath, 'simctl', 'create', deviceName, deviceType.identifier, runtime];
    printTrace(args.join(' '));
    runCheckedSync(args);

    return getDevices().firstWhere((SimDevice d) => d.name == deviceName);
  }

  SimDeviceType _findSuitableDeviceType() {
    final List<Map<String, dynamic>> allTypes = _list(SimControlListSection.devicetypes);
    final List<Map<String, dynamic>> usableTypes = allTypes
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
    final List<Map<String, dynamic>> allRuntimes = _list(SimControlListSection.runtimes);
    final List<Map<String, dynamic>> usableRuntimes = allRuntimes
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
      final List<String> args = <String>[_xcrunPath, 'simctl', 'delete', device.name];
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

    final List<String> command = <String>[_xcrunPath, 'simctl', 'list', '--json', section.name];
    printTrace(command.join(' '));
    final ProcessResult results = processManager.runSync(command);
    if (results.exitCode != 0) {
      printError('Error executing simctl: ${results.exitCode}\n${results.stderr}');
      return <String, Map<String, dynamic>>{};
    }

    return JSON.decode(results.stdout)[section.name];
  }

  /// Returns a list of all available devices, both potential and connected.
  List<SimDevice> getDevices() {
    final List<SimDevice> devices = <SimDevice>[];

    final Map<String, dynamic> devicesSection = _list(SimControlListSection.devices);

    for (String deviceCategory in devicesSection.keys) {
      final List<Map<String, String>> devicesData = devicesSection[deviceCategory];

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

  bool _isAnyConnected() => getConnectedDevices().isNotEmpty;

  Future<bool> isInstalled(String appId) {
    return exitsHappyAsync(<String>[
      _xcrunPath,
      'simctl',
      'get_app_container',
      'booted',
      appId,
    ]);
  }

  Future<Null> install(String deviceId, String appPath) {
    return runCheckedAsync(<String>[_xcrunPath, 'simctl', 'install', deviceId, appPath]);
  }

  Future<Null> uninstall(String deviceId, String appId) {
    return runCheckedAsync(<String>[_xcrunPath, 'simctl', 'uninstall', deviceId, appId]);
  }

  Future<Null> launch(String deviceId, String appIdentifier, [List<String> launchArgs]) {
    final List<String> args = <String>[_xcrunPath, 'simctl', 'launch', deviceId, appIdentifier];
    if (launchArgs != null)
      args.addAll(launchArgs);
    return runCheckedAsync(args);
  }

  Future<Null> takeScreenshot(String outputPath) {
    return runCheckedAsync(<String>[_xcrunPath, 'simctl', 'io', 'booted', 'screenshot', outputPath]);
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
  IOSSimulator(String id, { this.name, this.category }) : super(id);

  @override
  final String name;

  final String category;

  @override
  Future<bool> get isLocalEmulator async => true;

  @override
  bool get supportsHotMode => true;

  Map<ApplicationPackage, _IOSSimulatorLogReader> _logReaders;
  _IOSSimulatorDevicePortForwarder _portForwarder;

  String get xcrunPath => fs.path.join('/usr', 'bin', 'xcrun');

  String _getSimulatorPath() {
    return fs.path.join(homeDirPath, 'Library', 'Developer', 'CoreSimulator', 'Devices', id);
  }

  String _getSimulatorAppHomeDirectory(ApplicationPackage app) {
    final String simulatorPath = _getSimulatorPath();
    if (simulatorPath == null)
      return null;
    return fs.path.join(simulatorPath, 'data');
  }

  @override
  Future<bool> isAppInstalled(ApplicationPackage app) {
    return SimControl.instance.isInstalled(app.id);
  }

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> installApp(ApplicationPackage app) async {
    try {
      final IOSApp iosApp = app;
      SimControl.instance.install(id, iosApp.simulatorBundlePath);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> uninstallApp(ApplicationPackage app) async {
    try {
      await SimControl.instance.uninstall(id, app.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  bool isSupported() {
    if (!platform.isMacOS) {
      _supportMessage = 'iOS devices require a Mac host machine.';
      return false;
    }

    // Step 1: Check if the device is part of a blacklisted category.
    //         We do not support WatchOS or tvOS devices.

    final RegExp blacklist = new RegExp(r'Apple (TV|Watch)', caseSensitive: false);
    if (blacklist.hasMatch(name)) {
      _supportMessage = 'Flutter does not support Apple TV or Apple Watch. Select an iPhone 5s or above.';
      return false;
    }

    // Step 2: Check if the device must be rejected because of its version.
    //         There is an artificial check on older simulators where arm64
    //         targeted applications cannot be run (even though the Flutter
    //         runner on the simulator is completely different).

    // Check for unsupported iPads.
    final Match iPadMatch = new RegExp(r'iPad (2|Retina)', caseSensitive: false).firstMatch(name);
    if (iPadMatch != null) {
      _supportMessage = 'Flutter does not yet support iPad 2 or iPad Retina. Select an iPad Air or above.';
      return false;
    }

    // Check for unsupported iPhones.
    final Match iPhoneMatch = new RegExp(r'iPhone [0-5]').firstMatch(name);
    if (iPhoneMatch != null) {
      if (name == 'iPhone 5s')
        return true;
      _supportMessage = 'Flutter does not yet support iPhone 5 or earlier. Select an iPhone 5s or above.';
      return false;
    }

    return true;
  }

  String _supportMessage;

  @override
  String supportMessage() {
    if (isSupported())
      return 'Supported';

    return _supportMessage != null ? _supportMessage : 'Unknown';
  }

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage app,
    BuildMode mode, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    String kernelPath,
    bool prebuiltApplication: false,
    bool applicationNeedsRebuild: false,
  }) async {
    if (!prebuiltApplication) {
      printTrace('Building ${app.name} for $id.');

      try {
        await _setupUpdatedApplicationBundle(app);
      } on ToolExit catch (e) {
        printError(e.message);
        return new LaunchResult.failed();
      }
    } else {
      if (!await installApp(app))
        return new LaunchResult.failed();
    }

    // Prepare launch arguments.
    final List<String> args = <String>['--enable-dart-profiling'];

    if (!prebuiltApplication) {
      args.addAll(<String>[
        '--flx=${fs.path.absolute(fs.path.join(getBuildDirectory(), 'app.flx'))}',
        '--dart-main=${fs.path.absolute(mainPath)}',
        '--packages=${fs.path.absolute('.packages')}',
      ]);
    }

    if (debuggingOptions.debuggingEnabled) {
      if (debuggingOptions.buildMode == BuildMode.debug)
        args.add('--enable-checked-mode');
      if (debuggingOptions.startPaused)
        args.add('--start-paused');
      if (debuggingOptions.useTestFonts)
        args.add('--use-test-fonts');

      final int observatoryPort = await debuggingOptions.findBestObservatoryPort();
      args.add('--observatory-port=$observatoryPort');
      final int diagnosticPort = await debuggingOptions.findBestDiagnosticPort();
      args.add('--diagnostic-port=$diagnosticPort');
    }

    ProtocolDiscovery observatoryDiscovery;
    if (debuggingOptions.debuggingEnabled)
      observatoryDiscovery = new ProtocolDiscovery.observatory(getLogReader(app: app));

    // Launch the updated application in the simulator.
    try {
      SimControl.instance.launch(id, app.id, args);
    } catch (error) {
      printError('$error');
      return new LaunchResult.failed();
    }

    if (!debuggingOptions.debuggingEnabled) {
      return new LaunchResult.succeeded();
    }

    // Wait for the service protocol port here. This will complete once the
    // device has printed "Observatory is listening on..."
    printTrace('Waiting for observatory port to be available...');

    try {
      final Uri deviceUri = await observatoryDiscovery.uri;
      return new LaunchResult.succeeded(observatoryUri: deviceUri);
    } catch (error) {
      printError('Error waiting for a debug connection: $error');
      return new LaunchResult.failed();
    } finally {
      observatoryDiscovery.cancel();
    }
  }

  Future<bool> _applicationIsInstalledAndRunning(ApplicationPackage app) async {
    final List<bool> criteria = await Future.wait(<Future<bool>>[
      isAppInstalled(app),
      exitsHappyAsync(<String>['/usr/bin/killall', 'Runner']),
    ]);
    return criteria.reduce((bool a, bool b) => a && b);
  }

  Future<Null> _setupUpdatedApplicationBundle(ApplicationPackage app) async {
    await _sideloadUpdatedAssetsForInstalledApplicationBundle(app);

    if (!await _applicationIsInstalledAndRunning(app))
      return _buildAndInstallApplicationBundle(app);
  }

  Future<Null> _buildAndInstallApplicationBundle(ApplicationPackage app) async {
    // Step 1: Build the Xcode project.
    // The build mode for the simulator is always debug.
    final XcodeBuildResult buildResult = await buildXcodeProject(app: app, mode: BuildMode.debug, buildForDevice: false);
    if (!buildResult.success)
      throwToolExit('Could not build the application for the simulator.');

    // Step 2: Assert that the Xcode project was successfully built.
    final IOSApp iosApp = app;
    final Directory bundle = fs.directory(iosApp.simulatorBundlePath);
    final bool bundleExists = bundle.existsSync();
    if (!bundleExists)
      throwToolExit('Could not find the built application bundle at ${bundle.path}.');

    // Step 3: Install the updated bundle to the simulator.
    SimControl.instance.install(id, fs.path.absolute(bundle.path));
  }

  Future<Null> _sideloadUpdatedAssetsForInstalledApplicationBundle(ApplicationPackage app) =>
      flx.build(precompiledSnapshot: true);

  @override
  Future<bool> stopApp(ApplicationPackage app) async {
    // Currently we don't have a way to stop an app running on iOS.
    return false;
  }

  Future<bool> pushFile(
      ApplicationPackage app, String localFile, String targetFile) async {
    if (platform.isMacOS) {
      final String simulatorHomeDirectory = _getSimulatorAppHomeDirectory(app);
      await runCheckedAsync(<String>['cp', localFile, fs.path.join(simulatorHomeDirectory, targetFile)]);
      return true;
    }
    return false;
  }

  String get logFilePath {
    return fs.path.join(homeDirPath, 'Library', 'Logs', 'CoreSimulator', id, 'system.log');
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  Future<String> get sdkNameAndVersion async => category;

  @override
  DeviceLogReader getLogReader({ApplicationPackage app}) {
    _logReaders ??= <ApplicationPackage, _IOSSimulatorLogReader>{};
    return _logReaders.putIfAbsent(app, () => new _IOSSimulatorLogReader(this, app));
  }

  @override
  DevicePortForwarder get portForwarder => _portForwarder ??= new _IOSSimulatorDevicePortForwarder(this);

  @override
  void clearLogs() {
    final File logFile = fs.file(logFilePath);
    if (logFile.existsSync()) {
      final RandomAccessFile randomFile = logFile.openSync(mode: FileMode.WRITE);
      randomFile.truncateSync(0);
      randomFile.closeSync();
    }
  }

  void ensureLogsExists() {
    final File logFile = fs.file(logFilePath);
    if (!logFile.existsSync())
      logFile.writeAsBytesSync(<int>[]);
  }

  bool get _xcodeVersionSupportsScreenshot {
    return Xcode.instance.xcodeMajorVersion > 8 ||
        (Xcode.instance.xcodeMajorVersion == 8 && Xcode.instance.xcodeMinorVersion >= 2);
  }

  @override
  bool get supportsScreenshot => _xcodeVersionSupportsScreenshot;

  @override
  Future<Null> takeScreenshot(File outputFile) {
    return SimControl.instance.takeScreenshot(outputFile.path);
  }
}

class _IOSSimulatorLogReader extends DeviceLogReader {
  String _appName;

  _IOSSimulatorLogReader(this.device, ApplicationPackage app) {
    _linesController = new StreamController<String>.broadcast(
      onListen: _start,
      onCancel: _stop
    );
    _appName = app == null ? null : app.name.replaceAll('.app', '');
  }

  final IOSSimulator device;

  StreamController<String> _linesController;

  // We log from two files: the device and the system log.
  Process _deviceProcess;
  Process _systemProcess;

  @override
  Stream<String> get logLines => _linesController.stream;

  @override
  String get name => device.name;

  Future<Null> _start() async {
    // Device log.
    device.ensureLogsExists();
    _deviceProcess = await runCommand(<String>['tail', '-n', '0', '-F', device.logFilePath]);
    _deviceProcess.stdout.transform(UTF8.decoder).transform(const LineSplitter()).listen(_onDeviceLine);
    _deviceProcess.stderr.transform(UTF8.decoder).transform(const LineSplitter()).listen(_onDeviceLine);

    // Track system.log crashes.
    // ReportCrash[37965]: Saved crash report for FlutterRunner[37941]...
    _systemProcess = await runCommand(<String>['tail', '-n', '0', '-F', '/private/var/log/system.log']);
    _systemProcess.stdout.transform(UTF8.decoder).transform(const LineSplitter()).listen(_onSystemLine);
    _systemProcess.stderr.transform(UTF8.decoder).transform(const LineSplitter()).listen(_onSystemLine);

    _deviceProcess.exitCode.whenComplete(() {
      if (_linesController.hasListener)
        _linesController.close();
    });
  }

  // Match the log prefix (in order to shorten it):
  //   'Jan 29 01:31:44 devoncarew-macbookpro3 SpringBoard[96648]: ...'
  static final RegExp _mapRegex = new RegExp(r'\S+ +\S+ +\S+ \S+ (.+)\[\d+\]\)?: (.*)$');

  // Jan 31 19:23:28 --- last message repeated 1 time ---
  static final RegExp _lastMessageSingleRegex = new RegExp(r'\S+ +\S+ +\S+ --- last message repeated 1 time ---$');
  static final RegExp _lastMessageMultipleRegex = new RegExp(r'\S+ +\S+ +\S+ --- last message repeated (\d+) times ---$');

  static final RegExp _flutterRunnerRegex = new RegExp(r' FlutterRunner\[\d+\] ');

  /// List of log categories to always show in the logs, even if this is an app-specific
  /// [DeviceLogReader]. Add to this list to make the log output more verbose.
  static final List<String> _whitelistedLogCategories = <String>[
    'CoreSimulatorBridge',
  ];

  String _filterDeviceLine(String string) {
    final Match match = _mapRegex.matchAsPrefix(string);
    if (match != null) {
      final String category = match.group(1);
      final String content = match.group(2);

      // Filter out some messages that clearly aren't related to Flutter.
      if (string.contains(': could not find icon for representation -> com.apple.'))
        return null;

      if (category == 'CoreSimulatorBridge'
          && content.startsWith('Pasteboard change listener callback port'))
        return null;

      if (category == 'routined'
          && content.startsWith('CoreLocation: Error occurred while trying to retrieve motion state update'))
        return null;

      if (category == 'syslogd' && content == 'ASL Sender Statistics')
        return null;

      // assertiond: assertion failed: 15E65 13E230: assertiond + 15801 [3C808658-78EC-3950-A264-79A64E0E463B]: 0x1
      if (category == 'assertiond'
          && content.startsWith('assertion failed: ')
          && content.endsWith(']: 0x1'))
         return null;

      // assertion failed: 15G1212 13E230: libxpc.dylib + 57882 [66C28065-C9DB-3C8E-926F-5A40210A6D1B]: 0x7d
      if (category == 'Runner'
          && content.startsWith('assertion failed: ')
          && content.contains(' libxpc.dylib '))
        return null;

      if (_appName == null || _whitelistedLogCategories.contains(category))
        return '$category: $content';
      else if (category == _appName)
        return content;

      return null;
    }

    if (_lastMessageSingleRegex.matchAsPrefix(string) != null)
      return null;

    if (new RegExp(r'assertion failed: .* libxpc.dylib .* 0x7d$').matchAsPrefix(string) != null)
      return null;

    return string;
  }

  String _lastLine;

  void _onDeviceLine(String line) {
    printTrace('[DEVICE LOG] $line');
    final Match multi = _lastMessageMultipleRegex.matchAsPrefix(line);

    if (multi != null) {
      if (_lastLine != null) {
        int repeat = int.parse(multi.group(1));
        repeat = math.max(0, math.min(100, repeat));
        for (int i = 1; i < repeat; i++)
          _linesController.add(_lastLine);
      }
    } else {
      _lastLine = _filterDeviceLine(line);
      if (_lastLine != null)
        _linesController.add(_lastLine);
    }
  }

  String _filterSystemLog(String string) {
    final Match match = _mapRegex.matchAsPrefix(string);
    return match == null ? string : '${match.group(1)}: ${match.group(2)}';
  }

  void _onSystemLine(String line) {
    printTrace('[SYS LOG] $line');
    if (!_flutterRunnerRegex.hasMatch(line))
      return;

    final String filteredLine = _filterSystemLog(line);
    if (filteredLine == null)
      return;

    _linesController.add(filteredLine);
  }

  void _stop() {
    _deviceProcess?.kill();
    _systemProcess?.kill();
  }
}

int compareIosVersions(String v1, String v2) {
  final List<int> v1Fragments = v1.split('.').map(int.parse).toList();
  final List<int> v2Fragments = v2.split('.').map(int.parse).toList();

  int i = 0;
  while(i < v1Fragments.length && i < v2Fragments.length) {
    final int v1Fragment = v1Fragments[i];
    final int v2Fragment = v2Fragments[i];
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
  final Match m1 = _iosDeviceTypePattern.firstMatch(id1);
  final Match m2 = _iosDeviceTypePattern.firstMatch(id2);

  final int v1 = int.parse(m1[1]);
  final int v2 = int.parse(m2[1]);

  if (v1 != v2)
    return v1.compareTo(v2);

  // Sorted in the least preferred first order.
  const List<String> qualifiers = const <String>['-Plus', '', 's-Plus', 's'];

  final int q1 = qualifiers.indexOf(m1[2]);
  final int q2 = qualifiers.indexOf(m2[2]);
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
