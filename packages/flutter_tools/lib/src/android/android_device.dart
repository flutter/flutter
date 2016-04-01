// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../android/android_sdk.dart';
import '../application_package.dart';
import '../base/common.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../flx.dart' as flx;
import '../globals.dart';
import '../service_protocol.dart';
import '../toolchain.dart';
import 'adb.dart';
import 'android.dart';

const String _defaultAdbPath = 'adb';

// Path where the FLX bundle will be copied on the device.
const String _deviceBundlePath = '/data/local/tmp/dev.flx';

// Path where the snapshot will be copied on the device.
const String _deviceSnapshotPath = '/data/local/tmp/dev_snapshot.bin';

class AndroidDevices extends PollingDeviceDiscovery {
  AndroidDevices() : super('AndroidDevices');

  @override
  bool get supportsPlatform => true;

  @override
  List<Device> pollingGetDevices() => getAdbDevices();
}

class AndroidDevice extends Device {
  AndroidDevice(
    String id, {
    this.productID,
    this.modelID,
    this.deviceCodeName
  }) : super(id);

  final String productID;
  final String modelID;
  final String deviceCodeName;

  bool _isLocalEmulator;

  @override
  bool get isLocalEmulator {
    if (_isLocalEmulator == null) {
      // http://developer.android.com/ndk/guides/abis.html (x86, armeabi-v7a, ...)
      String value = runCheckedSync(adbCommandForDevice(['shell', 'getprop', 'ro.product.cpu.abi']));
      _isLocalEmulator = value.startsWith('x86');
    }

    return _isLocalEmulator;
  }

  _AdbLogReader _logReader;
  _AndroidDevicePortForwarder _portForwarder;

  List<String> adbCommandForDevice(List<String> args) {
    return <String>[androidSdk.adbPath, '-s', id]..addAll(args);
  }

  bool _isValidAdbVersion(String adbVersion) {
    // Sample output: 'Android Debug Bridge version 1.0.31'
    Match versionFields = new RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(adbVersion);
    if (versionFields != null) {
      int majorVersion = int.parse(versionFields[1]);
      int minorVersion = int.parse(versionFields[2]);
      int patchVersion = int.parse(versionFields[3]);
      if (majorVersion > 1) {
        return true;
      }
      if (majorVersion == 1 && minorVersion > 0) {
        return true;
      }
      if (majorVersion == 1 && minorVersion == 0 && patchVersion >= 32) {
        return true;
      }
      return false;
    }
    printError(
        'Unrecognized adb version string $adbVersion. Skipping version check.');
    return true;
  }

  bool _checkForSupportedAdbVersion() {
    if (androidSdk == null)
      return false;

    try {
      String adbVersion = runCheckedSync(<String>[androidSdk.adbPath, 'version']);
      if (_isValidAdbVersion(adbVersion))
        return true;
      printError('The ADB at "${androidSdk.adbPath}" is too old; please install version 1.0.32 or later.');
    } catch (error, trace) {
      printError('Error running ADB: $error', trace);
    }

    return false;
  }

  bool _checkForSupportedAndroidVersion() {
    try {
      // If the server is automatically restarted, then we get irrelevant
      // output lines like this, which we want to ignore:
      //   adb server is out of date.  killing..
      //   * daemon started successfully *
      runCheckedSync(<String>[androidSdk.adbPath, 'start-server']);

      // Sample output: '22'
      String sdkVersion = runCheckedSync(
        adbCommandForDevice(<String>['shell', 'getprop', 'ro.build.version.sdk'])
      ).trimRight();

      int sdkVersionParsed = int.parse(sdkVersion, onError: (String source) => null);
      if (sdkVersionParsed == null) {
        printError('Unexpected response from getprop: "$sdkVersion"');
        return false;
      }

      if (sdkVersionParsed < minApiLevel) {
        printError(
          'The Android version ($sdkVersion) on the target device is too old. Please '
          'use a $minVersionName (version $minApiLevel / $minVersionText) device or later.');
        return false;
      }

      return true;
    } catch (e) {
      printError('Unexpected failure from adb: $e');
      return false;
    }
  }

