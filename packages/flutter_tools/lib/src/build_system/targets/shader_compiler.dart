// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../../artifacts.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/logger.dart';
import '../../convert.dart';
import '../build_system.dart';

/// A class the wraps the functionality of the Impeller shader compiler
/// impellerc.
class ShaderCompiler {
  ShaderCompiler({
    required ProcessManager processManager,
    required Logger logger,
    required FileSystem fileSystem,
    required Artifacts artifacts,
  }) : _processManager = processManager,
       _logger = logger,
       _fs = fileSystem,
       _artifacts = artifacts;

  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fs;
  final Artifacts _artifacts;

  /// The [Source] inputs that targets using this should depend on.
  ///
  /// See [Target.inputs].
  static const List<Source> inputs = <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/shader_compiler.dart'),
    Source.hostArtifact(HostArtifact.impellerc),
  ];

  /// Calls impellerc, which transforms the [input] glsl shader into a
  /// platform specific shader at [outputPath].
  ///
  /// All parameters are required.
  ///
  /// If the shader compiler subprocess fails, it will print the stdout and
  /// stderr to the log and throw a [ShaderCompilerException]. Otherwise, it
  /// will return true.
  Future<bool> compileShader({
    required File input,
    required String outputPath,
  }) async {
    final File impellerc = _fs.file(
      _artifacts.getHostArtifact(HostArtifact.impellerc),
    );
    if (!impellerc.existsSync()) {
      throw ShaderCompilerException._(
        'The impellerc utility is missing at "${impellerc.path}". '
        'Run "flutter doctor".',
      );
    }

    final List<String> cmd = <String>[
      impellerc.path,
      // TODO(zanderso): When impeller is enabled, the correct flags for the
      // target backend will need to be passed.
      // https://github.com/flutter/flutter/issues/102853
      '--flutter-spirv',
      '--spirv=$outputPath',
      '--input=${input.path}',
      '--input-type=frag',
    ];
    final Process impellercProcess = await _processManager.start(cmd);
    final int code = await impellercProcess.exitCode;
    if (code != 0) {
      _logger.printTrace(await utf8.decodeStream(impellercProcess.stdout));
      _logger.printError(await utf8.decodeStream(impellercProcess.stderr));
      throw ShaderCompilerException._(
        'Shader compilation of "${input.path}" to "$outputPath" '
        'failed with exit code $code.',
      );
    }

    return true;
  }
}

class ShaderCompilerException implements Exception {
  ShaderCompilerException._(this.message);

  final String message;

  @override
  String toString() => 'ShaderCompilerException: $message\n\n';
}
