// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../convert.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../protocol_discovery.dart';
import 'ios_workflow.dart';
import 'mac.dart';
import 'plist_parser.dart';

const String _xcrunPath = '/usr/bin/xcrun';
const String iosSimulatorId = 'apple_ios_simulator';

class IOSSimulators extends PollingDeviceDiscovery {
  IOSSimulators() : super('iOS simulators');

  @override
  bool get supportsPlatform => globals.platform.isMacOS;

  @override
  bool get canListAnything => iosWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices() async => IOSSimulatorUtils.instance.getAttachedDevices();
}

class IOSSimulatorUtils {
  /// Returns [IOSSimulatorUtils] active in the current app context (i.e. zone).
  static IOSSimulatorUtils get instance => context.get<IOSSimulatorUtils>();

  Future<List<IOSSimulator>> getAttachedDevices() async {
    if (!globals.xcode.isInstalledAndMeetsVersionCheck) {
      return <IOSSimulator>[];
    }

    final List<SimDevice> connected = await SimControl.instance.getConnectedDevices();
    return connected.map<IOSSimulator>((SimDevice device) {
      return IOSSimulator(device.udid, name: device.name, simulatorCategory: device.category);
    }).toList();
  }
}

/// A wrapper around the `simctl` command line tool.
class SimControl {
  /// Returns [SimControl] active in the current app context (i.e. zone).
  static SimControl get instance => context.get<SimControl>();

  /// Runs `simctl list --json` and returns the JSON of the corresponding
  /// [section].
  Future<Map<String, dynamic>> _list(SimControlListSection section) async {
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
    globals.printTrace(command.join(' '));
    final ProcessResult results = await globals.processManager.run(command);
    if (results.exitCode != 0) {
      globals.printError('Error executing simctl: ${results.exitCode}\n${results.stderr}');
      return <String, Map<String, dynamic>>{};
    }
    try {
      final Object decodeResult = json.decode(results.stdout?.toString())[section.name];
      if (decodeResult is Map<String, dynamic>) {
        return decodeResult;
      }
      globals.printError('simctl returned unexpected JSON response: ${results.stdout}');
      return <String, dynamic>{};
    } on FormatException {
      // We failed to parse the simctl output, or it returned junk.
      // One known message is "Install Started" isn't valid JSON but is
      // returned sometimes.
      globals.printError('simctl returned non-JSON response: ${results.stdout}');
      return <String, dynamic>{};
    }
  }

  /// Returns a list of all available devices, both potential and connected.
  Future<List<SimDevice>> getDevices() async {
    final List<SimDevice> devices = <SimDevice>[];

    final Map<String, dynamic> devicesSection = await _list(SimControlListSection.devices);

    for (final String deviceCategory in devicesSection.keys) {
      final Object devicesData = devicesSection[deviceCategory];
      if (devicesData != null && devicesData is List<dynamic>) {
        for (final Map<String, dynamic> data in devicesData.map<Map<String, dynamic>>(castStringKeyedMap)) {
          devices.add(SimDevice(deviceCategory, data));
        }
      }
    }

    return devices;
  }

  /// Returns all the connected simulator devices.
  Future<List<SimDevice>> getConnectedDevices() async {
    final List<SimDevice> simDevices = await getDevices();
    return simDevices.where((SimDevice device) => device.isBooted).toList();
  }

  Future<bool> isInstalled(String deviceId, String appId) {
    return processUtils.exitsHappy(<String>[
      _xcrunPath,
      'simctl',
      'get_app_container',
      deviceId,
      appId,
    ]);
  }

  Future<RunResult> install(String deviceId, String appPath) {
    Future<RunResult> result;
    try {
      result = processUtils.run(
        <String>[_xcrunPath, 'simctl', 'install', deviceId, appPath],
        throwOnError: true,
      );
    } on ProcessException catch (exception) {
      throwToolExit('Unable to install $appPath on $deviceId:\n$exception');
    }
    return result;
  }

