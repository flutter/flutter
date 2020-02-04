// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import 'android_studio.dart' as android_studio;

AndroidSdk get androidSdk => context.get<AndroidSdk>();

const String kAndroidHome = 'ANDROID_HOME';
const String kAndroidSdkRoot = 'ANDROID_SDK_ROOT';

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

final RegExp _numberedAndroidPlatformRe = RegExp(r'^android-([0-9]+)$');
final RegExp _sdkVersionRe = RegExp(r'^ro.build.version.sdk=([0-9]+)$');

/// The minimum Android SDK version we support.
const int minimumAndroidSdkVersion = 25;

/// Locate ADB. Prefer to use one from an Android SDK, if we can locate that.
/// This should be used over accessing androidSdk.adbPath directly because it
/// will work for those users who have Android Platform Tools installed but
/// not the full SDK.
String getAdbPath([ AndroidSdk existingSdk ]) {
  if (existingSdk?.adbPath != null) {
    return existingSdk.adbPath;
  }

  final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();

  if (sdk?.latestVersion == null) {
    return globals.os.which('adb')?.path;
  } else {
    return sdk?.adbPath;
  }
}

/// Locate 'emulator'. Prefer to use one from an Android SDK, if we can locate that.
/// This should be used over accessing androidSdk.emulatorPath directly because it
/// will work for those users who have Android Tools installed but
/// not the full SDK.
String getEmulatorPath([ AndroidSdk existingSdk ]) {
  return existingSdk?.emulatorPath ??
    AndroidSdk.locateAndroidSdk()?.emulatorPath;
}

/// Locate the path for storing AVD emulator images. Returns null if none found.
String getAvdPath() {

  final List<String> searchPaths = <String>[
    globals.platform.environment['ANDROID_AVD_HOME'],
    if (globals.platform.environment['HOME'] != null)
      globals.fs.path.join(globals.platform.environment['HOME'], '.android', 'avd'),
  ];


  if (globals.platform.isWindows) {
    final String homeDrive = globals.platform.environment['HOMEDRIVE'];
    final String homePath = globals.platform.environment['HOMEPATH'];

    if (homeDrive != null && homePath != null) {
      // Can't use path.join for HOMEDRIVE/HOMEPATH
      // https://github.com/dart-lang/path/issues/37
      final String home = homeDrive + homePath;
      searchPaths.add(globals.fs.path.join(home, '.android', 'avd'));
    }
  }

  return searchPaths.where((String p) => p != null).firstWhere(
    (String p) => globals.fs.directory(p).existsSync(),
    orElse: () => null,
  );
}

/// Locate 'avdmanager'. Prefer to use one from an Android SDK, if we can locate that.
/// This should be used over accessing androidSdk.avdManagerPath directly because it
/// will work for those users who have Android Tools installed but
/// not the full SDK.
String getAvdManagerPath([ AndroidSdk existingSdk ]) {
  return existingSdk?.avdManagerPath ??
    AndroidSdk.locateAndroidSdk()?.avdManagerPath;
}

class AndroidNdkSearchError {
  AndroidNdkSearchError(this.reason);

  /// The message explaining why NDK was not found.
  final String reason;
}

class AndroidNdk {
  AndroidNdk._(this.directory, this.compiler, this.compilerArgs);

  /// The path to the NDK.
  final String directory;

  /// The path to the NDK compiler.
  final String compiler;

  /// The mandatory arguments to the NDK compiler.
  final List<String> compilerArgs;

