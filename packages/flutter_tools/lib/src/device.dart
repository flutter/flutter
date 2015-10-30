// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.device;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';

import 'application_package.dart';
import 'build_configuration.dart';
import 'process.dart';

final Logger _logging = new Logger('sky_tools.device');

abstract class Device {
  final String id;
  static Map<String, Device> _deviceCache = {};

  factory Device._unique(String className, [String id = null]) {
    if (id == null) {
      if (className == AndroidDevice.className) {
        id = AndroidDevice.defaultDeviceID;
      } else if (className == IOSDevice.className) {
        id = IOSDevice.defaultDeviceID;
      } else if (className == IOSSimulator.className) {
        id = IOSSimulator.defaultDeviceID;
      } else {
        throw 'Attempted to create a Device of unknown type $className';
      }
    }

    return _deviceCache.putIfAbsent(id, () {
      if (className == AndroidDevice.className) {
        final device = new AndroidDevice._(id);
        _deviceCache[id] = device;
        return device;
      } else if (className == IOSDevice.className) {
        final device = new IOSDevice._(id);
        _deviceCache[id] = device;
        return device;
      } else if (className == IOSSimulator.className) {
        final device = new IOSSimulator._(id);
        _deviceCache[id] = device;
        return device;
      } else {
        throw 'Attempted to create a Device of unknown type $className';
      }
    });
  }

  Device._(this.id);

  /// Install an app package on the current device
  bool installApp(ApplicationPackage app);

  /// Check if the device is currently connected
  bool isConnected();

  /// Check if the current version of the given app is already installed
  bool isAppInstalled(ApplicationPackage app);

  BuildPlatform get platform;

  Future<int> logs({bool clear: false});

  /// Start an app package on the current device
  Future<bool> startApp(ApplicationPackage app);

  /// Stop an app package on the current device
  Future<bool> stopApp(ApplicationPackage app);
}

class IOSDevice extends Device {
  static const String className = 'IOSDevice';
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
    IOSDevice device = new Device._unique(className, id);
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
          _logging.severe(macInstructions);
        } else if (Platform.isLinux) {
          _logging.severe(linuxInstructions);
        } else {
          _logging.severe('$command is not available on your platform.');
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
    return runAndKill(
        [debuggerPath, 'run', app.id], new Duration(seconds: 3)).then(
        (_) {
      return true;
    }, onError: (e) {
      _logging.info('Failure running $debuggerPath: ', e);
      return false;
    });
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
  BuildPlatform get platform => BuildPlatform.iOS;

  /// Note that clear is not supported on iOS at this time.
  Future<int> logs({bool clear: false}) async {
    if (!isConnected()) {
      return 2;
    }
    return runCommandAndStreamOutput([loggerPath],
        prefix: 'iOS dev: ', filter: new RegExp(r'.*SkyShell.*'));
  }
}

class IOSSimulator extends Device {
  static const String className = 'IOSSimulator';
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
    IOSSimulator device = new Device._unique(className, id);
    device._name = name;
    if (iOSSimulatorPath == null) {
      iOSSimulatorPath = path.join('/Applications', 'iOS Simulator.app',
          'Contents', 'MacOS', 'iOS Simulator');
    }
    device._iOSSimPath = iOSSimulatorPath;
    return device;
  }

  IOSSimulator._(String id) : super._(id) {}

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
      _logging.warning('Multiple running simulators were detected, '
          'which is not supposed to happen.');
      for (Match m in matches) {
        if (m.groupCount > 0) {
          _logging.warning('Killing simulator ${m.group(1)}');
          runSync([xcrunPath, 'simctl', 'shutdown', m.group(1)]);
        }
      }
    } else if (matches.length == 1) {
      match = matches.first;
    }

    if (match != null && match.groupCount > 0) {
      return match.group(1);
    } else {
      _logging.info('No running simulators found');
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
          _logging.info('Timed out waiting for iOS Simulator $id to boot.');
          return false;
        }
        if (!isConnected()) {
          _logging.info('Waiting for iOS Simulator $id to boot...');
          return new Future.delayed(new Duration(milliseconds: 500),
              () => checkConnection(attempts - 1));
        }
        return true;
      }
      return checkConnection();
    } else {
      try {
        runCheckedSync([xcrunPath, 'simctl', 'boot', id]);
      } catch (e) {
        _logging.warning('Unable to boot iOS Simulator $id: ', e);
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
  BuildPlatform get platform => BuildPlatform.iOSSimulator;

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
    return runCommandAndStreamOutput(['tail', '-f', logFilePath],
        prefix: 'iOS sim: ', filter: new RegExp(r'.*SkyShell.*'));
  }
}

