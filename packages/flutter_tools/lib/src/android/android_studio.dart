// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'java.dart';
library;

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../base/common.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../base/version.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../ios/plist_parser.dart';

const _androidStudioTitle = 'Android Studio';
const _androidStudioId = 'AndroidStudio';
const _androidStudioPreviewTitle = 'Android Studio Preview';
const _androidStudioPreviewId = 'AndroidStudioPreview';

// Android Studio layout:

// Linux/Windows:
// $HOME/.AndroidStudioX.Y/system/.home
// $HOME/.cache/Google/AndroidStudioX.Y/.home

// macOS:
// /Applications/Android Studio.app/Contents/
// $HOME/Applications/Android Studio.app/Contents/

// Match Android Studio >= 4.1 base folder (AndroidStudio*.*)
// and < 4.1 (.AndroidStudio*.*)
final _dotHomeStudioVersionMatcher = RegExp(r'^\.?(AndroidStudio[^\d]*)([\d.]+)');

class AndroidStudio {
  /// A [version] value of null represents an unknown version.
  AndroidStudio(
    this.directory, {
    this.version,
    this.configuredPath,
    this.studioAppName = 'AndroidStudio',
    this.presetPluginsPath,
    @visibleForTesting Platform? platform,
    @visibleForTesting FileSystem? fileSystem,
    @visibleForTesting ProcessManager? processManager,
    @visibleForTesting Logger? logger,
  }) : _platform = platform ?? globals.platform,
       _fileSystem = fileSystem ?? globals.fs,
       _processManager = processManager ?? globals.processManager,
       _processUtils = ProcessUtils(
         processManager: processManager ?? globals.processManager,
         logger: logger ?? globals.logger,
       ) {
    _initAndValidate();
  }

  final Platform _platform;
  final FileSystem _fileSystem;
  final ProcessManager _processManager;
  final ProcessUtils _processUtils;

  static AndroidStudio? fromMacOSBundle(
    String bundlePath, {
    String? configuredPath,
    FileSystem? fileSystem,
    PlistParser? plistParser,
    Platform? platform,
    ProcessManager? processManager,
  }) {
    final FileSystem fs = fileSystem ?? globals.fs;
    final PlistParser parser = plistParser ?? globals.plistParser;
    final Platform plt = platform ?? globals.platform;
    final fsUtils = FileSystemUtils(fileSystem: fs, platform: plt);

    final String studioPath = fs.path.join(bundlePath, 'Contents');
    final String plistFile = fs.path.join(studioPath, 'Info.plist');
    final Map<String, dynamic> plistValues = parser.parseFile(plistFile);
    // If we've found a JetBrainsToolbox wrapper, ignore it.
    if (plistValues.containsKey('JetBrainsToolboxApp')) {
      return null;
    }

    final versionString = plistValues[PlistParser.kCFBundleShortVersionStringKey] as String?;

    Version? version;
    if (versionString != null) {
      version = _parseVersion(versionString);
    }

    String? pathsSelectorValue;
    final Map<String, dynamic>? jvmOptions = castStringKeyedMap(plistValues['JVMOptions']);
    if (jvmOptions != null) {
      final Map<String, dynamic>? jvmProperties = castStringKeyedMap(jvmOptions['Properties']);
      if (jvmProperties != null) {
        pathsSelectorValue = jvmProperties['idea.paths.selector'] as String;
      }
    }

    final int? major = version?.major;
    final int? minor = version?.minor;
    String? presetPluginsPath;
    final String? homeDirPath = fsUtils.homeDirPath;
    if (homeDirPath != null && pathsSelectorValue != null) {
      if (major != null && major >= 4 && minor != null && minor >= 1) {
        presetPluginsPath = fs.path.join(
          homeDirPath,
          'Library',
          'Application Support',
          'Google',
          pathsSelectorValue,
        );
      } else {
        presetPluginsPath = fs.path.join(
          homeDirPath,
          'Library',
          'Application Support',
          pathsSelectorValue,
        );
      }
    }
    return AndroidStudio(
      studioPath,
      version: version,
      presetPluginsPath: presetPluginsPath,
      configuredPath: configuredPath,
      fileSystem: fs,
      platform: plt,
      processManager: processManager,
    );
  }

