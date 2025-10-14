// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dwds/dwds.dart';

import '../base/file_system.dart';

import '../compile.dart';
import '../convert.dart';

/// An expression compiler connecting to FrontendServer.
///
/// This is only used in development mode.
class WebExpressionCompiler implements ExpressionCompiler {
  WebExpressionCompiler(this._generator, {required FileSystem fileSystem})
    : _fileSystem = fileSystem;

  final ResidentCompiler _generator;
  final FileSystem _fileSystem;

  @override
  Future<ExpressionCompilationResult> compileExpressionToJs(
    String isolateId,
    String libraryUri,
    String scriptUri,
    int line,
    int column,
    Map<String, String> jsModules,
    Map<String, String> jsFrameValues,
    String moduleName,
    String expression,
  ) async {
    final CompilerOutput? compilerOutput = await _generator.compileExpressionToJs(
      libraryUri,
      scriptUri,
      line,
      column,
      jsModules,
      jsFrameValues,
      moduleName,
      expression,
    );

    if (compilerOutput != null) {
      final String content = utf8.decode(
        _fileSystem.file(compilerOutput.outputFilename).readAsBytesSync(),
      );
      return ExpressionCompilationResult(content, compilerOutput.errorCount > 0);
    }

    return ExpressionCompilationResult(
      "InternalError: frontend server failed to compile '$expression'",
      true,
    );
  }

  @override
  Future<void> initialize(CompilerOptions options) async {}

  @override
  Future<bool> updateDependencies(Map<String, ModuleInfo> modules) async => true;
}