  String _getDeviceSha1Path(ApplicationPackage app) {
    return '/data/local/tmp/sky.${app.id}.sha1';
  }

  String _getDeviceApkSha1(ApplicationPackage app) {
    return runCheckedSync(adbCommandForDevice(<String>['shell', 'cat', _getDeviceSha1Path(app)]));
  }

  String _getSourceSha1(ApplicationPackage app) {
    File shaFile = new File('${app.localPath}.sha1');
    return shaFile.existsSync() ? shaFile.readAsStringSync() : '';
  }

  @override
  String get name => modelID;

  @override
  bool isAppInstalled(ApplicationPackage app) {
    // This call takes 400ms - 600ms.
    if (runCheckedSync(adbCommandForDevice(['shell', 'pm', 'path', app.id])).isEmpty)
      return false;

    // Check the application SHA.
    return _getDeviceApkSha1(app) == _getSourceSha1(app);
  }

  @override
  bool installApp(ApplicationPackage app) {
    if (!FileSystemEntity.isFileSync(app.localPath)) {
      printError('"${app.localPath}" does not exist.');
      return false;
    }

    if (!_checkForSupportedAdbVersion() || !_checkForSupportedAndroidVersion())
      return false;

    printStatus('Installing ${app.name} on device.');
    runCheckedSync(adbCommandForDevice(<String>['install', '-r', app.localPath]));
    runCheckedSync(adbCommandForDevice(<String>['shell', 'echo', '-n', _getSourceSha1(app), '>', _getDeviceSha1Path(app)]));
    return true;
  }

  Future<Null> _forwardObservatoryPort(int devicePort, int port) async {
    bool portWasZero = (port == null) || (port == 0);

    try {
      // Set up port forwarding for observatory.
      port = await portForwarder.forward(devicePort,
                                         hostPort: port);
      if (portWasZero)
        printStatus('Observatory listening on http://127.0.0.1:$port');
    } catch (e) {
      printError('Unable to forward Observatory port $port: $e');
    }
  }

  Future<bool> startBundle(AndroidApk apk, String bundlePath, {
    bool checked: true,
    bool traceStartup: false,
    String route,
    bool clearLogs: false,
    bool startPaused: false,
    int debugPort: observatoryDefaultPort
  }) async {
    printTrace('$this startBundle');

    if (!FileSystemEntity.isFileSync(bundlePath)) {
      printError('Cannot find $bundlePath');
      return false;
    }

    if (clearLogs)
      this.clearLogs();

    runCheckedSync(adbCommandForDevice(<String>['push', bundlePath, _deviceBundlePath]));

    ServiceProtocolDiscovery serviceProtocolDiscovery =
        new ServiceProtocolDiscovery(logReader);

    // We take this future here but do not wait for completion until *after* we
    // start the bundle.
    Future<int> scrapeServicePort = serviceProtocolDiscovery.nextPort();

    List<String> cmd = adbCommandForDevice(<String>[
      'shell', 'am', 'start',
      '-a', 'android.intent.action.RUN',
      '-d', _deviceBundlePath,
      '-f', '0x20000000',  // FLAG_ACTIVITY_SINGLE_TOP
      '--ez', 'enable-background-compilation', 'true',
    ]);
    if (checked)
      cmd.addAll(<String>['--ez', 'enable-checked-mode', 'true']);
    if (traceStartup)
      cmd.addAll(<String>['--ez', 'trace-startup', 'true']);
    if (startPaused)
      cmd.addAll(<String>['--ez', 'start-paused', 'true']);
    if (route != null)
      cmd.addAll(<String>['--es', 'route', route]);
    cmd.add(apk.launchActivity);
    String result = runCheckedSync(cmd);
    // This invocation returns 0 even when it fails.
    if (result.contains('Error: ')) {
      printError(result.trim());
      return false;
    }

    // Wait for the service protocol port here. This will complete once the
    // device has printed "Observatory is listening on...".
    printTrace('Waiting for observatory port to be available...');

    try {
      int devicePort = await scrapeServicePort.timeout(new Duration(seconds: 12));
      printTrace('service protocol port = $devicePort');
      await _forwardObservatoryPort(devicePort, debugPort);
      return true;
    } catch (error) {
      if (error is TimeoutException)
        printError('Timed out while waiting for a debug connection.');
      else
        printError('Error waiting for a debug connection: $error');

      return false;
    }
  }