  static AndroidStudio? fromHomeDot(
    Directory homeDotDir, {
    FileSystem? fileSystem,
    Platform? platform,
    ProcessManager? processManager,
  }) {
    final FileSystem fs = fileSystem ?? globals.fs;
    final Platform plt = platform ?? globals.platform;
    final Match? versionMatch = _dotHomeStudioVersionMatcher.firstMatch(homeDotDir.basename);
    if (versionMatch?.groupCount != 2) {
      return null;
    }
    final Version? version = Version.parse(versionMatch![2]);
    final String? studioAppName = versionMatch[1];
    if (studioAppName == null || version == null) {
      return null;
    }

    final int major = version.major;
    final int minor = version.minor;

    // The install path is written in a .home text file,
    // it location is in <base dir>/.home for Android Studio >= 4.1
    // and <base dir>/system/.home for Android Studio < 4.1
    String dotHomeFilePath;

    if (major >= 4 && minor >= 1) {
      dotHomeFilePath = fs.path.join(homeDotDir.path, '.home');
    } else {
      dotHomeFilePath = fs.path.join(homeDotDir.path, 'system', '.home');
    }

    String? installPath;

    try {
      installPath = fs.file(dotHomeFilePath).readAsStringSync();
    } on Exception {
      // ignored, installPath will be null, which is handled below
    }

    if (installPath != null && fs.isDirectorySync(installPath)) {
      return AndroidStudio(
        installPath,
        version: version,
        studioAppName: studioAppName,
        fileSystem: fs,
        platform: plt,
        processManager: processManager,
      );
    }
    return null;
  }

  final String directory;
  final String studioAppName;

  /// The version of Android Studio.
  ///
  /// A null value represents an unknown version.
  final Version? version;

  final String? configuredPath;
  final String? presetPluginsPath;

  String? _javaPath;
  var _isValid = false;
  final _validationMessages = <String>[];

  /// The path of the JDK bundled with Android Studio.
  ///
  /// This will be null if the bundled JDK could not be found or run.
  ///
  /// If you looking to invoke the java binary or add it to the system
  /// environment variables, consider using the [Java] class instead.
  String? get javaPath => _javaPath;

  bool get isValid => _isValid;

  String? get pluginsPath {
    if (presetPluginsPath != null) {
      return presetPluginsPath!;
    }

    // JetBrains Toolbox writes plugins to a sibling directory with a ".plugins" suffix.
    if (!globals.platform.isMacOS) {
      final toolboxPluginsPath = '$directory.plugins';
      if (globals.fs.directory(toolboxPluginsPath).existsSync()) {
        return toolboxPluginsPath;
      }
    }

    if (version == null) {
      return null;
    }

    final int major = version!.major;
    final int minor = version!.minor;
    final String? homeDirPath = globals.fsUtils.homeDirPath;
    if (homeDirPath == null) {
      return null;
    }
    if (globals.platform.isMacOS) {
      /// plugin path of Android Studio has been changed after version 4.1.
      if (major >= 4 && minor >= 1) {
        return globals.fs.path.join(
          homeDirPath,
          'Library',
          'Application Support',
          'Google',
          'AndroidStudio$major.$minor',
        );
      } else {
        return globals.fs.path.join(
          homeDirPath,
          'Library',
          'Application Support',
          'AndroidStudio$major.$minor',
        );
      }
    } else {
      if (major >= 4 && minor >= 1 && globals.platform.isLinux) {
        return globals.fs.path.join(
          homeDirPath,
          '.local',
          'share',
          'Google',
          '$studioAppName$major.$minor',
        );
      }

      return globals.fs.path.join(homeDirPath, '.$studioAppName$major.$minor', 'config', 'plugins');
    }
  }