  /// Locate NDK within the given SDK or throw [AndroidNdkSearchError].
  static AndroidNdk locateNdk(String androidHomeDir) {
    if (androidHomeDir == null) {
      throw AndroidNdkSearchError('Can not locate NDK because no SDK is found');
    }

    String findBundle(String androidHomeDir) {
      final String ndkDirectory = globals.fs.path.join(androidHomeDir, 'ndk-bundle');
      if (!globals.fs.isDirectorySync(ndkDirectory)) {
        throw AndroidNdkSearchError('Can not locate ndk-bundle, tried: $ndkDirectory');
      }
      return ndkDirectory;
    }

    // Returns list that contains toolchain bin folder and compiler binary name.
    List<String> findToolchainAndCompiler(String ndkDirectory) {
      String directory;
      if (globals.platform.isLinux) {
        directory = 'linux-x86_64';
      } else if (globals.platform.isMacOS) {
        directory = 'darwin-x86_64';
      } else {
        throw AndroidNdkSearchError('Only Linux and macOS are supported');
      }

      final String toolchainBin = globals.fs.path.join(ndkDirectory,
          'toolchains', 'arm-linux-androideabi-4.9', 'prebuilt', directory,
          'bin');
      final String ndkCompiler = globals.fs.path.join(toolchainBin,
          'arm-linux-androideabi-gcc');
      if (!globals.fs.isFileSync(ndkCompiler)) {
        throw AndroidNdkSearchError('Can not locate GCC binary, tried $ndkCompiler');
      }

      return <String>[toolchainBin, ndkCompiler];
    }

    List<String> findSysroot(String ndkDirectory) {
      // If entity represents directory with name android-<version> that
      // contains arch-arm subdirectory then returns version, otherwise
      // returns null.
      int toPlatformVersion(FileSystemEntity entry) {
        if (entry is! Directory) {
          return null;
        }

        if (!globals.fs.isDirectorySync(globals.fs.path.join(entry.path, 'arch-arm'))) {
          return null;
        }

        final String name = globals.fs.path.basename(entry.path);

        const String platformPrefix = 'android-';
        if (!name.startsWith(platformPrefix)) {
          return null;
        }

        return int.tryParse(name.substring(platformPrefix.length));
      }

      final String platformsDir = globals.fs.path.join(ndkDirectory, 'platforms');
      final List<int> versions = globals.fs
          .directory(platformsDir)
          .listSync()
          .map(toPlatformVersion)
          .where((int version) => version != null)
          .toList(growable: false);
      versions.sort();

      final int suitableVersion = versions
          .firstWhere((int version) => version >= 9, orElse: () => null);
      if (suitableVersion == null) {
        throw AndroidNdkSearchError('Can not locate a suitable platform ARM sysroot (need android-9 or newer), tried to look in $platformsDir');
      }

      final String armPlatform = globals.fs.path.join(ndkDirectory, 'platforms',
          'android-$suitableVersion', 'arch-arm');
      return <String>['--sysroot', armPlatform];
    }

    int findNdkMajorVersion(String ndkDirectory) {
      final String propertiesFile = globals.fs.path.join(ndkDirectory, 'source.properties');
      if (!globals.fs.isFileSync(propertiesFile)) {
        throw AndroidNdkSearchError('Can not establish ndk-bundle version: $propertiesFile not found');
      }

      // Parse source.properties: each line has Key = Value format.
      final Iterable<String> propertiesFileLines = globals.fs.file(propertiesFile)
          .readAsStringSync()
          .split('\n')
          .map<String>((String line) => line.trim())
          .where((String line) => line.isNotEmpty);
      final Map<String, String> properties = <String, String>{};
      for (final String line in propertiesFileLines) {
        final List<String> parts = line.split(' = ');
        if (parts.length == 2) {
          properties[parts[0]] = parts[1];
        } else {
          globals.printError('Malformed line in ndk source.properties: "$line".');
        }
      }

      if (!properties.containsKey('Pkg.Revision')) {
        throw AndroidNdkSearchError('Can not establish ndk-bundle version: $propertiesFile does not contain Pkg.Revision');
      }

      // Extract major version from Pkg.Revision property which looks like <ndk-version>.x.y.
      return int.parse(properties['Pkg.Revision'].split('.').first);
    }

    final String ndkDir = findBundle(androidHomeDir);
    final int ndkVersion = findNdkMajorVersion(ndkDir);
    final List<String> ndkToolchainAndCompiler = findToolchainAndCompiler(ndkDir);
    final String ndkToolchain = ndkToolchainAndCompiler[0];
    final String ndkCompiler = ndkToolchainAndCompiler[1];
    final List<String> ndkCompilerArgs = findSysroot(ndkDir);
    if (ndkVersion >= 18) {
      // Newer versions of NDK use clang instead of gcc, which falls back to
      // system linker instead of using toolchain linker. Force clang to
      // use appropriate linker by passing -fuse-ld=<path-to-ld> command line
      // flag.
      final String ndkLinker = globals.fs.path.join(ndkToolchain, 'arm-linux-androideabi-ld');
      if (!globals.fs.isFileSync(ndkLinker)) {
        throw AndroidNdkSearchError('Can not locate linker binary, tried $ndkLinker');
      }
      ndkCompilerArgs.add('-fuse-ld=$ndkLinker');
    }
    return AndroidNdk._(ndkDir, ndkCompiler, ndkCompilerArgs);
  }

