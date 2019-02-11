// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'base/context.dart';
import 'base/file_system.dart';
import 'base/platform.dart';

/// The [CodeGenerator] instance.
///
/// If [experimentalBuildEnabled] is false, this will contain an unsupported
/// implementation.
CodeGenerator get codeGenerator => context[CodeGenerator];

/// Whether to attempt to build a flutter project using build* libraries.
///
/// This requires both an experimental opt in via the environment variable
/// 'FLUTTER_EXPERIMENTAL_BUILD' and that the project itself has a
/// dependency on the package 'flutter_build' and 'build_runner.'
bool get experimentalBuildEnabled {
  return _experimentalBuildEnabled ??= platform.environment['FLUTTER_EXPERIMENTAL_BUILD']?.toLowerCase() == 'true';
}
bool _experimentalBuildEnabled;

@visibleForTesting
set experimentalBuildEnabled(bool value) {
  _experimentalBuildEnabled = value;
}

/// A wrapper for a build_runner process which delegates to a generated
/// build script.
///
/// This is only enabled if [experimentalBuildEnabled] is true, and only for
/// external flutter users.
abstract class CodeGenerator {
  const CodeGenerator();

  /// Run a build_runner build and return the resulting .packages and dill file.
  ///
  /// The defines of the build command are the arguments required in the
  /// flutter_build kernel builder.
  Future<CodeGenerationResult> build({
    @required String mainPath,
    @required bool aot,
    @required bool linkPlatformKernelIn,
    @required bool trackWidgetCreation,
    @required bool targetProductVm,
    List<String> extraFrontEndOptions = const <String>[],
    bool disableKernelGeneration = false,
  });

  /// Invalidates a generated build script by deleting it.
  ///
  /// Must be called any time a pubspec file update triggers a corresponding change
  /// in .packages.
  Future<void> invalidateBuildScript();

  // Generates a synthetic package under .dart_tool/flutter_tool which is in turn
  // used to generate a build script.
  Future<void> generateBuildScript();
}

class UnsupportedBuildRunner extends CodeGenerator {
  const UnsupportedBuildRunner();

  @override
  Future<CodeGenerationResult> build({
    String mainPath,
    bool aot,
    bool linkPlatformKernelIn,
    bool trackWidgetCreation,
    bool targetProductVm,
    List<String> extraFrontEndOptions = const <String> [],
    bool disableKernelGeneration = false,
  }) {
    throw UnsupportedError('build_runner is not currently supported.');
  }

  @override
  Future<void> generateBuildScript() {
    throw UnsupportedError('build_runner is not currently supported.');
  }

  @override
  Future<void> invalidateBuildScript() {
    throw UnsupportedError('build_runner is not currently supported.');
  }

}

/// The result of running a build through a [CodeGenerator].
///
/// If no dill or packages file is generated, they will be null.
class CodeGenerationResult {
  const CodeGenerationResult(this.packagesFile, this.dillFile);

  final File packagesFile;
  final File dillFile;
}


