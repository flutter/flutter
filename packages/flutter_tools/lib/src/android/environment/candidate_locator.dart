// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/config.dart';
import '../../base/file_system.dart';
import '../../base/os.dart';
import '../../base/platform.dart';
import '../../base/version.dart';
import '../android_studio.dart';
import '../java.dart';

/// Represents a Java home candidate directory path and its discovery source.
///
/// A path of `null` indicates a fallback to the system PATH environment variable.
typedef JavaHomeCandidate = ({String? path, JavaSource source});

/// Represents a lazily evaluated sequence of candidate items discovered in priority order.
abstract class CandidateLocator<T> {
  /// Lazily yields candidates from highest to lowest priority.
  Iterable<T> get candidates;
}

/// Discovers candidate Java installations in priority order.
class JavaCandidateLocator implements CandidateLocator<JavaHomeCandidate> {
  JavaCandidateLocator({required this.config, required this.androidStudio, required this.platform});

  final Config config;
  final AndroidStudio? androidStudio;
  final Platform platform;

  @override
  Iterable<JavaHomeCandidate> get candidates sync* {
    // 1. Explicit flutter config: flutter config --jdk-dir
    final configJdk = config.getValue('jdk-dir') as String?;
    if (configJdk != null && configJdk.isNotEmpty) {
      yield (path: configJdk, source: JavaSource.flutterConfig);
    }

    // 2. Bundled JDK from Android Studio
    final String? studioJdk = androidStudio?.javaPath;
    if (studioJdk != null && studioJdk.isNotEmpty) {
      yield (path: studioJdk, source: JavaSource.androidStudio);
    }

    // 3. JAVA_HOME environment variable
    final String? envJdk = platform.environment[Java.javaHomeEnvironmentVariable];
    if (envJdk != null && envJdk.isNotEmpty) {
      yield (path: envJdk, source: JavaSource.javaHome);
    }

    // 4. PATH fallback
    yield (path: null, source: JavaSource.path);
  }
}

/// Discovers candidate Android SDK directories in priority order.
class SdkCandidateLocator implements CandidateLocator<Directory> {
  SdkCandidateLocator({
    required this.config,
    required this.platform,
    required this.fileSystem,
    required this.operatingSystemUtils,
    required this.fileSystemUtils,
  });

  final Config config;
  final Platform platform;
  final FileSystem fileSystem;
  final OperatingSystemUtils operatingSystemUtils;
  final FileSystemUtils fileSystemUtils;

  static const String _kAndroidHome = 'ANDROID_HOME';
  static const String _kAndroidSdkRoot = 'ANDROID_SDK_ROOT';

  @override
  Iterable<Directory> get candidates sync* {
    final checkedPaths = <String>{};

    Iterable<Directory> checkCandidate(String? path) sync* {
      if (path == null || path.isEmpty) {
        return;
      }
      for (final candidatePath in <String>[path, fileSystem.path.join(path, 'sdk')]) {
        final Directory dir = fileSystem.directory(candidatePath);
        if (!checkedPaths.contains(dir.path)) {
          checkedPaths.add(dir.path);
          final bool isValid =
              fileSystem.isDirectorySync(fileSystem.path.join(dir.path, 'licenses')) ||
              fileSystem.isDirectorySync(fileSystem.path.join(dir.path, 'platform-tools'));
          if (isValid) {
            yield dir;
          }
        }
      }
    }

    // 1. Explicit flutter config: flutter config --android-sdk
    yield* checkCandidate(config.getValue('android-sdk') as String?);

    // 2. Environment variables: ANDROID_HOME, ANDROID_SDK_ROOT
    yield* checkCandidate(platform.environment[_kAndroidHome]);
    yield* checkCandidate(platform.environment[_kAndroidSdkRoot]);

    // 3. Default OS installation paths
    final String? home = fileSystemUtils.homeDirPath;
    if (home != null && home.isNotEmpty) {
      if (platform.isLinux) {
        yield* checkCandidate(fileSystem.path.join(home, 'Android', 'Sdk'));
      } else if (platform.isMacOS) {
        yield* checkCandidate(fileSystem.path.join(home, 'Library', 'Android', 'sdk'));
      } else if (platform.isWindows) {
        yield* checkCandidate(fileSystem.path.join(home, 'AppData', 'Local', 'Android', 'sdk'));
      }
    }

    // 4. Fallback: Path traversal from aapt / adb binaries on PATH
    for (final File aapt in operatingSystemUtils.whichAll('aapt')) {
      final File resolved = fileSystem.file(aapt.resolveSymbolicLinksSync());
      yield* checkCandidate(resolved.parent.parent.parent.path);
    }
    for (final File adb in operatingSystemUtils.whichAll('adb')) {
      final File resolved = fileSystem.file(adb.resolveSymbolicLinksSync());
      yield* checkCandidate(resolved.parent.parent.path);
    }
  }
}

/// Discovers candidate Android NDK directories in priority order.
class NdkCandidateLocator implements CandidateLocator<Directory> {
  NdkCandidateLocator({required this.sdkRoot, required this.config, required this.platform});

  final Directory sdkRoot;
  final Config config;
  final Platform platform;

  static const String _kAndroidNdkHome = 'ANDROID_NDK_HOME';
  static const String _kAndroidNdkPath = 'ANDROID_NDK_PATH';
  static const String _kAndroidNdkRoot = 'ANDROID_NDK_ROOT';

  @override
  Iterable<Directory> get candidates sync* {
    final checkedPaths = <String>{};

    Iterable<Directory> checkCandidate(String? path) sync* {
      if (path == null || path.isEmpty) {
        return;
      }
      final Directory dir = sdkRoot.fileSystem.directory(path);
      if (!checkedPaths.contains(dir.path) && dir.existsSync()) {
        checkedPaths.add(dir.path);
        yield dir;
      }
    }

    // 1. Explicit flutter config: flutter config --android-ndk
    yield* checkCandidate(config.getValue('android-ndk') as String?);

    // 2. Environment variables: ANDROID_NDK_HOME, ANDROID_NDK_PATH, ANDROID_NDK_ROOT
    for (final key in <String>[_kAndroidNdkHome, _kAndroidNdkPath, _kAndroidNdkRoot]) {
      yield* checkCandidate(platform.environment[key]);
    }

    // 3. Default NDK directory inside Android SDK: ndk/<version> sorted newest first
    final Directory ndkDir = sdkRoot.childDirectory('ndk');
    if (ndkDir.existsSync()) {
      final List<Version> ndkVersions =
          ndkDir
              .listSync()
              .map((FileSystemEntity entity) {
                try {
                  return Version.parse(entity.basename);
                } on Exception {
                  return null;
                }
              })
              .whereType<Version>()
              .toList()
            // Use latest NDK first.
            ..sort((Version a, Version b) => -a.compareTo(b));
      for (final ndkVersion in ndkVersions) {
        final Directory candidateDir = ndkDir.childDirectory(ndkVersion.toString());
        if (!checkedPaths.contains(candidateDir.path)) {
          checkedPaths.add(candidateDir.path);
          yield candidateDir;
        }
      }
    }
  }
}