  /// Returns a descriptive message explaining why NDK can not be found within
  /// the given SDK.
  static String explainMissingNdk(String androidHomeDir) {
    try {
      locateNdk(androidHomeDir);
      return 'Unexpected error: found NDK on the second try';
    } on AndroidNdkSearchError catch (e) {
      return e.reason;
    }
  }
}

class AndroidSdk {
  AndroidSdk(this.directory, [this.ndk]) {
    reinitialize();
  }

  static const String _javaHomeEnvironmentVariable = 'JAVA_HOME';
  static const String _javaExecutable = 'java';

  /// The path to the Android SDK.
  final String directory;

  /// Android NDK (can be `null`).
  final AndroidNdk ndk;

  List<AndroidSdkVersion> _sdkVersions;
  AndroidSdkVersion _latestVersion;

  /// Whether the `platform-tools` directory exists in the Android SDK.
  ///
  /// It is possible to have an Android SDK folder that is missing this with
  /// the expectation that it will be downloaded later, e.g. by gradle or the
  /// sdkmanager. The [licensesAvailable] property should be used to determine
  /// whether the licenses are at least possibly accepted.
  bool get platformToolsAvailable => globals.fs.directory(globals.fs.path.join(directory, 'platform-tools')).existsSync();

  /// Whether the `licenses` directory exists in the Android SDK.
  ///
  /// The existence of this folder normally indicates that the SDK licenses have
  /// been accepted, e.g. via the sdkmanager, Android Studio, or by copying them
  /// from another workstation such as in CI scenarios. If these files are valid
  /// gradle or the sdkmanager will be able to download and use other parts of
  /// the SDK on demand.
  bool get licensesAvailable => globals.fs.directory(globals.fs.path.join(directory, 'licenses')).existsSync();

  static AndroidSdk locateAndroidSdk() {
    String findAndroidHomeDir() {
      String androidHomeDir;
      if (globals.config.containsKey('android-sdk')) {
        androidHomeDir = globals.config.getValue('android-sdk') as String;
      } else if (globals.platform.environment.containsKey(kAndroidHome)) {
        androidHomeDir = globals.platform.environment[kAndroidHome];
      } else if (globals.platform.environment.containsKey(kAndroidSdkRoot)) {
        androidHomeDir = globals.platform.environment[kAndroidSdkRoot];
      } else if (globals.platform.isLinux) {
        if (globals.fsUtils.homeDirPath != null) {
          androidHomeDir = globals.fs.path.join(
            globals.fsUtils.homeDirPath,
            'Android',
            'Sdk',
          );
        }
      } else if (globals.platform.isMacOS) {
        if (globals.fsUtils.homeDirPath != null) {
          androidHomeDir = globals.fs.path.join(
            globals.fsUtils.homeDirPath,
            'Library',
            'Android',
            'sdk',
          );
        }
      } else if (globals.platform.isWindows) {
        if (globals.fsUtils.homeDirPath != null) {
          androidHomeDir = globals.fs.path.join(
            globals.fsUtils.homeDirPath,
            'AppData',
            'Local',
            'Android',
            'sdk',
          );
        }
      }

      if (androidHomeDir != null) {
        if (validSdkDirectory(androidHomeDir)) {
          return androidHomeDir;
        }
        if (validSdkDirectory(globals.fs.path.join(androidHomeDir, 'sdk'))) {
          return globals.fs.path.join(androidHomeDir, 'sdk');
        }
      }

      // in build-tools/$version/aapt
      final List<File> aaptBins = globals.os.whichAll('aapt');
      for (File aaptBin in aaptBins) {
        // Make sure we're using the aapt from the SDK.
        aaptBin = globals.fs.file(aaptBin.resolveSymbolicLinksSync());
        final String dir = aaptBin.parent.parent.parent.path;
        if (validSdkDirectory(dir)) {
          return dir;
        }
      }

      // in platform-tools/adb
      final List<File> adbBins = globals.os.whichAll('adb');
      for (File adbBin in adbBins) {
        // Make sure we're using the adb from the SDK.
        adbBin = globals.fs.file(adbBin.resolveSymbolicLinksSync());
        final String dir = adbBin.parent.parent.path;
        if (validSdkDirectory(dir)) {
          return dir;
        }
      }

      return null;
    }

    final String androidHomeDir = findAndroidHomeDir();
    if (androidHomeDir == null) {
      // No dice.
      globals.printTrace('Unable to locate an Android SDK.');
      return null;
    }

    // Try to find the NDK compiler. If we can't find it, it's also ok.
    AndroidNdk ndk;
    try {
      ndk = AndroidNdk.locateNdk(androidHomeDir);
    } on AndroidNdkSearchError {
      // Ignore AndroidNdkSearchError's but don't ignore any other
      // exceptions.
    }

    return AndroidSdk(androidHomeDir, ndk);
  }

