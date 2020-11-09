// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../base/version.dart';
import '../globals.dart' as globals;
import '../ios/plist_parser.dart';

AndroidStudio get androidStudio => context.get<AndroidStudio>();

// Android Studio layout:

// Linux/Windows:
// $HOME/.AndroidStudioX.Y/system/.home

// macOS:
// /Applications/Android Studio.app/Contents/
// $HOME/Applications/Android Studio.app/Contents/

final RegExp _dotHomeStudioVersionMatcher =
    RegExp(r'^\.(AndroidStudio[^\d]*)([\d.]+)');

String get javaPath => androidStudio?.javaPath;

class AndroidStudio implements Comparable<AndroidStudio> {
  AndroidStudio(
    this.directory, {
    Version version,
    this.configured,
    this.studioAppName = 'AndroidStudio',
    this.presetPluginsPath,
  }) : version = version ?? Version.unknown {
    _init();
  }

  factory AndroidStudio.fromMacOSBundle(String bundlePath) {
    String studioPath = globals.fs.path.join(bundlePath, 'Contents');
    String plistFile = globals.fs.path.join(studioPath, 'Info.plist');
    Map<String, dynamic> plistValues = globals.plistParser.parseFile(plistFile);
    // As AndroidStudio managed by JetBrainsToolbox could have a wrapper pointing to the real Android Studio.
    // Check if we've found a JetBrainsToolbox wrapper and deal with it properly.
    final String jetBrainsToolboxAppBundlePath = plistValues['JetBrainsToolboxApp'] as String;
    if (jetBrainsToolboxAppBundlePath != null) {
      studioPath = globals.fs.path.join(jetBrainsToolboxAppBundlePath, 'Contents');
      plistFile = globals.fs.path.join(studioPath, 'Info.plist');
      plistValues = globals.plistParser.parseFile(plistFile);
    }

    final String versionString = plistValues[PlistParser.kCFBundleShortVersionStringKey] as String;

    Version version;
    if (versionString != null) {
      version = Version.parse(versionString);
    }

    String pathsSelectorValue;
    final Map<String, dynamic> jvmOptions = castStringKeyedMap(plistValues['JVMOptions']);
    if (jvmOptions != null) {
      final Map<String, dynamic> jvmProperties = castStringKeyedMap(jvmOptions['Properties']);
      if (jvmProperties != null) {
        pathsSelectorValue = jvmProperties['idea.paths.selector'] as String;
      }
    }
    final String presetPluginsPath = pathsSelectorValue == null
      ? null
      : globals.fs.path.join(
        globals.fsUtils.homeDirPath,
        'Library',
        'Application Support',
        pathsSelectorValue,
      );
    return AndroidStudio(studioPath, version: version, presetPluginsPath: presetPluginsPath);
  }

  factory AndroidStudio.fromHomeDot(Directory homeDotDir) {
    final Match versionMatch =
        _dotHomeStudioVersionMatcher.firstMatch(homeDotDir.basename);
    if (versionMatch?.groupCount != 2) {
      return null;
    }
    final Version version = Version.parse(versionMatch[2]);
    final String studioAppName = versionMatch[1];
    if (studioAppName == null || version == null) {
      return null;
    }
    String installPath;
    try {
      installPath = globals.fs
          .file(globals.fs.path.join(homeDotDir.path, 'system', '.home'))
          .readAsStringSync();
    } on Exception {
      // ignored, installPath will be null, which is handled below
    }
    if (installPath != null && globals.fs.isDirectorySync(installPath)) {
      return AndroidStudio(
          installPath,
          version: version,
          studioAppName: studioAppName,
      );
    }
    return null;
  }

  final String directory;
  final String studioAppName;
  final Version version;
  final String configured;
  final String presetPluginsPath;

  String _javaPath;
  bool _isValid = false;
  final List<String> _validationMessages = <String>[];

  String get javaPath => _javaPath;

  bool get isValid => _isValid;

  String get pluginsPath {
    if (presetPluginsPath != null) {
      return presetPluginsPath;
    }
    final int major = version?.major;
    final int minor = version?.minor;
    if (globals.platform.isMacOS) {
      return globals.fs.path.join(
        globals.fsUtils.homeDirPath,
        'Library',
        'Application Support',
        'AndroidStudio$major.$minor',
      );
    } else {
      return globals.fs.path.join(
        globals.fsUtils.homeDirPath,
        '.$studioAppName$major.$minor',
        'config',
        'plugins',
      );
    }
  }

  List<String> get validationMessages => _validationMessages;

  @override
  int compareTo(AndroidStudio other) {
    final int result = version.compareTo(other.version);
    if (result == 0) {
      return directory.compareTo(other.directory);
    }
    return result;
  }

  /// Locates the newest, valid version of Android Studio.
  static AndroidStudio latestValid() {
    final String configuredStudio = globals.config.getValue('android-studio-dir') as String;
    if (configuredStudio != null) {
      String configuredStudioPath = configuredStudio;
      if (globals.platform.isMacOS && !configuredStudioPath.endsWith('Contents')) {
        configuredStudioPath = globals.fs.path.join(configuredStudioPath, 'Contents');
      }
      return AndroidStudio(configuredStudioPath,
          configured: configuredStudio);
    }

    // Find all available Studio installations.
    final List<AndroidStudio> studios = allInstalled();
    if (studios.isEmpty) {
      return null;
    }
    studios.sort();
    return studios.lastWhere((AndroidStudio s) => s.isValid,
        orElse: () => null);
  }

  static List<AndroidStudio> allInstalled() =>
      globals.platform.isMacOS ? _allMacOS() : _allLinuxOrWindows();