  List<String> get validationMessages => _validationMessages;

  /// Locates the newest, valid version of Android Studio.
  ///
  /// In the case that `--android-studio-dir` is configured, the version of
  /// Android Studio found at that location is always returned, even if it is
  /// invalid.
  static AndroidStudio? latestValid({
    Platform? platform,
    FileSystem? fileSystem,
    ProcessManager? processManager,
    Config? config,
    PlistParser? plistParser,
  }) {
    final Directory? configuredStudioDir = _configuredDir(config: config, fileSystem: fileSystem);

    // Find all available Studio installations.
    final List<AndroidStudio> studios = allInstalled(
      platform: platform,
      fileSystem: fileSystem,
      processManager: processManager,
      config: config,
      plistParser: plistParser,
    );
    if (studios.isEmpty) {
      return null;
    }

    final AndroidStudio? manuallyConfigured = studios
        .where(
          (AndroidStudio studio) =>
              studio.configuredPath != null &&
              configuredStudioDir != null &&
              _pathsAreEqual(studio.configuredPath!, configuredStudioDir.path),
        )
        .firstOrNull;

    if (manuallyConfigured != null) {
      return manuallyConfigured;
    }

    AndroidStudio? newest;
    for (final AndroidStudio studio in studios.where((AndroidStudio s) => s.isValid)) {
      if (newest == null) {
        newest = studio;
        continue;
      }

      // We prefer installs with known versions.
      if (studio.version != null && newest.version == null) {
        newest = studio;
      } else if (studio.version != null &&
          newest.version != null &&
          studio.version! > newest.version!) {
        newest = studio;
      } else if (studio.version == null &&
          newest.version == null &&
          studio.directory.compareTo(newest.directory) > 0) {
        newest = studio;
      }
    }

    return newest;
  }

  static List<AndroidStudio> allInstalled({
    Platform? platform,
    FileSystem? fileSystem,
    ProcessManager? processManager,
    Config? config,
    PlistParser? plistParser,
  }) {
    final Platform plt = platform ?? globals.platform;
    return plt.isMacOS
        ? _allMacOS(
            platform: platform,
            fileSystem: fileSystem,
            processManager: processManager,
            config: config,
            plistParser: plistParser,
          )
        : _allLinuxOrWindows(
            platform: platform,
            fileSystem: fileSystem,
            processManager: processManager,
            config: config,
          );
  }

