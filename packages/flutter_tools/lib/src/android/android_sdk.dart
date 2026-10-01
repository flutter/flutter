// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'application_package.dart';
library;

import 'package:process/process.dart';

import '../base/common.dart';
import '../base/config.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/signals.dart';
import '../base/terminal.dart';
import '../base/version.dart';
import '../convert.dart';
import 'java.dart';

// ANDROID_SDK_ROOT is deprecated.
// See https://developer.android.com/studio/command-line/variables.html#envar
const kAndroidSdkRoot = 'ANDROID_SDK_ROOT';
const kAndroidHome = 'ANDROID_HOME';

// No official environment variable for the NDK root is documented:
// https://developer.android.com/tools/variables#envar
// The follow three seem to be most commonly used.
const kAndroidNdkHome = 'ANDROID_NDK_HOME';
const kAndroidNdkPath = 'ANDROID_NDK_PATH';
const kAndroidNdkRoot = 'ANDROID_NDK_ROOT';

final _numberedAndroidPlatformRe = RegExp(r'^android-([0-9]+)$');
final _sdkVersionRe = RegExp(r'^ro.build.version.sdk=([0-9]+)$');

Logger _createDefaultLogger(Platform platform) {
  final stdio = Stdio();
  return StdoutLogger(
    terminal: AnsiTerminal(platform: platform, stdio: stdio),
    stdio: stdio,
    outputPreferences: OutputPreferences(
      wrapText: stdio.hasTerminal,
      showColor: platform.stdoutSupportsAnsi,
      stdio: stdio,
    ),
  );
}

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
class AndroidSdk {
  AndroidSdk(
    this.directory, {
    Config? config,
    this._java,
    Logger? logger,
    Platform? platform,
    ProcessManager? processManager,
  }) : _platform = platform ?? const LocalPlatform(),
       _config =
           config ??
           Config(
             Config.kFlutterSettings,
             fileSystem: directory.fileSystem,
             logger: logger ?? _createDefaultLogger(platform ?? const LocalPlatform()),
             platform: platform ?? const LocalPlatform(),
           ),
       _logger = logger ?? _createDefaultLogger(platform ?? const LocalPlatform()),
       _processManager = processManager ?? const LocalProcessManager(),
       _processUtils = ProcessUtils(
         logger: logger ?? _createDefaultLogger(platform ?? const LocalPlatform()),
         processManager: processManager ?? const LocalProcessManager(),
       );

  /// The Android SDK root directory.
  final Directory directory;

  final Config _config;
  final Java? _java;
  final Logger _logger;
  final Platform _platform;
  final ProcessManager _processManager;
  final ProcessUtils _processUtils;

  FileSystem get _fileSystem => directory.fileSystem;

  var _sdkVersions = <AndroidSdkVersion>[];
  AndroidSdkVersion? _latestVersion;
  bool _reinitialized = false;

  void _ensureInitialized() {
    if (_reinitialized) {
      return;
    }
    _reinitialized = true;
    reinitialize();
  }

  /// Whether the `cmdline-tools` directory exists in the Android SDK.
  ///
  /// This is required to use the newest SDK manager which only works with
  /// the newer JDK.
  bool get cmdlineToolsAvailable => directory.childDirectory('cmdline-tools').existsSync();

  /// Whether the `platform-tools` or `cmdline-tools` directory exists in the Android SDK.
  ///
  /// It is possible to have an Android SDK folder that is missing this with
  /// the expectation that it will be downloaded later, e.g. by gradle or the
  /// sdkmanager. The [licensesAvailable] property should be used to determine
  /// whether the licenses are at least possibly accepted.
  bool get platformToolsAvailable =>
      cmdlineToolsAvailable || directory.childDirectory('platform-tools').existsSync();

  /// Whether the `licenses` directory exists in the Android SDK.
  ///
  /// The existence of this folder normally indicates that the SDK licenses have
  /// been accepted, e.g. via the sdkmanager, Android Studio, or by copying them
  /// from another workstation such as in CI scenarios. If these files are valid
  /// gradle or the sdkmanager will be able to download and use other parts of
  /// the SDK on demand.
  bool get licensesAvailable => directory.childDirectory('licenses').existsSync();

