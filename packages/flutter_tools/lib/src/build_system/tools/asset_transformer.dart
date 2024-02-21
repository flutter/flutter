// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:process/process.dart';

import '../../base/error_handling_io.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/logger.dart';
import '../../flutter_manifest.dart';
import '../build_system.dart';

/// Applies a series of user-specified asset-transforming packages to an asset file.
final class AssetTransformer {
  AssetTransformer({
    required ProcessManager processManager,
    required Logger logger,
    required FileSystem fileSystem,
    required String dartBinaryPath,
  })  : _processManager = processManager,
        _logger = logger,
        _fileSystem = fileSystem,
        _dartBinaryPath = dartBinaryPath;

  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fileSystem;
  final String _dartBinaryPath;
  final Random _random = Random();

  /// The [Source] inputs that targets using this should depend on.
  ///
  /// See [Target.inputs].
  static const List<Source> inputs = <Source>[
    Source.pattern(
      '{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/asset_transformer.dart',
    ),
  ];

  /// Applies, in sequence, a list of transformers to an [asset] and then copies
  /// the output to [outputPath].
  ///
  /// Returns `true` if successful and `false` otherwise.
  Future<bool> transformAsset({
    required File asset,
    required String outputPath,
    required String workingDirectory,
    required List<AssetTransformerEntry> transformerEntries,
  }) async {

    String getTempFilePath() => '${_random.nextInt(1<<32)}${_fileSystem.path.extension(asset.path)}';

    File tempInputFile = _fileSystem.systemTempDirectory.childFile(getTempFilePath());
    await asset.copy(tempInputFile.path);
    File tempOutputFile = _fileSystem.systemTempDirectory.childFile(getTempFilePath());

    try {
      for (final (int i, AssetTransformerEntry transformer) in transformerEntries.indexed) {
        final _AssetTransformerFailure? transformerFailure = await _applyTransformer(
          asset: tempInputFile,
          output: tempOutputFile,
          transformer: transformer,
          workingDirectory: workingDirectory,
        );

        if (transformerFailure != null) {
          _logger.printError(
            'User-defined transformation of asset "${asset.path}" failed.\n'
            '${transformerFailure.message}',
          );
          return false;
        }

        ErrorHandlingFileSystem.deleteIfExists(tempInputFile);
        if (i == transformerEntries.length - 1) {
          await tempOutputFile.copy(outputPath);
        } else {
          tempInputFile = tempOutputFile;
          tempOutputFile = _fileSystem.systemTempDirectory.childFile(getTempFilePath());
        }
      }
    } finally {
      ErrorHandlingFileSystem.deleteIfExists(tempInputFile);
      ErrorHandlingFileSystem.deleteIfExists(tempOutputFile);
    }

    return true;
  }

  Future<_AssetTransformerFailure?> _applyTransformer({
    required File asset,
    required File output,
    required AssetTransformerEntry transformer,
    required String workingDirectory,
  }) async {
    final List<String> transformerArguments = <String>[
      '--input=${asset.absolute.path}',
      '--output=${output.absolute.path}',
      ...?transformer.args,
    ];

    final List<String> command = <String>[
      _dartBinaryPath,
      'run',
      transformer.package,
      ...transformerArguments,
    ];

    final ProcessResult result = await _processManager.run(
      command,
      workingDirectory: workingDirectory,
    );
    final String stdout = result.stdout as String;
    final String stderr = result.stderr as String;

    if (result.exitCode != 0) {
      return _AssetTransformerFailure(
        'Transformer process terminated with non-zero exit code: ${result.exitCode}\n'
        'Transformer package: ${transformer.package}\n'
        'Full command: ${command.join(' ')}\n'
        'stdout:\n$stdout\n'
        'stderr:\n$stderr'
      );
    }

    if (!_fileSystem.file(output).existsSync()) {
      return _AssetTransformerFailure(
        'Asset transformer ${transformer.package} did not produce an output file.\n'
        'Input file provided to transformer: "${asset.path}"\n'
        'Expected output file at: "${output.absolute.path}"\n'
        'Full command: ${command.join(' ')}\n'
        'stdout:\n$stdout\n'
        'stderr:\n$stderr',
      );
    }

    return null;
  }
}

final class _AssetTransformerFailure {
  const _AssetTransformerFailure(this.message);

  final String message;
}
