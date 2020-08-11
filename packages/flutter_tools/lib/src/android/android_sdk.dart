// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../base/common.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../convert.dart';
import 'android_studio.dart';

// ANDROID_HOME is deprecated.
// See https://developer.android.com/studio/command-line/variables.html#envar
const String kAndroidHome = 'ANDROID_HOME';
const String kAndroidSdkRoot = 'ANDROID_SDK_ROOT';


final RegExp _numberedAndroidPlatformRe = RegExp(r'^android-([0-9]+)$');
final RegExp _sdkVersionRe = RegExp(r'^ro.build.version.sdk=([0-9]+)$');

/// The minimum Android SDK version we support.
const int minimumAndroidSdkVersion = 25;

/// The interface to the Android SDK libraries and tools.
///
/// Android SDK layout:
/// $ANDROID_SDK_ROOT/platform-tools/adb
/// $ANDROID_SDK_ROOT/build-tools/19.1.0/aapt, dx, zipalign
/// $ANDROID_SDK_ROOT/build-tools/22.0.1/aapt
/// $ANDROID_SDK_ROOT/build-tools/23.0.2/aapt
/// $ANDROID_SDK_ROOT/build-tools/24.0.0-preview/aapt
/// $ANDROID_SDK_ROOT/build-tools/25.0.2/apksigner
/// $ANDROID_SDK_ROOT/platforms/android-22/android.jar
/// $ANDROID_SDK_ROOT/platforms/android-23/android.jar
/// $ANDROID_SDK_ROOT/platforms/android-N/android.jar
class AndroidSdk {
  AndroidSdk(this.directory, {
    @required FileSystem fileSystem,
    @required Platform platform,
    @required ProcessManager processManager,
    @required OperatingSystemUtils operatingSystemUtils,
    @required AndroidStudio androidStudio,
    @required Logger logger,
  }) : _fileSystem = fileSystem,
       _platform = platform,
       _processManager = processManager,
       _operatingSystemUtils = operatingSystemUtils,
       _androidStudio = androidStudio,
       _logger = logger {
    reinitialize();
  }

  static const String _javaHomeEnvironmentVariable = 'JAVA_HOME';
  static const String _javaExecutable = 'java';

  /// The path to the Android SDK.
  final String directory;

  final FileSystem _fileSystem;
  final Platform _platform;
  final ProcessManager _processManager;
  final OperatingSystemUtils _operatingSystemUtils;
  final AndroidStudio _androidStudio;
  final Logger _logger;

  List<AndroidSdkVersion> _sdkVersions;
  AndroidSdkVersion _latestVersion;

  /// Whether the `platform-tools` or `cmdline-tools` directory exists in the Android SDK.
  ///
  /// It is possible to have an Android SDK folder that is missing this with
  /// the expectation that it will be downloaded later, e.g. by gradle or the
  /// sdkmanager. The [licensesAvailable] property should be used to determine
  /// whether the licenses are at least possibly accepted.
  bool get platformToolsAvailable =>
    _fileSystem.directory(_fileSystem.path.join(directory, 'cmdline-tools')).existsSync() ||
    _fileSystem.directory(_fileSystem.path.join(directory, 'platform-tools')).existsSync();

  /// Whether the `licenses` directory exists in the Android SDK.
  ///
  /// The existence of this folder normally indicates that the SDK licenses have
  /// been accepted, e.g. via the sdkmanager, Android Studio, or by copying them
  /// from another workstation such as in CI scenarios. If these files are valid
  /// gradle or the sdkmanager will be able to download and use other parts of
  /// the SDK on demand.
  bool get licensesAvailable => _fileSystem.directory(_fileSystem.path.join(directory, 'licenses')).existsSync();