  static AndroidSdk? locateAndroidSdk({
    Config? config,
    FileSystem? fileSystem,
    FileSystemUtils? fileSystemUtils,
    Logger? logger,
    OperatingSystemUtils? operatingSystemUtils,
    Platform? platform,
    ProcessManager? processManager,
  }) {
    final Platform resolvedPlatform = platform ?? const LocalPlatform();
    final FileSystem resolvedFileSystem =
        fileSystem ??
        ErrorHandlingFileSystem(
          delegate: LocalFileSystem(
            LocalSignals.instance,
            Signals.defaultExitSignals,
            ShutdownHooks(),
          ),
          platform: resolvedPlatform,
        );
    final FileSystemUtils resolvedFileSystemUtils =
        fileSystemUtils ??
        FileSystemUtils(fileSystem: resolvedFileSystem, platform: resolvedPlatform);
    final Logger resolvedLogger = logger ?? _createDefaultLogger(resolvedPlatform);
    final ProcessManager resolvedProcessManager = processManager ?? const LocalProcessManager();
    final Config resolvedConfig =
        config ??
        Config(
          Config.kFlutterSettings,
          fileSystem: resolvedFileSystem,
          logger: resolvedLogger,
          platform: resolvedPlatform,
        );
    final OperatingSystemUtils resolvedOsUtils =
        operatingSystemUtils ??
        OperatingSystemUtils(
          fileSystem: resolvedFileSystem,
          logger: resolvedLogger,
          platform: resolvedPlatform,
          processManager: resolvedProcessManager,
        );

    String? findAndroidHomeDir() {
      String? androidHomeDir;
      if (resolvedConfig.containsKey('android-sdk')) {
        androidHomeDir = resolvedConfig.getValue('android-sdk') as String?;
      } else if (resolvedPlatform.environment.containsKey(kAndroidHome)) {
        androidHomeDir = resolvedPlatform.environment[kAndroidHome];
      } else if (resolvedPlatform.environment.containsKey(kAndroidSdkRoot)) {
        androidHomeDir = resolvedPlatform.environment[kAndroidSdkRoot];
      } else if (resolvedPlatform.isLinux) {
        if (resolvedFileSystemUtils.homeDirPath != null) {
          androidHomeDir = resolvedFileSystem.path.join(
            resolvedFileSystemUtils.homeDirPath!,
            'Android',
            'Sdk',
          );
        }
      } else if (resolvedPlatform.isMacOS) {
        if (resolvedFileSystemUtils.homeDirPath != null) {
          androidHomeDir = resolvedFileSystem.path.join(
            resolvedFileSystemUtils.homeDirPath!,
            'Library',
            'Android',
            'sdk',
          );
        }
      } else if (resolvedPlatform.isWindows) {
        if (resolvedFileSystemUtils.homeDirPath != null) {
          androidHomeDir = resolvedFileSystem.path.join(
            resolvedFileSystemUtils.homeDirPath!,
            'AppData',
            'Local',
            'Android',
            'sdk',
          );
        }
      }

      if (androidHomeDir != null) {
        if (validSdkDirectory(androidHomeDir, fileSystem: resolvedFileSystem)) {
          return androidHomeDir;
        }
        final String subSdkDir = resolvedFileSystem.path.join(androidHomeDir, 'sdk');
        if (validSdkDirectory(subSdkDir, fileSystem: resolvedFileSystem)) {
          return subSdkDir;
        }
      }

      // in build-tools/$version/aapt
      for (File aaptBin in resolvedOsUtils.whichAll('aapt')) {
        // Make sure we're using the aapt from the SDK.
        aaptBin = resolvedFileSystem.file(aaptBin.resolveSymbolicLinksSync());
        final String dir = aaptBin.parent.parent.parent.path;
        if (validSdkDirectory(dir, fileSystem: resolvedFileSystem)) {
          return dir;
        }
      }

      // in platform-tools/adb
      for (File adbBin in resolvedOsUtils.whichAll('adb')) {
        // Make sure we're using the adb from the SDK.
        adbBin = resolvedFileSystem.file(adbBin.resolveSymbolicLinksSync());
        final String dir = adbBin.parent.parent.path;
        if (validSdkDirectory(dir, fileSystem: resolvedFileSystem)) {
          return dir;
        }
      }

      return null;
    }

    final String? androidHomeDir = findAndroidHomeDir();
    if (androidHomeDir == null) {
      // No dice.
      resolvedLogger.printTrace('Unable to locate an Android SDK.');
      return null;
    }

    return AndroidSdk(
      resolvedFileSystem.directory(androidHomeDir),
      config: resolvedConfig,
      logger: resolvedLogger,
      platform: resolvedPlatform,
      processManager: resolvedProcessManager,
    );
  }

