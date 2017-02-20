// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
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

/// Locate Gradle.
String get gradleExecutable {
  // See if the user has explicitly configured gradle-dir.
  String gradleDir = config.getValue('gradle-dir');
  if (gradleDir != null) {
    if (fs.isFileSync(gradleDir))
      return gradleDir;
    return fs.path.join(gradleDir, 'bin', 'gradle');
  }
  return androidStudio?.gradleExecutable ?? os.which('gradle')?.path;
}

class AndroidStudio implements Comparable<AndroidStudio> {
  AndroidStudio(this.directory, {this.version = '0.0', this.configured}) {
    _init();
  }

  final String directory;
  final String version;
  final String configured;

  String _gradlePath;
  bool _isValid = false;
  List<String> _validationMessages = <String>[];

  factory AndroidStudio.fromMacOSBundle(String bundlePath) {
    String studioPath = fs.path.join(bundlePath, 'Contents');
    String plistFile = fs.path.join(studioPath, 'Info.plist');
    String version =
        getValueFromFile(plistFile, kCFBundleShortVersionStringKey);
    return new AndroidStudio(studioPath, version: version);
  }

  factory AndroidStudio.fromHomeDot(Directory homeDotDir) {
    String version = homeDotDir.basename.substring('.AndroidStudio'.length);
    String installPath;
    try {
      installPath = fs
          .file(fs.path.join(homeDotDir.path, 'system', '.home'))
          .readAsStringSync();
    } catch (e) {
      // ignored
    }
    if (installPath != null && fs.isDirectorySync(installPath)) {
      return new AndroidStudio(installPath, version: version);
    }
    return null;
  }

  String get gradlePath => _gradlePath;

  String get gradleExecutable => fs.path
      .join(_gradlePath, 'bin', platform.isWindows ? 'gradle.bat' : 'gradle');

  bool get isValid => _isValid;

  List<String> get validationMessages => _validationMessages;

  @override
  int compareTo(AndroidStudio other) {
    int result = version.compareTo(other.version);
    if (result == 0)
      return directory.compareTo(other.directory);
    return result;
  }

  /// Locates the newest, valid version of Android Studio.
  static AndroidStudio latestValid() {
    String configuredStudio = config.getValue('android-studio-dir');
    if (configuredStudio != null) {
      String configuredStudioPath = configuredStudio;
      if (os.isMacOS && !configuredStudioPath.endsWith('Contents'))
        configuredStudioPath = fs.path.join(configuredStudioPath, 'Contents');
      return new AndroidStudio(configuredStudioPath,
          configured: configuredStudio);
    }

    // Find all available Studio installations.
    List<AndroidStudio> studios = allInstalled();
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
    List<FileSystemEntity> candidatePaths = <FileSystemEntity>[];

    void _checkForStudio(String path) {
      if (!fs.isDirectorySync(path))
        return;
      Iterable<Directory> directories = fs
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
    }

    _checkForStudio('/Applications');
    _checkForStudio(fs.path.join(homeDirPath, 'Applications'));

    String configuredStudioDir = config.getValue('android-studio-dir');
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
    List<AndroidStudio> studios = <AndroidStudio>[];

    bool _hasStudioAt(String path, {String newerThan}) {
      return studios.any((AndroidStudio studio) {
        if (studio.directory != path) return false;
        if (newerThan != null) {
          return studio.version.compareTo(newerThan) >= 0;
        }
        return true;
      });
    }

    // Read all $HOME/AndroidStudio*/system/.home files. There may be several
    // pointing to the same installation, so we grab only the latest one.
    for (FileSystemEntity entity in fs.directory(homeDirPath).listSync()) {
      if (entity is Directory && entity.basename.startsWith('.AndroidStudio')) {
        AndroidStudio studio = new AndroidStudio.fromHomeDot(entity);
        if (studio != null &&
            !_hasStudioAt(studio.directory, newerThan: studio.version)) {
          studios.removeWhere(
              (AndroidStudio other) => other.directory == studio.directory);
          studios.add(studio);
        }
      }
    }

    String configuredStudioDir = config.getValue('android-studio-dir');
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
        Version version =
            new Version.parse(entry.basename.substring('gradle-'.length));
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
  }

  @override
  String toString() =>
      version == '0.0' ? 'Android Studio (unknown)' : 'Android Studio $version';
}
