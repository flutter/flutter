// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/context.dart';
import 'project.dart';

/// The [CodeGenerator] instance.
///
/// If [experimentalBuildEnabled] is false, this will contain an unsupported
/// implementation.
CodeGenerator get codeGenerator => context.get<CodeGenerator>();

/// A wrapper for a build_runner process which delegates to a generated
/// build script.
///
/// This is only enabled if [experimentalBuildEnabled] is true, and only for
/// external flutter users.
abstract class CodeGenerator {
  const CodeGenerator();

  /// Starts a persistent code generting daemon.
  ///
  /// The defines of the daemon command are the arguments required in the
  /// flutter_build kernel builder.
  Future<CodegenDaemon> daemon(FlutterProject flutterProject);

  // Generates a synthetic package under .dart_tool/flutter_tool which is in turn
  // used to generate a build script.
  Future<void> generateBuildScript(FlutterProject flutterProject);
}

class UnsupportedCodeGenerator extends CodeGenerator {
  const UnsupportedCodeGenerator();

  @override
  Future<void> generateBuildScript(FlutterProject flutterProject) {
    throw UnsupportedError('build_runner is not currently supported.');
  }

  @override
  Future<CodegenDaemon> daemon(FlutterProject flutterProject) {
    throw UnsupportedError('build_runner is not currently supported.');
  }
}

abstract class CodegenDaemon {
  /// Whether the previously enqueued build was successful.
  Stream<CodegenStatus> get buildResults;

  CodegenStatus get lastStatus;

  /// Starts a new build.
  void startBuild();
}

/// The current status of a codegen build.
enum CodegenStatus {
  /// The build has started running.
  ///
  /// If this is the current status when running a hot reload, an additional build does
  /// not need to be started.
  Started,
  /// The build succeeded.
  Succeeded,
  /// The build failed.
  Failed
}
