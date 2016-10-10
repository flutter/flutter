// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

import '../base/common.dart';
import '../base/os.dart';
import '../globals.dart';

// Android SDK layout:

// $ANDROID_HOME/platform-tools/adb

// $ANDROID_HOME/build-tools/19.1.0/aapt, dx, zipalign
// $ANDROID_HOME/build-tools/22.0.1/aapt
// $ANDROID_HOME/build-tools/23.0.2/aapt
// $ANDROID_HOME/build-tools/24.0.0-preview/aapt

// $ANDROID_HOME/platforms/android-22/android.jar
// $ANDROID_HOME/platforms/android-23/android.jar
// $ANDROID_HOME/platforms/android-N/android.jar

// Special case some version names in the sdk.
const Map<String, int> _namedVersionMap = const <String, int> {
  'android-N': 24
};

/// Locate ADB. Prefer to use one from an Android SDK, if we can locate that.
/// This should be used over accessing androidSdk.adbPath directly because it
/// will work for those users who have Android Platform Tools installed but
/// not the full SDK.
String getAdbPath([AndroidSdk existingSdk]) {
  if (existingSdk?.adbPath != null)
    return existingSdk.adbPath;

  AndroidSdk sdk = AndroidSdk.locateAndroidSdk();

  if (sdk?.latestVersion == null) {
    return os.which('adb')?.path;
  } else {
    return sdk.adbPath;
  }
}

class AndroidSdk {
  AndroidSdk(this.directory) {
    _init();
  }

  final String directory;

  List<AndroidSdkVersion> _sdkVersions;
  AndroidSdkVersion _latestVersion;

  static AndroidSdk locateAndroidSdk() {
    String androidHomeDir;
    if (Platform.environment.containsKey('ANDROID_HOME')) {
      androidHomeDir = Platform.environment['ANDROID_HOME'];
    } else if (Platform.isLinux) {
      if (homeDirPath != null)
        androidHomeDir = '$homeDirPath/Android/Sdk';
    } else if (Platform.isMacOS) {
      if (homeDirPath != null)
        androidHomeDir = '$homeDirPath/Library/Android/sdk';
    }

    if (androidHomeDir != null) {
      if (validSdkDirectory(androidHomeDir))
        return new AndroidSdk(androidHomeDir);
      if (validSdkDirectory(path.join(androidHomeDir, 'sdk')))
        return new AndroidSdk(path.join(androidHomeDir, 'sdk'));
    }

    File aaptBin = os.which('aapt'); // in build-tools/$version/aapt
    if (aaptBin != null) {
      // Make sure we're using the aapt from the SDK.
      aaptBin = new File(aaptBin.resolveSymbolicLinksSync());
      String dir = aaptBin.parent.parent.parent.path;
      if (validSdkDirectory(dir))
        return new AndroidSdk(dir);
    }

    File adbBin = os.which('adb'); // in platform-tools/adb
    if (adbBin != null) {
      // Make sure we're using the adb from the SDK.
      adbBin = new File(adbBin.resolveSymbolicLinksSync());
      String dir = adbBin.parent.parent.path;
      if (validSdkDirectory(dir))
        return new AndroidSdk(dir);
    }

    // No dice.
    printTrace('Unable to locate an Android SDK.');
    return null;
  }

  static bool validSdkDirectory(String dir) {
    return FileSystemEntity.isDirectorySync(path.join(dir, 'platform-tools'));
  }

  List<AndroidSdkVersion> get sdkVersions => _sdkVersions;

  AndroidSdkVersion get latestVersion => _latestVersion;

  String get adbPath => getPlatformToolsPath('adb');

  /// Validate the Android SDK. This returns an empty list if there are no
  /// issues; otherwise, it returns a list of issues found.
  List<String> validateSdkWellFormed() {
    if (!FileSystemEntity.isFileSync(adbPath))
      return <String>['Android SDK file not found: $adbPath.'];

    if (sdkVersions.isEmpty || latestVersion == null)
      return <String>['Android SDK does not have the proper build-tools.'];

    return latestVersion.validateSdkWellFormed();
  }

