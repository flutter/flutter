// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:pool/pool.dart';
import 'package:process/process.dart';

import '../../base/error_handling_io.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/logger.dart';
import '../../build_info.dart';
import '../../devfs.dart';
import '../../flutter_manifest.dart';
import '../build_system.dart';
import '../depfile.dart';

/// Applies a series of user-specified asset-transforming packages to an asset file.
final class AssetTransformer {
  AssetTransformer({
    required this._processManager,
    required this._fileSystem,
    required this._dartBinaryPath,
    required this._buildMode,
  });

  static const buildModeEnvVar = 'FLUTTER_BUILD_MODE';

  final ProcessManager _processManager;
  final FileSystem _fileSystem;
  final String _dartBinaryPath;
  final BuildMode _buildMode;

  /// The [Source] inputs that targets using this should depend on.
  ///
  /// See [Target.inputs].
  static const inputs = <Source>[
    Source.pattern(
      '{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/asset_transformer.dart',
    ),
  ];

  /// Applies, in sequence, a list of transformers to an [asset] and then copies
  /// the output to [outputPath].
  Future<AssetTransformationResult> transformAsset({
    required File asset,
    required String outputPath,
    required String workingDirectory,
    required List<AssetTransformerEntry> transformerEntries,
    required Logger logger,
  }) async {
    final Directory tempDirectory = _fileSystem.systemTempDirectory.createTempSync();

    var transformStep = 0;
    File nextTempFile() {
      final String basename = _fileSystem.path.basename(asset.path);
      final String ext = _fileSystem.path.extension(asset.path);

      final File result = tempDirectory.childFile('$basename-transformOutput$transformStep$ext');
      transformStep++;
      return result;
    }

    File tempInputFile = nextTempFile();
    await asset.copy(tempInputFile.path);
    File tempOutputFile = nextTempFile();

    final allDependencies = <File>[];
    final stopwatch = Stopwatch()..start();
    try {
      for (final (int i, AssetTransformerEntry transformer) in transformerEntries.indexed) {
        final AssetTransformationResult transformerResult = await _applyTransformer(
          asset: tempInputFile,
          output: tempOutputFile,
          transformer: transformer,
          workingDirectory: workingDirectory,
          logger: logger,
        );

        if (transformerResult.failure != null) {
          return AssetTransformationResult(failure: transformerResult.failure);
        }
        allDependencies.addAll(transformerResult.dependencies);

        ErrorHandlingFileSystem.deleteIfExists(tempInputFile);
        if (i == transformerEntries.length - 1) {
          await _fileSystem.file(outputPath).create(recursive: true);
          await tempOutputFile.copy(outputPath);
        } else {
          tempInputFile = tempOutputFile;
          tempOutputFile = nextTempFile();
        }
      }

      logger.printTrace(
        "Finished transforming asset at path '${asset.path}' (${stopwatch.elapsedMilliseconds}ms)",
      );
    } finally {
      ErrorHandlingFileSystem.deleteIfExists(tempDirectory, recursive: true);
    }

    final String tempDirPath = tempDirectory.path;
    final List<File> filteredDependencies = allDependencies
        .where((File file) => !_fileSystem.path.isWithin(tempDirPath, file.path))
        .toList();

    return AssetTransformationResult(dependencies: filteredDependencies);
  }