  static bool validSdkDirectory(String dir, {FileSystem? fileSystem}) {
    return sdkDirectoryHasLicenses(dir, fileSystem: fileSystem) ||
        sdkDirectoryHasPlatformTools(dir, fileSystem: fileSystem);
  }

  static bool sdkDirectoryHasPlatformTools(String dir, {FileSystem? fileSystem}) {
    final FileSystem resolvedFileSystem =
        fileSystem ??
        LocalFileSystem(LocalSignals.instance, Signals.defaultExitSignals, ShutdownHooks());
    return resolvedFileSystem.isDirectorySync(resolvedFileSystem.path.join(dir, 'platform-tools'));
  }

  static bool sdkDirectoryHasLicenses(String dir, {FileSystem? fileSystem}) {
    final FileSystem resolvedFileSystem =
        fileSystem ??
        LocalFileSystem(LocalSignals.instance, Signals.defaultExitSignals, ShutdownHooks());
    return resolvedFileSystem.isDirectorySync(resolvedFileSystem.path.join(dir, 'licenses'));
  }

  List<AndroidSdkVersion> get sdkVersions {
    _ensureInitialized();
    return _sdkVersions;
  }

  AndroidSdkVersion? get latestVersion {
    _ensureInitialized();
    return _latestVersion;
  }

  late final String? adbPath = getPlatformToolsPath(_platform.isWindows ? 'adb.exe' : 'adb');

  String? get emulatorPath => getEmulatorPath();

  String? get avdManagerPath => getAvdManagerPath();

  /// Locate the path for storing AVD emulator images. Returns null if none found.
  String? getAvdPath() {
    final String? avdHome = _platform.environment['ANDROID_AVD_HOME'];
    final String? home = _platform.environment['HOME'];
    final searchPaths = <String>[
      ?avdHome,
      if (home != null) _fileSystem.path.join(home, '.android', 'avd'),
    ];

    if (_platform.isWindows) {
      final String? homeDrive = _platform.environment['HOMEDRIVE'];
      final String? homePath = _platform.environment['HOMEPATH'];

      if (homeDrive != null && homePath != null) {
        // Can't use path.join for HOMEDRIVE/HOMEPATH
        // https://github.com/dart-lang/path/issues/37
        final String home = homeDrive + homePath;
        searchPaths.add(_fileSystem.path.join(home, '.android', 'avd'));
      }
    }

    for (final searchPath in searchPaths) {
      if (_fileSystem.directory(searchPath).existsSync()) {
        return searchPath;
      }
    }
    return null;
  }

  Directory get _platformsDir => directory.childDirectory('platforms');

  Iterable<Directory> get _platforms {
    Iterable<Directory> platforms = <Directory>[];
    if (_platformsDir.existsSync()) {
      platforms = _platformsDir.listSync().whereType<Directory>();
    }
    return platforms;
  }

  /// Validate the Android SDK. This returns an empty list if there are no
  /// issues; otherwise, it returns a list of issues found.
  List<String> validateSdkWellFormed() {
    if (adbPath == null || !_processManager.canRun(adbPath)) {
      return <String>['Android SDK file not found: ${adbPath ?? 'adb'}.'];
    }

    if (sdkVersions.isEmpty || latestVersion == null) {
      final msg = StringBuffer('No valid Android SDK platforms found in ${_platformsDir.path}.');
      if (_platforms.isEmpty) {
        msg.write(' Directory was empty.');
      } else {
        msg.write(' Candidates were:\n');
        msg.write(_platforms.map((Directory dir) => '  - ${dir.basename}').join('\n'));
      }
      return <String>[msg.toString()];
    }

    if (directory.absolute.path.contains(' ')) {
      final androidSdkSpaceWarning =
          'Android SDK location currently '
          'contains spaces, which is not supported by the Android SDK as it '
          'causes problems with NDK tools. Try moving it from '
          '${directory.absolute.path} to a path without spaces.';
      return <String>[androidSdkSpaceWarning];
    }

    return latestVersion!.validateSdkWellFormed();
  }