  static List<AndroidStudio> _allMacOS() {
    final List<FileSystemEntity> candidatePaths = <FileSystemEntity>[];

    void _checkForStudio(String path) {
      if (!globals.fs.isDirectorySync(path)) {
        return;
      }
      try {
        final Iterable<Directory> directories = globals.fs
            .directory(path)
            .listSync(followLinks: false)
            .whereType<Directory>();
        for (final Directory directory in directories) {
          final String name = directory.basename;
          // An exact match, or something like 'Android Studio 3.0 Preview.app'.
          if (name.startsWith('Android Studio') && name.endsWith('.app')) {
            candidatePaths.add(directory);
          } else if (!directory.path.endsWith('.app')) {
            _checkForStudio(directory.path);
          }
        }
      } on Exception catch (e) {
        globals.printTrace('Exception while looking for Android Studio: $e');
      }
    }

    _checkForStudio('/Applications');
    _checkForStudio(globals.fs.path.join(
      globals.fsUtils.homeDirPath,
      'Applications',
    ));

    final String configuredStudioDir = globals.config.getValue('android-studio-dir') as String;
    if (configuredStudioDir != null) {
      FileSystemEntity configuredStudio = globals.fs.file(configuredStudioDir);
      if (configuredStudio.basename == 'Contents') {
        configuredStudio = configuredStudio.parent;
      }
      if (!candidatePaths
          .any((FileSystemEntity e) => e.path == configuredStudio.path)) {
        candidatePaths.add(configuredStudio);
      }
    }

    return candidatePaths
        .map<AndroidStudio>((FileSystemEntity e) => AndroidStudio.fromMacOSBundle(e.path))
        .where((AndroidStudio s) => s != null)
        .toList();
  }

  static List<AndroidStudio> _allLinuxOrWindows() {
    final List<AndroidStudio> studios = <AndroidStudio>[];

    bool _hasStudioAt(String path, { Version newerThan }) {
      return studios.any((AndroidStudio studio) {
        if (studio.directory != path) {
          return false;
        }
        if (newerThan != null) {
          return studio.version.compareTo(newerThan) >= 0;
        }
        return true;
      });
    }

    // Read all $HOME/.AndroidStudio*/system/.home files. There may be several
    // pointing to the same installation, so we grab only the latest one.
    if (globals.fsUtils.homeDirPath != null &&
        globals.fs.directory(globals.fsUtils.homeDirPath).existsSync()) {
      final Directory homeDir = globals.fs.directory(globals.fsUtils.homeDirPath);
      for (final Directory entity in homeDir.listSync(followLinks: false).whereType<Directory>()) {
        if (!entity.basename.startsWith('.AndroidStudio')) {
          continue;
        }
        final AndroidStudio studio = AndroidStudio.fromHomeDot(entity);
        if (studio != null && !_hasStudioAt(studio.directory, newerThan: studio.version)) {
          studios.removeWhere((AndroidStudio other) => other.directory == studio.directory);
          studios.add(studio);
        }
      }
    }
    // 4.1 has a different location for AndroidStudio installs on Windows.
    if (globals.platform.isWindows) {
      final File homeDot = globals.fs.file(globals.fs.path.join(
        globals.platform.environment['LOCALAPPDATA'],
        'Google',
        'AndroidStudio4.1',
        '.home',
      ));
      if (homeDot.existsSync()) {
        final String installPath = homeDot.readAsStringSync();
        if (globals.fs.isDirectorySync(installPath)) {
          final AndroidStudio studio = AndroidStudio(
            installPath,
            version: Version(4, 1, 0),
            studioAppName: 'Android Studio 4.1',
          );
          if (studio != null && !_hasStudioAt(studio.directory, newerThan: studio.version)) {
            studios.removeWhere((AndroidStudio other) => other.directory == studio.directory);
            studios.add(studio);
          }
        }
      }
    }

    final String configuredStudioDir = globals.config.getValue('android-studio-dir') as String;
    if (configuredStudioDir != null && !_hasStudioAt(configuredStudioDir)) {
      studios.add(AndroidStudio(configuredStudioDir,
          configured: configuredStudioDir));
    }

    if (globals.platform.isLinux) {
      void _checkWellKnownPath(String path) {
        if (globals.fs.isDirectorySync(path) && !_hasStudioAt(path)) {
          studios.add(AndroidStudio(path));
        }
      }

      // Add /opt/android-studio and $HOME/android-studio, if they exist.
      _checkWellKnownPath('/opt/android-studio');
      _checkWellKnownPath('${globals.fsUtils.homeDirPath}/android-studio');
    }
    return studios;
  }

  static String extractStudioPlistValueWithMatcher(String plistValue, RegExp keyMatcher) {
    if (plistValue == null || keyMatcher == null) {
      return null;
    }
    return keyMatcher?.stringMatch(plistValue)?.split('=')?.last?.trim()?.replaceAll('"', '');
  }

  void _init() {
    _isValid = false;
    _validationMessages.clear();

    if (configured != null) {
      _validationMessages.add('android-studio-dir = $configured');
    }

    if (!globals.fs.isDirectorySync(directory)) {
      _validationMessages.add('Android Studio not found at $directory');
      return;
    }

    final String javaPath = globals.platform.isMacOS ?
        globals.fs.path.join(directory, 'jre', 'jdk', 'Contents', 'Home') :
        globals.fs.path.join(directory, 'jre');
    final String javaExecutable = globals.fs.path.join(javaPath, 'bin', 'java');
    if (!globals.processManager.canRun(javaExecutable)) {
      _validationMessages.add('Unable to find bundled Java version.');
    } else {
      RunResult result;
      try {
        result = processUtils.runSync(<String>[javaExecutable, '-version']);
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

  @override
  String toString() => 'Android Studio ($version)';
}