  Future<AssetTransformationResult> _applyTransformer({
    required File asset,
    required File output,
    required AssetTransformerEntry transformer,
    required String workingDirectory,
    required Logger logger,
  }) async {
    final command = <String>[
      _dartBinaryPath,
      'run',
      transformer.package,
      '--input=${asset.path}',
      '--output=${output.path}',
      ...transformer.args,
    ];

    final ProcessResult result = await _processManager.run(
      command,
      workingDirectory: workingDirectory,
      environment: <String, String>{buildModeEnvVar: _buildMode.cliName},
    );

    final stdout = result.stdout as String;
    final stderr = result.stderr as String;

    if (result.exitCode != 0) {
      return AssetTransformationResult(
        failure: AssetTransformationFailure(
          'Transformer process terminated with non-zero exit code: ${result.exitCode}\n'
          'Transformer package: ${transformer.package}\n'
          'Full command: ${command.join(' ')}\n'
          'stdout:\n$stdout\n'
          'stderr:\n$stderr',
        ),
      );
    }

    if (!_fileSystem.file(output).existsSync()) {
      return AssetTransformationResult(
        failure: AssetTransformationFailure(
          'Asset transformer ${transformer.package} did not produce an output file.\n'
          'Input file provided to transformer: "${asset.path}"\n'
          'Expected output file at: "${output.absolute.path}"\n'
          'Full command: ${command.join(' ')}\n'
          'stdout:\n$stdout\n'
          'stderr:\n$stderr',
        ),
      );
    }

    var dependencies = <File>[];
    final File depfile = _fileSystem.file('${output.path}.d');
    if (depfile.existsSync()) {
      try {
        final depfileService = DepfileService(logger: logger, fileSystem: _fileSystem);
        final Depfile parsedDepfile = depfileService.parse(
          depfile,
          _fileSystem.directory(workingDirectory),
        );
        dependencies = parsedDepfile.inputs;
      } on Exception catch (e) {
        logger.printTrace('Failed to parse depfile: $e');
      }
    }

    return AssetTransformationResult(dependencies: dependencies);
  }
}

// A wrapper around [AssetTransformer] to support hot reload of transformed assets.
final class DevelopmentAssetTransformer {
  DevelopmentAssetTransformer({
    required this._fileSystem,
    required this._transformer,
    required this._logger,
  });

  final AssetTransformer _transformer;
  final FileSystem _fileSystem;
  final _transformationPool = Pool(4);
  final Logger _logger;

  final Map<String, Set<Uri>> _dependencies = <String, Set<Uri>>{};

  /// The dependencies registered by transformers, indexed by asset key.
  Map<String, Set<Uri>> get dependencies => _dependencies;

  /// Removes dependencies for assets that are no longer active.
  void pruneDependencies(Set<String> activeAssetKeys) {
    _dependencies.removeWhere((String key, _) => !activeAssetKeys.contains(key));
  }

  /// Re-transforms an asset and returns a [DevFSContent] that should be synced
  /// to the attached device in its place.
  ///
  /// Returns `null` if any of the transformation subprocesses failed.
  Future<DevFSContent?> retransformAsset({
    required String inputAssetKey,
    required DevFSContent inputAssetContent,
    required List<AssetTransformerEntry> transformerEntries,
    required String workingDirectory,
  }) async {
    final File output = _fileSystem.systemTempDirectory.childFile(
      'retransformerOutput-$inputAssetKey',
    );
    ErrorHandlingFileSystem.deleteIfExists(output);
    File? inputFile;
    var cleanupInput = false;
    Uint8List resultBytes;
    PoolResource? resource;
    try {
      resource = await _transformationPool.request();
      if (inputAssetContent is DevFSFileContent) {
        inputFile = inputAssetContent.file as File;
      } else {
        inputFile = _fileSystem.systemTempDirectory.childFile('retransformerInput-$inputAssetKey');
        inputFile.writeAsBytesSync(await inputAssetContent.contentsAsBytes());
        cleanupInput = true;
      }
      final AssetTransformationResult transformationResult = await _transformer.transformAsset(
        asset: inputFile,
        outputPath: output.path,
        transformerEntries: transformerEntries,
        workingDirectory: workingDirectory,
        logger: _logger,
      );
      if (transformationResult.failure != null) {
        _logger.printError(transformationResult.failure!.message);
        return null;
      }
      _dependencies[inputAssetKey] = transformationResult.dependencies
          .map((File f) => f.absolute.uri)
          .toSet();
      resultBytes = output.readAsBytesSync();
    } finally {
      resource?.release();
      ErrorHandlingFileSystem.deleteIfExists(output);
      if (cleanupInput && inputFile != null) {
        ErrorHandlingFileSystem.deleteIfExists(inputFile);
      }
    }
    return DevFSByteContent(resultBytes);
  }
}

final class AssetTransformationFailure {
  const AssetTransformationFailure(this.message);

  final String message;
}

final class AssetTransformationResult {
  const AssetTransformationResult({this.failure, this.dependencies = const <File>[]});

  final AssetTransformationFailure? failure;
  final List<File> dependencies;
}
