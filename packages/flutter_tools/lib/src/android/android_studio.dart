// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../base/version.dart';
import '../globals.dart';
import '../ios/plist_utils.dart';

AndroidStudio get androidStudio =>
    context.putIfAbsent(AndroidStudio, AndroidStudio.latestValid);

// Android Studio layout:

// Linux/Windows:
// $HOME/.AndroidStudioX.Y/system/.home

// macOS:
// /Applications/Android Studio.app/Contents/
// $HOME/Applications/Android Studio.app/Contents/

// $STUDIO_HOME/gradle/gradle-X.Y.Z/bin/gradle

final Version minGradleVersion = new Version(2, 14, 1);

final RegExp _dotHomeStudioVersionMatcher =
    new RegExp(r'^\.AndroidStudio([^\d]*)([\d.]+)');

/// Locate Gradle.
String get gradleExecutable {
  // See if the user has explicitly configured gradle-dir.
  final String gradleDir = config.getValue('gradle-dir');
  if (gradleDir != null) {
    if (fs.isFileSync(gradleDir))
      return gradleDir;
    return fs.path.join(
        gradleDir, 'bin', platform.isWindows ? 'gradle.bat' : 'gradle'
    );
  }
  return androidStudio?.gradleExecutable ?? os.which('gradle')?.path;
}

String get javaPath => androidStudio?.javaPath;

class AndroidStudio implements Comparable<AndroidStudio> {
  AndroidStudio(this.directory, {Version version, this.configured})
      : this.version = version ?? Version.unknown {
    _init();
  }

  final String directory;
  final Version version;
  final String configured;

  String _gradlePath;
  String _javaPath;
  bool _isValid = false;
  final List<String> _validationMessages = <String>[];

  factory AndroidStudio.fromMacOSBundle(String bundlePath) {
    final String studioPath = fs.path.join(bundlePath, 'Contents');
    final String plistFile = fs.path.join(studioPath, 'Info.plist');
    final String versionString =
        getValueFromFile(plistFile, kCFBundleShortVersionStringKey);
    Version version;
    if (versionString != null)
      version = new Version.parse(versionString);
    return new AndroidStudio(studioPath, version: version);
  }

  factory AndroidStudio.fromHomeDot(Directory homeDotDir) {
    final Match versionMatch =
        _dotHomeStudioVersionMatcher.firstMatch(homeDotDir.basename);
    if (versionMatch?.groupCount != 2) {
      return null;
    }
    final Version version = new Version.parse(versionMatch[2]);
    if (version == null) {
      return null;
    }
    String installPath;
    try {
      installPath = fs
          .file(fs.path.join(homeDotDir.path, 'system', '.home'))
          .readAsStringSync();
    } catch (e) {
      // ignored, installPath will be null, which is handled below
    }
    if (installPath != null && fs.isDirectorySync(installPath)) {
      return new AndroidStudio(installPath, version: version);
    }
    return null;
  }

  String get gradlePath => _gradlePath;

  String get gradleExecutable => isValid
      ? fs.path.join(_gradlePath, 'bin', platform.isWindows ? 'gradle.bat' : 'gradle')
      : null;

  String get javaPath => _javaPath;

  bool get isValid => _isValid;

  List<String> get validationMessages => _validationMessages;

  @override
  int compareTo(AndroidStudio other) {
    final int result = version.compareTo(other.version);
    if (result == 0)
      return directory.compareTo(other.directory);
    return result;
  }