  String getPlatformToolsPath(String binaryName) {
    return path.join(directory, 'platform-tools', binaryName);
  }

  void _init() {
    List<String> platforms = <String>[]; // android-22, ...

    Directory platformsDir = new Directory(path.join(directory, 'platforms'));
    if (platformsDir.existsSync()) {
      platforms = platformsDir
        .listSync()
        .map((FileSystemEntity entity) => path.basename(entity.path))
        .where((String name) => name.startsWith('android-'))
        .toList();
    }

    List<Version> buildTools = <Version>[]; // 19.1.0, 22.0.1, ...

    Directory buildToolsDir = new Directory(path.join(directory, 'build-tools'));
    if (buildToolsDir.existsSync()) {
      buildTools = buildToolsDir
        .listSync()
        .map((FileSystemEntity entity) {
          try {
            return new Version.parse(path.basename(entity.path));
          } catch (error) {
            return null;
          }
        })
        .where((Version version) => version != null)
        .toList();
    }

    // Match up platforms with the best cooresponding build-tools.
    _sdkVersions = platforms.map((String platformName) {
      int platformVersion;

      try {
        if (_namedVersionMap.containsKey(platformName))
          platformVersion = _namedVersionMap[platformName];
        else
          platformVersion = int.parse(platformName.substring('android-'.length));
      } catch (error) {
        return null;
      }

      Version buildToolsVersion = Version.primary(buildTools.where((Version version) {
        return version.major == platformVersion;
      }).toList());

      buildToolsVersion ??= Version.primary(buildTools);

      if (buildToolsVersion == null)
        return null;

      return new AndroidSdkVersion(
        this,
        platformVersionName: platformName,
        buildToolsVersionName: buildToolsVersion.toString()
      );
    }).where((AndroidSdkVersion version) => version != null).toList();

    _sdkVersions.sort();

    _latestVersion = _sdkVersions.isEmpty ? null : _sdkVersions.last;
  }

  @override
  String toString() => 'AndroidSdk: $directory';
}

class AndroidSdkVersion implements Comparable<AndroidSdkVersion> {
  AndroidSdkVersion(this.sdk, {
    this.platformVersionName,
    this.buildToolsVersionName
  });

  final AndroidSdk sdk;
  final String platformVersionName;
  final String buildToolsVersionName;

  int get sdkLevel {
    if (_namedVersionMap.containsKey(platformVersionName))
      return _namedVersionMap[platformVersionName];
    else
      return int.parse(platformVersionName.substring('android-'.length));
  }

  String get androidJarPath => getPlatformsPath('android.jar');

  String get aaptPath => getBuildToolsPath('aapt');

  String get dxPath => getBuildToolsPath('dx');

  String get zipalignPath => getBuildToolsPath('zipalign');

  List<String> validateSdkWellFormed() {
    if (_exists(androidJarPath) != null)
      return <String>[_exists(androidJarPath)];

    if (_exists(aaptPath) != null)
      return <String>[_exists(aaptPath)];

    if (_exists(dxPath) != null)
      return <String>[_exists(dxPath)];

    if (_exists(zipalignPath) != null)
      return <String>[_exists(zipalignPath)];

    return <String>[];
  }

  String getPlatformsPath(String itemName) {
    return path.join(sdk.directory, 'platforms', platformVersionName, itemName);
  }

  String getBuildToolsPath(String binaryName) {
    return path.join(sdk.directory, 'build-tools', buildToolsVersionName, binaryName);
  }

  @override
  int compareTo(AndroidSdkVersion other) => sdkLevel - other.sdkLevel;

  @override
  String toString() => '[${sdk.directory}, SDK version $sdkLevel, build-tools $buildToolsVersionName]';

  String _exists(String path) {
    if (!FileSystemEntity.isFileSync(path))
      return 'Android SDK file not found: $path.';
    return null;
  }
}
