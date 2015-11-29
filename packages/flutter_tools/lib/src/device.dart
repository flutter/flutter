// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import 'application_package.dart';
import 'base/logging.dart';
import 'base/process.dart';
import 'build_configuration.dart';

abstract class Device {
  final String id;
  static Map<String, Device> _deviceCache = {};

  static Device _unique(String id, Device constructor(String id)) {
    return _deviceCache.putIfAbsent(id, () => constructor(id));
  }

  Device._(this.id);

  /// Install an app package on the current device
  bool installApp(ApplicationPackage app);

  /// Check if the device is currently connected
  bool isConnected();

  /// Check if the current version of the given app is already installed
  bool isAppInstalled(ApplicationPackage app);

  TargetPlatform get platform;

  Future<int> logs({bool clear: false});

  /// Start an app package on the current device
  Future<bool> startApp(ApplicationPackage app);

  /// Stop an app package on the current device
  Future<bool> stopApp(ApplicationPackage app);

  String toString() => '$runtimeType $id';
}

class IOSDevice extends Device {
  static final String defaultDeviceID = 'default_ios_id';

  static const String _macInstructions =
      'To work with iOS devices, please install ideviceinstaller. '
      'If you use homebrew, you can install it with '
      '"\$ brew install ideviceinstaller".';
  static const String _linuxInstructions =
      'To work with iOS devices, please install ideviceinstaller. '
      'On Ubuntu or Debian, you can install it with '
      '"\$ apt-get install ideviceinstaller".';

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
    IOSDevice device = Device._unique(id ?? defaultDeviceID, (String id) => new IOSDevice._(id));
    device._name = name;
    return device;
  }

  IOSDevice._(String id) : super._(id) {
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
        '\$ brew install ios-deploy',
        'Copying files to iOS devices is not currently supported on Linux.');
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
  static String _checkForCommand(String command,
      [String macInstructions = _macInstructions,
      String linuxInstructions = _linuxInstructions]) {
    return _commandMap.putIfAbsent(command, () {
      try {
        command = runCheckedSync(['which', command]).trim();
      } catch (e) {
        if (Platform.isMacOS) {
          logging.severe(macInstructions);
        } else if (Platform.isLinux) {
          logging.severe(linuxInstructions);
        } else {
          logging.severe('$command is not available on your platform.');
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
      String apps = runCheckedSync([installerPath, '-l']);
      if (new RegExp(app.id, multiLine: true).hasMatch(apps)) {
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  @override
  Future<bool> startApp(ApplicationPackage app) async {
    if (!isAppInstalled(app)) {
      return false;
    }
    // idevicedebug hangs forever after launching the app, so kill it after
    // giving it plenty of time to send the launch command.
    return await runAndKill(
      [debuggerPath, 'run', app.id],
      new Duration(seconds: 3)
    ).then(
      (_) {
        return true;
      }, onError: (e) {
        logging.info('Failure running $debuggerPath: ', e);
        return false;
      }
    );
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
      // TODO(iansf): It may be possible to make this work on Linux. Since this
      //              functionality appears to be the only that prevents us from
      //              supporting iOS on Linux, it may be worth putting some time
      //              into investigating this.
      //              See https://bbs.archlinux.org/viewtopic.php?id=192655
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
    IOSSimulator device = Device._unique(id ?? defaultDeviceID, (String id) => new IOSSimulator._(id));
    device._name = name;
    if (iOSSimulatorPath == null) {
      iOSSimulatorPath = path.join('/Applications', 'iOS Simulator.app',
          'Contents', 'MacOS', 'iOS Simulator');
    }
    device._iOSSimPath = iOSSimulatorPath;
    return device;
  }

  IOSSimulator._(String id) : super._(id);

  static String _getRunningSimulatorID([IOSSimulator mockIOS]) {
    String xcrunPath = mockIOS != null ? mockIOS.xcrunPath : _xcrunPath;
    String output = runCheckedSync([xcrunPath, 'simctl', 'list', 'devices']);

    Match match;
    Iterable<Match> matches = new RegExp(r'[^\(]+\(([^\)]+)\) \(Booted\)',
        multiLine: true).allMatches(output);
    if (matches.length > 1) {
      // More than one simulator is listed as booted, which is not allowed but
      // sometimes happens erroneously.  Kill them all because we don't know
      // which one is actually running.
      logging.warning('Multiple running simulators were detected, '
          'which is not supposed to happen.');
      for (Match m in matches) {
        if (m.groupCount > 0) {
          logging.warning('Killing simulator ${m.group(1)}');
          runSync([xcrunPath, 'simctl', 'shutdown', m.group(1)]);
        }
      }
    } else if (matches.length == 1) {
      match = matches.first;
    }

    if (match != null && match.groupCount > 0) {
      return match.group(1);
    } else {
      logging.info('No running simulators found');
      return null;
    }
  }

  String _getSimulatorPath() {
    String deviceID = id == defaultDeviceID ? _getRunningSimulatorID() : id;
    String homeDirectory = path.absolute(Platform.environment['HOME']);
    if (deviceID == null) {
      return null;
    }
    return path.join(homeDirectory, 'Library', 'Developer', 'CoreSimulator',
        'Devices', deviceID);
  }

  String _getSimulatorAppHomeDirectory(ApplicationPackage app) {
    String simulatorPath = _getSimulatorPath();
    if (simulatorPath == null) {
      return null;
    }
    return path.join(simulatorPath, 'data');
  }

  static List<IOSSimulator> getAttachedDevices([IOSSimulator mockIOS]) {
    List<IOSSimulator> devices = [];
    String id = _getRunningSimulatorID(mockIOS);
    if (id != null) {
      // TODO(iansf): get the simulator's name
      // String name = _getDeviceName(id, mockIOS);
      devices.add(new IOSSimulator(id: id));
    }
    return devices;
  }

  Future<bool> boot() async {
    if (!Platform.isMacOS) {
      return false;
    }
    if (isConnected()) {
      return true;
    }
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
    if (!isConnected()) {
      return false;
    }
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
    if (!Platform.isMacOS) {
      return false;
    }
    String simulatorID = _getRunningSimulatorID();
    if (simulatorID == null) {
      return false;
    } else if (id == defaultDeviceID) {
      return true;
    } else {
      return _getRunningSimulatorID() == id;
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
  Future<bool> startApp(ApplicationPackage app) async {
    if (!isAppInstalled(app)) {
      return false;
    }
    try {
      if (id == defaultDeviceID) {
        runCheckedSync(
            [xcrunPath, 'simctl', 'launch', 'booted', app.id]);
      } else {
        runCheckedSync([xcrunPath, 'simctl', 'launch', id, app.id]);
      }
      return true;
    } catch (e) {
      return false;
    }
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
      runCheckedSync(
          ['cp', localFile, path.join(simulatorHomeDirectory, targetFile)]);
      return true;
    }
    return false;
  }

  @override
  TargetPlatform get platform => TargetPlatform.iOSSimulator;

  Future<int> logs({bool clear: false}) async {
    if (!isConnected()) {
      return 2;
    }
    String homeDirectory = path.absolute(Platform.environment['HOME']);
    String simulatorDeviceID = _getRunningSimulatorID();
    String logFilePath = path.join(homeDirectory, 'Library', 'Logs',
        'CoreSimulator', simulatorDeviceID, 'system.log');
    if (clear) {
      runSync(['rm', logFilePath]);
    }
    return await runCommandAndStreamOutput(['tail', '-f', logFilePath],
        prefix: 'iOS sim: ', filter: new RegExp(r'.*SkyShell.*'));
  }
}

class AndroidDevice extends Device {
  static const String _ADB_PATH = 'adb';
  static const int _observatoryPort = 8181;

  static final String defaultDeviceID = 'default_android_device';

  String productID;
  String modelID;
  String deviceCodeName;

  String _adbPath;
  String get adbPath => _adbPath;
  bool _hasAdb = false;
  bool _hasValidAndroid = false;

  factory AndroidDevice(
      {String id: null,
      String productID: null,
      String modelID: null,
      String deviceCodeName: null}) {
    AndroidDevice device = Device._unique(id ?? defaultDeviceID, (String id) => new AndroidDevice._(id));
    device.productID = productID;
    device.modelID = modelID;
    device.deviceCodeName = deviceCodeName;
    return device;
  }

  /// mockAndroid argument is only to facilitate testing with mocks, so that
  /// we don't have to rely on the test setup having adb available to it.
  static List<AndroidDevice> getAttachedDevices([AndroidDevice mockAndroid]) {
    List<AndroidDevice> devices = [];
    String adbPath = (mockAndroid != null) ? mockAndroid.adbPath : _getAdbPath();

    try {
      runCheckedSync([adbPath, 'version']);
    } catch (e) {
      logging.severe('Unable to find adb. Is "adb" in your path?');
      return devices;
    }

    List<String> output = runSync([adbPath, 'devices', '-l']).trim().split('\n');

    // 015d172c98400a03       device usb:340787200X product:nakasi model:Nexus_7 device:grouper
    RegExp deviceRegex1 = new RegExp(
        r'^(\S+)\s+device\s+.*product:(\S+)\s+model:(\S+)\s+device:(\S+)$');

    // 0149947A0D01500C       device usb:340787200X
    RegExp deviceRegex2 = new RegExp(r'^(\S+)\s+device\s+\S+$');

    RegExp unauthorizedRegex = new RegExp(r'^(\S+)\s+unauthorized\s+\S+$');

    // Skip first line, which is always 'List of devices attached'.
    for (String line in output.skip(1)) {
      // Skip lines like:
      // * daemon not running. starting it now on port 5037 *
      // * daemon started successfully *
      if (line.startsWith('* daemon '))
        continue;

      if (deviceRegex1.hasMatch(line)) {
        Match match = deviceRegex1.firstMatch(line);
        String deviceID = match[1];
        String productID = match[2];
        String modelID = match[3];
        String deviceCodeName = match[4];

        devices.add(new AndroidDevice(
            id: deviceID,
            productID: productID,
            modelID: modelID,
            deviceCodeName: deviceCodeName
        ));
      } else if (deviceRegex2.hasMatch(line)) {
        Match match = deviceRegex2.firstMatch(line);
        String deviceID = match[1];
        devices.add(new AndroidDevice(id: deviceID));
      } else if (unauthorizedRegex.hasMatch(line)) {
        Match match = unauthorizedRegex.firstMatch(line);
        String deviceID = match[1];
        logging.warning(
          'Device $deviceID is not authorized.\n'
          'You might need to check your device for an authorization dialog.'
        );
      } else {
        logging.warning(
          'Unexpected failure parsing device information from adb output:\n'
          '$line\n'
          'Please report a bug at https://github.com/flutter/flutter/issues/new');
      }
    }
    return devices;
  }

  AndroidDevice._(id) : super._(id) {
    _adbPath = _getAdbPath();
    _hasAdb = _checkForAdb();

    // Checking for Jelly Bean only needs to be done if we are starting an
    // app, but it has an important side effect, which is to discard any
    // progress messages if the adb server is restarted.
    _hasValidAndroid = _checkForSupportedAndroidVersion();

    if (!_hasAdb || !_hasValidAndroid) {
      logging.warning('Unable to run on Android.');
    }
  }

  static String getAndroidSdkPath() {
    if (Platform.environment.containsKey('ANDROID_HOME')) {
      String androidHomeDir = Platform.environment['ANDROID_HOME'];
      if (FileSystemEntity.isDirectorySync(
          path.join(androidHomeDir, 'platform-tools'))) {
        return androidHomeDir;
      } else if (FileSystemEntity.isDirectorySync(
          path.join(androidHomeDir, 'sdk', 'platform-tools'))) {
        return path.join(androidHomeDir, 'sdk');
      } else {
        logging.warning('Android SDK not found at $androidHomeDir');
        return null;
      }
    } else {
      logging.warning('Android SDK not found. The ANDROID_HOME variable must be set.');
      return null;
    }
  }

  static String _getAdbPath() {
    if (Platform.environment.containsKey('ANDROID_HOME')) {
      String androidHomeDir = Platform.environment['ANDROID_HOME'];
      String adbPath1 =
          path.join(androidHomeDir, 'sdk', 'platform-tools', 'adb');
      String adbPath2 = path.join(androidHomeDir, 'platform-tools', 'adb');
      if (FileSystemEntity.isFileSync(adbPath1)) {
        return adbPath1;
      } else if (FileSystemEntity.isFileSync(adbPath2)) {
        return adbPath2;
      } else {
        logging.info('"adb" not found at\n  "$adbPath1" or\n  "$adbPath2"\n' +
            'using default path "$_ADB_PATH"');
        return _ADB_PATH;
      }
    } else {
      return _ADB_PATH;
    }
  }

  List<String> adbCommandForDevice(List<String> args) {
    List<String> result = <String>[adbPath];
    if (id != defaultDeviceID) {
      result.addAll(['-s', id]);
    }
    result.addAll(args);
    return result;
  }

  bool _isValidAdbVersion(String adbVersion) {
    // Sample output: 'Android Debug Bridge version 1.0.31'
    Match versionFields =
        new RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(adbVersion);
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
    logging.warning(
        'Unrecognized adb version string $adbVersion. Skipping version check.');
    return true;
  }

  bool _checkForAdb() {
    try {
      String adbVersion = runCheckedSync([adbPath, 'version']);
      if (_isValidAdbVersion(adbVersion)) {
        return true;
      }

      String locatedAdbPath = runCheckedSync(['which', 'adb']);
      logging.severe('"$locatedAdbPath" is too old. '
          'Please install version 1.0.32 or later.\n'
          'Try setting ANDROID_HOME to the path to your Android SDK install. '
          'Android builds are unavailable.');
    } catch (e, stack) {
      logging.severe('"adb" not found in \$PATH. '
          'Please install the Android SDK or set ANDROID_HOME '
          'to the path of your Android SDK install.');
      logging.info(e);
      logging.info(stack);
    }
    return false;
  }

  bool _checkForSupportedAndroidVersion() {
    try {
      // If the server is automatically restarted, then we get irrelevant
      // output lines like this, which we want to ignore:
      //   adb server is out of date.  killing..
      //   * daemon started successfully *
      runCheckedSync(adbCommandForDevice(['start-server']));

      String ready = runSync(adbCommandForDevice(['shell', 'echo', 'ready']));
      if (ready.trim() != 'ready') {
        logging.info('Android device not found.');
        return false;
      }

      // Sample output: '22'
      String sdkVersion =
          runCheckedSync(adbCommandForDevice(['shell', 'getprop', 'ro.build.version.sdk']))
              .trimRight();

      int sdkVersionParsed =
          int.parse(sdkVersion, onError: (String source) => null);
      if (sdkVersionParsed == null) {
        logging.severe('Unexpected response from getprop: "$sdkVersion"');
        return false;
      }
      if (sdkVersionParsed < 16) {
        logging.severe('The Android version ($sdkVersion) on the target device '
            'is too old. Please use a Jelly Bean (version 16 / 4.1.x) device or later.');
        return false;
      }
      return true;
    } catch (e) {
      logging.severe('Unexpected failure from adb: ', e);
    }
    return false;
  }

  String _getDeviceSha1Path(ApplicationPackage app) {
    return '/data/local/tmp/sky.${app.id}.sha1';
  }

  String _getDeviceApkSha1(ApplicationPackage app) {
    return runCheckedSync(adbCommandForDevice(['shell', 'cat', _getDeviceSha1Path(app)]));
  }

  String _getSourceSha1(ApplicationPackage app) {
    var sha1 = new SHA1();
    var file = new File(app.localPath);
    sha1.add(file.readAsBytesSync());
    return CryptoUtils.bytesToHex(sha1.close());
  }

  @override
  bool isAppInstalled(ApplicationPackage app) {
    if (!isConnected()) {
      return false;
    }
    if (runCheckedSync(adbCommandForDevice(['shell', 'pm', 'path', app.id])) ==
        '') {
      logging.info(
          'TODO(iansf): move this log to the caller. ${app.name} is not on the device. Installing now...');
      return false;
    }
    if (_getDeviceApkSha1(app) != _getSourceSha1(app)) {
      logging.info(
          'TODO(iansf): move this log to the caller. ${app.name} is out of date. Installing now...');
      return false;
    }
    return true;
  }

  @override
  bool installApp(ApplicationPackage app) {
    if (!isConnected()) {
      logging.info('Android device not connected. Not installing.');
      return false;
    }
    if (!FileSystemEntity.isFileSync(app.localPath)) {
      logging.severe('"${app.localPath}" does not exist.');
      return false;
    }

    print('Installing ${app.name} on device.');
    runCheckedSync(adbCommandForDevice(['install', '-r', app.localPath]));
    runCheckedSync(adbCommandForDevice(['shell', 'echo', '-n', _getSourceSha1(app), '>', _getDeviceSha1Path(app)]));
    return true;
  }

  void _forwardObservatoryPort() {
    // Set up port forwarding for observatory.
    String portString = 'tcp:$_observatoryPort';
    runCheckedSync(adbCommandForDevice(['forward', portString, portString]));
  }

  bool startBundle(AndroidApk apk, String bundlePath, {
    bool poke,
    bool checked,
    String route
  }) {
    logging.fine('$this startBundle');

    if (!FileSystemEntity.isFileSync(bundlePath)) {
      logging.severe('Cannot find $bundlePath');
      return false;
    }

    if (!poke)
      _forwardObservatoryPort();

    String deviceTmpPath = '/data/local/tmp/dev.flx';
    runCheckedSync(adbCommandForDevice(['push', bundlePath, deviceTmpPath]));
    List<String> cmd = adbCommandForDevice([
      'shell', 'am', 'start',
      '-a', 'android.intent.action.RUN',
      '-d', deviceTmpPath,
    ]);
    if (checked)
      cmd.addAll(['--ez', 'enable-checked-mode', 'true']);
    if (route != null)
      cmd.addAll(['--es', 'route', route]);
    cmd.add(apk.launchActivity);
    runCheckedSync(cmd);
    return true;
  }

  @override
  Future<bool> startApp(ApplicationPackage app) async {
    // Android currently has to be started with startBundle(...).
    assert(false);
    return false;
  }

  Future<bool> stopApp(ApplicationPackage app) async {
    final AndroidApk apk = app;
    runSync(adbCommandForDevice(['shell', 'am', 'force-stop', apk.id]));
    return true;
  }

  @override
  TargetPlatform get platform => TargetPlatform.android;

  void clearLogs() {
    runSync(adbCommandForDevice(['logcat', '-c']));
  }

  Future<int> logs({bool clear: false}) async {
    if (!isConnected()) {
      return 2;
    }

    if (clear) {
      clearLogs();
    }

    return await runCommandAndStreamOutput(adbCommandForDevice([
      'logcat',
      '-v',
      'tag', // Only log the tag and the message
      '-s',
      'flutter:V',
      'chromium:D',
      'ActivityManager:W',
      '*:F',
    ]), prefix: 'android: ');
  }

  void startTracing(AndroidApk apk) {
    runCheckedSync(adbCommandForDevice([
      'shell',
      'am',
      'broadcast',
      '-a',
      '${apk.id}.TRACING_START'
    ]));
  }

  String stopTracing(AndroidApk apk) {
    clearLogs();
    runCheckedSync(adbCommandForDevice([
      'shell',
      'am',
      'broadcast',
      '-a',
      '${apk.id}.TRACING_STOP'
    ]));

    RegExp traceRegExp = new RegExp(r'Saving trace to (\S+)', multiLine: true);
    RegExp completeRegExp = new RegExp(r'Trace complete', multiLine: true);

    String tracePath = null;
    bool isComplete = false;
    while (!isComplete) {
      String logs = runSync(adbCommandForDevice(['logcat', '-d']));
      Match fileMatch = traceRegExp.firstMatch(logs);
      if (fileMatch[1] != null) {
        tracePath = fileMatch[1];
      }
      isComplete = completeRegExp.hasMatch(logs);
    }

    if (tracePath != null) {
      runSync(adbCommandForDevice(['shell', 'run-as', apk.id, 'chmod', '777', tracePath]));
      runSync(adbCommandForDevice(['pull', tracePath]));
      runSync(adbCommandForDevice(['shell', 'rm', tracePath]));
      return path.basename(tracePath);
    }
    logging.warning('No trace file detected. '
        'Did you remember to start the trace before stopping it?');
    return null;
  }

  @override
  bool isConnected() => _hasValidAndroid;
}

class DeviceStore {
  final AndroidDevice android;
  final IOSDevice iOS;
  final IOSSimulator iOSSimulator;

  List<Device> get all {
    List<Device> result = <Device>[];
    if (android != null)
      result.add(android);
    if (iOS != null)
      result.add(iOS);
    if (iOSSimulator != null)
      result.add(iOSSimulator);
    return result;
  }

  DeviceStore({
    this.android,
    this.iOS,
    this.iOSSimulator
  });

  factory DeviceStore.forConfigs(List<BuildConfiguration> configs) {
    AndroidDevice android;
    IOSDevice iOS;
    IOSSimulator iOSSimulator;

    for (BuildConfiguration config in configs) {
      switch (config.targetPlatform) {
        case TargetPlatform.android:
          assert(android == null);
          List<AndroidDevice> androidDevices = AndroidDevice.getAttachedDevices();
          if (config.deviceId != null) {
            android = androidDevices.firstWhere(
                (AndroidDevice dev) => (dev.id == config.deviceId),
                orElse: () => null);
            if (android == null) {
              print('Warning: Device ID ${config.deviceId} not found');
            }
          } else if (androidDevices.length == 1) {
            android = androidDevices[0];
          } else if (androidDevices.length > 1) {
            print('Warning: Multiple Android devices are connected, but no device ID was specified.');
          }
          break;
        case TargetPlatform.iOS:
          assert(iOS == null);
          iOS = new IOSDevice();
          break;
        case TargetPlatform.iOSSimulator:
          assert(iOSSimulator == null);
          iOSSimulator = new IOSSimulator();
          break;
        case TargetPlatform.mac:
        case TargetPlatform.linux:
          break;
      }
    }

    return new DeviceStore(android: android, iOS: iOS, iOSSimulator: iOSSimulator);
  }
}