  Future<RunResult> uninstall(String deviceId, String appId) {
    Future<RunResult> result;
    try {
      result = processUtils.run(
        <String>[_xcrunPath, 'simctl', 'uninstall', deviceId, appId],
        throwOnError: true,
      );
    } on ProcessException catch (exception) {
      throwToolExit('Unable to uninstall $appId from $deviceId:\n$exception');
    }
    return result;
  }

  Future<RunResult> launch(String deviceId, String appIdentifier, [ List<String> launchArgs ]) {
    Future<RunResult> result;
    try {
      result = processUtils.run(
        <String>[
          _xcrunPath,
          'simctl',
          'launch',
          deviceId,
          appIdentifier,
          ...?launchArgs,
        ],
        throwOnError: true,
      );
    } on ProcessException catch (exception) {
      throwToolExit('Unable to launch $appIdentifier on $deviceId:\n$exception');
    }
    return result;
  }

  Future<void> takeScreenshot(String deviceId, String outputPath) async {
    try {
      await processUtils.run(
        <String>[_xcrunPath, 'simctl', 'io', deviceId, 'screenshot', outputPath],
        throwOnError: true,
      );
    } on ProcessException catch (exception) {
      throwToolExit('Unable to take screenshot of $deviceId:\n$exception');
    }
  }
}

/// Enumerates all data sections of `xcrun simctl list --json` command.
class SimControlListSection {
  const SimControlListSection._(this.name);

  final String name;

  static const SimControlListSection devices = SimControlListSection._('devices');
  static const SimControlListSection devicetypes = SimControlListSection._('devicetypes');
  static const SimControlListSection runtimes = SimControlListSection._('runtimes');
  static const SimControlListSection pairs = SimControlListSection._('pairs');
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
  final Map<String, dynamic> data;

  String get state => data['state']?.toString();
  String get availability => data['availability']?.toString();
  String get name => data['name']?.toString();
  String get udid => data['udid']?.toString();

  bool get isBooted => state == 'Booted';
}

class IOSSimulator extends Device {
  IOSSimulator(String id, { this.name, this.simulatorCategory }) : super(
      id,
      category: Category.mobile,
      platformType: PlatformType.ios,
      ephemeral: true,
  );

  @override
  final String name;

  final String simulatorCategory;

  @override
  Future<bool> get isLocalEmulator async => true;

  @override
  Future<String> get emulatorId async => iosSimulatorId;

  @override
  bool get supportsHotReload => true;

  @override
  bool get supportsHotRestart => true;

  Map<ApplicationPackage, _IOSSimulatorLogReader> _logReaders;
  _IOSSimulatorDevicePortForwarder _portForwarder;

  String get xcrunPath => globals.fs.path.join('/usr', 'bin', 'xcrun');