  static bool validSdkDirectory(String dir) {
    return sdkDirectoryHasLicenses(dir) || sdkDirectoryHasPlatformTools(dir);
  }

  static bool sdkDirectoryHasPlatformTools(String dir) {
    return globals.fs.isDirectorySync(globals.fs.path.join(dir, 'platform-tools'));
  }

  static bool sdkDirectoryHasLicenses(String dir) {
    return globals.fs.isDirectorySync(globals.fs.path.join(dir, 'licenses'));
  }

  List<AndroidSdkVersion> get sdkVersions => _sdkVersions;

  AndroidSdkVersion get latestVersion => _latestVersion;

  String get adbPath => getPlatformToolsPath(globals.platform.isWindows ? 'adb.exe' : 'adb');

  String get emulatorPath => getEmulatorPath();

  String get avdManagerPath => getAvdManagerPath();

  Directory get _platformsDir => globals.fs.directory(globals.fs.path.join(directory, 'platforms'));

  Iterable<Directory> get _platforms {
    Iterable<Directory> platforms = <Directory>[];
    if (_platformsDir.existsSync()) {
      platforms = _platformsDir
        .listSync()
        .whereType<Directory>();
    }
    return platforms;
  }

  /// Validate the Android SDK. This returns an empty list if there are no
  /// issues; otherwise, it returns a list of issues found.
  List<String> validateSdkWellFormed() {
    if (adbPath == null || !globals.processManager.canRun(adbPath)) {
      return <String>['Android SDK file not found: ${adbPath ?? 'adb'}.'];
    }

    if (sdkVersions.isEmpty || latestVersion == null) {
      final StringBuffer msg = StringBuffer('No valid Android SDK platforms found in ${_platformsDir.path}.');
      if (_platforms.isEmpty) {
        msg.write(' Directory was empty.');
      } else {
        msg.write(' Candidates were:\n');
        msg.write(_platforms
          .map((Directory dir) => '  - ${dir.basename}')
          .join('\n'));
      }
      return <String>[msg.toString()];
    }

    return latestVersion.validateSdkWellFormed();
  }

  String getPlatformToolsPath(String binaryName) {
    final String path = globals.fs.path.join(directory, 'platform-tools', binaryName);
    if (globals.fs.file(path).existsSync()) {
      return path;
    }
    return null;
  }