  static AndroidSdk locateAndroidSdk({
    @required FileSystem fileSystem,
    @required Config config,
    @required Platform platform,
    @required OperatingSystemUtils operatingSystemUtils,
    @required Logger logger,
    @required AndroidStudio androidStudio,
    @required ProcessManager processManager,
  }) {
    final FileSystemUtils fileSystemUtils = FileSystemUtils(platform: platform, fileSystem: fileSystem);
    String findAndroidHomeDir() {
      String androidHomeDir;
      if (config.containsKey('android-sdk')) {
        androidHomeDir = config.getValue('android-sdk') as String;
      } else if (platform.environment.containsKey(kAndroidHome)) {
        androidHomeDir = platform.environment[kAndroidHome];
      } else if (platform.environment.containsKey(kAndroidSdkRoot)) {
        androidHomeDir = platform.environment[kAndroidSdkRoot];
      } else if (platform.isLinux) {
        if (fileSystemUtils.homeDirPath != null) {
          androidHomeDir = fileSystem.path.join(
            fileSystemUtils.homeDirPath,
            'Android',
            'Sdk',
          );
        }
      } else if (platform.isMacOS) {
        if (fileSystemUtils.homeDirPath != null) {
          androidHomeDir = fileSystem.path.join(
            fileSystemUtils.homeDirPath,
            'Library',
            'Android',
            'sdk',
          );
        }
      } else if (platform.isWindows) {
        if (fileSystemUtils.homeDirPath != null) {
          androidHomeDir = fileSystem.path.join(
            fileSystemUtils.homeDirPath,
            'AppData',
            'Local',
            'Android',
            'sdk',
          );
        }
      }

      if (androidHomeDir != null) {
        if (validSdkDirectory(androidHomeDir, fileSystem: fileSystem)) {
          return androidHomeDir;
        }
        if (validSdkDirectory(fileSystem.path.join(androidHomeDir, 'sdk'), fileSystem: fileSystem)) {
          return fileSystem.path.join(androidHomeDir, 'sdk');
        }
      }

      // in build-tools/$version/aapt
      final List<File> aaptBins = operatingSystemUtils.whichAll('aapt');
      for (File aaptBin in aaptBins) {
        // Make sure we're using the aapt from the SDK.
        aaptBin = fileSystem.file(aaptBin.resolveSymbolicLinksSync());
        final String dir = aaptBin.parent.parent.parent.path;
        if (validSdkDirectory(dir, fileSystem: fileSystem)) {
          return dir;
        }
      }

      // in platform-tools/adb
      final List<File> adbBins = operatingSystemUtils.whichAll('adb');
      for (File adbBin in adbBins) {
        // Make sure we're using the adb from the SDK.
        adbBin = fileSystem.file(adbBin.resolveSymbolicLinksSync());
        final String dir = adbBin.parent.parent.path;
        if (validSdkDirectory(dir, fileSystem: fileSystem)) {
          return dir;
        }
      }

      return null;
    }

    final String androidHomeDir = findAndroidHomeDir();
    if (androidHomeDir == null) {
      logger.printTrace('Unable to locate an Android SDK.');
    }

    return AndroidSdk(
      androidHomeDir,
      androidStudio: androidStudio,
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: operatingSystemUtils,
      logger: logger,
    );
  }

  static bool validSdkDirectory(String dir, {
    @required FileSystem fileSystem,
  }) {
    return sdkDirectoryHasLicenses(dir, fileSystem: fileSystem) ||
      sdkDirectoryHasPlatformTools(dir, fileSystem: fileSystem);
  }

  static bool sdkDirectoryHasPlatformTools(String dir, {
    @required FileSystem fileSystem,
  }) {
    return fileSystem.isDirectorySync(fileSystem.path.join(dir, 'platform-tools'));
  }

  static bool sdkDirectoryHasLicenses(String dir, {
    @required FileSystem fileSystem,
  }) {
    return fileSystem.isDirectorySync(fileSystem.path.join(dir, 'licenses'));
  }

  /// All downloaded Android SDK versions.
  ///
  /// This may be an empty list if the SDK is not fully materialized yet, or if
  /// the sdk was not correctly located.
  ///
  /// To verify that the Android SDK was downloaded, check that
  /// [latestVersion] is non `null`.
  List<AndroidSdkVersion> get sdkVersions => _sdkVersions;

  /// The latest version of the SDK tools in the currently located SDK.
  ///
  /// Returns `null` if the Android SDK is not downloaded.
  AndroidSdkVersion get latestVersion => _latestVersion;

  /// The path to the Android Debug Bridge (adb) executable.
  String get adbPath => getPlatformToolsPath(_platform.isWindows ? 'adb.exe' : 'adb');

  String get emulatorPath => getEmulatorPath();

  String get avdManagerPath => getAvdManagerPath();

  Directory get _platformsDir => _fileSystem.directory(_fileSystem.path.join(directory, 'platforms'));

  Iterable<Directory> get _platforms {
    Iterable<Directory> platforms = <Directory>[];
    if (_platformsDir.existsSync()) {
      platforms = _platformsDir
        .listSync()
        .whereType<Directory>();
    }
    return platforms;
  }

  /// Locate the path for storing AVD emulator images. Returns null if none found.
  String getAvdPath() {
    final List<String> searchPaths = <String>[
      _platform.environment['ANDROID_AVD_HOME'],
      if (_platform.environment['HOME'] != null)
        _fileSystem.path.join(_platform.environment['HOME'], '.android', 'avd'),
    ];

    if (_platform.isWindows) {
      final String homeDrive = _platform.environment['HOMEDRIVE'];
      final String homePath = _platform.environment['HOMEPATH'];

      if (homeDrive != null && homePath != null) {
        // Can't use path.join for HOMEDRIVE/HOMEPATH
        // https://github.com/dart-lang/path/issues/37
        final String home = homeDrive + homePath;
        searchPaths.add(_fileSystem.path.join(home, '.android', 'avd'));
      }
    }

    return searchPaths.where((String p) => p != null).firstWhere(
      (String p) => _fileSystem.directory(p).existsSync(),
      orElse: () => null,
    );
  }