  @override
  Future<bool> startApp(
    ApplicationPackage package,
    Toolchain toolchain, {
    String mainPath,
    String route,
    bool checked: true,
    bool clearLogs: false,
    bool startPaused: false,
    int debugPort: observatoryDefaultPort,
    Map<String, dynamic> platformArgs
  }) async {
    if (!_checkForSupportedAdbVersion() || !_checkForSupportedAndroidVersion())
      return false;

    String localBundlePath = await flx.buildFlx(
      toolchain,
      mainPath: mainPath,
      includeRobotoFonts: false
    );

    printTrace('Starting bundle for $this.');

    if (await startBundle(
      package,
      localBundlePath,
      checked: checked,
      traceStartup: platformArgs['trace-startup'],
      route: route,
      clearLogs: clearLogs,
      startPaused: startPaused,
      debugPort: debugPort
    )) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<bool> stopApp(ApplicationPackage app) {
    List<String> command = adbCommandForDevice(<String>['shell', 'am', 'force-stop', app.id]);
    return runCommandAndStreamOutput(command).then((int exitCode) => exitCode == 0);
  }

  // TODO(devoncarew): Use isLocalEmulator to return android_arm or android_x64.
  @override
  TargetPlatform get platform => TargetPlatform.android_arm;

  @override
  void clearLogs() {
    runSync(adbCommandForDevice(<String>['logcat', '-c']));
  }

  @override
  DeviceLogReader get logReader {
    if (_logReader == null)
      _logReader = new _AdbLogReader(this);
    return _logReader;
  }

  @override
  DevicePortForwarder get portForwarder {
    if (_portForwarder == null)
      _portForwarder = new _AndroidDevicePortForwarder(this);

    return _portForwarder;
  }

  void startTracing(AndroidApk apk) {
    runCheckedSync(adbCommandForDevice(<String>[
      'shell',
      'am',
      'broadcast',
      '-a',
      '${apk.id}.TRACING_START'
    ]));
  }

  /// Return the most recent timestamp in the Android log or `null` if there is
  /// no available timestamp. The format can be passed to logcat's -T option.
  String get lastLogcatTimestamp {
    String output = runCheckedSync(adbCommandForDevice(<String>[
      'logcat', '-v', 'time', '-t', '1'
    ]));

    RegExp timeRegExp = new RegExp(r'^\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}', multiLine: true);
    Match timeMatch = timeRegExp.firstMatch(output);
    return timeMatch?.group(0);
  }

  Future<String> stopTracing(AndroidApk apk, { String outPath }) async {
    // Workaround for logcat -c not always working:
    // http://stackoverflow.com/questions/25645012/logcat-on-android-l-not-clearing-after-unplugging-and-reconnecting
    String beforeStop = lastLogcatTimestamp;
    runCheckedSync(adbCommandForDevice(<String>[
      'shell',
      'am',
      'broadcast',
      '-a',
      '${apk.id}.TRACING_STOP'
    ]));

    RegExp traceRegExp = new RegExp(r'Saving trace to (\S+)', multiLine: true);
    RegExp completeRegExp = new RegExp(r'Trace complete', multiLine: true);

    String tracePath;
    bool isComplete = false;
    while (!isComplete) {
      List<String> args = <String>['logcat', '-d'];
      if (beforeStop != null)
        args.addAll(<String>['-T', beforeStop]);
      String logs = runCheckedSync(adbCommandForDevice(args));
      Match fileMatch = traceRegExp.firstMatch(logs);
      if (fileMatch != null && fileMatch[1] != null) {
        tracePath = fileMatch[1];
      }
      isComplete = completeRegExp.hasMatch(logs);
    }

    if (tracePath != null) {
      String localPath = (outPath != null) ? outPath : path.basename(tracePath);

      // Run cat via ADB to print the captured trace file. (adb pull will be unable
      // to access the file if it does not have root permissions)
      IOSink catOutput = new File(localPath).openWrite();
      List<String> catCommand = adbCommandForDevice(
          <String>['shell', 'run-as', apk.id, 'cat', tracePath]
      );
      Process catProcess = await Process.start(catCommand[0],
          catCommand.getRange(1, catCommand.length).toList());
      catProcess.stdout.pipe(catOutput);
      int exitCode = await catProcess.exitCode;
      if (exitCode != 0)
        throw 'Error code $exitCode returned when running ${catCommand.join(" ")}';

      runSync(adbCommandForDevice(
          <String>['shell', 'run-as', apk.id, 'rm', tracePath]
      ));
      return localPath;
    }
    printError('No trace file detected. '
        'Did you remember to start the trace before stopping it?');
    return null;
  }

  @override
  bool isSupported() => true;

  Future<bool> refreshSnapshot(String activity, String snapshotPath) async {
    if (!FileSystemEntity.isFileSync(snapshotPath)) {
      printError('Cannot find $snapshotPath');
      return false;
    }

    runCheckedSync(adbCommandForDevice(<String>['push', snapshotPath, _deviceSnapshotPath]));

    List<String> cmd = adbCommandForDevice(<String>[
      'shell', 'am', 'start',
      '-a', 'android.intent.action.RUN',
      '-d', _deviceBundlePath,
      '-f', '0x20000000',  // FLAG_ACTIVITY_SINGLE_TOP
      '--es', 'snapshot', _deviceSnapshotPath,
      activity,
    ]);
    runCheckedSync(cmd);
    return true;
  }

  @override
  bool get supportsScreenshot => true;

  @override
  Future<bool> takeScreenshot(File outputFile) {
    const String remotePath = '/data/local/tmp/flutter_screenshot.png';

    runCheckedSync(adbCommandForDevice(<String>['shell', 'screencap', '-p', remotePath]));
    runCheckedSync(adbCommandForDevice(<String>['pull', remotePath, outputFile.path]));
    runCheckedSync(adbCommandForDevice(<String>['shell', 'rm', remotePath]));

    return new Future<bool>.value(true);
  }
}

List<AndroidDevice> getAdbDevices() {
  String adbPath = getAdbPath(androidSdk);
  if (adbPath == null)
    return <AndroidDevice>[];

  List<AndroidDevice> devices = [];

  List<String> output = runSync(<String>[adbPath, 'devices', '-l']).trim().split('\n');

  // 015d172c98400a03       device usb:340787200X product:nakasi model:Nexus_7 device:grouper
  RegExp deviceRegex1 = new RegExp(
      r'^(\S+)\s+device\s+.*product:(\S+)\s+model:(\S+)\s+device:(\S+)$');

  // 0149947A0D01500C       device usb:340787200X
  RegExp deviceRegex2 = new RegExp(r'^(\S+)\s+device\s+\S+$');
  RegExp unauthorizedRegex = new RegExp(r'^(\S+)\s+unauthorized\s+\S+$');
  RegExp offlineRegex = new RegExp(r'^(\S+)\s+offline\s+\S+$');

  // Skip the first line, which is always 'List of devices attached'.
  for (String line in output.skip(1)) {
    // Skip lines like:
    // * daemon not running. starting it now on port 5037 *
    // * daemon started successfully *
    if (line.startsWith('* daemon '))
      continue;

    if (line.startsWith('List of devices'))
      continue;

    if (deviceRegex1.hasMatch(line)) {
      Match match = deviceRegex1.firstMatch(line);
      String deviceID = match[1];
      String productID = match[2];
      String modelID = match[3];
      String deviceCodeName = match[4];

      if (modelID != null)
        modelID = cleanAdbDeviceName(modelID);

      devices.add(new AndroidDevice(
        deviceID,
        productID: productID,
        modelID: modelID,
        deviceCodeName: deviceCodeName
      ));
    } else if (deviceRegex2.hasMatch(line)) {
      Match match = deviceRegex2.firstMatch(line);
      String deviceID = match[1];
      devices.add(new AndroidDevice(deviceID));
    } else if (unauthorizedRegex.hasMatch(line)) {
      Match match = unauthorizedRegex.firstMatch(line);
      String deviceID = match[1];
      printError(
        'Device $deviceID is not authorized.\n'
        'You might need to check your device for an authorization dialog.'
      );
    } else if (offlineRegex.hasMatch(line)) {
      Match match = offlineRegex.firstMatch(line);
      String deviceID = match[1];
      printError('Device $deviceID is offline.');
    } else {
      printError(
        'Unexpected failure parsing device information from adb output:\n'
        '$line\n'
        'Please report a bug at https://github.com/flutter/flutter/issues/new');
    }
  }
  return devices;
}

/// A log reader that logs from `adb logcat`.
class _AdbLogReader extends DeviceLogReader {
  _AdbLogReader(this.device);