  String getEmulatorPath() {
    final String binaryName = globals.platform.isWindows ? 'emulator.exe' : 'emulator';
    // Emulator now lives inside "emulator" but used to live inside "tools" so
    // try both.
    final List<String> searchFolders = <String>['emulator', 'tools'];
    for (final String folder in searchFolders) {
      final String path = globals.fs.path.join(directory, folder, binaryName);
      if (globals.fs.file(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  String getAvdManagerPath() {
    final String binaryName = globals.platform.isWindows ? 'avdmanager.bat' : 'avdmanager';
    final String path = globals.fs.path.join(directory, 'tools', 'bin', binaryName);
    if (globals.fs.file(path).existsSync()) {
      return path;
    }
    return null;
  }

  /// Sets up various paths used internally.
  ///
  /// This method should be called in a case where the tooling may have updated
  /// SDK artifacts, such as after running a gradle build.
  void reinitialize() {
    List<Version> buildTools = <Version>[]; // 19.1.0, 22.0.1, ...

    final Directory buildToolsDir = globals.fs.directory(globals.fs.path.join(directory, 'build-tools'));
    if (buildToolsDir.existsSync()) {
      buildTools = buildToolsDir
        .listSync()
        .map((FileSystemEntity entity) {
          try {
            return Version.parse(entity.basename);
          } catch (error) {
            return null;
          }
        })
        .where((Version version) => version != null)
        .toList();
    }

    // Match up platforms with the best corresponding build-tools.
    _sdkVersions = _platforms.map<AndroidSdkVersion>((Directory platformDir) {
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
              .map<Match>(_sdkVersionRe.firstMatch)
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

      if (buildToolsVersion == null) {
        return null;
      }

      return AndroidSdkVersion._(
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
    return globals.fs.path.join(directory, 'tools', 'bin', 'sdkmanager');
  }

  /// First try Java bundled with Android Studio, then sniff JAVA_HOME, then fallback to PATH.
  static String findJavaBinary() {
    if (android_studio.javaPath != null) {
      return globals.fs.path.join(android_studio.javaPath, 'bin', 'java');
    }

    final String javaHomeEnv = globals.platform.environment[_javaHomeEnvironmentVariable];
    if (javaHomeEnv != null) {
      // Trust JAVA_HOME.
      return globals.fs.path.join(javaHomeEnv, 'bin', 'java');
    }

    // MacOS specific logic to avoid popping up a dialog window.
    // See: http://stackoverflow.com/questions/14292698/how-do-i-check-if-the-java-jdk-is-installed-on-mac.
    if (globals.platform.isMacOS) {
      try {
        final String javaHomeOutput = processUtils.runSync(
          <String>['/usr/libexec/java_home'],
          throwOnError: true,
          hideStdout: true,
        ).stdout.trim();
        if (javaHomeOutput != null) {
          final List<String> javaHomeOutputSplit = javaHomeOutput.split('\n');
          if ((javaHomeOutputSplit != null) && (javaHomeOutputSplit.isNotEmpty)) {
            final String javaHome = javaHomeOutputSplit[0].trim();
            return globals.fs.path.join(javaHome, 'bin', 'java');
          }
        }
      } catch (_) { /* ignore */ }
    }

    // Fallback to PATH based lookup.
    return globals.os.which(_javaExecutable)?.path;
  }

  Map<String, String> _sdkManagerEnv;
  /// Returns an environment with the Java folder added to PATH for use in calling
  /// Java-based Android SDK commands such as sdkmanager and avdmanager.
  Map<String, String> get sdkManagerEnv {
    if (_sdkManagerEnv == null) {
      // If we can locate Java, then add it to the path used to run the Android SDK manager.
      _sdkManagerEnv = <String, String>{};
      final String javaBinary = findJavaBinary();
      if (javaBinary != null) {
        _sdkManagerEnv['PATH'] = globals.fs.path.dirname(javaBinary) +
                                 globals.os.pathVarSeparator +
                                 globals.platform.environment['PATH'];
      }
    }
    return _sdkManagerEnv;
  }

  /// Returns the version of the Android SDK manager tool or null if not found.
  String get sdkManagerVersion {
    if (!globals.processManager.canRun(sdkManagerPath)) {
      throwToolExit('Android sdkmanager not found. Update to the latest Android SDK to resolve this.');
    }
    final RunResult result = processUtils.runSync(
      <String>[sdkManagerPath, '--version'],
      environment: sdkManagerEnv,
    );
    if (result.exitCode != 0) {
      globals.printTrace('sdkmanager --version failed: exitCode: ${result.exitCode} stdout: ${result.stdout} stderr: ${result.stderr}');
      return null;
    }
    return result.stdout.trim();
  }

  @override
  String toString() => 'AndroidSdk: $directory';
}

class AndroidSdkVersion implements Comparable<AndroidSdkVersion> {
  AndroidSdkVersion._(
    this.sdk, {
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
    if (_exists(androidJarPath) != null) {
      return <String>[_exists(androidJarPath)];
    }

    if (_canRun(aaptPath) != null) {
      return <String>[_canRun(aaptPath)];
    }

    return <String>[];
  }

  String getPlatformsPath(String itemName) {
    return globals.fs.path.join(sdk.directory, 'platforms', platformName, itemName);
  }

  String getBuildToolsPath(String binaryName) {
    return globals.fs.path.join(sdk.directory, 'build-tools', buildToolsVersionName, binaryName);
  }

  @override
  int compareTo(AndroidSdkVersion other) => sdkLevel - other.sdkLevel;

  @override
  String toString() => '[${sdk.directory}, SDK version $sdkLevel, build-tools $buildToolsVersionName]';

  String _exists(String path) {
    if (!globals.fs.isFileSync(path)) {
      return 'Android SDK file not found: $path.';
    }
    return null;
  }

  String _canRun(String path) {
    if (!globals.processManager.canRun(path)) {
      return 'Android SDK file not found: $path.';
    }
    return null;
  }
}