  /// Validate the Android SDK. This returns an empty list if there are no
  /// issues. otherwise, it returns a list of issues found.
  List<String> validateSdkWellFormed() {
    if (adbPath == null || !_processManager.canRun(adbPath)) {
      return <String>['Android SDK file not found: ${adbPath ?? 'adb'}.'];
    }

    if (latestVersion == null || sdkVersions.isEmpty) {
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

    return latestVersion.validateSdkWellFormed(
      fileSystem: _fileSystem,
      processManager: _processManager,
    );
  }

  String getPlatformToolsPath(String binaryName) {
    final String path = _fileSystem.path.join(directory, 'platform-tools', binaryName);
    if (_fileSystem.file(path).existsSync()) {
      return path;
    }
    return _operatingSystemUtils.which(binaryName)?.path;
  }

  /// Returns the emulator executable path.
  ///
  /// First checks for this inside the located android SDK. If this cannot be found,
  /// returns the result of `which`/`where`.
  String getEmulatorPath() {
    final String binaryName = _platform.isWindows ? 'emulator.exe' : 'emulator';
    // Emulator now lives inside "emulator" but used to live inside "tools" so
    // try both.
    final List<String> searchFolders = <String>['emulator', 'tools'];
    for (final String folder in searchFolders) {
      final String path = _fileSystem.path.join(directory, folder, binaryName);
      if (_fileSystem.file(path).existsSync()) {
        return path;
      }
    }
    return _operatingSystemUtils.which(binaryName)?.path;
  }

  String getAvdManagerPath() {
    final String binaryName = _platform.isWindows ? 'avdmanager.bat' : 'avdmanager';
    final String path = _fileSystem.path.join(directory, 'tools', 'bin', binaryName);
    if (_fileSystem.file(path).existsSync()) {
      return path;
    }
    return _operatingSystemUtils.which(binaryName)?.path;
  }

  /// Sets up various paths used internally.
  ///
  /// This method should be called in a case where the tooling may have updated
  /// SDK artifacts, such as after running a gradle build.
  void reinitialize() {
    List<Version> buildTools = <Version>[]; // 19.1.0, 22.0.1, ...

    final Directory buildToolsDir = _fileSystem.directory(_fileSystem.path.join(directory, 'build-tools'));
    if (buildToolsDir.existsSync()) {
      buildTools = buildToolsDir
        .listSync()
        .map((FileSystemEntity entity) {
          try {
            return Version.parse(entity.basename);
          } on Exception {
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
      } on Exception {
        return null;
      }

      Version buildToolsVersion = Version.primary(buildTools.where((Version version) {
        return version.major == platformVersion;
      }).toList());

      buildToolsVersion ??= Version.primary(buildTools);

      if (buildToolsVersion == null) {
        return null;
      }

      return AndroidSdkVersion(
        this,
        sdkLevel: platformVersion,
        platformName: platformName,
        buildToolsVersion: buildToolsVersion,
      );
    }).where((AndroidSdkVersion version) => version != null).toList();

    _sdkVersions.sort();

    _latestVersion = _sdkVersions.isEmpty ? null : _sdkVersions.last;
  }

  /// Returns the filesystem path of the Android SDK manager tool.
  ///
  /// The sdkmanager was previously in the tools directory but this component
  /// was marked as obsolete in 3.6.
  String get sdkManagerPath {
    final File cmdlineTool = _fileSystem.file(
      _fileSystem.path.join(directory, 'cmdline-tools', 'latest', 'bin',
        _platform.isWindows
          ? 'sdkmanager.bat'
          : 'sdkmanager'
      ),
    );
    if (cmdlineTool.existsSync()) {
      return cmdlineTool.path;
    }
    return _fileSystem.path.join(directory, 'tools', 'bin', 'sdkmanager');
  }

  /// First try Java bundled with Android Studio, then sniff JAVA_HOME, then fallback to PATH.
  static Future<String> findJavaBinary({
    @required AndroidStudio androidStudio,
    @required FileSystem fileSystem,
    @required OperatingSystemUtils operatingSystemUtils,
    @required Platform platform,
    @required ProcessUtils processUtils,
  }) async {
    if (androidStudio?.javaPath != null) {
      return fileSystem.path.join(androidStudio.javaPath, 'bin', 'java');
    }

    final String javaHomeEnv = platform.environment[_javaHomeEnvironmentVariable];
    if (javaHomeEnv != null) {
      // Trust JAVA_HOME.
      return fileSystem.path.join(javaHomeEnv, 'bin', 'java');
    }

    // MacOS specific logic to avoid popping up a dialog window.
    // See: http://stackoverflow.com/questions/14292698/how-do-i-check-if-the-java-jdk-is-installed-on-mac.
    if (platform.isMacOS) {
      try {
        final String javaHomeOutput = (await processUtils.run(
          <String>['/usr/libexec/java_home', '-v', '1.8'],
          throwOnError: true,
        )).stdout.trim();
        if (javaHomeOutput != null) {
          if ((javaHomeOutput != null) && (javaHomeOutput.isNotEmpty)) {
            final String javaHome = javaHomeOutput.split('\n').last.trim();
            return fileSystem.path.join(javaHome, 'bin', 'java');
          }
        }
      } on Exception { /* ignore */ }
    }

    // Fallback to PATH based lookup.
    return operatingSystemUtils.which(_javaExecutable)?.path;
  }

  Map<String, String> _sdkManagerEnv;
  /// Returns an environment with the Java folder added to PATH for use in calling
  /// Java-based Android SDK commands such as sdkmanager and avdmanager.
  Future<Map<String, String>> get sdkManagerEnv async {
    if (_sdkManagerEnv == null) {
      // If we can locate Java, then add it to the path used to run the Android SDK manager.
      _sdkManagerEnv = <String, String>{};
      final String javaBinary = await findJavaBinary(
        androidStudio: _androidStudio,
        fileSystem: _fileSystem,
        operatingSystemUtils: _operatingSystemUtils,
        platform: _platform,
        processUtils: ProcessUtils(processManager: _processManager, logger: _logger),
      );
      // This is probably the cause of the Java version bug.
      if (javaBinary != null) {
        _sdkManagerEnv['PATH'] = _fileSystem.path.dirname(javaBinary) +
                                 _operatingSystemUtils.pathVarSeparator +
                                 _platform.environment['PATH'];
      }
    }
    return _sdkManagerEnv;
  }

  /// Returns the version of the Android SDK manager tool or null if not found.
  Future<String> get sdkManagerVersion async {
    if (!_processManager.canRun(sdkManagerPath)) {
      throwToolExit('Android sdkmanager not found. Update to the latest Android SDK to resolve this.');
    }
    final ProcessResult result = await _processManager.run(
      <String>[sdkManagerPath, '--version'],
      environment: await sdkManagerEnv,
    );
    if (result.exitCode != 0) {
      _logger.printTrace('sdkmanager --version failed: exitCode: ${result.exitCode} stdout: ${result.stdout} stderr: ${result.stderr}');
      return null;
    }
    return result.stdout.toString().trim();
  }

  @override
  String toString() => 'AndroidSdk: $directory';
}

class AndroidSdkVersion implements Comparable<AndroidSdkVersion> {
  AndroidSdkVersion(
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

  String androidJarPath({@required FileSystem fileSystem}) => getPlatformsPath('android.jar', fileSystem: fileSystem);

  String aaptPath({@required FileSystem fileSystem}) => getBuildToolsPath('aapt', fileSystem: fileSystem);

  List<String> validateSdkWellFormed({
    @required ProcessManager processManager,
    @required FileSystem fileSystem,
  }) {
    if (_exists(androidJarPath(fileSystem: fileSystem), fileSystem) != null) {
      return <String>[_exists(androidJarPath(fileSystem: fileSystem), fileSystem)];
    }
    if (_canRun(aaptPath(fileSystem: fileSystem), processManager) != null) {
      return <String>[_canRun(aaptPath(fileSystem: fileSystem), processManager)];
    }
    return <String>[];
  }

  String getPlatformsPath(String itemName, {@required FileSystem fileSystem}) {
    return fileSystem.path.join(sdk.directory, 'platforms', platformName, itemName);
  }

  String getBuildToolsPath(String binaryName, {@required FileSystem fileSystem}) {
    return fileSystem.path.join(sdk.directory, 'build-tools', buildToolsVersionName, binaryName);
  }

  @override
  int compareTo(AndroidSdkVersion other) => sdkLevel - other.sdkLevel;

  @override
  String toString() => '[${sdk.directory}, SDK version $sdkLevel, build-tools $buildToolsVersionName]';

  String _exists(String path, FileSystem fileSystem) {
    if (!fileSystem.isFileSync(path)) {
      return 'Android SDK file not found: $path.';
    }
    return null;
  }

  String _canRun(String path, ProcessManager processManager) {
    if (!processManager.canRun(path)) {
      return 'Android SDK file not found: $path.';
    }
    return null;
  }
}
