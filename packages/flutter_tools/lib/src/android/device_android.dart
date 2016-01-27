// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/logging.dart';
import '../base/process.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../flx.dart' as flx;
import '../toolchain.dart';
import 'android.dart';

class AndroidDevice extends Device {
  static const String _defaultAdbPath = 'adb';
  static const int _observatoryPort = 8181;

  static final String defaultDeviceID = 'default_android_device';

  String productID;
  String modelID;
  String deviceCodeName;

  bool _connected;
  String _adbPath;
  String get adbPath => _adbPath;
  bool _hasAdb = false;
  bool _hasValidAndroid = false;

  factory AndroidDevice({
    String id: null,
    String productID: null,
    String modelID: null,
    String deviceCodeName: null,
    bool connected
  }) {
    AndroidDevice device = Device.unique(id ?? defaultDeviceID, (String id) => new AndroidDevice.fromId(id));
    device.productID = productID;
    device.modelID = modelID;
    device.deviceCodeName = deviceCodeName;
    if (connected != null)
      device._connected = connected;
    return device;
  }

  /// This constructor is intended as protected access; prefer [AndroidDevice].
  AndroidDevice.fromId(id) : super.fromId(id) {
    _adbPath = getAdbPath();
    _hasAdb = _checkForAdb();

    // Checking for [minApiName] only needs to be done if we are starting an
    // app, but it has an important side effect, which is to discard any
    // progress messages if the adb server is restarted.
    _hasValidAndroid = _checkForSupportedAndroidVersion();

    if (!_hasAdb || !_hasValidAndroid) {
      logging.warning('Unable to run on Android.');
    }
  }

  /// mockAndroid argument is only to facilitate testing with mocks, so that
  /// we don't have to rely on the test setup having adb available to it.
  static List<AndroidDevice> getAttachedDevices([AndroidDevice mockAndroid]) {
    List<AndroidDevice> devices = [];
    String adbPath = (mockAndroid != null) ? mockAndroid.adbPath : getAdbPath();

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
    RegExp offlineRegex = new RegExp(r'^(\S+)\s+offline\s+\S+$');

    // Skip first line, which is always 'List of devices attached'.
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
      } else if (offlineRegex.hasMatch(line)) {
        Match match = offlineRegex.firstMatch(line);
        String deviceID = match[1];
        logging.warning('Device $deviceID is offline.');
      } else {
        logging.warning(
          'Unexpected failure parsing device information from adb output:\n'
          '$line\n'
          'Please report a bug at https://github.com/flutter/flutter/issues/new');
      }
    }
    return devices;
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

  static String getAdbPath() {
    if (Platform.environment.containsKey('ANDROID_HOME')) {
      String androidHomeDir = Platform.environment['ANDROID_HOME'];
      String adbPath1 = path.join(androidHomeDir, 'sdk', 'platform-tools', 'adb');
      String adbPath2 = path.join(androidHomeDir, 'platform-tools', 'adb');
      if (FileSystemEntity.isFileSync(adbPath1)) {
        return adbPath1;
      } else if (FileSystemEntity.isFileSync(adbPath2)) {
        return adbPath2;
      } else {
        logging.info('"adb" not found at\n  "$adbPath1" or\n  "$adbPath2"\n' +
            'using default path "$_defaultAdbPath"');
        return _defaultAdbPath;
      }
    } else {
      return _defaultAdbPath;
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
      if (sdkVersionParsed < minApiLevel) {
        logging.severe(
          'The Android version ($sdkVersion) on the target device is too old. Please '
          'use a $minVersionName (version $minApiLevel / $minVersionText) device or later.');
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

  String get name => modelID;

  @override
  bool isAppInstalled(ApplicationPackage app) {
    if (!isConnected()) {
      return false;
    }
    if (runCheckedSync(adbCommandForDevice(['shell', 'pm', 'path', app.id])) == '') {
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
    try {
      runCheckedSync(adbCommandForDevice(['forward', portString, portString]));
    } catch (e) {
      logging.warning('Unable to forward observatory port ($_observatoryPort):\n$e');
    }
  }

  bool startBundle(AndroidApk apk, String bundlePath, {
    bool poke: false,
    bool checked: true,
    bool traceStartup: false,
    String route,
    bool clearLogs: false
  }) {
    logging.fine('$this startBundle');

    if (!FileSystemEntity.isFileSync(bundlePath)) {
      logging.severe('Cannot find $bundlePath');
      return false;
    }

    if (!poke)
      _forwardObservatoryPort();

    if (clearLogs)
      this.clearLogs();

    String deviceTmpPath = '/data/local/tmp/dev.flx';
    runCheckedSync(adbCommandForDevice(['push', bundlePath, deviceTmpPath]));
    List<String> cmd = adbCommandForDevice([
      'shell', 'am', 'start',
      '-a', 'android.intent.action.RUN',
      '-d', deviceTmpPath,
    ]);
    if (checked)
      cmd.addAll(['--ez', 'enable-checked-mode', 'true']);
    if (traceStartup)
      cmd.addAll(['--ez', 'trace-startup', 'true']);
    if (route != null)
      cmd.addAll(['--es', 'route', route]);
    cmd.add(apk.launchActivity);
    runCheckedSync(cmd);
    return true;
  }

  @override
  Future<bool> startApp(
    ApplicationPackage package,
    Toolchain toolchain, {
    String mainPath,
    String route,
    bool checked: true,
    Map<String, dynamic> platformArgs
  }) {
    return flx.buildInTempDir(
      toolchain,
      mainPath: mainPath
    ).then((flx.DirectoryResult buildResult) {
      logging.fine('Starting bundle for $this.');

      try {
        if (startBundle(
          package,
          buildResult.localBundlePath,
          poke: platformArgs['poke'],
          checked: checked,
          traceStartup: platformArgs['trace-startup'],
          route: route,
          clearLogs: platformArgs['clear-logs']
        )) {
          return true;
        } else {
          return false;
        }
      } finally {
        buildResult.dispose();
      }
    });
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
      'ActivityManager:W',
      'System.err:W',
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

  // Return the most recent timestamp in the Android log.  The format can be
  // passed to logcat's -T option.
  String lastLogcatTimestamp() {
    String output = runCheckedSync(adbCommandForDevice(['logcat', '-v', 'time', '-t', '1']));

    RegExp timeRegExp = new RegExp(r'^\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}', multiLine: true);
    Match timeMatch = timeRegExp.firstMatch(output);
    return timeMatch[0];
  }

  Future<String> stopTracing(AndroidApk apk, { String outPath: null }) async {
    // Workaround for logcat -c not always working:
    // http://stackoverflow.com/questions/25645012/logcat-on-android-l-not-clearing-after-unplugging-and-reconnecting
    String beforeStop = lastLogcatTimestamp();
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
      String logs = runCheckedSync(adbCommandForDevice(['logcat', '-d', '-T', beforeStop]));
      Match fileMatch = traceRegExp.firstMatch(logs);
      if (fileMatch != null && fileMatch[1] != null) {
        tracePath = fileMatch[1];
      }
      isComplete = completeRegExp.hasMatch(logs);
    }

    if (tracePath != null) {
      String localPath = (outPath != null) ? outPath : path.basename(tracePath);

      // Run cat via ADB to print the captured trace file.  (adb pull will be unable
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
    logging.warning('No trace file detected. '
        'Did you remember to start the trace before stopping it?');
    return null;
  }

  bool isConnected() => _connected != null ? _connected : _hasValidAndroid;

  void setConnected(bool value) {
    _connected = value;
  }
}
