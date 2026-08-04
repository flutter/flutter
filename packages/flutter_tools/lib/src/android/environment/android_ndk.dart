// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/config.dart';
import '../../base/file_system.dart';
import '../../base/platform.dart';
import 'candidate_locator.dart';

/// Represents an Android NDK installation directory and its toolchain binaries.
class AndroidNdk {
  AndroidNdk({required this.directory, required this.config, required this.platform});

  final Directory directory;
  final Config config;
  final Platform platform;

  static const Map<String, String> _llvmHostDirectoryName = <String, String>{
    'linux': 'linux-x86_64',
    'macos': 'darwin-x86_64',
    'windows': 'windows-x86_64',
  };

  /// Locates the highest priority valid Android NDK using [NdkCandidateLocator].
  static AndroidNdk? locate({
    required Config config,
    required Platform platform,
    required Directory? sdkDir,
  }) {
    if (sdkDir == null) {
      return null;
    }
    final locator = NdkCandidateLocator(sdkRoot: sdkDir, config: config, platform: platform);
    for (final Directory ndkDir in locator.candidates) {
      final ndk = AndroidNdk(directory: ndkDir, config: config, platform: platform);
      if (ndk.clangPath != null) {
        return ndk;
      }
    }
    return null;
  }

  /// Locates a native LLVM compiler binary inside this NDK installation.
  String? getBinaryPath(String binaryName) {
    final String? hostDir = _llvmHostDirectoryName[platform.operatingSystem];
    if (hostDir == null) {
      return null;
    }
    final File executable = directory
        .childDirectory('toolchains')
        .childDirectory('llvm')
        .childDirectory('prebuilt')
        .childDirectory(hostDir)
        .childDirectory('bin')
        .childFile(binaryName);
    if (executable.existsSync()) {
      return executable.path;
    }
    return null;
  }

  /// Path to the C/C++ compiler binary (`clang`).
  String? get clangPath => getBinaryPath(platform.isWindows ? 'clang.exe' : 'clang');

  /// Path to the archive tool binary (`llvm-ar`).
  String? get arPath => getBinaryPath(platform.isWindows ? 'llvm-ar.exe' : 'llvm-ar');

  /// Path to the linker binary (`ld.lld`).
  String? get ldPath => getBinaryPath(platform.isWindows ? 'ld.lld.exe' : 'ld.lld');

  /// Optional version identifier for this NDK compiler toolchain.
  String? get compilerVersion => null;
}