  final AndroidDevice device;

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
  Future<int> get finished => _process != null ? _process.exitCode : new Future<int>.value(0);

  @override
  Future<Null> start() async {
    if (_process != null)
      throw new StateError('_AdbLogReader must be stopped before it can be started.');

    // Start the adb logcat process.
    List<String> args = <String>['logcat', '-v', 'tag'];
    String lastTimestamp = device.lastLogcatTimestamp;
    if (lastTimestamp != null)
      args.addAll(<String>['-T', lastTimestamp]);
    args.addAll(<String>[
      '-s', 'flutter:V', 'SkyMain:V', 'AndroidRuntime:W', 'ActivityManager:W', 'System.err:W', '*:F'
    ]);
    _process = await runCommand(device.adbCommandForDevice(args));
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
    if (_process == null)
      throw new StateError('_AdbLogReader must be started before it can be stopped.');

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

  void _onLine(String line) {
    // Filter out some noisy ActivityManager notifications.
    if (line.startsWith('W/ActivityManager: getRunningAppProcesses'))
      return;

    _linesStreamController.add(line);
  }

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! _AdbLogReader)
      return false;
    return other.device.id == device.id;
  }
}

class _AndroidDevicePortForwarder extends DevicePortForwarder {
  _AndroidDevicePortForwarder(this.device);

