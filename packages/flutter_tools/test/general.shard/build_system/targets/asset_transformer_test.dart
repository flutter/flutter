// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:file/memory.dart';
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

    final File asset = fileSystem.file('asset.txt');
    const String outputPath = 'output.txt';

    final FakeProcessManager processManager =
        FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          artifacts.getArtifactPath(Artifact.engineDartBinary),
          'run',
          'my_transformer',
          '--input=${asset.path}',
          '--output=$outputPath',
          '-f',
          '--my_option',
          'my_option_value',
        ],
        onRun: (_) {
          fileSystem.file(outputPath).createSync(recursive: true);
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
      throwOnFailure: true,
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
}
