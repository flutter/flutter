// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/tools/asset_transformer.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';

void main() {
  test('Invokes dart properly', () async {
    final FileSystem fileSystem = MemoryFileSystem();
    final BufferLogger logger = BufferLogger.test();
    final Artifacts artifacts = Artifacts.test();

    final File asset = fileSystem.file('asset.txt')..createSync()..writeAsStringSync('hello world');
    const String outputPath = 'output.txt';

    final FakeProcessManager processManager =
        FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <Pattern>[
          artifacts.getArtifactPath(Artifact.engineDartBinary),
          'run',
          'my_transformer',
          RegExp('--input=.*'),
          RegExp('--output=.*'),
          '-f',
          '--my_option',
          'my_option_value',
        ],
        onRun: (List<String> args) {
          final ArgResults parsedArgs = (ArgParser()
            ..addOption('input')
            ..addOption('output')
            ..addFlag('foo', abbr: 'f')
            ..addOption('my_option'))
            .parse(args);
          fileSystem.file(parsedArgs['output']).createSync(recursive: true);
        },
      ),
    ]);

    final AssetTransformer transformer = AssetTransformer(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    await transformer.transformAsset(
      asset: asset,
      outputPath: outputPath,
      workingDirectory: fileSystem.currentDirectory.path,
      transformerEntries: <AssetTransformerEntry>[
        const AssetTransformerEntry(
          package: 'my_transformer',
          args: <String>[
            '-f',
            '--my_option',
            'my_option_value',
          ],
        )
      ],
    );

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('logs useful error information when transformation process returns a nonzero exit code', () async {
    final FileSystem fileSystem = MemoryFileSystem();
    final BufferLogger logger = BufferLogger.test();
    final Artifacts artifacts = Artifacts.test();

    final File asset = fileSystem.file('asset.txt')..createSync();
    const String outputPath = 'output.txt';

    final String dartBinaryPath = artifacts.getArtifactPath(Artifact.engineDartBinary);
    final FakeProcessManager processManager =
        FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <Pattern>[
          dartBinaryPath,
          'run',
          'my_transformer',
          RegExp('--input=.*'),
          RegExp('--output=.*'),
        ],
        onRun: (List<String> args) {
          final ArgResults parsedArgs = (ArgParser()
            ..addOption('input')
            ..addOption('output'))
            .parse(args);
          fileSystem.file(parsedArgs['output']).createSync(recursive: true);
        },
        exitCode: 1,
        stdout: 'Beginning transformation',
        stderr: 'Something went wrong',
      ),
    ]);

    final AssetTransformer transformer = AssetTransformer(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    await transformer.transformAsset(
      asset: asset,
      outputPath: outputPath,
      workingDirectory: fileSystem.currentDirectory.path,
      transformerEntries: <AssetTransformerEntry>[
        const AssetTransformerEntry(
          package: 'my_transformer',
          args: <String>[],
        )
      ],
    );

    expect(processManager, hasNoRemainingExpectations);
    expect(logger.errorText, contains(RegExp(
'''
User-defined transformation of asset "asset\\.txt" failed\\.
Transformer process terminated with non-zero exit code: 1
Transformer package: my_transformer
Full command: $dartBinaryPath run my_transformer --input=.*\\.txt --output=.*\\.txt
stdout:
Beginning transformation
stderr:
Something went wrong
''')));
  });

  testWithoutContext('prints error message when the transformer does not produce an output file', () async {
    final FileSystem fileSystem = MemoryFileSystem();
    final BufferLogger logger = BufferLogger.test();
    final Artifacts artifacts = Artifacts.test();

    final File asset = fileSystem.file('asset.txt')..createSync();
    const String outputPath = 'output.txt';

    final String dartBinaryPath = artifacts.getArtifactPath(Artifact.engineDartBinary);
    final FakeProcessManager processManager =
        FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <Pattern>[
          dartBinaryPath,
          'run',
          'my_transformer',
          RegExp('--input=.*'),
          RegExp('--output=.*'),
        ],
        onRun: (_) {
          // Do nothing.
        },
        stderr: 'Transformation failed, but I forgot to exit with a non-zero code.'
      ),
    ]);

    final AssetTransformer transformer = AssetTransformer(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    await transformer.transformAsset(
      asset: asset,
      outputPath: outputPath,
      workingDirectory: fileSystem.currentDirectory.path,
      transformerEntries: <AssetTransformerEntry>[
        const AssetTransformerEntry(
          package: 'my_transformer',
          args: <String>[],
        )
      ],
    );

    expect(processManager, hasNoRemainingExpectations);
    expect(logger.errorText, contains(RegExp(
r'''
User-defined transformation of asset "asset\.txt" failed.
Asset transformer my_transformer did not produce an output file\.
Input file provided to transformer: ".*\.txt"
Expected output file at: ".*\.txt"
Full command: Artifact\.engineDartBinary run my_transformer --input=.*\.txt --output=.*\.txt
stdout:

stderr:
Transformation failed, but I forgot to exit with a non-zero code\.
'''
    )));
  });

  testWithoutContext('correctly chains transformations when there are multiple of them', () async {
    final FileSystem fileSystem = MemoryFileSystem();
    final BufferLogger logger = BufferLogger.test();
    final Artifacts artifacts = Artifacts.test();

    final File asset = fileSystem.file('asset.txt')
      ..createSync()
      ..writeAsStringSync('ABC');
    const String outputPath = 'output.txt';

    final String dartBinaryPath = artifacts.getArtifactPath(Artifact.engineDartBinary);
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <Pattern>[
          dartBinaryPath,
          'run',
          'my_lowercase_transformer',
          RegExp('--input=.*'),
          RegExp('--output=.*'),
        ],
        onRun: (List<String> args) {
          final ArgResults parsedArgs = (ArgParser()
              ..addOption('input')
              ..addOption('output'))
            .parse(args);

          final String inputFileContents = fileSystem.file(parsedArgs['input']).readAsStringSync();
          fileSystem.file(parsedArgs['output'])
            ..createSync()
            ..writeAsStringSync(inputFileContents.toLowerCase());
        },
      ),
      FakeCommand(
        command: <Pattern>[
          dartBinaryPath,
          'run',
          'my_distance_from_ascii_a_transformer',
          RegExp('--input=.*'),
          RegExp('--output=.*'),
        ],
        onRun: (List<String> args) {
          final ArgResults parsedArgs = (ArgParser()
              ..addOption('input')
              ..addOption('output'))
            .parse(args);

          final String inputFileContents = fileSystem.file(parsedArgs['input']).readAsStringSync();
          final StringBuffer outputContents = StringBuffer();

          for (int i = 0; i < inputFileContents.length; i++) {
            outputContents.write(inputFileContents.codeUnitAt(i) - 'a'.codeUnits.first);
          }

          fileSystem.file(parsedArgs['output'])
            ..createSync()
            ..writeAsStringSync(outputContents.toString());
        },
      ),
    ]);

    final AssetTransformer transformer = AssetTransformer(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    await transformer.transformAsset(
      asset: asset,
      outputPath: outputPath,
      workingDirectory: fileSystem.currentDirectory.path,
      transformerEntries: <AssetTransformerEntry>[
        const AssetTransformerEntry(
          package: 'my_lowercase_transformer',
          args: <String>[],
        ),
        const AssetTransformerEntry(
          package: 'my_distance_from_ascii_a_transformer',
          args: <String>[],
        ),
      ],
    );

    expect(processManager, hasNoRemainingExpectations);
    expect(fileSystem.file(outputPath).readAsStringSync(), '012');
  });

  testWithoutContext('prints an error when a transformer in a chain (thats not the first) does not produce an output', () async {
    final FileSystem fileSystem = MemoryFileSystem();
    final BufferLogger logger = BufferLogger.test();
    final Artifacts artifacts = Artifacts.test();

    final File asset = fileSystem.file('asset.txt')
      ..createSync()
      ..writeAsStringSync('ABC');
    const String outputPath = 'output.txt';

    final String dartBinaryPath = artifacts.getArtifactPath(Artifact.engineDartBinary);
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <Pattern>[
          dartBinaryPath,
          'run',
          'my_lowercase_transformer',
          RegExp('--input=.*'),
          RegExp('--output=.*'),
        ],
        onRun: (List<String> args) {
          final ArgResults parsedArgs = (ArgParser()
              ..addOption('input')
              ..addOption('output'))
            .parse(args);

          final String inputFileContents = fileSystem.file(parsedArgs['input']).readAsStringSync();
          fileSystem.file(parsedArgs['output'])
            ..createSync()
            ..writeAsStringSync(inputFileContents.toLowerCase());
        },
      ),
      FakeCommand(
        command: <Pattern>[
          dartBinaryPath,
          'run',
          'my_distance_from_ascii_a_transformer',
          RegExp('--input=.*'),
          RegExp('--output=.*'),
        ],
        onRun: (List<String> args) {
          // Do nothing.
        },
        stderr: 'Transformation failed, but I forgot to exit with a non-zero code.'
      ),
    ]);

    final AssetTransformer transformer = AssetTransformer(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    await transformer.transformAsset(
      asset: asset,
      outputPath: outputPath,
      workingDirectory: fileSystem.currentDirectory.path,
      transformerEntries: <AssetTransformerEntry>[
        const AssetTransformerEntry(
          package: 'my_lowercase_transformer',
          args: <String>[],
        ),
        const AssetTransformerEntry(
          package: 'my_distance_from_ascii_a_transformer',
          args: <String>[],
        ),
      ],
    );

    expect(processManager, hasNoRemainingExpectations);
    expect(fileSystem.file(outputPath), isNot(exists));
    expect(logger.errorText, contains(RegExp(
r'''
User-defined transformation of asset "asset.txt" failed.
Asset transformer my_distance_from_ascii_a_transformer did not produce an output file\.
Input file provided to transformer: ".*\.txt"
Expected output file at: ".*\.txt"
Full command: Artifact\.engineDartBinary run my_distance_from_ascii_a_transformer --input=.*\.txt --output=.*\.txt
stdout:

stderr:
Transformation failed, but I forgot to exit with a non-zero code\.
'''
    )));
    expect(fileSystem.systemTempDirectory.listSync(), isEmpty);
  });
}
