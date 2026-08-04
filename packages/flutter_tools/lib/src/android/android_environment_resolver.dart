// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/config.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/version.dart';
import 'android_sdk.dart';
import 'android_studio.dart';
import 'java.dart';

/// Represents a potential Java home directory and the source from where it was found.
///
/// If `path` is null, the Java candidate is resolved from the system `PATH`.
typedef JavaHomeCandidate = ({String? path, JavaSource source});

/// Interface for streaming candidates in priority order using lazy evaluation.
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

/// Discovers candidate Android SDK root directories in priority order.
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
    yield* checkCandidate(platform.environment[kAndroidHome]);
    yield* checkCandidate(platform.environment[kAndroidSdkRoot]);

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
    for (final key in <String>[kAndroidNdkHome, kAndroidNdkPath, kAndroidNdkRoot]) {
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
            ..sort((Version a, Version b) => -a.compareTo(b));
      for (final ndkVersion in ndkVersions) {
        yield* checkCandidate(ndkDir.childDirectory(ndkVersion.toString()).path);
      }
    }
  }
}

/// Validates whether a Java candidate and Android SDK pair are compatible.
class AndroidCompatibilityChecker {
  AndroidCompatibilityChecker({
    required this.fileSystem,
    required this.processManager,
    required this.platform,
    required this.operatingSystemUtils,
    required this.logger,
  });

  final FileSystem fileSystem;
  final ProcessManager processManager;
  final Platform platform;
  final OperatingSystemUtils operatingSystemUtils;
  final Logger logger;

  /// Verifies whether [javaCandidate] is functional and compatible with [sdkDir].
  bool isCompatiblePair(JavaHomeCandidate javaCandidate, Directory? sdkDir) {
    String? javaBin;
    if (javaCandidate.path != null) {
      javaBin = fileSystem.path.join(javaCandidate.path!, 'bin', 'java');
    } else {
      javaBin = operatingSystemUtils.which('java')?.path;
    }

    if (javaBin == null || !processManager.canRun(javaBin)) {
      logger.printTrace(
        'Java candidate ${javaCandidate.path ?? "PATH"} missing or not runnable java binary ($javaBin).',
      );
      return false;
    }

    if (sdkDir == null) {
      return true;
    }

    final sdk = AndroidSdk(sdkDir, fileSystem: fileSystem);
    final String? sdkmanagerPath = sdk.getCmdlineToolsPath('sdkmanager');
    if (sdkmanagerPath == null || !processManager.canRun(sdkmanagerPath)) {
      // If cmdline-tools is not installed, we accept the Java/SDK pair
      // if Java can run.
      return true;
    }

    final String? javaHome = javaCandidate.path;
    final String pathDir = fileSystem.path.dirname(javaBin);
    final pathEnv = '$pathDir:${platform.environment['PATH'] ?? ""}';

    final ProcessResult result = processManager.runSync(
      <String>[sdkmanagerPath, '--version'],
      environment: <String, String>{
        if (javaHome != null) Java.javaHomeEnvironmentVariable: javaHome,
        'PATH': pathEnv,
      },
    );

    if (result.exitCode != 0) {
      logger.printTrace(
        'Skipping Java candidate ${javaCandidate.path ?? "PATH"} (${javaCandidate.source.name}): '
        'incompatible with sdkmanager at $sdkmanagerPath.\n'
        'Exit code: ${result.exitCode}. Stderr: ${result.stderr}',
      );
      return false;
    }

    return true;
  }
}

/// Represents an immutable pair of resolved and cross-validated Android SDK and Java runtime.
class ResolvedAndroidEnvironment {
  const ResolvedAndroidEnvironment({
    required this.sdk,
    required this.java,
    this.incompatibleJavaCandidates = const <JavaHomeCandidate>[],
  });

  final AndroidSdk? sdk;
  final Java? java;
  final List<JavaHomeCandidate> incompatibleJavaCandidates;
}

/// Centralized resolver service for locating and cross-validating the Android environment.
class AndroidEnvironmentResolver {
  AndroidEnvironmentResolver({
    required this.javaLocator,
    required this.sdkLocator,
    required this.compatibilityChecker,
    required this.fileSystem,
    required this.operatingSystemUtils,
    required this.logger,
    required this.platform,
    required this.processManager,
  });

  final CandidateLocator<JavaHomeCandidate> javaLocator;
  final CandidateLocator<Directory> sdkLocator;
  final AndroidCompatibilityChecker compatibilityChecker;
  final FileSystem fileSystem;
  final OperatingSystemUtils operatingSystemUtils;
  final Logger logger;
  final Platform platform;
  final ProcessManager processManager;

  bool _resolved = false;
  ResolvedAndroidEnvironment? _cached;

  /// Clears the cached resolution result so subsequent calls re-resolve.
  void clearCache() {
    _resolved = false;
    _cached = null;
  }

  /// Resolves the highest-priority compatible (SDK, Java) pair.
  ResolvedAndroidEnvironment? resolve({bool force = false}) {
    if (_resolved && !force) {
      return _cached;
    }
    _resolved = true;

    // 1. Try to find a compatible pair of SDK and Java.
    final incompatible = <JavaHomeCandidate>[];
    for (final Directory sdkDir in sdkLocator.candidates) {
      for (final JavaHomeCandidate javaCandidate in javaLocator.candidates) {
        if (compatibilityChecker.isCompatiblePair(javaCandidate, sdkDir)) {
          final Java? java = _createJava(javaCandidate);
          final sdk = AndroidSdk(sdkDir, java: java, fileSystem: fileSystem);
          return _cached = ResolvedAndroidEnvironment(
            sdk: sdk,
            java: java,
            incompatibleJavaCandidates: incompatible,
          );
        } else {
          incompatible.add(javaCandidate);
        }
      }
    }

    // 2. If no compatible pair was found, resolve individual valid candidates.
    final Directory? sdkDir = sdkLocator.candidates.firstOrNull;
    final JavaHomeCandidate? javaCandidate = javaLocator.candidates
        .where((JavaHomeCandidate c) => compatibilityChecker.isCompatiblePair(c, null))
        .firstOrNull;

    final Java? java = _createJava(javaCandidate);
    final AndroidSdk? sdk = sdkDir != null
        ? AndroidSdk(sdkDir, java: java, fileSystem: fileSystem)
        : null;

    if (sdk == null && java == null) {
      return _cached = null;
    }

    return _cached = ResolvedAndroidEnvironment(
      sdk: sdk,
      java: java,
      incompatibleJavaCandidates: incompatible,
    );
  }

  Java? _createJava(JavaHomeCandidate? candidate) {
    if (candidate == null) {
      return null;
    }
    String? binaryPath;
    if (candidate.path != null) {
      binaryPath = fileSystem.path.join(candidate.path!, 'bin', 'java');
    } else {
      binaryPath = operatingSystemUtils.which('java')?.path;
    }
    if (binaryPath == null || !processManager.canRun(binaryPath)) {
      return null;
    }
    return Java(
      javaHome: candidate.path,
      binaryPath: binaryPath,
      javaSource: candidate.source,
      logger: logger,
      fileSystem: fileSystem,
      os: operatingSystemUtils,
      platform: platform,
      processManager: processManager,
    );
  }
}