  /// Locates the newest, valid version of Android Studio.
  static AndroidStudio latestValid() {
    final String configuredStudio = config.getValue('android-studio-dir');
    if (configuredStudio != null) {
      String configuredStudioPath = configuredStudio;
      if (platform.isMacOS && !configuredStudioPath.endsWith('Contents'))
        configuredStudioPath = fs.path.join(configuredStudioPath, 'Contents');
      return new AndroidStudio(configuredStudioPath,
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
      platform.isMacOS ? _allMacOS() : _allLinuxOrWindows();

  static List<AndroidStudio> _allMacOS() {
    final List<FileSystemEntity> candidatePaths = <FileSystemEntity>[];

    void _checkForStudio(String path) {
      if (!fs.isDirectorySync(path))
        return;
      try {
        final Iterable<Directory> directories = fs
            .directory(path)
            .listSync()
            .where((FileSystemEntity e) => e is Directory);
        for (Directory directory in directories) {
          if (directory.basename == 'Android Studio.app') {
            candidatePaths.add(directory);
          } else if (!directory.path.endsWith('.app')) {
            _checkForStudio(directory.path);
          }
        }
      } catch (e) {
        printTrace('Exception while looking for Android Studio: $e');
      }
    }

    _checkForStudio('/Applications');
    _checkForStudio(fs.path.join(homeDirPath, 'Applications'));

    final String configuredStudioDir = config.getValue('android-studio-dir');
    if (configuredStudioDir != null) {
      FileSystemEntity configuredStudio = fs.file(configuredStudioDir);
      if (configuredStudio.basename == 'Contents') {
        configuredStudio = configuredStudio.parent;
      }
      if (!candidatePaths
          .any((FileSystemEntity e) => e.path == configuredStudio.path)) {
        candidatePaths.add(configuredStudio);
      }
    }

    return candidatePaths
        .map((FileSystemEntity e) => new AndroidStudio.fromMacOSBundle(e.path))
        .where((AndroidStudio s) => s != null)
        .toList();
  }

  static List<AndroidStudio> _allLinuxOrWindows() {
    final List<AndroidStudio> studios = <AndroidStudio>[];

    bool _hasStudioAt(String path, {Version newerThan}) {
      return studios.any((AndroidStudio studio) {
        if (studio.directory != path)
          return false;
        if (newerThan != null) {
          return studio.version.compareTo(newerThan) >= 0;
        }
        return true;
      });
    }

    // Read all $HOME/.AndroidStudio*/system/.home files. There may be several
    // pointing to the same installation, so we grab only the latest one.
    for (FileSystemEntity entity in fs.directory(homeDirPath).listSync()) {
      if (entity is Directory && entity.basename.startsWith('.AndroidStudio')) {
        final AndroidStudio studio = new AndroidStudio.fromHomeDot(entity);
        if (studio != null &&
            !_hasStudioAt(studio.directory, newerThan: studio.version)) {
          studios.removeWhere(
              (AndroidStudio other) => other.directory == studio.directory);
          studios.add(studio);
        }
      }
    }

    final String configuredStudioDir = config.getValue('android-studio-dir');
    if (configuredStudioDir != null && !_hasStudioAt(configuredStudioDir)) {
      studios.add(new AndroidStudio(configuredStudioDir,
          configured: configuredStudioDir));
    }

    if (platform.isLinux) {
      void _checkWellKnownPath(String path) {
        if (fs.isDirectorySync(path) && !_hasStudioAt(path)) {
          studios.add(new AndroidStudio(path));
        }
      }

      // Add /opt/android-studio and $HOME/android-studio, if they exist.
      _checkWellKnownPath('/opt/android-studio');
      _checkWellKnownPath('$homeDirPath/android-studio');
    }
    return studios;
  }

  void _init() {
    _isValid = false;
    _validationMessages.clear();

    if (configured != null) {
      _validationMessages.add('android-studio-dir = $configured');
    }

    if (!fs.isDirectorySync(directory)) {
      _validationMessages.add('Android Studio not found at $directory');
      return;
    }

    Version latestGradleVersion;

    List<FileSystemEntity> gradlePaths;
    try {
      gradlePaths = fs.directory(fs.path.join(directory, 'gradle')).listSync();
      for (FileSystemEntity entry in gradlePaths.where((FileSystemEntity e) =>
          e.basename.startsWith('gradle-') && e is Directory)) {
        final Version version =
            new Version.parse(entry.basename.substring('gradle-'.length)) ??
                Version.unknown;
        if (latestGradleVersion == null || version > latestGradleVersion) {
          latestGradleVersion = version;
          if (version >= minGradleVersion) {
            _gradlePath = entry.path;
          }
        }
      }
    } catch (e) {
      printTrace('Unable to determine Gradle version: $e');
    }

    if (latestGradleVersion == null) {
      _validationMessages.add('Gradle not found.');
    } else if (_gradlePath == null) {
      _validationMessages.add('Gradle version $minGradleVersion required. '
          'Found version $latestGradleVersion.');
    } else if (processManager.canRun(gradleExecutable)) {
      _isValid = true;
      _validationMessages.add('Gradle version $latestGradleVersion');
    } else {
      _validationMessages.add(
          'Gradle version $latestGradleVersion at $_gradlePath is not executable.');
    }

    final String javaPath = platform.isMacOS ?
        fs.path.join(directory, 'jre', 'jdk', 'Contents', 'Home') :
        fs.path.join(directory, 'jre');
    final String javaExecutable = fs.path.join(javaPath, 'bin', 'java');
    if (!processManager.canRun(javaExecutable)) {
      _validationMessages.add('Unable to find bundled Java version.');
    } else {
      final ProcessResult result = processManager.runSync(<String>[javaExecutable, '-version']);
      if (result.exitCode == 0) {
        final List<String> versionLines = result.stderr.split('\n');
        final String javaVersion = versionLines.length >= 2 ? versionLines[1] : versionLines[0];
        _validationMessages.add('Java version: $javaVersion');
        _javaPath = javaPath;
      } else {
        _validationMessages.add('Unable to determine bundled Java version.');
      }
    }
  }

  @override
  String toString() => 'Android Studio ($version)';
}