  @override
  Future<bool> isAppInstalled(ApplicationPackage app) {
    return SimControl.instance.isInstalled(id, app.id);
  }

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> installApp(covariant IOSApp app) async {
    try {
      final IOSApp iosApp = app;
      await SimControl.instance.install(id, iosApp.simulatorBundlePath);
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
    if (!globals.platform.isMacOS) {
      _supportMessage = 'iOS devices require a Mac host machine.';
      return false;
    }

    // Check if the device is part of a blacklisted category.
    // We do not yet support WatchOS or tvOS devices.
    final RegExp blacklist = RegExp(r'Apple (TV|Watch)', caseSensitive: false);
    if (blacklist.hasMatch(name)) {
      _supportMessage = 'Flutter does not support Apple TV or Apple Watch.';
      return false;
    }
    return true;
  }

  String _supportMessage;

  @override
  String supportMessage() {
    if (isSupported()) {
      return 'Supported';
    }

    return _supportMessage ?? 'Unknown';
  }

  @override
  Future<LaunchResult> startApp(
    covariant IOSApp package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
  }) async {
    if (!prebuiltApplication && package is BuildableIOSApp) {
      globals.printTrace('Building ${package.name} for $id.');

      try {
        await _setupUpdatedApplicationBundle(package, debuggingOptions.buildInfo, mainPath);
      } on ToolExit catch (e) {
        globals.printError(e.message);
        return LaunchResult.failed();
      }
    } else {
      if (!await installApp(package)) {
        return LaunchResult.failed();
      }
    }

    // Prepare launch arguments.
    final List<String> args = <String>[
      '--enable-dart-profiling',
      if (debuggingOptions.debuggingEnabled) ...<String>[
        if (debuggingOptions.buildInfo.isDebug) ...<String>[
          '--enable-checked-mode',
          '--verify-entry-points',
        ],
        if (debuggingOptions.startPaused) '--start-paused',
        if (debuggingOptions.disableServiceAuthCodes) '--disable-service-auth-codes',
        if (debuggingOptions.skiaDeterministicRendering) '--skia-deterministic-rendering',
        if (debuggingOptions.useTestFonts) '--use-test-fonts',
        '--observatory-port=${debuggingOptions.hostVmServicePort ?? 0}',
      ],
    ];

    ProtocolDiscovery observatoryDiscovery;
    if (debuggingOptions.debuggingEnabled) {
      observatoryDiscovery = ProtocolDiscovery.observatory(
        getLogReader(app: package),
        ipv6: ipv6,
        hostPort: debuggingOptions.hostVmServicePort,
        devicePort: debuggingOptions.deviceVmServicePort,
      );
    }

    // Launch the updated application in the simulator.
    try {
      // Use the built application's Info.plist to get the bundle identifier,
      // which should always yield the correct value and does not require
      // parsing the xcodeproj or configuration files.
      // See https://github.com/flutter/flutter/issues/31037 for more information.
      final String plistPath = globals.fs.path.join(package.simulatorBundlePath, 'Info.plist');
      final String bundleIdentifier = PlistParser.instance.getValueFromFile(plistPath, PlistParser.kCFBundleIdentifierKey);

      await SimControl.instance.launch(id, bundleIdentifier, args);
    } catch (error) {
      globals.printError('$error');
      return LaunchResult.failed();
    }

    if (!debuggingOptions.debuggingEnabled) {
      return LaunchResult.succeeded();
    }

    // Wait for the service protocol port here. This will complete once the
    // device has printed "Observatory is listening on..."
    globals.printTrace('Waiting for observatory port to be available...');

    try {
      final Uri deviceUri = await observatoryDiscovery.uri;
      return LaunchResult.succeeded(observatoryUri: deviceUri);
    } catch (error) {
      globals.printError('Error waiting for a debug connection: $error');
      return LaunchResult.failed();
    } finally {
      await observatoryDiscovery.cancel();
    }
  }

  Future<void> _setupUpdatedApplicationBundle(covariant BuildableIOSApp app, BuildInfo buildInfo, String mainPath) async {
    await sideloadUpdatedAssetsForInstalledApplicationBundle(buildInfo, mainPath);

    // Step 1: Build the Xcode project.
    // The build mode for the simulator is always debug.

    final BuildInfo debugBuildInfo = BuildInfo(BuildMode.debug, buildInfo.flavor,
        trackWidgetCreation: buildInfo.trackWidgetCreation,
        extraFrontEndOptions: buildInfo.extraFrontEndOptions,
        extraGenSnapshotOptions: buildInfo.extraGenSnapshotOptions);

    final XcodeBuildResult buildResult = await buildXcodeProject(
      app: app,
      buildInfo: debugBuildInfo,
      targetOverride: mainPath,
      buildForDevice: false,
    );
    if (!buildResult.success) {
      throwToolExit('Could not build the application for the simulator.');
    }

    // Step 2: Assert that the Xcode project was successfully built.
    final Directory bundle = globals.fs.directory(app.simulatorBundlePath);
    final bool bundleExists = bundle.existsSync();
    if (!bundleExists) {
      throwToolExit('Could not find the built application bundle at ${bundle.path}.');
    }

    // Step 3: Install the updated bundle to the simulator.
    await SimControl.instance.install(id, globals.fs.path.absolute(bundle.path));
  }