  String? getPlatformToolsPath(String binaryName) {
    final File cmdlineToolsBinary = directory.childDirectory('cmdline-tools').childFile(binaryName);
    if (cmdlineToolsBinary.existsSync()) {
      return cmdlineToolsBinary.path;
    }
    final File platformToolBinary = directory
        .childDirectory('platform-tools')
        .childFile(binaryName);
    if (platformToolBinary.existsSync()) {
      return platformToolBinary.path;
    }
    return null;
  }

  String? getEmulatorPath() {
    final binaryName = _platform.isWindows ? 'emulator.exe' : 'emulator';
    // Emulator now lives inside "emulator" but used to live inside "tools" so
    // try both.
    final searchFolders = <String>['emulator', 'tools'];
    for (final folder in searchFolders) {
      final File file = directory.childDirectory(folder).childFile(binaryName);
      if (file.existsSync()) {
        return file.path;
      }
    }
    return null;
  }

  String? getCmdlineToolsPath(String binaryName, {bool skipOldTools = false}) {
    // First look for the latest version of the command-line tools
    final File cmdlineToolsLatestBinary = directory
        .childDirectory('cmdline-tools')
        .childDirectory('latest')
        .childDirectory('bin')
        .childFile(binaryName);
    if (cmdlineToolsLatestBinary.existsSync()) {
      return cmdlineToolsLatestBinary.path;
    }

    // Next look for the highest version of the command-line tools
    final Directory cmdlineToolsDir = directory.childDirectory('cmdline-tools');
    if (cmdlineToolsDir.existsSync()) {
      final cmdlineTools = <Version>[
        ...cmdlineToolsDir.listSync().whereType<Directory>().map((Directory subDirectory) {
          try {
            return Version.parse(subDirectory.basename);
          } on Exception {
            return null;
          }
        }).whereType<Version>(),
      ]..sort();

      for (final Version cmdlineToolsVersion in cmdlineTools.reversed) {
        final File cmdlineToolsBinary = directory
            .childDirectory('cmdline-tools')
            .childDirectory(cmdlineToolsVersion.toString())
            .childDirectory('bin')
            .childFile(binaryName);
        if (cmdlineToolsBinary.existsSync()) {
          return cmdlineToolsBinary.path;
        }
      }
    }
    if (skipOldTools) {
      return null;
    }

    // Finally fallback to the old SDK tools
    final File toolsBinary = directory
        .childDirectory('tools')
        .childDirectory('bin')
        .childFile(binaryName);
    if (toolsBinary.existsSync()) {
      return toolsBinary.path;
    }

    return null;
  }

  String? getAvdManagerPath() =>
      getCmdlineToolsPath(_platform.isWindows ? 'avdmanager.bat' : 'avdmanager');

  /// From https://developer.android.com/ndk/guides/other_build_systems.
  static const _llvmHostDirectoryName = <String, String>{
    'macos': 'darwin-x86_64',
    'linux': 'linux-x86_64',
    'windows': 'windows-x86_64',
  };

