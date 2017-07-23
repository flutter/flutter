// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../base/version.dart';
import '../globals.dart';

AndroidSdk get androidSdk => context[AndroidSdk];

const String kAndroidHome = 'ANDROID_HOME';

// Android SDK layout:

// $ANDROID_HOME/platform-tools/adb

// $ANDROID_HOME/build-tools/19.1.0/aapt, dx, zipalign
// $ANDROID_HOME/build-tools/22.0.1/aapt
// $ANDROID_HOME/build-tools/23.0.2/aapt
// $ANDROID_HOME/build-tools/24.0.0-preview/aapt
// $ANDROID_HOME/build-tools/25.0.2/apksigner

// $ANDROID_HOME/platforms/android-22/android.jar
// $ANDROID_HOME/platforms/android-23/android.jar
// $ANDROID_HOME/platforms/android-N/android.jar

// Special case some version names in the sdk.
const Map<String, int> _namedVersionMap = const <String, int> {
  'android-N': 24,
  'android-stable': 24,
};

/// The minimum Android SDK version we support.
const int minimumAndroidSdkVersion = 25;

/// Locate ADB. Prefer to use one from an Android SDK, if we can locate that.
/// This should be used over accessing androidSdk.adbPath directly because it
/// will work for those users who have Android Platform Tools installed but
/// not the full SDK.
String getAdbPath([AndroidSdk existingSdk]) {
  if (existingSdk?.adbPath != null)
    return existingSdk.adbPath;

  final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();

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

    if (config.containsKey('android-sdk')) {
      androidHomeDir = config.getValue('android-sdk');
    } else if (platform.environment.containsKey(kAndroidHome)) {
      androidHomeDir = platform.environment[kAndroidHome];
    } else if (platform.isLinux) {
      if (homeDirPath != null)
        androidHomeDir = fs.path.join(homeDirPath, 'Android', 'Sdk');
    } else if (platform.isMacOS) {
      if (homeDirPath != null)
        androidHomeDir = fs.path.join(homeDirPath, 'Library', 'Android', 'sdk');
    } else if (platform.isWindows) {
      if (homeDirPath != null)
        androidHomeDir = fs.path.join(homeDirPath, 'AppData', 'Local', 'Android', 'sdk');
    }

    if (androidHomeDir != null) {
      if (validSdkDirectory(androidHomeDir))
        return new AndroidSdk(androidHomeDir);
      if (validSdkDirectory(fs.path.join(androidHomeDir, 'sdk')))
        return new AndroidSdk(fs.path.join(androidHomeDir, 'sdk'));
    }

    // in build-tools/$version/aapt
    final List<File> aaptBins = os.whichAll('aapt');
    for (File aaptBin in aaptBins) {
      // Make sure we're using the aapt from the SDK.
      aaptBin = fs.file(aaptBin.resolveSymbolicLinksSync());
      final String dir = aaptBin.parent.parent.parent.path;
      if (validSdkDirectory(dir))
        return new AndroidSdk(dir);
    }

    // in platform-tools/adb
    final List<File> adbBins = os.whichAll('adb');
    for (File adbBin in adbBins) {
      // Make sure we're using the adb from the SDK.
      adbBin = fs.file(adbBin.resolveSymbolicLinksSync());
      final String dir = adbBin.parent.parent.path;
      if (validSdkDirectory(dir))
        return new AndroidSdk(dir);
    }

    // No dice.
    printTrace('Unable to locate an Android SDK.');
    return null;
  }

  static bool validSdkDirectory(String dir) {
    return fs.isDirectorySync(fs.path.join(dir, 'platform-tools'));
  }

  List<AndroidSdkVersion> get sdkVersions => _sdkVersions;

  AndroidSdkVersion get latestVersion => _latestVersion;

  String get adbPath => getPlatformToolsPath('adb');

  /// Validate the Android SDK. This returns an empty list if there are no
  /// issues; otherwise, it returns a list of issues found.
  List<String> validateSdkWellFormed() {
    if (!processManager.canRun(adbPath))
      return <String>['Android SDK file not found: $adbPath.'];

    if (sdkVersions.isEmpty || latestVersion == null)
      return <String>['Android SDK is missing command line tools; download from https://goo.gl/XxQghQ'];

    return latestVersion.validateSdkWellFormed();
  }

  String getPlatformToolsPath(String binaryName) {
    return fs.path.join(directory, 'platform-tools', binaryName);
  }

  void _init() {
    List<String> platforms = <String>[]; // android-22, ...

    final Directory platformsDir = fs.directory(fs.path.join(directory, 'platforms'));
    if (platformsDir.existsSync()) {
      platforms = platformsDir
        .listSync()
        .map<String>((FileSystemEntity entity) => fs.path.basename(entity.path))
        .where((String name) => name.startsWith('android-'))
        .toList();
    }

    List<Version> buildTools = <Version>[]; // 19.1.0, 22.0.1, ...

    final Directory buildToolsDir = fs.directory(fs.path.join(directory, 'build-tools'));
    if (buildToolsDir.existsSync()) {
      buildTools = buildToolsDir
        .listSync()
        .map((FileSystemEntity entity) {
          try {
            return new Version.parse(fs.path.basename(entity.path));
          } catch (error) {
            return null;
          }
        })
        .where((Version version) => version != null)
        .toList();
    }

    // Match up platforms with the best corresponding build-tools.
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
        buildToolsVersion: buildToolsVersion
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
    this.buildToolsVersion,
  });

  final AndroidSdk sdk;
  final String platformVersionName;
  final Version buildToolsVersion;
  String get buildToolsVersionName => buildToolsVersion.toString();

  int get sdkLevel {
    if (_namedVersionMap.containsKey(platformVersionName))
      return _namedVersionMap[platformVersionName];
    else
      return int.parse(platformVersionName.substring('android-'.length));
  }

  String get androidJarPath => getPlatformsPath('android.jar');

  String get aaptPath => getBuildToolsPath('aapt');

  List<String> validateSdkWellFormed() {
    if (_exists(androidJarPath) != null)
      return <String>[_exists(androidJarPath)];

    if (_canRun(aaptPath) != null)
      return <String>[_canRun(aaptPath)];

    return <String>[];
  }

  String getPlatformsPath(String itemName) {
    return fs.path.join(sdk.directory, 'platforms', platformVersionName, itemName);
  }

  String getBuildToolsPath(String binaryName) {
    return fs.path.join(sdk.directory, 'build-tools', buildToolsVersionName, binaryName);
  }

  @override
  int compareTo(AndroidSdkVersion other) => sdkLevel - other.sdkLevel;

  @override
  String toString() => '[${sdk.directory}, SDK version $sdkLevel, build-tools $buildToolsVersionName]';

  String _exists(String path) {
    if (!fs.isFileSync(path))
      return 'Android SDK file not found: $path.';
    return null;
  }

  String _canRun(String path) {
    if (!processManager.canRun(path))
      return 'Android SDK file not found: $path.';
    return null;
  }
}