  @visibleForTesting
  Future<void> sideloadUpdatedAssetsForInstalledApplicationBundle(BuildInfo buildInfo, String mainPath) {
    // Run compiler to produce kernel file for the application.
    return BundleBuilder().build(
      platform: TargetPlatform.ios,
      mainPath: mainPath,
      precompiledSnapshot: false,
      buildMode: buildInfo.mode,
      trackWidgetCreation: buildInfo.trackWidgetCreation,
    );
  }

  @override
  Future<bool> stopApp(ApplicationPackage app) async {
    // Currently we don't have a way to stop an app running on iOS.
    return false;
  }

  String get logFilePath {
    return globals.platform.environment.containsKey('IOS_SIMULATOR_LOG_FILE_PATH')
      ? globals.platform.environment['IOS_SIMULATOR_LOG_FILE_PATH'].replaceAll('%{id}', id)
      : globals.fs.path.join(
          globals.fsUtils.homeDirPath,
          'Library',
          'Logs',
          'CoreSimulator',
          id,
          'system.log',
        );
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  Future<String> get sdkNameAndVersion async => simulatorCategory;

  final RegExp _iosSdkRegExp = RegExp(r'iOS( |-)(\d+)');

  Future<int> get sdkMajorVersion async {
    final Match sdkMatch = _iosSdkRegExp.firstMatch(await sdkNameAndVersion);
    return int.parse(sdkMatch?.group(2) ?? '11');
  }

  @override
  DeviceLogReader getLogReader({ covariant IOSApp app }) {
    assert(app is IOSApp);
    _logReaders ??= <ApplicationPackage, _IOSSimulatorLogReader>{};
    return _logReaders.putIfAbsent(app, () => _IOSSimulatorLogReader(this, app));
  }

  @override
  DevicePortForwarder get portForwarder => _portForwarder ??= _IOSSimulatorDevicePortForwarder(this);

  @override
  void clearLogs() {
    final File logFile = globals.fs.file(logFilePath);
    if (logFile.existsSync()) {
      final RandomAccessFile randomFile = logFile.openSync(mode: FileMode.write);
      randomFile.truncateSync(0);
      randomFile.closeSync();
    }
  }

  Future<void> ensureLogsExists() async {
    if (await sdkMajorVersion < 11) {
      final File logFile = globals.fs.file(logFilePath);
      if (!logFile.existsSync()) {
        logFile.writeAsBytesSync(<int>[]);
      }
    }
  }

  bool get _xcodeVersionSupportsScreenshot {
    return globals.xcode.majorVersion > 8 || (globals.xcode.majorVersion == 8 && globals.xcode.minorVersion >= 2);
  }

  @override
  bool get supportsScreenshot => _xcodeVersionSupportsScreenshot;

  @override
  Future<void> takeScreenshot(File outputFile) {
    return SimControl.instance.takeScreenshot(id, outputFile.path);
  }

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.ios.existsSync();
  }

  @override
  Future<void> dispose() async {
    _logReaders?.forEach(
      (ApplicationPackage application, _IOSSimulatorLogReader logReader) {
        logReader.dispose();
      },
    );
    await _portForwarder?.dispose();
  }
}

/// Launches the device log reader process on the host.
Future<Process> launchDeviceLogTool(IOSSimulator device) async {
  // Versions of iOS prior to iOS 11 log to the simulator syslog file.
  if (await device.sdkMajorVersion < 11) {
    return processUtils.start(<String>['tail', '-n', '0', '-F', device.logFilePath]);
  }

  // For iOS 11 and above, use /usr/bin/log to tail process logs.
  // Run in interactive mode (via script), otherwise /usr/bin/log buffers in 4k chunks. (radar: 34420207)
  return processUtils.start(<String>[
    'script', '/dev/null', '/usr/bin/log', 'stream', '--style', 'syslog', '--predicate', 'processImagePath CONTAINS "${device.id}"',
  ]);
}

