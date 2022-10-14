// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../base/version.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../ios/plist_parser.dart';
import 'android_studio_validator.dart';

// Android Studio layout:

// Linux/Windows:
// $HOME/.AndroidStudioX.Y/system/.home
// $HOME/.cache/Google/AndroidStudioX.Y/.home

// macOS:
// /Applications/Android Studio.app/Contents/
// $HOME/Applications/Android Studio.app/Contents/

// Match Android Studio >= 4.1 base folder (AndroidStudio*.*)
// and < 4.1 (.AndroidStudio*.*)
final RegExp _dotHomeStudioVersionMatcher =
    RegExp(r'^\.?(AndroidStudio[^\d]*)([\d.]+)');

String? get javaPath => globals.androidStudio?.javaPath;

class AndroidStudio implements Comparable<AndroidStudio> {
  AndroidStudio(
    this.directory, {
    Version? version,
    this.configured,
    this.studioAppName = 'AndroidStudio',
    this.presetPluginsPath,
  }) : version = version ?? Version.unknown {
    _init(version: version);
  }

  static AndroidStudio? fromMacOSBundle(String bundlePath) {
    final String studioPath = globals.fs.path.join(bundlePath, 'Contents');
    final String plistFile = globals.fs.path.join(studioPath, 'Info.plist');
    final Map<String, dynamic> plistValues = globals.plistParser.parseFile(plistFile);
    // If we've found a JetBrainsToolbox wrapper, ignore it.
    if (plistValues.containsKey('JetBrainsToolboxApp')) {
      return null;
    }

    final String? versionString = plistValues[PlistParser.kCFBundleShortVersionStringKey] as String?;

    Version? version;
    if (versionString != null) {
      version = Version.parse(versionString);
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
    final String? homeDirPath = globals.fsUtils.homeDirPath;
    if (homeDirPath != null && pathsSelectorValue != null) {
      if (major != null && major >= 4 && minor != null && minor >= 1) {
        presetPluginsPath = globals.fs.path.join(
          homeDirPath,
          'Library',
          'Application Support',
          'Google',
          pathsSelectorValue,
        );
      } else {
        presetPluginsPath = globals.fs.path.join(
          homeDirPath,
          'Library',
          'Application Support',
          pathsSelectorValue,
        );
      }
    }
    return AndroidStudio(studioPath, version: version, presetPluginsPath: presetPluginsPath);
  }

  static AndroidStudio? fromHomeDot(Directory homeDotDir) {
    final Match? versionMatch =
        _dotHomeStudioVersionMatcher.firstMatch(homeDotDir.basename);
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

    if (major != null && major >= 4 && minor != null && minor >= 1) {
      dotHomeFilePath = globals.fs.path.join(homeDotDir.path, '.home');
    } else {
      dotHomeFilePath =
          globals.fs.path.join(homeDotDir.path, 'system', '.home');
    }

    String? installPath;

    try {
      installPath = globals.fs.file(dotHomeFilePath).readAsStringSync();
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
  final String? configured;
  final String? presetPluginsPath;

  String? _javaPath;
  bool _isValid = false;
  final List<String> _validationMessages = <String>[];

  String? get javaPath => _javaPath;

  bool get isValid => _isValid;

  String? get pluginsPath {
    if (presetPluginsPath != null) {
      return presetPluginsPath!;
    }
    final int major = version.major;
    final int minor = version.minor;
    final String? homeDirPath = globals.fsUtils.homeDirPath;
    if (homeDirPath == null) {
      return null;
    }
    if (globals.platform.isMacOS) {
      /// plugin path of Android Studio has been changed after version 4.1.
      if (major != null && major >= 4 && minor != null && minor >= 1) {
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
      // JetBrains Toolbox write plugins here
      final String toolboxPluginsPath = '$directory.plugins';

      if (globals.fs.directory(toolboxPluginsPath).existsSync()) {
        return toolboxPluginsPath;
      }

      if (major != null && major >= 4 && minor != null && minor >= 1 &&
          globals.platform.isLinux) {
        return globals.fs.path.join(
          homeDirPath,
          '.local',
          'share',
          'Google',
          '$studioAppName$major.$minor',
        );
      }

      return globals.fs.path.join(
        homeDirPath,
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
  static AndroidStudio? latestValid() {
    final String? configuredStudio = globals.config.getValue('android-studio-dir') as String?;
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
    AndroidStudio? newest;
    for (final AndroidStudio studio in studios.where((AndroidStudio s) => s.isValid)) {
      if (newest == null || studio.compareTo(newest) > 0) {
        newest = studio;
      }
    }

    return newest;
  }

  static List<AndroidStudio> allInstalled() =>
      globals.platform.isMacOS ? _allMacOS() : _allLinuxOrWindows();

  static List<AndroidStudio> _allMacOS() {
    final List<FileSystemEntity> candidatePaths = <FileSystemEntity>[];

    void checkForStudio(String path) {
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
            checkForStudio(directory.path);
          }
        }
      } on Exception catch (e) {
        globals.printTrace('Exception while looking for Android Studio: $e');
      }
    }

    checkForStudio('/Applications');
    final String? homeDirPath = globals.fsUtils.homeDirPath;
    if (homeDirPath != null) {
      checkForStudio(globals.fs.path.join(
        homeDirPath,
        'Applications',
      ));
    }

    final String? configuredStudioDir = globals.config.getValue('android-studio-dir') as String?;
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

    // Query Spotlight for unexpected installation locations.
    String spotlightQueryResult = '';
    try {
      final ProcessResult spotlightResult = globals.processManager.runSync(<String>[
        'mdfind',
        // com.google.android.studio, com.google.android.studio-EAP
        'kMDItemCFBundleIdentifier="com.google.android.studio*"',
      ]);
      spotlightQueryResult = spotlightResult.stdout as String;
    } on ProcessException {
      // The Spotlight query is a nice-to-have, continue checking known installation locations.
    }
    for (final String studioPath in LineSplitter.split(spotlightQueryResult)) {
      final Directory appBundle = globals.fs.directory(studioPath);
      if (!candidatePaths.any((FileSystemEntity e) => e.path == studioPath)) {
        candidatePaths.add(appBundle);
      }
    }

    return candidatePaths
        .map<AndroidStudio?>((FileSystemEntity e) => AndroidStudio.fromMacOSBundle(e.path))
        .whereType<AndroidStudio>()
        .toList();
  }

  static List<AndroidStudio> _allLinuxOrWindows() {
    final List<AndroidStudio> studios = <AndroidStudio>[];

    bool hasStudioAt(String path, { Version? newerThan }) {
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

    // Read all $HOME/.AndroidStudio*/system/.home
    // or $HOME/.cache/Google/AndroidStudio*/.home files.
    // There may be several pointing to the same installation,
    // so we grab only the latest one.
    final String? homeDirPath = globals.fsUtils.homeDirPath;

    if (homeDirPath != null && globals.fs.directory(homeDirPath).existsSync()) {
      final Directory homeDir = globals.fs.directory(homeDirPath);

      final List<Directory> directoriesToSearch = <Directory>[homeDir];

      // >=4.1 has new install location at $HOME/.cache/Google
      final String cacheDirPath =
          globals.fs.path.join(homeDirPath, '.cache', 'Google');

      if (globals.fs.isDirectorySync(cacheDirPath)) {
        directoriesToSearch.add(globals.fs.directory(cacheDirPath));
      }

      final List<Directory> entities = <Directory>[];

      for (final Directory baseDir in directoriesToSearch) {
        final Iterable<Directory> directories =
            baseDir.listSync(followLinks: false).whereType<Directory>();
        entities.addAll(directories.where((Directory directory) =>
            _dotHomeStudioVersionMatcher.hasMatch(directory.basename)));
      }

      for (final Directory entity in entities) {
        final AndroidStudio? studio = AndroidStudio.fromHomeDot(entity);
        if (studio != null && !hasStudioAt(studio.directory, newerThan: studio.version)) {
          studios.removeWhere((AndroidStudio other) => other.directory == studio.directory);
          studios.add(studio);
        }
      }
    }

    // Discover Android Studio > 4.1
    if (globals.platform.isWindows && globals.platform.environment.containsKey('LOCALAPPDATA')) {
      final Directory cacheDir = globals.fs.directory(globals.fs.path.join(globals.platform.environment['LOCALAPPDATA']!, 'Google'));
      if (!cacheDir.existsSync()) {
        return studios;
      }
      for (final Directory dir in cacheDir.listSync().whereType<Directory>()) {
        final String name  = globals.fs.path.basename(dir.path);
        AndroidStudioValidator.idToTitle.forEach((String id, String title) {
          if (name.startsWith(id)) {
            final String version = name.substring(id.length);
            String? installPath;

            try {
              installPath = globals.fs.file(globals.fs.path.join(dir.path, '.home')).readAsStringSync();
            } on FileSystemException {
              // ignored
            }
            if (installPath != null && globals.fs.isDirectorySync(installPath)) {
              final AndroidStudio studio = AndroidStudio(
                installPath,
                version: Version.parse(version),
                studioAppName: title,
              );
              if (studio != null && !hasStudioAt(studio.directory, newerThan: studio.version)) {
                studios.removeWhere((AndroidStudio other) => other.directory == studio.directory);
                studios.add(studio);
              }
            }
          }
        });
      }
    }

    final String? configuredStudioDir = globals.config.getValue('android-studio-dir') as String?;
    if (configuredStudioDir != null && !hasStudioAt(configuredStudioDir)) {
      studios.add(AndroidStudio(configuredStudioDir,
          configured: configuredStudioDir));
    }

    if (globals.platform.isLinux) {
      void checkWellKnownPath(String path) {
        if (globals.fs.isDirectorySync(path) && !hasStudioAt(path)) {
          studios.add(AndroidStudio(path));
        }
      }

      // Add /opt/android-studio and $HOME/android-studio, if they exist.
      checkWellKnownPath('/opt/android-studio');
      checkWellKnownPath('${globals.fsUtils.homeDirPath}/android-studio');
    }
    return studios;
  }

  static String? extractStudioPlistValueWithMatcher(String plistValue, RegExp keyMatcher) {
    if (plistValue == null || keyMatcher == null) {
      return null;
    }
    return keyMatcher.stringMatch(plistValue)?.split('=').last.trim().replaceAll('"', '');
  }

  void _init({Version? version}) {
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
        version != null && version.major < 2020 ?
        globals.fs.path.join(directory, 'jre', 'jdk', 'Contents', 'Home') :
        globals.fs.path.join(directory, 'jre', 'Contents', 'Home') :
        globals.fs.path.join(directory, 'jre');
    final String javaExecutable = globals.fs.path.join(javaPath, 'bin', 'java');
    if (!globals.processManager.canRun(javaExecutable)) {
      _validationMessages.add('Unable to find bundled Java version.');
    } else {
      RunResult? result;
      try {
        result = globals.processUtils.runSync(<String>[javaExecutable, '-version']);
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