class AndroidDevice extends Device {
  static const String _ADB_PATH = 'adb';
  static const String _observatoryPort = '8181';
  static const String _serverPort = '9888';

  static const String className = 'AndroidDevice';
  static final String defaultDeviceID = 'default_android_device';

  static const String _kFlutterServerStartMessage = 'Serving';
  static const Duration _kFlutterServerTimeout = const Duration(seconds: 3);

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
    AndroidDevice device = new Device._unique(className, id);
    device.productID = productID;
    device.modelID = modelID;
    device.deviceCodeName = deviceCodeName;
    return device;
  }

  /// mockAndroid argument is only to facilitate testing with mocks, so that
  /// we don't have to rely on the test setup having adb available to it.
  static List<AndroidDevice> getAttachedDevices([AndroidDevice mockAndroid]) {
    List<AndroidDevice> devices = [];
    String adbPath =
        (mockAndroid != null) ? mockAndroid.adbPath : _getAdbPath();
    List<String> output =
        runSync([adbPath, 'devices', '-l']).trim().split('\n');
    RegExp deviceInfo = new RegExp(
        r'^(\S+)\s+device\s+\S+\s+product:(\S+)\s+model:(\S+)\s+device:(\S+)$');
    // Skip first line, which is always 'List of devices attached'.
    for (String line in output.skip(1)) {
      Match match = deviceInfo.firstMatch(line);
      if (match != null) {
        String deviceID = match[1];
        String productID = match[2];
        String modelID = match[3];
        String deviceCodeName = match[4];

        devices.add(new AndroidDevice(
            id: deviceID,
            productID: productID,
            modelID: modelID,
            deviceCodeName: deviceCodeName));
      } else {
        _logging.warning('Unexpected failure parsing device information '
            'from adb output:\n$line\n'
            'Please report a bug at http://flutter.io/');
      }
    }
    return devices;
  }

  AndroidDevice._(id) : super._(id) {
    _adbPath = _getAdbPath();
    _hasAdb = _checkForAdb();

    // Checking for lollipop only needs to be done if we are starting an
    // app, but it has an important side effect, which is to discard any
    // progress messages if the adb server is restarted.
    _hasValidAndroid = _checkForLollipopOrLater();

    if (!_hasAdb || !_hasValidAndroid) {
      _logging.warning('Unable to run on Android.');
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
        _logging.info('"adb" not found at\n  "$adbPath1" or\n  "$adbPath2"\n' +
            'using default path "$_ADB_PATH"');
        return _ADB_PATH;
      }
    } else {
      return _ADB_PATH;
    }
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
    _logging.warning(
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
      _logging.severe('"$locatedAdbPath" is too old. '
          'Please install version 1.0.32 or later.\n'
          'Try setting ANDROID_HOME to the path to your Android SDK install. '
          'Android builds are unavailable.');
    } catch (e, stack) {
      _logging.severe('"adb" not found in \$PATH. '
          'Please install the Android SDK or set ANDROID_HOME '
          'to the path of your Android SDK install.');
      _logging.info(e);
      _logging.info(stack);
    }
    return false;
  }

  bool _checkForLollipopOrLater() {
    try {
      // If the server is automatically restarted, then we get irrelevant
      // output lines like this, which we want to ignore:
      //   adb server is out of date.  killing..
      //   * daemon started successfully *
      runCheckedSync([adbPath, 'start-server']);

      String ready = runSync([adbPath, 'shell', 'echo', 'ready']);
      if (ready.trim() != 'ready') {
        _logging.info('Android device not found.');
        return false;
      }

      // Sample output: '22'
      String sdkVersion =
          runCheckedSync([adbPath, 'shell', 'getprop', 'ro.build.version.sdk'])
              .trimRight();

      int sdkVersionParsed =
          int.parse(sdkVersion, onError: (String source) => null);
      if (sdkVersionParsed == null) {
        _logging.severe('Unexpected response from getprop: "$sdkVersion"');
        return false;
      }
      if (sdkVersionParsed < 22) {
        _logging.severe('Version "$sdkVersion" of the Android SDK is too old. '
            'Please install Lollipop (version 22) or later.');
        return false;
      }
      return true;
    } catch (e) {
      _logging.severe('Unexpected failure from adb: ', e);
    }
    return false;
  }

  String _getDeviceDataPath(ApplicationPackage app) {
    return '/data/data/${app.id}';
  }

  String _getDeviceSha1Path(ApplicationPackage app) {
    return '${_getDeviceDataPath(app)}/${app.name}.sha1';
  }

  String _getDeviceApkSha1(ApplicationPackage app) {
    return runCheckedSync([adbPath, 'shell', 'cat', _getDeviceSha1Path(app)]);
  }

  String _getSourceSha1(ApplicationPackage app) {
    var sha1 = new SHA1();
    var file = new File(app.localPath);
    sha1.add(file.readAsBytesSync());
    return CryptoUtils.bytesToHex(sha1.close());
  }

  /**
   * Since Window's paths have backslashes, we need to convert those to forward slashes to make a valid URL
   */
  String _convertToURL(String path) {
    return path.replaceAll('\\', '/');
  }

  @override
  bool isAppInstalled(ApplicationPackage app) {
    if (!isConnected()) {
      return false;
    }
    if (runCheckedSync([adbPath, 'shell', 'pm', 'path', app.id]) ==
        '') {
      _logging.info(
          'TODO(iansf): move this log to the caller. ${app.name} is not on the device. Installing now...');
      return false;
    }
    if (_getDeviceApkSha1(app) != _getSourceSha1(app)) {
      _logging.info(
          'TODO(iansf): move this log to the caller. ${app.name} is out of date. Installing now...');
      return false;
    }
    return true;
  }

  @override
  bool installApp(ApplicationPackage app) {
    if (!isConnected()) {
      _logging.info('Android device not connected. Not installing.');
      return false;
    }
    if (!FileSystemEntity.isFileSync(app.localPath)) {
      _logging.severe('"${app.localPath}" does not exist.');
      return false;
    }

    print('Installing ${app.name} on device.');
    runCheckedSync([adbPath, 'install', '-r', app.localPath]);
    runCheckedSync([adbPath, 'shell', 'run-as', app.id, 'chmod', '777', _getDeviceDataPath(app)]);
    runCheckedSync([adbPath, 'shell', 'echo', '-n', _getSourceSha1(app), '>', _getDeviceSha1Path(app)]);
    return true;
  }

  Future<bool> startServer(
      String target, bool poke, bool checked, AndroidApk apk) async {
    String serverRoot = '';
    String mainDart = '';
    String missingMessage = '';
    if (await FileSystemEntity.isDirectory(target)) {
      serverRoot = target;
      mainDart = path.join(serverRoot, 'lib', 'main.dart');
      missingMessage = 'Missing lib/main.dart in project: $serverRoot';
    } else {
      serverRoot = Directory.current.path;
      mainDart = target;
      missingMessage = '$mainDart does not exist.';
    }

    if (!await FileSystemEntity.isFile(mainDart)) {
      _logging.severe(missingMessage);
      return false;
    }

    if (!poke) {
      // Set up port forwarding for observatory.
      String observatoryPortString = 'tcp:$_observatoryPort';
      runCheckedSync(
          [adbPath, 'forward', observatoryPortString, observatoryPortString]);

      // Actually start the server.
      Process server = await Process.start(
          sdkBinaryName('pub'), ['run', 'sky_tools:sky_server', _serverPort],
          workingDirectory: serverRoot,
          mode: ProcessStartMode.DETACHED_WITH_STDIO
      );
      await server.stdout.transform(UTF8.decoder)
          .firstWhere((String value) => value.startsWith(_kFlutterServerStartMessage))
          .timeout(_kFlutterServerTimeout);

      // Set up reverse port-forwarding so that the Android app can reach the
      // server running on localhost.
      String serverPortString = 'tcp:$_serverPort';
      runCheckedSync([adbPath, 'reverse', serverPortString, serverPortString]);
    }

    String relativeDartMain = _convertToURL(path.relative(mainDart, from: serverRoot));
    String url = 'http://localhost:$_serverPort/$relativeDartMain';
    if (poke) {
      url += '?rand=${new Random().nextDouble()}';
    }

    // Actually launch the app on Android.
    List<String> cmd = [
      adbPath,
      'shell',
      'am',
      'start',
      '-a',
      'android.intent.action.VIEW',
      '-d',
      url,
    ];
    if (checked) {
      cmd.addAll(['--ez', 'enable-checked-mode', 'true']);
    }
    cmd.add(apk.launchActivity);

    runCheckedSync(cmd);

    return true;
  }

  @override
  Future<bool> startApp(ApplicationPackage app) async {
    // Android currently has to be started with startServer(...).
    assert(false);
    return false;
  }

  Future<bool> stopApp(ApplicationPackage app) async {
    final AndroidApk apk = app;

    // Turn off reverse port forwarding
    runSync([adbPath, 'reverse', '--remove', 'tcp:$_serverPort']);
    // Stop the app
    runSync([adbPath, 'shell', 'am', 'force-stop', apk.id]);
    // Kill the server
    if (Platform.isMacOS) {
      String pids = runSync(['lsof', '-i', ':$_serverPort', '-t']).trim();
      if (pids.isEmpty) {
        _logging.fine('No process to kill for port $_serverPort');
        return true;
      }

      // Handle multiple returned pids.
      for (String pidString in pids.split('\n')) {
        // Killing a pid with a shell command from within dart is hard, so use a
        // library command, but it's still nice to give the equivalent command
        // when doing verbose logging.
        _logging.info('kill $pidString');

        int pid = int.parse(pidString, onError: (_) => null);
        if (pid != null)
          Process.killPid(pid);
      }
    } else if (Platform.isWindows) {
      //Get list of network processes and split on newline
      List<String> processes = runSync(['netstat.exe','-ano']).split("\r");

      //List entries from netstat is formatted like so
      // TCP    192.168.2.11:50945     192.30.252.90:443      LISTENING     1304
      //This regexp is to find process where the the port exactly matches
      RegExp pattern = new RegExp(':$_serverPort[ ]+');

      //Split the columns by 1 or more spaces
      RegExp columnPattern = new RegExp('[ ]+');
      processes.forEach((String process) {
        if (process.contains(pattern)) {
          //The last column is the Process ID
          String processId = process.split(columnPattern).last;
          //Force and Tree kill the process
          _logging.info('kill $processId');
          runSync(['TaskKill.exe', '/F', '/T', '/PID', processId]);
        }
      });
    } else {
      runSync(['fuser', '-k', '$_serverPort/tcp']);
    }

    return true;
  }

  @override
  BuildPlatform get platform => BuildPlatform.android;

  void clearLogs() {
    runSync([adbPath, 'logcat', '-c']);
  }

  Future<int> logs({bool clear: false}) async {
    if (!isConnected()) {
      return 2;
    }

    if (clear) {
      clearLogs();
    }

    return runCommandAndStreamOutput([
      adbPath,
      'logcat',
      '-v',
      'tag', // Only log the tag and the message
      '-s',
      'sky',
      'chromium',
    ], prefix: 'android: ');
  }

  void startTracing(AndroidApk apk) {
    runCheckedSync([
      adbPath,
      'shell',
      'am',
      'broadcast',
      '-a',
      '${apk.id}.TRACING_START'
    ]);
  }

  String stopTracing(AndroidApk apk) {
    clearLogs();
    runCheckedSync([
      adbPath,
      'shell',
      'am',
      'broadcast',
      '-a',
      '${apk.id}.TRACING_STOP'
    ]);

    RegExp traceRegExp = new RegExp(r'Saving trace to (\S+)', multiLine: true);
    RegExp completeRegExp = new RegExp(r'Trace complete', multiLine: true);

    String tracePath = null;
    bool isComplete = false;
    while (!isComplete) {
      String logs = runSync([adbPath, 'logcat', '-d']);
      Match fileMatch = traceRegExp.firstMatch(logs);
      if (fileMatch[1] != null) {
        tracePath = fileMatch[1];
      }
      isComplete = completeRegExp.hasMatch(logs);
    }

    if (tracePath != null) {
      runSync([adbPath, 'shell', 'run-as', apk.id, 'chmod', '777', tracePath]);
      runSync([adbPath, 'pull', tracePath]);
      runSync([adbPath, 'shell', 'rm', tracePath]);
      return path.basename(tracePath);
    }
    _logging.warning('No trace file detected. '
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
      switch (config.platform) {
        case BuildPlatform.android:
          assert(android == null);
          android = new AndroidDevice();
          break;
        case BuildPlatform.iOS:
          assert(iOS == null);
          iOS = new IOSDevice();
          break;
        case BuildPlatform.iOSSimulator:
          assert(iOSSimulator == null);
          iOSSimulator = new IOSSimulator();
          break;

        case BuildPlatform.mac:
        case BuildPlatform.linux:
          // TODO(abarth): Support mac and linux targets.
          assert(false);
          break;
      }
    }

    return new DeviceStore(android: android, iOS: iOS, iOSSimulator: iOSSimulator);
  }
}