Future<Process> launchSystemLogTool(IOSSimulator device) async {
  // Versions of iOS prior to 11 tail the simulator syslog file.
  if (await device.sdkMajorVersion < 11) {
    return processUtils.start(<String>['tail', '-n', '0', '-F', '/private/var/log/system.log']);
  }

  // For iOS 11 and later, all relevant detail is in the device log.
  return null;
}

class _IOSSimulatorLogReader extends DeviceLogReader {
  _IOSSimulatorLogReader(this.device, IOSApp app) {
    _linesController = StreamController<String>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
    _appName = app == null ? null : app.name.replaceAll('.app', '');
  }

  final IOSSimulator device;

  String _appName;

  StreamController<String> _linesController;

  // We log from two files: the device and the system log.
  Process _deviceProcess;
  Process _systemProcess;

  @override
  Stream<String> get logLines => _linesController.stream;

  @override
  String get name => device.name;

  Future<void> _start() async {
    // Device log.
    await device.ensureLogsExists();
    _deviceProcess = await launchDeviceLogTool(device);
    _deviceProcess.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen(_onDeviceLine);
    _deviceProcess.stderr.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen(_onDeviceLine);

    // Track system.log crashes.
    // ReportCrash[37965]: Saved crash report for FlutterRunner[37941]...
    _systemProcess = await launchSystemLogTool(device);
    if (_systemProcess != null) {
      _systemProcess.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen(_onSystemLine);
      _systemProcess.stderr.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen(_onSystemLine);
    }

    // We don't want to wait for the process or its callback. Best effort
    // cleanup in the callback.
    unawaited(_deviceProcess.exitCode.whenComplete(() {
      if (_linesController.hasListener) {
        _linesController.close();
      }
    }));
  }

  // Match the log prefix (in order to shorten it):
  // * Xcode 8: Sep 13 15:28:51 cbracken-macpro localhost Runner[37195]: (Flutter) Observatory listening on http://127.0.0.1:57701/
  // * Xcode 9: 2017-09-13 15:26:57.228948-0700  localhost Runner[37195]: (Flutter) Observatory listening on http://127.0.0.1:57701/
  static final RegExp _mapRegex = RegExp(r'\S+ +\S+ +\S+ +(\S+ +)?(\S+)\[\d+\]\)?: (\(.*?\))? *(.*)$');

  // Jan 31 19:23:28 --- last message repeated 1 time ---
  static final RegExp _lastMessageSingleRegex = RegExp(r'\S+ +\S+ +\S+ --- last message repeated 1 time ---$');
  static final RegExp _lastMessageMultipleRegex = RegExp(r'\S+ +\S+ +\S+ --- last message repeated (\d+) times ---$');

  static final RegExp _flutterRunnerRegex = RegExp(r' FlutterRunner\[\d+\] ');

  String _filterDeviceLine(String string) {
    final Match match = _mapRegex.matchAsPrefix(string);
    if (match != null) {
      final String category = match.group(2);
      final String tag = match.group(3);
      final String content = match.group(4);

      // Filter out non-Flutter originated noise from the engine.
      if (_appName != null && category != _appName) {
        return null;
      }

      if (tag != null && tag != '(Flutter)') {
        return null;
      }

      // Filter out some messages that clearly aren't related to Flutter.
      if (string.contains(': could not find icon for representation -> com.apple.')) {
        return null;
      }

      // assertion failed: 15G1212 13E230: libxpc.dylib + 57882 [66C28065-C9DB-3C8E-926F-5A40210A6D1B]: 0x7d
      if (content.startsWith('assertion failed: ') && content.contains(' libxpc.dylib ')) {
        return null;
      }

      if (_appName == null) {
        return '$category: $content';
      } else if (category == _appName) {
        return content;
      }

      return null;
    }

    if (string.startsWith('Filtering the log data using ')) {
      return null;
    }

    if (string.startsWith('Timestamp                       (process)[PID]')) {
      return null;
    }

    if (_lastMessageSingleRegex.matchAsPrefix(string) != null) {
      return null;
    }

    if (RegExp(r'assertion failed: .* libxpc.dylib .* 0x7d$').matchAsPrefix(string) != null) {
      return null;
    }

    return string;
  }

