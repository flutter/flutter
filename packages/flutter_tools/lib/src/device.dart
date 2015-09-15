// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.device;

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'process_wrapper.dart';

final Logger _logging = new Logger('sky_tools.device');

abstract class _Device {
  final String id;
  static Map<String, _Device> _deviceCache = {};

  factory _Device(String className, [String id = null]) {
    if (id == null) {
      if (className == AndroidDevice.className) {
        id = AndroidDevice.defaultDeviceID;
      } else {
        throw 'Attempted to create a Device of unknown type $className';
      }
    }

    return _deviceCache.putIfAbsent(id, () {
      if (className == AndroidDevice.className) {
        final device = new AndroidDevice._(id);
        _deviceCache[id] = device;
        return device;
      } else {
        throw 'Attempted to create a Device of unknown type $className';
      }
    });
  }

  _Device._(this.id);

  /// Install an app package on the current device
  bool installApp(String path);

  /// Check if the current device needs an installation
  bool needsInstall();

  /// Check if the device is currently connected
  bool isConnected();
}

class AndroidDevice extends _Device {
  static const String _ADB_PATH = 'adb';

  static const String className = 'AndroidDevice';
  static final String defaultDeviceID = 'default';

  String _adbPath;
  String get adbPath => _adbPath;

  factory AndroidDevice([String id = null]) {
    return new _Device(className, id);
  }

  AndroidDevice._(id) : super._(id) {
    _updatePaths();

    // Checking for lollipop only needs to be done if we are starting an
    // app, but it has an important side effect, which is to discard any
    // progress messages if the adb server is restarted.
    if (!_checkForAdb() || !_checkForLollipopOrLater()) {
      _logging.severe('Unable to run on Android.');
    }
  }

  @override
  bool installApp(String path) {
    return true;
  }

  @override
  bool needsInstall() {
    return true;
  }

  @override
  bool isConnected() {
    return true;
  }

  void _updatePaths() {
    if (Platform.environment.containsKey('ANDROID_HOME')) {
      String androidHomeDir = Platform.environment['ANDROID_HOME'];
      String adbPath1 =
          path.join(androidHomeDir, 'sdk', 'platform-tools', 'adb');
      String adbPath2 = path.join(androidHomeDir, 'platform-tools', 'adb');
      if (FileSystemEntity.isFileSync(adbPath1)) {
        _adbPath = adbPath1;
      } else if (FileSystemEntity.isFileSync(adbPath2)) {
        _adbPath = adbPath2;
      } else {
        _logging.info('"adb" not found at\n  "$adbPath1" or\n  "$adbPath2"\n' +
            'using default path "$_ADB_PATH"');
        _adbPath = _ADB_PATH;
      }
    } else {
      _adbPath = _ADB_PATH;
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
}
