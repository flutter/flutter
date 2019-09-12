// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../base/version.dart';
import '../globals.dart';
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
    String studioPath = fs.path.join(bundlePath, 'Contents');
    String plistFile = fs.path.join(studioPath, 'Info.plist');
    Map<String, dynamic> plistValues = PlistParser.instance.parseFile(plistFile);
    // As AndroidStudio managed by JetBrainsToolbox could have a wrapper pointing to the real Android Studio.
    // Check if we've found a JetBrainsToolbox wrapper and deal with it properly.
    final String jetBrainsToolboxAppBundlePath = plistValues['JetBrainsToolboxApp'];
    if (jetBrainsToolboxAppBundlePath != null) {
      studioPath = fs.path.join(jetBrainsToolboxAppBundlePath, 'Contents');
      plistFile = fs.path.join(studioPath, 'Info.plist');
      plistValues = PlistParser.instance.parseFile(plistFile);
    }

    final String versionString = plistValues[PlistParser.kCFBundleShortVersionStringKey];

    Version version;
    if (versionString != null)
      version = Version.parse(versionString);

    String pathsSelectorValue;
    final Map<String, dynamic> jvmOptions = plistValues['JVMOptions'];
    if (jvmOptions != null) {
      final Map<String, dynamic> jvmProperties = jvmOptions['Properties'];
      if (jvmProperties != null) {
        pathsSelectorValue = jvmProperties['idea.paths.selector'];
      }
    }
    final String presetPluginsPath = pathsSelectorValue == null
        ? null
        : fs.path.join(homeDirPath, 'Library', 'Application Support', '$pathsSelectorValue');
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
      installPath = fs
          .file(fs.path.join(homeDotDir.path, 'system', '.home'))
          .readAsStringSync();
    } catch (e) {
      // ignored, installPath will be null, which is handled below
    }
    if (installPath != null && fs.isDirectorySync(installPath)) {
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
    if (platform.isMacOS) {
      return fs.path.join(
          homeDirPath,
          'Library',
          'Application Support',
          'AndroidStudio$major.$minor');
    } else {
      return fs.path.join(homeDirPath,
          '.$studioAppName$major.$minor',
          'config',
          'plugins');
    }
  }

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
      platform.isMacOS ? _allMacOS() : _allLinuxOrWindows();

  static List<AndroidStudio> _allMacOS() {
    final List<FileSystemEntity> candidatePaths = <FileSystemEntity>[];

    void _checkForStudio(String path) {
      if (!fs.isDirectorySync(path))
        return;
      try {
        final Iterable<Directory> directories = fs
            .directory(path)
            .listSync(followLinks: false)
            .whereType<Directory>();
        for (Directory directory in directories) {
          final String name = directory.basename;
          // An exact match, or something like 'Android Studio 3.0 Preview.app'.
          if (name.startsWith('Android Studio') && name.endsWith('.app')) {
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
        .map<AndroidStudio>((FileSystemEntity e) => AndroidStudio.fromMacOSBundle(e.path))
        .where((AndroidStudio s) => s != null)
        .toList();
  }

  static List<AndroidStudio> _allLinuxOrWindows() {
    final List<AndroidStudio> studios = <AndroidStudio>[];

    bool _hasStudioAt(String path, { Version newerThan }) {
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
    if (fs.directory(homeDirPath).existsSync()) {
      for (FileSystemEntity entity in fs.directory(homeDirPath).listSync(followLinks: false)) {
        if (entity is Directory && entity.basename.startsWith('.AndroidStudio')) {
          final AndroidStudio studio = AndroidStudio.fromHomeDot(entity);
          if (studio != null && !_hasStudioAt(studio.directory, newerThan: studio.version)) {
            studios.removeWhere((AndroidStudio other) => other.directory == studio.directory);
            studios.add(studio);
          }
        }
      }
    }

    final String configuredStudioDir = config.getValue('android-studio-dir');
    if (configuredStudioDir != null && !_hasStudioAt(configuredStudioDir)) {
      studios.add(AndroidStudio(configuredStudioDir,
          configured: configuredStudioDir));
    }

    if (platform.isLinux) {
      void _checkWellKnownPath(String path) {
        if (fs.isDirectorySync(path) && !_hasStudioAt(path)) {
          studios.add(AndroidStudio(path));
        }
      }

      // Add /opt/android-studio and $HOME/android-studio, if they exist.
      _checkWellKnownPath('/opt/android-studio');
      _checkWellKnownPath('$homeDirPath/android-studio');
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

    if (!fs.isDirectorySync(directory)) {
      _validationMessages.add('Android Studio not found at $directory');
      return;
    }

    final String javaPath = platform.isMacOS ?
        fs.path.join(directory, 'jre', 'jdk', 'Contents', 'Home') :
        fs.path.join(directory, 'jre');
    final String javaExecutable = fs.path.join(javaPath, 'bin', 'java');
    if (!processManager.canRun(javaExecutable)) {
      _validationMessages.add('Unable to find bundled Java version.');
    } else {
      final RunResult result = processUtils.runSync(<String>[javaExecutable, '-version']);
      if (result.exitCode == 0) {
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