  /// Locates the binary path for an NDK binary.
  ///
  /// The order of resolution is as follows:
  ///
  /// 1. If [Config] defines an `'android-ndk'` use that.
  /// 2. If the environment variable `ANDROID_NDK_HOME` is defined, use that.
  /// 3. If the environment variable `ANDROID_NDK_PATH` is defined, use that.
  /// 4. If the environment variable `ANDROID_NDK_ROOT` is defined, use that.
  /// 5. Look for the default install location inside the Android SDK:
  ///    [directory]/ndk/\<version\>/. If multiple versions exist, use the
  ///    newest.
  Iterable<Directory> getNdkDirectoriesInResolutionOrder({Platform? platform, Config? config}) {
    platform ??= _platform;
    config ??= _config;

    final ndkDirectories = <Directory>[];
    String? androidNdkHomeDir;
    if (config.containsKey('android-ndk')) {
      androidNdkHomeDir = config.getValue('android-ndk') as String?;
    } else if (platform.environment.containsKey(kAndroidNdkHome)) {
      androidNdkHomeDir = platform.environment[kAndroidNdkHome];
    } else if (platform.environment.containsKey(kAndroidNdkPath)) {
      androidNdkHomeDir = platform.environment[kAndroidNdkPath];
    } else if (platform.environment.containsKey(kAndroidNdkRoot)) {
      androidNdkHomeDir = platform.environment[kAndroidNdkRoot];
    }
    if (androidNdkHomeDir != null) {
      ndkDirectories.add(directory.fileSystem.directory(androidNdkHomeDir));
    }

    // Look for the default install location of the NDK inside the Android
    // SDK when installed through `sdkmanager` or Android studio.
    final Directory ndk = directory.childDirectory('ndk');
    if (!ndk.existsSync()) {
      return ndkDirectories;
    }
    final ndkVersions = <Version>[
      ...ndk.listSync().map((FileSystemEntity entity) {
        try {
          return Version.parse(entity.basename);
        } on Exception {
          return null;
        }
      }).whereType<Version>(),
      // Use latest NDK first.
    ]..sort((Version a, Version b) => -a.compareTo(b));
    for (final ndkVersion in ndkVersions) {
      ndkDirectories.add(ndk.childDirectory(ndkVersion.toString()));
    }
    return ndkDirectories;
  }

  String? getNdkBinaryPath(String binaryName, {Platform? platform, Config? config}) {
    platform ??= _platform;
    config ??= _config;
    for (final Directory androidNdkHomeDir in getNdkDirectoriesInResolutionOrder(
      platform: platform,
      config: config,
    )) {
      final File executable = androidNdkHomeDir
          .childDirectory('toolchains')
          .childDirectory('llvm')
          .childDirectory('prebuilt')
          .childDirectory(_llvmHostDirectoryName[platform.operatingSystem]!)
          .childDirectory('bin')
          .childFile(binaryName);
      if (executable.existsSync()) {
        // LLVM missing in this NDK version.
        return executable.path;
      }
    }
    return null;
  }

  String? getNdkClangPath({Platform? platform, Config? config}) {
    platform ??= _platform;
    return getNdkBinaryPath(
      platform.isWindows ? 'clang.exe' : 'clang',
      platform: platform,
      config: config,
    );
  }

  String? getNdkArPath({Platform? platform, Config? config}) {
    platform ??= _platform;
    return getNdkBinaryPath(
      platform.isWindows ? 'llvm-ar.exe' : 'llvm-ar',
      platform: platform,
      config: config,
    );
  }

  String? getNdkLdPath({Platform? platform, Config? config}) {
    platform ??= _platform;
    return getNdkBinaryPath(
      platform.isWindows ? 'ld.lld.exe' : 'ld.lld',
      platform: platform,
      config: config,
    );
  }

  /// Sets up various paths used internally.
  ///
  /// This method should be called in a case where the tooling may have updated
  /// SDK artifacts, such as after running a gradle build.
  void reinitialize() {
    _reinitialized = true;
    var buildTools = <Version>[]; // 19.1.0, 22.0.1, ...

    final Directory buildToolsDir = directory.childDirectory('build-tools');
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
          .whereType<Version>()
          .toList();
    }