  static List<AndroidStudio> _allMacOS({
    Platform? platform,
    FileSystem? fileSystem,
    ProcessManager? processManager,
    Config? config,
    PlistParser? plistParser,
  }) {
    final Platform plt = platform ?? globals.platform;
    final FileSystem fs = fileSystem ?? globals.fs;
    final fsUtils = FileSystemUtils(fileSystem: fs, platform: plt);
    final Config cfg = config ?? globals.config;
    final ProcessManager pm = processManager ?? globals.processManager;

    final candidatePaths = <FileSystemEntity>[];

    void checkForStudio(String path) {
      if (!fs.isDirectorySync(path)) {
        return;
      }
      try {
        final Iterable<Directory> directories = fs
            .directory(path)
            .listSync(followLinks: false)
            .whereType<Directory>();
        for (final directory in directories) {
          final String name = directory.basename;
          // An exact match, or something like 'Android Studio 3.0 Preview.app'.
          if (name.startsWith('Android Studio') && name.endsWith('.app')) {
            candidatePaths.add(directory);
          } else if (!directory.path.endsWith('.app')) {
            checkForStudio(directory.path);
          }
        }
      } on Exception catch (e) {
        globals.printTrace('Exception while looking for Android Studio: $e');
      }
    }

    checkForStudio('/Applications');
    final String? homeDirPath = fsUtils.homeDirPath;
    if (homeDirPath != null) {
      checkForStudio(fs.path.join(homeDirPath, 'Applications'));
    }

    Directory? configuredStudioDir = _configuredDir(config: cfg, fileSystem: fs);
    if (configuredStudioDir != null) {
      if (configuredStudioDir.basename == 'Contents') {
        configuredStudioDir = configuredStudioDir.parent;
      }
      if (!candidatePaths.any(
        (FileSystemEntity e) => _pathsAreEqual(e.path, configuredStudioDir!.path),
      )) {
        candidatePaths.add(configuredStudioDir);
      }
    }

    // Query Spotlight for unexpected installation locations.
    var spotlightQueryResult = '';
    try {
      final ProcessResult spotlightResult = pm.runSync(<String>[
        'mdfind',
        // com.google.android.studio, com.google.android.studio-EAP
        'kMDItemCFBundleIdentifier="com.google.android.studio*"',
      ]);
      spotlightQueryResult = spotlightResult.stdout as String;
    } on ProcessException {
      // The Spotlight query is a nice-to-have, continue checking known installation locations.
    }
    for (final String studioPath in LineSplitter.split(spotlightQueryResult)) {
      final Directory appBundle = fs.directory(studioPath);
      if (!candidatePaths.any((FileSystemEntity e) => e.path == studioPath)) {
        candidatePaths.add(appBundle);
      }
    }

    return candidatePaths
        .map<AndroidStudio?>((FileSystemEntity e) {
          if (configuredStudioDir == null) {
            return AndroidStudio.fromMacOSBundle(
              e.path,
              fileSystem: fs,
              plistParser: plistParser,
              platform: plt,
              processManager: pm,
            );
          }

          return AndroidStudio.fromMacOSBundle(
            e.path,
            configuredPath: _pathsAreEqual(configuredStudioDir.path, e.path)
                ? configuredStudioDir.path
                : null,
            fileSystem: fs,
            plistParser: plistParser,
            platform: plt,
            processManager: pm,
          );
        })
        .whereType<AndroidStudio>()
        .toList();
  }

  static const _idToTitle = <String, String>{
    _androidStudioId: _androidStudioTitle,
    _androidStudioPreviewId: _androidStudioPreviewTitle,
  };