  String _lastLine;

  void _onDeviceLine(String line) {
    globals.printTrace('[DEVICE LOG] $line');
    final Match multi = _lastMessageMultipleRegex.matchAsPrefix(line);

    if (multi != null) {
      if (_lastLine != null) {
        int repeat = int.parse(multi.group(1));
        repeat = math.max(0, math.min(100, repeat));
        for (int i = 1; i < repeat; i++) {
          _linesController.add(_lastLine);
        }
      }
    } else {
      _lastLine = _filterDeviceLine(line);
      if (_lastLine != null) {
        _linesController.add(_lastLine);
      }
    }
  }

  String _filterSystemLog(String string) {
    final Match match = _mapRegex.matchAsPrefix(string);
    return match == null ? string : '${match.group(1)}: ${match.group(2)}';
  }

  void _onSystemLine(String line) {
    globals.printTrace('[SYS LOG] $line');
    if (!_flutterRunnerRegex.hasMatch(line)) {
      return;
    }

    final String filteredLine = _filterSystemLog(line);
    if (filteredLine == null) {
      return;
    }

    _linesController.add(filteredLine);
  }

  void _stop() {
    _deviceProcess?.kill();
    _systemProcess?.kill();
  }

  @override
  void dispose() {
    _stop();
  }
}

int compareIosVersions(String v1, String v2) {
  final List<int> v1Fragments = v1.split('.').map<int>(int.parse).toList();
  final List<int> v2Fragments = v2.split('.').map<int>(int.parse).toList();

  int i = 0;
  while (i < v1Fragments.length && i < v2Fragments.length) {
    final int v1Fragment = v1Fragments[i];
    final int v2Fragment = v2Fragments[i];
    if (v1Fragment != v2Fragment) {
      return v1Fragment.compareTo(v2Fragment);
    }
    i += 1;
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
    RegExp(r'com.apple.CoreSimulator.SimDeviceType.iPhone-(\d+)(.*)');

int compareIphoneVersions(String id1, String id2) {
  final Match m1 = _iosDeviceTypePattern.firstMatch(id1);
  final Match m2 = _iosDeviceTypePattern.firstMatch(id2);

  final int v1 = int.parse(m1[1]);
  final int v2 = int.parse(m2[1]);

  if (v1 != v2) {
    return v1.compareTo(v2);
  }

  // Sorted in the least preferred first order.
  const List<String> qualifiers = <String>['-Plus', '', 's-Plus', 's'];

  final int q1 = qualifiers.indexOf(m1[2]);
  final int q2 = qualifiers.indexOf(m2[2]);
  return q1.compareTo(q2);
}

class _IOSSimulatorDevicePortForwarder extends DevicePortForwarder {
  _IOSSimulatorDevicePortForwarder(this.device);

  final IOSSimulator device;

  final List<ForwardedPort> _ports = <ForwardedPort>[];

  @override
  List<ForwardedPort> get forwardedPorts => _ports;

  @override
  Future<int> forward(int devicePort, { int hostPort }) async {
    if (hostPort == null || hostPort == 0) {
      hostPort = devicePort;
    }
    assert(devicePort == hostPort);
    _ports.add(ForwardedPort(devicePort, hostPort));
    return hostPort;
  }

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async {
    _ports.remove(forwardedPort);
  }

  @override
  Future<void> dispose() async {
    final List<ForwardedPort> portsCopy = List<ForwardedPort>.from(_ports);
    for (final ForwardedPort port in portsCopy) {
      await unforward(port);
    }
  }
}