  final AndroidDevice device;

  static int _extractPort(String portString) {
    return int.parse(portString.trim(), onError: (_) => null);
  }

  @override
  List<ForwardedPort> get forwardedPorts {
    final List<ForwardedPort> ports = <ForwardedPort>[];

    String stdout = runCheckedSync(device.adbCommandForDevice(
      <String>['forward', '--list']
    ));

    List<String> lines = LineSplitter.split(stdout).toList();
    for (String line in lines) {
      if (line.startsWith(device.id)) {
        List<String> splitLine = line.split("tcp:");

        // Sanity check splitLine.
        if (splitLine.length != 3)
          continue;

        // Attempt to extract ports.
        int hostPort = _extractPort(splitLine[1]);
        int devicePort = _extractPort(splitLine[2]);

        // Failed, skip.
        if ((hostPort == null) || (devicePort == null))
          continue;

        ports.add(new ForwardedPort(hostPort, devicePort));
      }
    }

    return ports;
  }

  @override
  Future<int> forward(int devicePort, { int hostPort }) async {
    if ((hostPort == null) || (hostPort == 0)) {
      // Auto select host port.
      hostPort = await findAvailablePort();
    }

    runCheckedSync(device.adbCommandForDevice(
      <String>['forward', 'tcp:$hostPort', 'tcp:$devicePort']
    ));

    return hostPort;
  }

  @override
  Future<Null> unforward(ForwardedPort forwardedPort) async {
    runCheckedSync(device.adbCommandForDevice(
      <String>['forward', '--remove', 'tcp:${forwardedPort.hostPort}']
    ));
  }
}