  static List<AndroidStudio> _allLinuxOrWindows({
    Platform? platform,
    FileSystem? fileSystem,
    ProcessManager? processManager,
    Config? config,
  }) {
    final Platform plt = platform ?? globals.platform;
    final FileSystem fs = fileSystem ?? globals.fs;
    final fsUtils = FileSystemUtils(fileSystem: fs, platform: plt);
    final ProcessManager pm = processManager ?? globals.processManager;
    final Config cfg = config ?? globals.config;

    final studios = <AndroidStudio>[];

    bool alreadyFoundStudioAt(String path, {Version? newerThan}) {
      return studios.any((AndroidStudio studio) {
        if (studio.directory != path) {
          return false;
        }
        if (newerThan != null) {
          if (studio.version == null) {
            return false;
          }
          return studio.version!.compareTo(newerThan) >= 0;
        }
        return true;
      });
    }

    // Read all $HOME/.AndroidStudio*/system/.home
    // or $HOME/.cache/Google/AndroidStudio*/.home files.
    // There may be several pointing to the same installation,
    // so we grab only the latest one.
    final String? homeDirPath = fsUtils.homeDirPath;

    if (homeDirPath != null && fs.directory(homeDirPath).existsSync()) {
      // >=4.1 has new install location at $HOME/.cache/Google
      final String cacheDirPath = fs.path.join(homeDirPath, '.cache', 'Google');
      final directoriesToSearch = <Directory>[
        fs.directory(homeDirPath),
        if (fs.isDirectorySync(cacheDirPath)) fs.directory(cacheDirPath),
      ];

      final entities = <Directory>[];

      for (final baseDir in directoriesToSearch) {
        final Iterable<Directory> directories = baseDir
            .listSync(followLinks: false)
            .whereType<Directory>();
        entities.addAll(
          directories.where(
            (Directory directory) => _dotHomeStudioVersionMatcher.hasMatch(directory.basename),
          ),
        );
      }

      for (final entity in entities) {
        final AndroidStudio? studio = fromHomeDot(
          entity,
          fileSystem: fs,
          platform: plt,
          processManager: pm,
        );
        if (studio != null && !alreadyFoundStudioAt(studio.directory, newerThan: studio.version)) {
          studios.removeWhere((AndroidStudio other) => other.directory == studio.directory);
          studios.add(studio);
        }
      }
    }

    // Discover Android Studio > 4.1
    if (plt.isWindows && plt.environment.containsKey('LOCALAPPDATA')) {
      final Directory cacheDir = fs.directory(
        fs.path.join(plt.environment['LOCALAPPDATA']!, 'Google'),
      );
      if (!cacheDir.existsSync()) {
        return studios;
      }
      for (final Directory dir in cacheDir.listSync().whereType<Directory>()) {
        final String name = fs.path.basename(dir.path);
        _idToTitle.forEach((String id, String title) {
          if (name.startsWith(id)) {
            final String version = name.substring(id.length);
            String? installPath;

            try {
              installPath = fs.file(fs.path.join(dir.path, '.home')).readAsStringSync();
            } on FileSystemException {
              // ignored
            }
            if (installPath != null && fs.isDirectorySync(installPath)) {
              final studio = AndroidStudio(
                installPath,
                version: Version.parse(version),
                studioAppName: title,
                fileSystem: fs,
                platform: plt,
                processManager: pm,
              );
              if (!alreadyFoundStudioAt(studio.directory, newerThan: studio.version)) {
                studios.removeWhere(
                  (AndroidStudio other) => _pathsAreEqual(other.directory, studio.directory),
                );
                studios.add(studio);
              }
            }
          }
        });
      }
    }

    final configuredStudioDir = cfg.getValue('android-studio-dir') as String?;
    if (configuredStudioDir != null) {
      final AndroidStudio? matchingAlreadyFoundInstall = studios
          .where((AndroidStudio other) => _pathsAreEqual(configuredStudioDir, other.directory))
          .firstOrNull;
      if (matchingAlreadyFoundInstall != null) {
        studios.remove(matchingAlreadyFoundInstall);
        studios.add(
          AndroidStudio(
            configuredStudioDir,
            configuredPath: configuredStudioDir,
            version: matchingAlreadyFoundInstall.version,
            fileSystem: fs,
            platform: plt,
            processManager: pm,
          ),
        );
      } else {
        studios.add(
          AndroidStudio(
            configuredStudioDir,
            configuredPath: configuredStudioDir,
            fileSystem: fs,
            platform: plt,
            processManager: pm,
          ),
        );
      }
    }

    if (plt.isLinux) {
      void checkWellKnownPath(String path) {
        if (fs.isDirectorySync(path) && !alreadyFoundStudioAt(path)) {
          studios.add(AndroidStudio(path, fileSystem: fs, platform: plt, processManager: pm));
        }
      }

      // Add /opt/android-studio and $HOME/android-studio, if they exist.
      checkWellKnownPath('/opt/android-studio');
      checkWellKnownPath('${fsUtils.homeDirPath}/android-studio');
    }
    return studios;
  }

  /// Gets the Android Studio install directory set by the user, if it is configured.
  ///
  /// The returned [Directory], if not null, is guaranteed to have existed during
  /// this function's execution.
  static Directory? _configuredDir({Config? config, FileSystem? fileSystem}) {
    final Config cfg = config ?? globals.config;
    final FileSystem fs = fileSystem ?? globals.fs;
    final configuredPath = cfg.getValue('android-studio-dir') as String?;
    if (configuredPath == null) {
      return null;
    }
    final Directory result = fs.directory(configuredPath);

    bool? configuredStudioPathExists;
    String? exceptionMessage;
    try {
      configuredStudioPathExists = result.existsSync();
    } on FileSystemException catch (e) {
      exceptionMessage = e.toString();
    }

    if (configuredStudioPathExists == false || exceptionMessage != null) {
      throwToolExit('''
Could not find the Android Studio installation at the manually configured path "$configuredPath".
${exceptionMessage == null ? '' : 'Encountered exception: $exceptionMessage\n\n'}
Please verify that the path is correct and update it by running this command: flutter config --android-studio-dir '<path>'
To have flutter search for Android Studio installations automatically, remove
the configured path by running this command: flutter config --android-studio-dir
''');
    }

    return result;
  }

