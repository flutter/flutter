// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart' show ProcessResult;
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../base/version.dart';
import '../globals.dart';
import 'android_studio.dart' as android_studio;

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

final RegExp _numberedAndroidPlatformRe = new RegExp(r'^android-([0-9]+)$');
final RegExp _sdkVersionRe = new RegExp(r'^ro.build.version.sdk=([0-9]+)$');

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
  AndroidSdk(this.directory, [this.ndkDirectory, this.ndkCompiler,
      this.ndkCompilerArgs]) {
    _init();
  }

  static const String _kJavaHomeEnvironmentVariable = 'JAVA_HOME';
  static const String _kJavaExecutable = 'java';

  /// The path to the Android SDK.
  final String directory;

  /// The path to the NDK (can be `null`).
  final String ndkDirectory;

  /// The path to the NDK compiler (can be `null`).
  final String ndkCompiler;

  /// The mandatory arguments to the NDK compiler (can be `null`).
  final List<String> ndkCompilerArgs;

  List<AndroidSdkVersion> _sdkVersions;
  AndroidSdkVersion _latestVersion;

  static AndroidSdk locateAndroidSdk() {
    String findAndroidHomeDir() {
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
          return androidHomeDir;
        if (validSdkDirectory(fs.path.join(androidHomeDir, 'sdk')))
          return fs.path.join(androidHomeDir, 'sdk');
      }

      // in build-tools/$version/aapt
      final List<File> aaptBins = os.whichAll('aapt');
      for (File aaptBin in aaptBins) {
        // Make sure we're using the aapt from the SDK.
        aaptBin = fs.file(aaptBin.resolveSymbolicLinksSync());
        final String dir = aaptBin.parent.parent.parent.path;
        if (validSdkDirectory(dir))
          return dir;
      }

      // in platform-tools/adb
      final List<File> adbBins = os.whichAll('adb');
      for (File adbBin in adbBins) {
        // Make sure we're using the adb from the SDK.
        adbBin = fs.file(adbBin.resolveSymbolicLinksSync());
        final String dir = adbBin.parent.parent.path;
        if (validSdkDirectory(dir))
          return dir;
      }

      return null;
    }

    String findNdk(String androidHomeDir) {
      final String ndkDirectory = fs.path.join(androidHomeDir, 'ndk-bundle');
      if (fs.isDirectorySync(ndkDirectory)) {
        return ndkDirectory;
      }
      return null;
    }

    String findNdkCompiler(String ndkDirectory) {
      String directory;
      if (platform.isLinux) {
        directory = 'linux-x86_64';
      } else if (platform.isMacOS) {
        directory = 'darwin-x86_64';
      }
      if (directory != null) {
        final String ndkCompiler = fs.path.join(ndkDirectory,
            'toolchains', 'arm-linux-androideabi-4.9', 'prebuilt', directory,
            'bin', 'arm-linux-androideabi-gcc');
        if (fs.isFileSync(ndkCompiler)) {
          return ndkCompiler;
        }
      }
      return null;
    }

    List<String> computeNdkCompilerArgs(String ndkDirectory) {
      final String armPlatform = fs.path.join(ndkDirectory, 'platforms',
          'android-9', 'arch-arm');
      if (fs.isDirectorySync(armPlatform)) {
        return <String>['--sysroot', armPlatform];
      }
      return null;
    }

    final String androidHomeDir = findAndroidHomeDir();
    if (androidHomeDir == null) {
      // No dice.
      printTrace('Unable to locate an Android SDK.');
      return null;
    }

    // Try to find the NDK compiler. If we can't find it, it's also ok.
    final String ndkDir = findNdk(androidHomeDir);
    String ndkCompiler;
    List<String> ndkCompilerArgs;
    if (ndkDir != null) {
      ndkCompiler = findNdkCompiler(ndkDir);
      if (ndkCompiler != null) {
        ndkCompilerArgs = computeNdkCompilerArgs(ndkDir);
        if (ndkCompilerArgs == null) {
          ndkCompiler = null;
        }
      }
    }

    return new AndroidSdk(androidHomeDir, ndkDir, ndkCompiler, ndkCompilerArgs);
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
    Iterable<Directory> platforms = <Directory>[]; // android-22, ...

    final Directory platformsDir = fs.directory(fs.path.join(directory, 'platforms'));
    if (platformsDir.existsSync()) {
      platforms = platformsDir
        .listSync()
        .where((FileSystemEntity entity) => entity is Directory)
        .map<Directory>((FileSystemEntity entity) {
          final Directory dir = entity;
          return dir;
        });
    }

    List<Version> buildTools = <Version>[]; // 19.1.0, 22.0.1, ...

    final Directory buildToolsDir = fs.directory(fs.path.join(directory, 'build-tools'));
    if (buildToolsDir.existsSync()) {
      buildTools = buildToolsDir
        .listSync()
        .map((FileSystemEntity entity) {
          try {
            return new Version.parse(entity.basename);
          } catch (error) {
            return null;
          }
        })
        .where((Version version) => version != null)
        .toList();
    }

    // Match up platforms with the best corresponding build-tools.
    _sdkVersions = platforms.map((Directory platformDir) {
      final String platformName = platformDir.basename;
      int platformVersion;

      try {
        final Match numberedVersion = _numberedAndroidPlatformRe.firstMatch(platformName);
        if (numberedVersion != null) {
          platformVersion = int.parse(numberedVersion.group(1));
        } else {
          final String buildProps = platformDir.childFile('build.prop').readAsStringSync();
          final String versionString = const LineSplitter()
              .convert(buildProps)
              .map(_sdkVersionRe.firstMatch)
              .firstWhere((Match match) => match != null)
              .group(1);
          platformVersion = int.parse(versionString);
        }
      } catch (error) {
        return null;
      }

      Version buildToolsVersion = Version.primary(buildTools.where((Version version) {
        return version.major == platformVersion;
      }).toList());

      buildToolsVersion ??= Version.primary(buildTools);

      if (buildToolsVersion == null)
        return null;

      return new AndroidSdkVersion._(
        this,
        sdkLevel: platformVersion,
        platformName: platformName,
        buildToolsVersion: buildToolsVersion,
      );
    }).where((AndroidSdkVersion version) => version != null).toList();

    _sdkVersions.sort();

    _latestVersion = _sdkVersions.isEmpty ? null : _sdkVersions.last;
  }

  /// Returns the filesystem path of the Android SDK manager tool or null if not found.
  String get sdkManagerPath {
    return fs.path.join(directory, 'tools', 'bin', 'sdkmanager');
  }

  /// First try Java bundled with Android Studio, then sniff JAVA_HOME, then fallback to PATH.
  static String findJavaBinary() {

    if (android_studio.javaPath != null)
      return fs.path.join(android_studio.javaPath, 'bin', 'java');

    final String javaHomeEnv = platform.environment[_kJavaHomeEnvironmentVariable];
    if (javaHomeEnv != null) {
      // Trust JAVA_HOME.
      return fs.path.join(javaHomeEnv, 'bin', 'java');
    }

    // MacOS specific logic to avoid popping up a dialog window.
    // See: http://stackoverflow.com/questions/14292698/how-do-i-check-if-the-java-jdk-is-installed-on-mac.
    if (platform.isMacOS) {
      try {
        final String javaHomeOutput = runCheckedSync(<String>['/usr/libexec/java_home'], hideStdout: true);
        if (javaHomeOutput != null) {
          final List<String> javaHomeOutputSplit = javaHomeOutput.split('\n');
          if ((javaHomeOutputSplit != null) && (javaHomeOutputSplit.isNotEmpty)) {
            final String javaHome = javaHomeOutputSplit[0].trim();
            return fs.path.join(javaHome, 'bin', 'java');
          }
        }
      } catch (_) { /* ignore */ }
    }

    // Fallback to PATH based lookup.
    return os.which(_kJavaExecutable)?.path;
  }

  Map<String, String> _sdkManagerEnv;
  Map<String, String> get sdkManagerEnv {
    if (_sdkManagerEnv == null) {
      // If we can locate Java, then add it to the path used to run the Android SDK manager.
      _sdkManagerEnv = <String, String>{};
      final String javaBinary = findJavaBinary();
      if (javaBinary != null) {
        _sdkManagerEnv['PATH'] =
            fs.path.dirname(javaBinary) + os.pathVarSeparator + platform.environment['PATH'];
      }
    }
    return _sdkManagerEnv;
  }

  /// Returns the version of the Android SDK manager tool or null if not found.
  String get sdkManagerVersion {
    if (!processManager.canRun(sdkManagerPath))
      throwToolExit('Android sdkmanager not found. Update to the latest Android SDK to resolve this.');
    final ProcessResult result = processManager.runSync(<String>[sdkManagerPath, '--version'], environment: sdkManagerEnv);
    if (result.exitCode != 0) {
      printTrace('sdkmanager --version failed: exitCode: ${result.exitCode} stdout: ${result.stdout} stderr: ${result.stderr}');
      return null;
    }
    return result.stdout.trim();
  }

  @override
  String toString() => 'AndroidSdk: $directory';
}

class AndroidSdkVersion implements Comparable<AndroidSdkVersion> {
  AndroidSdkVersion._(this.sdk, {
    @required this.sdkLevel,
    @required this.platformName,
    @required this.buildToolsVersion,
  }) : assert(sdkLevel != null),
       assert(platformName != null),
       assert(buildToolsVersion != null);

  final AndroidSdk sdk;
  final int sdkLevel;
  final String platformName;
  final Version buildToolsVersion;

  String get buildToolsVersionName => buildToolsVersion.toString();

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
    return fs.path.join(sdk.directory, 'platforms', platformName, itemName);
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
