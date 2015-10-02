// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.device;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'application_package.dart';
import 'process.dart';

final Logger _logging = new Logger('sky_tools.device');

abstract class _Device {
  final String id;
  static Map<String, _Device> _deviceCache = {};

  factory _Device(String className, [String id = null]) {
    if (id == null) {
      if (className == AndroidDevice.className) {
        id = AndroidDevice.defaultDeviceID;
      } else if (className == IOSDevice.className) {
        id = IOSDevice.defaultDeviceID;
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
      } else {
        throw 'Attempted to create a Device of unknown type $className';
      }
    });
  }

  _Device._(this.id);

  /// Install an app package on the current device
  bool installApp(ApplicationPackage app);

  /// Check if the device is currently connected
  bool isConnected();

  /// Check if the current version of the given app is already installed
  bool isAppInstalled(ApplicationPackage app);
}

class IOSDevice extends _Device {
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

  String _name;
  String get name => _name;

  factory IOSDevice({String id, String name}) {
    IOSDevice device = new _Device(className, id);
    device._name = name;
    return device;
  }

  IOSDevice._(String id) : super._(id) {
    _installerPath = _checkForCommand('ideviceinstaller');
    _listerPath = _checkForCommand('idevice_id');
    _informerPath = _checkForCommand('ideviceinfo');
  }

  static List<IOSDevice> getAttachedDevices([IOSDevice mockIOS]) {
    List<IOSDevice> devices = [];
    for (String id in _getAttachedDeviceIDs(mockIOS)) {
      String name = _getDeviceName(id, mockIOS);
      devices.add(new IOSDevice(id: id, name: name));
    }
    return devices;
  }

  static List<String> _getAttachedDeviceIDs([IOSDevice mockIOS]) {
    String listerPath =
        (mockIOS != null) ? mockIOS.listerPath : _checkForCommand('idevice_id');
    return runSync([listerPath, '-l']).trim().split('\n');
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
        exit(2);
      }
      return command;
    });
  }

  @override
  bool installApp(ApplicationPackage app) {
    if (id == defaultDeviceID) {
      runCheckedSync([installerPath, '-i', app.appPath]);
    } else {
      runCheckedSync([installerPath, '-u', id, '-i', app.appPath]);
    }
    return false;
  }

  @override
  bool isConnected() {
    List<String> ids = _getAttachedDeviceIDs();
    for (String id in ids) {
      if (id == this.id || this.id == defaultDeviceID) {
        return true;
      }
    }
    return false;
  }

  @override
  bool isAppInstalled(ApplicationPackage app) {
    return false;
  }
}

class AndroidDevice extends _Device {
  static const String _ADB_PATH = 'adb';
  static const String _observatoryPort = '8181';
  static const String _serverPort = '9888';

  static const String className = 'AndroidDevice';
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
    AndroidDevice device = new _Device(className, id);
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
      _logging.severe('Unable to run on Android.');
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
    } catch (e, stack) {
      _logging.severe('Unexpected failure from adb: ', e, stack);
    }
    return false;
  }

  String _getDeviceSha1Path(ApplicationPackage app) {
    return '/sdcard/${app.appPackageID}/${app.appFileName}.sha1';
  }

  String _getDeviceApkSha1(ApplicationPackage app) {
    return runCheckedSync([adbPath, 'shell', 'cat', _getDeviceSha1Path(app)]);
  }

  String _getSourceSha1(ApplicationPackage app) {
    String sha1 =
        runCheckedSync(['shasum', '-a', '1', '-p', app.appPath]).split(' ')[0];
    return sha1;
  }

  @override
  bool isAppInstalled(ApplicationPackage app) {
    if (!isConnected()) {
      return false;
    }
    if (runCheckedSync([adbPath, 'shell', 'pm', 'path', app.appPackageID]) ==
        '') {
      _logging.info(
          'TODO(iansf): move this log to the caller. ${app.appFileName} is not on the device. Installing now...');
      return false;
    }
    if (_getDeviceApkSha1(app) != _getSourceSha1(app)) {
      _logging.info(
          'TODO(iansf): move this log to the caller. ${app.appFileName} is out of date. Installing now...');
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
    if (!FileSystemEntity.isFileSync(app.appPath)) {
      _logging.severe('"${app.appPath}" does not exist.');
      return false;
    }

    runCheckedSync([adbPath, 'install', '-r', app.appPath]);

    Directory tempDir = Directory.systemTemp;
    String sha1Path = path.join(
        tempDir.path, (app.appPath + '.sha1').replaceAll(path.separator, '_'));
    File sha1TempFile = new File(sha1Path);
    sha1TempFile.writeAsStringSync(_getSourceSha1(app), flush: true);
    runCheckedSync([adbPath, 'push', sha1Path, _getDeviceSha1Path(app)]);
    sha1TempFile.deleteSync();
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
      await Process.start('pub', ['run', 'sky_tools:sky_server', _serverPort],
          workingDirectory: serverRoot, mode: ProcessStartMode.DETACHED);

      // Set up reverse port-forwarding so that the Android app can reach the
      // server running on localhost.
      String serverPortString = 'tcp:$_serverPort';
      runCheckedSync([adbPath, 'reverse', serverPortString, serverPortString]);
    }

    String relativeDartMain = path.relative(mainDart, from: serverRoot);
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
    cmd.add(apk.component);

    runCheckedSync(cmd);

    return true;
  }

  bool stop(AndroidApk apk) {
    // Turn off reverse port forwarding
    runSync([adbPath, 'reverse', '--remove', 'tcp:$_serverPort']);
    // Stop the app
    runSync([adbPath, 'shell', 'am', 'force-stop', apk.appPackageID]);
    // Kill the server
    if (Platform.isMacOS) {
      String pid = runSync(['lsof', '-i', ':$_serverPort', '-t']);
      // Killing a pid with a shell command from within dart is hard,
      // so use a library command, but it's still nice to give the
      // equivalent command when doing verbose logging.
      _logging.info('kill $pid');
      Process.killPid(int.parse(pid));
    } else {
      runSync(['fuser', '-k', '$_serverPort/tcp']);
    }

    return true;
  }

  void clearLogs() {
    runSync([adbPath, 'logcat', '-c']);
  }

  Future<int> logs({bool clear: false}) {
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
    ], prefix: 'ANDROID: ');
  }

  void startTracing(AndroidApk apk) {
    runCheckedSync([
      adbPath,
      'shell',
      'am',
      'broadcast',
      '-a',
      '${apk.appPackageID}.TRACING_START'
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
      '${apk.appPackageID}.TRACING_STOP'
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
      // adb root exits with 0 even if the command fails,
      // so check the output string
      String output = runSync([adbPath, 'root']);
      if (new RegExp(r'.*cannot run as root.*').hasMatch(output)) {
        _logging
            .severe('Unable to download trace "${path.basename(tracePath)}"\n'
                'You need to be able to run adb as root '
                'on your android device');
        return null;
      }
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