    // Match up platforms with the best corresponding build-tools.
    _sdkVersions = _platforms
        .map<AndroidSdkVersion?>((Directory platformDir) {
          final String platformName = platformDir.basename;
          int platformVersion;

          try {
            final Match? numberedVersion = _numberedAndroidPlatformRe.firstMatch(platformName);
            if (numberedVersion != null) {
              platformVersion = int.parse(numberedVersion.group(1)!);
            } else {
              final String buildProps = platformDir.childFile('build.prop').readAsStringSync();
              final Iterable<Match> versionMatches = const LineSplitter()
                  .convert(buildProps)
                  .map<RegExpMatch?>(_sdkVersionRe.firstMatch)
                  .whereType<Match>();

              if (versionMatches.isEmpty) {
                return null;
              }

              final String? versionString = versionMatches.first.group(1);
              if (versionString == null) {
                return null;
              }
              platformVersion = int.parse(versionString);
            }
          } on Exception {
            return null;
          }

          Version? buildToolsVersion = Version.primary(
            buildTools.where((Version version) {
              return version.major == platformVersion;
            }).toList(),
          );

          buildToolsVersion ??= Version.primary(buildTools);

          if (buildToolsVersion == null) {
            return null;
          }

          return AndroidSdkVersion._(
            this,
            buildToolsVersion: buildToolsVersion,
            fileSystem: directory.fileSystem,
            platformName: platformName,
            processManager: _processManager,
            sdkLevel: platformVersion,
          );
        })
        .whereType<AndroidSdkVersion>()
        .toList();

    _sdkVersions.sort();

    _latestVersion = _sdkVersions.isEmpty ? null : _sdkVersions.last;
  }

  /// Returns the filesystem path of the Android SDK manager tool.
  String? get sdkManagerPath {
    final executable = _platform.isWindows ? 'sdkmanager.bat' : 'sdkmanager';
    return getCmdlineToolsPath(executable, skipOldTools: true);
  }

  /// Returns the version of the Android SDK manager tool or null if not found.
  String? get sdkManagerVersion {
    if (sdkManagerPath == null || !_processManager.canRun(sdkManagerPath)) {
      throwToolExit(
        'Android sdkmanager not found. Update to the latest Android SDK and ensure that '
        'the cmdline-tools are installed to resolve this.',
      );
    }
    final RunResult result = _processUtils.runSync(<String>[
      sdkManagerPath!,
      '--version',
    ], environment: _java?.environment);
    if (result.exitCode != 0) {
      _logger.printTrace(
        'sdkmanager --version failed: exitCode: ${result.exitCode} stdout: ${result.stdout} stderr: ${result.stderr}',
      );
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
    required this.buildToolsVersion,
    required this._fileSystem,
    required this.platformName,
    required this._processManager,
    required this.sdkLevel,
  });

  final AndroidSdk sdk;
  final int sdkLevel;
  final String platformName;
  final Version buildToolsVersion;

  final FileSystem _fileSystem;
  final ProcessManager _processManager;

  String get buildToolsVersionName => buildToolsVersion.toString();

  String get androidJarPath => getPlatformsPath('android.jar');

  /// Return the path to the android application package tool.
  ///
  /// This is used to dump the xml in order to launch built android applications.
  ///
  /// See also:
  ///   * [AndroidApk.fromApk], which depends on this to determine application identifiers.
  String get aaptPath => getBuildToolsPath('aapt');

  List<String> validateSdkWellFormed() {
    final String? existsAndroidJarPath = _exists(androidJarPath);
    if (existsAndroidJarPath != null) {
      return <String>[existsAndroidJarPath];
    }

    final String? canRunAaptPath = _canRun(aaptPath);
    if (canRunAaptPath != null) {
      return <String>[canRunAaptPath];
    }

    return <String>[];
  }

  String getPlatformsPath(String itemName) {
    return sdk.directory
        .childDirectory('platforms')
        .childDirectory(platformName)
        .childFile(itemName)
        .path;
  }

  String getBuildToolsPath(String binaryName) {
    return sdk.directory
        .childDirectory('build-tools')
        .childDirectory(buildToolsVersionName)
        .childFile(binaryName)
        .path;
  }

  @override
  int compareTo(AndroidSdkVersion other) => sdkLevel - other.sdkLevel;

  @override
  String toString() =>
      '[${sdk.directory}, SDK version $sdkLevel, build-tools $buildToolsVersionName]';

  String? _exists(String path) {
    if (!_fileSystem.isFileSync(path)) {
      return 'Android SDK file not found: $path.';
    }
    return null;
  }

  String? _canRun(String path) {
    if (!_processManager.canRun(path)) {
      return 'Android SDK file not found: $path.';
    }
    return null;
  }
}
