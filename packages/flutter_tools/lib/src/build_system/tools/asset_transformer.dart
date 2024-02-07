import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:pool/pool.dart';
import 'package:process/process.dart';

import '../../artifacts.dart';
import '../../base/error_handling_io.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/logger.dart';
import '../../devfs.dart';
import '../../flutter_manifest.dart';
import '../build_system.dart';

// A wrapper around [AssetTransformer] to support hot reload of transformed assets.
final class DevelopmentAssetTransformer {
  DevelopmentAssetTransformer({
    required FileSystem fileSystem,
    required AssetTransformer transformer,
    @visibleForTesting math.Random? random,
  }) : _fileSystem = fileSystem, _transformer = transformer,        _random = random ?? math.Random();

  final AssetTransformer _transformer;
  final FileSystem _fileSystem;
  final Pool _compilationPool = Pool(4);
  final math.Random _random;

  /// Retransforms an asset and returns a [DevFSContent] that should be synced
  /// to the attached device in its place.
  ///
  /// Returns `null` if any of the transformation subprocesses failed.
  Future<DevFSContent?> retransformAsset({
    required DevFSContent inputAsset,
    required List<AssetTransformerEntry> transformerEntries,
    required String? workingDirectory,
  }) async {
    final File output = _fileSystem.systemTempDirectory.childFile('${_random.nextDouble()}.temp');
    late File inputFile;
    bool cleanupInput = false;
    Uint8List result;
    PoolResource? resource;
    try {
      resource = await _compilationPool.request();
      if (inputAsset is DevFSFileContent) {
        inputFile = inputAsset.file as File;
      } else {
        inputFile = _fileSystem.systemTempDirectory.childFile('${_random.nextDouble()}.temp');
        inputFile.writeAsBytesSync(await inputAsset.contentsAsBytes());
        cleanupInput = true;
      }
      final bool success = await _transformer.transformAsset(
        asset: inputFile,
        outputPath: output.path,
        throwOnFailure: false,
        transformerEntries: transformerEntries,
        workingDirectory: workingDirectory,
      );
      if (!success) {
        return null;
      }
      result = output.readAsBytesSync();
    } finally {
      resource?.release();
      ErrorHandlingFileSystem.deleteIfExists(output);
      if (cleanupInput) {
        ErrorHandlingFileSystem.deleteIfExists(inputFile);
      }
    }
    return DevFSByteContent(result);
  }
}

/// Applies a series of user-specified asset-transforming packages to an asset file.
final class AssetTransformer {
  AssetTransformer({
    required ProcessManager processManager,
    required Logger logger,
    required FileSystem fileSystem,
    required Artifacts artifacts,
  })  : _processManager = processManager,
        _logger = logger,
        _fileSystem = fileSystem {
          _dartBinary = artifacts.getArtifactPath(Artifact.engineDartBinary);
        }

  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fileSystem;
  late String _dartBinary;


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
  /// If a transformer subprocess fails, its stdout and stderr will be logged.
  /// In addition, if [throwOnFailure] is set, an [AssetTransformerException]
  /// will be thrown; otherwise, this will return `true`.
  Future<bool> transformAsset({
    required File asset,
    required String outputPath,
    required String? workingDirectory, // TODO—dontmerge — document why this is needed.
    required bool throwOnFailure, // TODO—dontmerge — not sure if I like this pattern. I feel like we should return a result type let the caller decide whether or not to throw.
    required List<AssetTransformerEntry> transformerEntries,
  }) async {
    for (final (int i, AssetTransformerEntry transformer) in transformerEntries.indexed) {
      final List<String> transformerArguments = <String>[
        ...?transformer.args,
        if (i == 0) '--input=${asset.path}' else '--input=$outputPath',
        '--output=$outputPath',
      ];

      final List<String> command = <String>[
        _dartBinary,
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
        _logger.printTrace(stdout);
        _logger.printError(stderr);
        if (throwOnFailure) {
          throw AssetTransformerException._(
            'Asset transformation of "${asset.path}" to "$outputPath" failed '
            'with exit code ${result.exitCode}.\n'
            'Transformer package: ${transformer.package}\n'
            'Full command: ${command.join(' ')}\n'
            'stdout:\n$stdout\n'
            'stderr:\n$stderr',
          );
        }
        return false;
      }
      // TODO—dontmerge—this won't work for subsequent transformations
      if (!await _fileSystem.file(outputPath).exists()) {
        throw AssetTransformerException._(
          'Transformer ${transformer.package} did not produce an output.\n'
          'Input: ${asset.path}\n'
          'Expected output: $outputPath',
        );
      }
    }
    return true;
  }
}

// TODO—dontmerge — is there value in defining a custom Exception type here?
class AssetTransformerException implements Exception {
  AssetTransformerException._(this.message);

  final String message;

  @override
  String toString() => 'AssetTransformerException: $message\n\n';
}