  static String? extractStudioPlistValueWithMatcher(String plistValue, RegExp keyMatcher) {
    return keyMatcher.stringMatch(plistValue)?.split('=').last.trim().replaceAll('"', '');
  }

  void _initAndValidate() {
    _isValid = false;
    _validationMessages.clear();

    if (configuredPath != null) {
      _validationMessages.add('android-studio-dir = $configuredPath');
    }

    if (!_fileSystem.isDirectorySync(directory)) {
      _validationMessages.add('Android Studio not found at $directory');
      return;
    }

    final String javaPath;
    if (_platform.isMacOS) {
      if (version != null && version!.major < 2020) {
        javaPath = _fileSystem.path.join(directory, 'jre', 'jdk', 'Contents', 'Home');
      } else if (version != null && version!.major < 2022) {
        javaPath = _fileSystem.path.join(directory, 'jre', 'Contents', 'Home');
        // See https://github.com/flutter/flutter/issues/125246 for more context.
      } else {
        javaPath = _fileSystem.path.join(directory, 'jbr', 'Contents', 'Home');
      }
    } else {
      if (version != null && version!.major < 2022) {
        javaPath = _fileSystem.path.join(directory, 'jre');
      } else {
        javaPath = _fileSystem.path.join(directory, 'jbr');
      }
    }
    final String javaExecutable = _fileSystem.path.join(javaPath, 'bin', 'java');
    if (!_processManager.canRun(javaExecutable)) {
      _validationMessages.add('Unable to find bundled Java version.');
    } else {
      RunResult? result;
      try {
        result = _processUtils.runSync(<String>[javaExecutable, '-version']);
      } on ProcessException catch (e) {
        _validationMessages.add('Failed to run Java: $e');
      }
      if (result != null && result.exitCode == 0) {
        final List<String> versionLines = result.stderr.split('\n');
        final String javaVersion = versionLines.length >= 2 ? versionLines[1] : versionLines[0];
        _validationMessages.add('Java version $javaVersion');
        _javaPath = javaPath;
        _isValid = true;
      } else {
        _validationMessages.add('Unable to determine bundled Java version.');
      }
    }
  }

  static Version? _parseVersion(String text) {
    // Matches the version string for Preview builds on macOS.
    // Example match: EAP AI-242.21829.142.2422.12358220
    // We try to capture "2422" here, which can be translated to a
    // more human-friendly "24.2.2".
    final eapVersionPattern = RegExp(r'EAP\s+[A-Z]{2}-\d+\.\d+\.\d+\.(\d+)\.\d+');
    final Match? eapVersionMatch = eapVersionPattern.firstMatch(text);

    if (eapVersionMatch == null) {
      return Version.parse(text);
    }

    final String? rawVersionMatch = eapVersionMatch.group(1);

    // length of 4 is because that how version is encrypted: first two digits
    // for year (part of major version), third for minor version, fourth for patch.
    if (rawVersionMatch == null || rawVersionMatch.length != 4) {
      return null;
    }

    final int? major = int.tryParse('20${rawVersionMatch[0]}${rawVersionMatch[1]}');
    final int? minor = int.tryParse(rawVersionMatch[2]);
    final int? patch = int.tryParse(rawVersionMatch[3]);
    if (major == null || minor == null || patch == null) {
      return null;
    }
    return Version(major, minor, patch);
  }

  @override
  String toString() => 'Android Studio ($version)';
}

bool _pathsAreEqual(String path, String other) {
  return globals.fs.path.canonicalize(path) == globals.fs.path.canonicalize(other);
}
