// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../../base/config.dart';
import '../../base/file_system.dart';
import '../../base/logger.dart';
import '../../base/platform.dart';
import '../android_sdk.dart';
import '../java.dart';
import 'android_ndk.dart';
import 'candidate_locator.dart';
import 'compatibility_checker.dart';

/// Represents an immutable triad of resolved and cross-validated Android SDK, Java runtime, and NDK toolchain.
class ResolvedAndroidEnvironment {
  const ResolvedAndroidEnvironment({
    required this.sdk,
    required this.java,
    required this.ndk,
    this.incompatibleJavaCandidates = const <JavaHomeCandidate>[],
  });

  final AndroidSdk? sdk;
  final Java? java;
  final AndroidNdk? ndk;
  final List<JavaHomeCandidate> incompatibleJavaCandidates;
}

/// Centralized resolver service for locating and cross-validating the Android environment.
class AndroidEnvironmentResolver {
  AndroidEnvironmentResolver({
    required this.javaLocator,
    required this.sdkLocator,
    required this.compatibilityChecker,
    required this.fileSystem,
    required this.config,
    required this.logger,
    required this.platform,
    required this.processManager,
  });

  final CandidateLocator<JavaHomeCandidate> javaLocator;
  final CandidateLocator<Directory> sdkLocator;
  final AndroidCompatibilityChecker compatibilityChecker;
  final FileSystem fileSystem;
  final Config config;
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

  /// Resolves the highest-priority compatible (SDK, Java, NDK) triad.
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
            ndk: _resolveNdk(sdkDir),
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
      ndk: _resolveNdk(sdkDir),
      incompatibleJavaCandidates: incompatible,
    );
  }

  AndroidNdk? _resolveNdk(Directory? sdkDir) {
    if (sdkDir == null) {
      return null;
    }
    return AndroidNdk.locate(config: config, platform: platform, sdkDir: sdkDir);
  }

  Java? _createJava(JavaHomeCandidate? candidate) {
    if (candidate == null) {
      return null;
    }
    String? binaryPath;
    if (candidate.path != null) {
      binaryPath = fileSystem.path.join(candidate.path!, 'bin', 'java');
    } else {
      binaryPath = compatibilityChecker.operatingSystemUtils.which('java')?.path;
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
      os: compatibilityChecker.operatingSystemUtils,
      platform: platform,
      processManager: processManager,
    );
  }
}
