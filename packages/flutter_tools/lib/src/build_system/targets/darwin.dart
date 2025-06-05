// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../artifacts.dart';
import '../../base/io.dart';
import '../../build_info.dart';
import '../build_system.dart';

abstract class UnpackDarwin extends Target {
  const UnpackDarwin();

  /// Copies the [framework] artifact using `rsync` to the [Environment.outputDir].
  /// Throws an error if copy fails.
  @protected
  Future<void> copyFramework(
    Environment environment, {
    EnvironmentType? environmentType,
    TargetPlatform? targetPlatform,
    required Artifact framework,
    required BuildMode buildMode,
  }) async {
    final String basePath = environment.artifacts.getArtifactPath(
      framework,
      platform: targetPlatform,
      mode: buildMode,
      environmentType: environmentType,
    );

    final ProcessResult result = await environment.processManager.run(<String>[
      'rsync',
      '-av',
      '--delete',
      '--filter',
      '- .DS_Store/',
      '--chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r',
      basePath,
      environment.outputDir.path,
    ]);
    if (result.exitCode != 0) {
      throw Exception(
        'Failed to copy framework (exit ${result.exitCode}:\n'
        '${result.stdout}\n---\n${result.stderr}',
      );
    }
  }

  /// Verifies and destructively thins the framework binary found at [frameworkBinaryPath]
  /// to include only the architectures specified in [archs].
  ///
  /// [archs] should be a space separated list passed from Xcode containing one or
  /// more architectures (e.g. "x86_64 arm64", "arm64", "x86_64").
  ///
  /// Throws an error if the binary does not contain the [archs] or fails to thin.
  @protected
  Future<void> thinFramework(
    Environment environment,
    String frameworkBinaryPath,
    String archs,
  ) async {
    final List<String> archList = archs.split(' ').toList();
    final ProcessResult infoResult = await environment.processManager.run(<String>[
      'lipo',
      '-info',
      frameworkBinaryPath,
    ]);
    final String lipoInfo = infoResult.stdout as String;

    final ProcessResult verifyResult = await environment.processManager.run(<String>[
      'lipo',
      frameworkBinaryPath,
      '-verify_arch',
      ...archList,
    ]);

    if (verifyResult.exitCode != 0) {
      throw Exception(
        'Binary $frameworkBinaryPath does not contain architectures "$archs".\n'
        '\n'
        'lipo -info:\n'
        '$lipoInfo',
      );
    }

    // Skip thinning for non-fat executables.
    if (lipoInfo.startsWith('Non-fat file:')) {
      environment.logger.printTrace('Skipping lipo for non-fat file $frameworkBinaryPath');
      return;
    }

    // Thin in-place.
    final ProcessResult extractResult = await environment.processManager.run(<String>[
      'lipo',
      '-output',
      frameworkBinaryPath,
      for (final String arch in archList) ...<String>['-extract', arch],
      frameworkBinaryPath,
    ]);

    if (extractResult.exitCode != 0) {
      throw Exception(
        'Failed to extract architectures "$archs" for $frameworkBinaryPath.\n'
        '\n'
        'stderr:\n'
        '${extractResult.stderr}\n\n'
        'lipo -info:\n'
        '$lipoInfo',
      );
    }
  }
}
