// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/targets/shader_compiler.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';

const String shaderPath = '/shaders/my_shader.frag';
const String notShaderPath = '/shaders/not_a_shader.file';
const String outputPath = '/output/shaders/my_shader.spv';

void main() {
  late BufferLogger logger;
  late MemoryFileSystem fileSystem;
  late Artifacts artifacts;
  late String impellerc;

  setUp(() {
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    impellerc = artifacts.getHostArtifact(HostArtifact.impellerc).path;

    fileSystem.file(impellerc).createSync(recursive: true);
    fileSystem.file(shaderPath).createSync(recursive: true);
    fileSystem.file(notShaderPath).createSync(recursive: true);
  });

  testWithoutContext('compileShader returns false for non-shader files', () async {
    final ShaderCompiler shaderCompiler = ShaderCompiler(
      processManager: FakeProcessManager.empty(),
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      await shaderCompiler.compileShader(
        input: fileSystem.file(notShaderPath),
        outputPath: outputPath,
      ),
      false,
    );
  });

  testWithoutContext('compileShader returns true for shader files', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--flutter-spirv',
          '--spirv=$outputPath',
          '--input=$shaderPath',
        ],
        onRun: () {
          fileSystem.file(outputPath).createSync(recursive: true);
        },
      ),
    ]);
    final ShaderCompiler shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      await shaderCompiler.compileShader(
        input: fileSystem.file(shaderPath),
        outputPath: outputPath,
      ),
      true,
    );
    expect(fileSystem.file(outputPath).existsSync(), true);
  });
}
