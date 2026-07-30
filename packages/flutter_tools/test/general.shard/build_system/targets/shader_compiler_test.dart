// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/tools/shader_compiler.dart';
import 'package:flutter_tools/src/devfs.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';

const fragDir = '/shaders';
const shaderLibDir = '/./shader_lib';
const fragPath = '/shaders/my_shader.frag';
const notFragPath = '/shaders/not_a_frag.file';
const outputSpirvPath = '/output/shaders/my_shader.frag.spirv';
const outputPath = '/output/shaders/my_shader.frag';

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
    fileSystem.file(fragPath).createSync(recursive: true);
    fileSystem.file(notFragPath).createSync(recursive: true);
  });

  testWithoutContext('compileShader invokes impellerc for .frag files and web target', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--iplr',
          '--json',
          '--sl=$outputPath',
          '--spirv=$outputSpirvPath',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
          '--include=$shaderLibDir',
        ],
        onRun: (_) {
          fileSystem.file(outputPath).createSync(recursive: true);
          fileSystem.file(outputSpirvPath).createSync(recursive: true);
        },
      ),
    ]);
    final shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      await shaderCompiler.compileShader(
        input: fileSystem.file(fragPath),
        outputPath: outputPath,
        targetPlatform: TargetPlatform.web_javascript,
      ),
      true,
    );
    expect(fileSystem.file(outputPath).existsSync(), true);
    expect(fileSystem.file(outputSpirvPath).existsSync(), false);
  });

  testWithoutContext(
    'compileShader invokes impellerc for .frag files and metal ios target',
    () async {
      final processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            impellerc,
            '--runtime-stage-metal',
            '--iplr',
            '--sl=$outputPath',
            '--spirv=$outputPath.spirv',
            '--input=$fragPath',
            '--input-type=frag',
            '--include=$fragDir',
            '--include=$shaderLibDir',
          ],
          onRun: (_) {
            fileSystem.file(outputPath).createSync(recursive: true);
          },
        ),
      ]);
      final shaderCompiler = ShaderCompiler(
        processManager: processManager,
        logger: logger,
        fileSystem: fileSystem,
        artifacts: artifacts,
      );

      expect(
        await shaderCompiler.compileShader(
          input: fileSystem.file(fragPath),
          outputPath: outputPath,
          targetPlatform: TargetPlatform.ios,
        ),
        true,
      );
      expect(fileSystem.file(outputPath).existsSync(), true);
    },
  );

  testWithoutContext('compileShader invokes impellerc for .frag files and Android', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--runtime-stage-gles',
          '--runtime-stage-gles3',
          '--runtime-stage-vulkan',
          '--iplr',
          '--sl=$outputPath',
          '--spirv=$outputPath.spirv',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
          '--include=$shaderLibDir',
        ],
        onRun: (_) {
          fileSystem.file(outputPath).createSync(recursive: true);
        },
      ),
    ]);
    final shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      await shaderCompiler.compileShader(
        input: fileSystem.file(fragPath),
        outputPath: outputPath,
        targetPlatform: TargetPlatform.android,
      ),
      true,
    );
    expect(fileSystem.file(outputPath).existsSync(), true);
  });

  testWithoutContext('compileShader invokes impellerc for non-.frag files', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--iplr',
          '--json',
          '--sl=$outputPath',
          '--spirv=$outputSpirvPath',
          '--input=$notFragPath',
          '--input-type=frag',
          '--include=$fragDir',
          '--include=$shaderLibDir',
        ],
        onRun: (_) {
          fileSystem.file(outputPath).createSync(recursive: true);
          fileSystem.file(outputSpirvPath).createSync(recursive: true);
        },
      ),
    ]);
    final shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      await shaderCompiler.compileShader(
        input: fileSystem.file(notFragPath),
        outputPath: outputPath,
        targetPlatform: TargetPlatform.web_javascript,
      ),
      true,
    );
    expect(fileSystem.file(outputPath).existsSync(), true);
    expect(fileSystem.file(outputSpirvPath).existsSync(), false);
  });

  testWithoutContext('compileShader throws an exception when impellerc fails', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--iplr',
          '--json',
          '--sl=$outputPath',
          '--spirv=$outputSpirvPath',
          '--input=$notFragPath',
          '--input-type=frag',
          '--include=$fragDir',
          '--include=$shaderLibDir',
        ],
        stdout: 'impellerc stdout',
        stderr: 'impellerc stderr',
        exitCode: 1,
      ),
    ]);
    final shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    try {
      await shaderCompiler.compileShader(
        input: fileSystem.file(notFragPath),
        outputPath: outputPath,
        targetPlatform: TargetPlatform.web_javascript,
      );
      fail('unreachable');
    } on ShaderCompilerException catch (e) {
      expect(
        e.toString(),
        contains(
          'ShaderCompilerException: Shader compilation of "/shaders/not_a_frag.file" to '
          '"/output/shaders/my_shader.frag" failed with exit code 1.',
        ),
      );
    }

    expect(fileSystem.file(outputPath).existsSync(), false);
  });

  testWithoutContext('DevelopmentShaderCompiler can compile for android non-impeller', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--runtime-stage-gles',
          '--runtime-stage-gles3',
          '--runtime-stage-vulkan',
          '--iplr',
          '--sl=/.tmp_rand0/0.8255140718871702.temp',
          '--spirv=/.tmp_rand0/0.8255140718871702.temp.spirv',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
          '--include=$shaderLibDir',
          '--depfile=/.tmp_rand0/0.8863148172405516.d',
        ],
        onRun: (_) {
          fileSystem.file('/.tmp_rand0/0.8255140718871702.temp.spirv').createSync();
          fileSystem.file('/.tmp_rand0/0.8255140718871702.temp')
            ..createSync()
            ..writeAsBytesSync(<int>[1, 2, 3, 4]);
        },
      ),
    ]);
    fileSystem.file(fragPath).writeAsBytesSync(<int>[1, 2, 3, 4]);
    final shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );
    final developmentShaderCompiler = DevelopmentShaderCompiler(
      shaderCompiler: shaderCompiler,
      fileSystem: fileSystem,
      logger: logger,
      random: math.Random(0),
    );

    developmentShaderCompiler.configureCompiler(TargetPlatform.android);

    final DevFSContent? content = await developmentShaderCompiler.recompileShader(
      DevFSFileContent(fileSystem.file(fragPath)),
    );

    expect(await content!.contentsAsBytes(), <int>[1, 2, 3, 4]);
    expect(fileSystem.file('/.tmp_rand0/0.8255140718871702.temp.spirv'), isNot(exists));
    expect(fileSystem.file('/.tmp_rand0/0.8255140718871702.temp'), isNot(exists));
  });

  testWithoutContext(
    'DevelopmentShaderCompiler can compile for Flutter Tester with Impeller and Vulkan',
    () async {
      final processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            impellerc,
            '--sksl',
            '--runtime-stage-vulkan',
            '--iplr',
            '--sl=/.tmp_rand0/0.8255140718871702.temp',
            '--spirv=/.tmp_rand0/0.8255140718871702.temp.spirv',
            '--input=$fragPath',
            '--input-type=frag',
            '--include=$fragDir',
            '--include=$shaderLibDir',
            '--depfile=/.tmp_rand0/0.8863148172405516.d',
          ],
          onRun: (_) {
            fileSystem.file('/.tmp_rand0/0.8255140718871702.temp.spirv').createSync();
            fileSystem.file('/.tmp_rand0/0.8255140718871702.temp')
              ..createSync()
              ..writeAsBytesSync(<int>[1, 2, 3, 4]);
          },
        ),
      ]);
      fileSystem.file(fragPath).writeAsBytesSync(<int>[1, 2, 3, 4]);
      final shaderCompiler = ShaderCompiler(
        processManager: processManager,
        logger: logger,
        fileSystem: fileSystem,
        artifacts: artifacts,
      );
      final developmentShaderCompiler = DevelopmentShaderCompiler(
        shaderCompiler: shaderCompiler,
        fileSystem: fileSystem,
        logger: logger,
        random: math.Random(0),
      );

      developmentShaderCompiler.configureCompiler(TargetPlatform.tester);

      final DevFSContent? content = await developmentShaderCompiler.recompileShader(
        DevFSFileContent(fileSystem.file(fragPath)),
      );

      expect(await content!.contentsAsBytes(), <int>[1, 2, 3, 4]);
      expect(processManager.hasRemainingExpectations, false);
    },
  );

  testWithoutContext('DevelopmentShaderCompiler can compile for android with impeller', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--runtime-stage-gles',
          '--runtime-stage-gles3',
          '--runtime-stage-vulkan',
          '--iplr',
          '--sl=/.tmp_rand0/0.8255140718871702.temp',
          '--spirv=/.tmp_rand0/0.8255140718871702.temp.spirv',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
          '--include=$shaderLibDir',
          '--depfile=/.tmp_rand0/0.8863148172405516.d',
        ],
        onRun: (_) {
          fileSystem.file('/.tmp_rand0/0.8255140718871702.temp.spirv').createSync();
          fileSystem.file('/.tmp_rand0/0.8255140718871702.temp')
            ..createSync()
            ..writeAsBytesSync(<int>[1, 2, 3, 4]);
        },
      ),
    ]);
    fileSystem.file(fragPath).writeAsBytesSync(<int>[1, 2, 3, 4]);
    final shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );
    final developmentShaderCompiler = DevelopmentShaderCompiler(
      shaderCompiler: shaderCompiler,
      fileSystem: fileSystem,
      logger: logger,
      random: math.Random(0),
    );

    developmentShaderCompiler.configureCompiler(TargetPlatform.android);

    final DevFSContent? content = await developmentShaderCompiler.recompileShader(
      DevFSFileContent(fileSystem.file(fragPath)),
    );

    expect(await content!.contentsAsBytes(), <int>[1, 2, 3, 4]);
    expect(fileSystem.file('/.tmp_rand0/0.8255140718871702.temp.spirv'), isNot(exists));
    expect(fileSystem.file('/.tmp_rand0/0.8255140718871702.temp'), isNot(exists));
  });

  testWithoutContext(
    'DevelopmentShaderCompiler can compile for Flutter Tester with Impeller and Vulkan',
    () async {
      final processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            impellerc,
            '--sksl',
            '--runtime-stage-vulkan',
            '--iplr',
            '--sl=/.tmp_rand0/0.8255140718871702.temp',
            '--spirv=/.tmp_rand0/0.8255140718871702.temp.spirv',
            '--input=$fragPath',
            '--input-type=frag',
            '--include=$fragDir',
            '--include=$shaderLibDir',
            '--depfile=/.tmp_rand0/0.8863148172405516.d',
          ],
          onRun: (List<String> args) {
            fileSystem.file('/.tmp_rand0/0.8255140718871702.temp.spirv').createSync();
            fileSystem.file('/.tmp_rand0/0.8255140718871702.temp')
              ..createSync()
              ..writeAsBytesSync(<int>[1, 2, 3, 4]);
          },
        ),
      ]);
      fileSystem.file(fragPath).writeAsBytesSync(<int>[1, 2, 3, 4]);
      final shaderCompiler = ShaderCompiler(
        processManager: processManager,
        logger: logger,
        fileSystem: fileSystem,
        artifacts: artifacts,
      );
      final developmentShaderCompiler = DevelopmentShaderCompiler(
        shaderCompiler: shaderCompiler,
        fileSystem: fileSystem,
        logger: logger,
        random: math.Random(0),
      );

      developmentShaderCompiler.configureCompiler(TargetPlatform.tester);

      final DevFSContent? content = await developmentShaderCompiler.recompileShader(
        DevFSFileContent(fileSystem.file(fragPath)),
      );

      expect(await content!.contentsAsBytes(), <int>[1, 2, 3, 4]);
      expect(processManager.hasRemainingExpectations, false);
    },
  );

  testWithoutContext('DevelopmentShaderCompiler can compile for android with impeller', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--runtime-stage-gles',
          '--runtime-stage-gles3',
          '--runtime-stage-vulkan',
          '--iplr',
          '--sl=/.tmp_rand0/0.8255140718871702.temp',
          '--spirv=/.tmp_rand0/0.8255140718871702.temp.spirv',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
          '--include=$shaderLibDir',
          '--depfile=/.tmp_rand0/0.8863148172405516.d',
        ],
        onRun: (List<String> args) {
          fileSystem.file('/.tmp_rand0/0.8255140718871702.temp.spirv').createSync();
          fileSystem.file('/.tmp_rand0/0.8255140718871702.temp')
            ..createSync()
            ..writeAsBytesSync(<int>[1, 2, 3, 4]);
        },
      ),
    ]);
    fileSystem.file(fragPath).writeAsBytesSync(<int>[1, 2, 3, 4]);
    final shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );
    final developmentShaderCompiler = DevelopmentShaderCompiler(
      shaderCompiler: shaderCompiler,
      fileSystem: fileSystem,
      logger: logger,
      random: math.Random(0),
    );

    developmentShaderCompiler.configureCompiler(TargetPlatform.android);

    final DevFSContent? content = await developmentShaderCompiler.recompileShader(
      DevFSFileContent(fileSystem.file(fragPath)),
    );

    expect(await content!.contentsAsBytes(), <int>[1, 2, 3, 4]);
    expect(fileSystem.file('/.tmp_rand0/0.8255140718871702.temp.spirv'), isNot(exists));
    expect(fileSystem.file('/.tmp_rand0/0.8255140718871702.temp'), isNot(exists));
  });

  testWithoutContext('DevelopmentShaderCompiler can compile JSON for web targets', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--iplr',
          '--json',
          '--sl=/.tmp_rand0/0.8255140718871702.temp',
          '--spirv=/.tmp_rand0/0.8255140718871702.temp.spirv',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
          '--include=$shaderLibDir',
          '--depfile=/.tmp_rand0/0.8863148172405516.d',
        ],
        onRun: (_) {
          fileSystem.file('/.tmp_rand0/0.8255140718871702.temp.spirv').createSync();
          fileSystem.file('/.tmp_rand0/0.8255140718871702.temp')
            ..createSync()
            ..writeAsBytesSync(<int>[1, 2, 3, 4]);
        },
      ),
    ]);
    fileSystem.file(fragPath).writeAsBytesSync(<int>[1, 2, 3, 4]);
    final shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );
    final developmentShaderCompiler = DevelopmentShaderCompiler(
      shaderCompiler: shaderCompiler,
      fileSystem: fileSystem,
      logger: logger,
      random: math.Random(0),
    );

    developmentShaderCompiler.configureCompiler(TargetPlatform.web_javascript);

    final DevFSContent? content = await developmentShaderCompiler.recompileShader(
      DevFSFileContent(fileSystem.file(fragPath)),
    );

    expect(await content!.contentsAsBytes(), <int>[1, 2, 3, 4]);
    expect(fileSystem.file('/.tmp_rand0/0.8255140718871702.temp.spirv'), isNot(exists));
    expect(fileSystem.file('/.tmp_rand0/0.8255140718871702.temp'), isNot(exists));
  });

  testWithoutContext('DevelopmentShaderCompiler tracks transitive imports', () async {
    final String tempDir = fileSystem.systemTempDirectory.path;
    const helperPath = '/shaders/helper.glsl';
    fileSystem.file(helperPath).createSync(recursive: true);

    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--runtime-stage-gles',
          '--runtime-stage-gles3',
          '--runtime-stage-vulkan',
          '--iplr',
          '--sl=$tempDir/0.8255140718871702.temp',
          '--spirv=$tempDir/0.8255140718871702.temp.spirv',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
          '--include=$shaderLibDir',
          '--depfile=$tempDir/0.8863148172405516.d',
        ],
        onRun: (_) {
          fileSystem.file('$tempDir/0.8255140718871702.temp.spirv').createSync();
          fileSystem.file('$tempDir/0.8255140718871702.temp')
            ..createSync()
            ..writeAsBytesSync(<int>[1, 2, 3, 4]);
          fileSystem
              .file('$tempDir/0.8863148172405516.d')
              .writeAsStringSync('$tempDir/0.8255140718871702.temp: $fragPath $helperPath');
        },
      ),
    ]);

    fileSystem.file(fragPath).writeAsBytesSync(<int>[1, 2, 3, 4]);
    final shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );
    final developmentShaderCompiler = DevelopmentShaderCompiler(
      shaderCompiler: shaderCompiler,
      fileSystem: fileSystem,
      logger: logger,
      random: math.Random(0),
    );

    developmentShaderCompiler.configureCompiler(TargetPlatform.android);

    final shaderContent = DevFSFileContent(fileSystem.file(fragPath));

    final DevFSContent? content = await developmentShaderCompiler.recompileShader(shaderContent);
    expect(content, isNotNull);
    expect(await content!.contentsAsBytes(), <int>[1, 2, 3, 4]);

    expect(developmentShaderCompiler.areDependenciesModified(shaderContent), false);

    fileSystem.file(helperPath).setLastModifiedSync(DateTime.now().add(const Duration(seconds: 1)));

    expect(developmentShaderCompiler.areDependenciesModified(shaderContent), true);
  });

  testWithoutContext('DevelopmentShaderCompiler handles missing depfile gracefully', () async {
    final String tempDir = fileSystem.systemTempDirectory.path;

    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--runtime-stage-gles',
          '--runtime-stage-gles3',
          '--runtime-stage-vulkan',
          '--iplr',
          '--sl=$tempDir/0.8255140718871702.temp',
          '--spirv=$tempDir/0.8255140718871702.temp.spirv',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
          '--include=$shaderLibDir',
          '--depfile=$tempDir/0.8863148172405516.d',
        ],
        onRun: (_) {
          fileSystem.file('$tempDir/0.8255140718871702.temp.spirv').createSync();
          fileSystem.file('$tempDir/0.8255140718871702.temp')
            ..createSync()
            ..writeAsBytesSync(<int>[1, 2, 3, 4]);
        },
      ),
    ]);

    fileSystem.file(fragPath).writeAsBytesSync(<int>[1, 2, 3, 4]);
    final shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );
    final developmentShaderCompiler = DevelopmentShaderCompiler(
      shaderCompiler: shaderCompiler,
      fileSystem: fileSystem,
      logger: logger,
      random: math.Random(0),
    );

    developmentShaderCompiler.configureCompiler(TargetPlatform.android);

    final shaderContent = DevFSFileContent(fileSystem.file(fragPath));

    final DevFSContent? content = await developmentShaderCompiler.recompileShader(shaderContent);
    expect(content, isNotNull);
    expect(await content!.contentsAsBytes(), <int>[1, 2, 3, 4]);

    expect(developmentShaderCompiler.areDependenciesModified(shaderContent), false);
    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('DevelopmentShaderCompiler handles malformed depfile gracefully', () async {
    final String tempDir = fileSystem.systemTempDirectory.path;

    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--runtime-stage-gles',
          '--runtime-stage-gles3',
          '--runtime-stage-vulkan',
          '--iplr',
          '--sl=$tempDir/0.8255140718871702.temp',
          '--spirv=$tempDir/0.8255140718871702.temp.spirv',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
          '--include=$shaderLibDir',
          '--depfile=$tempDir/0.8863148172405516.d',
        ],
        onRun: (_) {
          fileSystem.file('$tempDir/0.8255140718871702.temp.spirv').createSync();
          fileSystem.file('$tempDir/0.8255140718871702.temp')
            ..createSync()
            ..writeAsBytesSync(<int>[1, 2, 3, 4]);
          fileSystem.file('$tempDir/0.8863148172405516.d').writeAsStringSync('malformed content');
        },
      ),
    ]);

    fileSystem.file(fragPath).writeAsBytesSync(<int>[1, 2, 3, 4]);
    final shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );
    final developmentShaderCompiler = DevelopmentShaderCompiler(
      shaderCompiler: shaderCompiler,
      fileSystem: fileSystem,
      logger: logger,
      random: math.Random(0),
    );

    developmentShaderCompiler.configureCompiler(TargetPlatform.android);

    final shaderContent = DevFSFileContent(fileSystem.file(fragPath));

    final DevFSContent? content = await developmentShaderCompiler.recompileShader(shaderContent);
    expect(content, isNotNull);
    expect(await content!.contentsAsBytes(), <int>[1, 2, 3, 4]);

    expect(developmentShaderCompiler.areDependenciesModified(shaderContent), false);
    expect(logger.errorText, contains('Invalid depfile:'));
    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('DevelopmentShaderCompiler handles non-file content gracefully', () async {
    final String tempDir = fileSystem.systemTempDirectory.path;

    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--runtime-stage-gles',
          '--runtime-stage-gles3',
          '--runtime-stage-vulkan',
          '--iplr',
          '--sl=$tempDir/0.8255140718871702.temp',
          '--spirv=$tempDir/0.8255140718871702.temp.spirv',
          '--input=$tempDir/0.424722653321134.temp',
          '--input-type=frag',
          '--include=$tempDir',
          '--include=$shaderLibDir',
          '--depfile=$tempDir/0.8863148172405516.d',
        ],
        onRun: (_) {
          fileSystem.file('$tempDir/0.8255140718871702.temp.spirv').createSync();
          fileSystem.file('$tempDir/0.8255140718871702.temp')
            ..createSync()
            ..writeAsBytesSync(<int>[1, 2, 3, 4]);
        },
      ),
    ]);

    final shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );
    final developmentShaderCompiler = DevelopmentShaderCompiler(
      shaderCompiler: shaderCompiler,
      fileSystem: fileSystem,
      logger: logger,
      random: math.Random(0),
    );

    developmentShaderCompiler.configureCompiler(TargetPlatform.android);

    final shaderContent = DevFSByteContent(Uint8List.fromList(<int>[1, 2, 3, 4]));

    final DevFSContent? content = await developmentShaderCompiler.recompileShader(shaderContent);
    expect(content, isNotNull);
    expect(await content!.contentsAsBytes(), <int>[1, 2, 3, 4]);

    expect(developmentShaderCompiler.areDependenciesModified(shaderContent), false);
    expect(processManager.hasRemainingExpectations, false);
  });

  group('blocked shader compiler', () {
    testWithoutContext(
      'compileShader throws ToolExit and logs friendly message when impellerc is blocked by Windows Application Control',
      () async {
        final blockedException = ProcessException(
          impellerc,
          <String>[],
          'An Application Control policy has blocked this file',
          1260,
        );
        final processManager = FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: <String>[
              impellerc,
              '--runtime-stage-metal',
              '--iplr',
              '--sl=$outputPath',
              '--spirv=$outputPath.spirv',
              '--input=$fragPath',
              '--input-type=frag',
              '--include=$fragDir',
              '--include=$shaderLibDir',
            ],
            exception: blockedException,
          ),
        ]);
        final shaderCompiler = ShaderCompiler(
          processManager: processManager,
          logger: logger,
          fileSystem: fileSystem,
          artifacts: artifacts,
          platform: FakePlatform(operatingSystem: 'windows'),
        );

        await expectLater(
          shaderCompiler.compileShader(
            input: fileSystem.file(fragPath),
            outputPath: outputPath,
            targetPlatform: TargetPlatform.ios,
          ),
          throwsToolExit(message: 'Impeller shader compiler was blocked by security policy.'),
        );

        expect(logger.errorText, contains('blocked by system'));
        expect(logger.errorText, contains(impellerc));
      },
    );

    testWithoutContext(
      'compileShader throws ToolExit and logs friendly message when impellerc is blocked by group policy',
      () async {
        final blockedException = ProcessException(
          impellerc,
          <String>[],
          'blocked by group policy',
          1260,
        );
        final processManager = FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: <String>[
              impellerc,
              '--runtime-stage-metal',
              '--iplr',
              '--sl=$outputPath',
              '--spirv=$outputPath.spirv',
              '--input=$fragPath',
              '--input-type=frag',
              '--include=$fragDir',
              '--include=$shaderLibDir',
            ],
            exception: blockedException,
          ),
        ]);
        final shaderCompiler = ShaderCompiler(
          processManager: processManager,
          logger: logger,
          fileSystem: fileSystem,
          artifacts: artifacts,
          platform: FakePlatform(operatingSystem: 'windows'),
        );

        await expectLater(
          shaderCompiler.compileShader(
            input: fileSystem.file(fragPath),
            outputPath: outputPath,
            targetPlatform: TargetPlatform.ios,
          ),
          throwsToolExit(message: 'Impeller shader compiler was blocked by security policy.'),
        );

        expect(logger.errorText, contains('blocked by system'));
        expect(logger.errorText, contains(impellerc));
      },
    );

    testWithoutContext(
      'compileShader handles non-fatal security policy block gracefully',
      () async {
        final blockedException = ProcessException(
          impellerc,
          <String>[],
          'blocked by group policy',
          1260,
        );
        final processManager = FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: <String>[
              impellerc,
              '--runtime-stage-metal',
              '--iplr',
              '--sl=$outputPath',
              '--spirv=$outputPath.spirv',
              '--input=$fragPath',
              '--input-type=frag',
              '--include=$fragDir',
              '--include=$shaderLibDir',
            ],
            exception: blockedException,
          ),
        ]);
        final shaderCompiler = ShaderCompiler(
          processManager: processManager,
          logger: logger,
          fileSystem: fileSystem,
          artifacts: artifacts,
          platform: FakePlatform(operatingSystem: 'windows'),
        );

        final bool success = await shaderCompiler.compileShader(
          input: fileSystem.file(fragPath),
          outputPath: outputPath,
          targetPlatform: TargetPlatform.ios,
          fatal: false,
        );

        expect(success, false);
        expect(logger.errorText, contains('blocked by system'));
        expect(logger.errorText, contains(impellerc));
      },
    );

    testWithoutContext('compileShader rethrows other ProcessExceptions', () async {
      final otherException = ProcessException(impellerc, <String>[], 'Some other error');
      final processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            impellerc,
            '--runtime-stage-metal',
            '--iplr',
            '--sl=$outputPath',
            '--spirv=$outputPath.spirv',
            '--input=$fragPath',
            '--input-type=frag',
            '--include=$fragDir',
            '--include=$shaderLibDir',
          ],
          exception: otherException,
        ),
      ]);
      final shaderCompiler = ShaderCompiler(
        processManager: processManager,
        logger: logger,
        fileSystem: fileSystem,
        artifacts: artifacts,
      );

      await expectLater(
        shaderCompiler.compileShader(
          input: fileSystem.file(fragPath),
          outputPath: outputPath,
          targetPlatform: TargetPlatform.ios,
        ),
        throwsA(
          isA<ProcessException>().having(
            (ProcessException e) => e.message,
            'message',
            contains('Some other error'),
          ),
        ),
      );
    });

    testWithoutContext('compileShader only logs the security policy block error once', () async {
      final blockedException = ProcessException(
        impellerc,
        <String>[],
        'blocked by group policy',
        1260,
      );
      final processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            impellerc,
            '--runtime-stage-metal',
            '--iplr',
            '--sl=$outputPath',
            '--spirv=$outputPath.spirv',
            '--input=$fragPath',
            '--input-type=frag',
            '--include=$fragDir',
            '--include=$shaderLibDir',
          ],
          exception: blockedException,
        ),
        FakeCommand(
          command: <String>[
            impellerc,
            '--runtime-stage-metal',
            '--iplr',
            '--sl=$outputPath',
            '--spirv=$outputPath.spirv',
            '--input=$fragPath',
            '--input-type=frag',
            '--include=$fragDir',
            '--include=$shaderLibDir',
          ],
          exception: blockedException,
        ),
      ]);
      final shaderCompiler = ShaderCompiler(
        processManager: processManager,
        logger: logger,
        fileSystem: fileSystem,
        artifacts: artifacts,
        platform: FakePlatform(operatingSystem: 'windows'),
      );

      final bool success1 = await shaderCompiler.compileShader(
        input: fileSystem.file(fragPath),
        outputPath: outputPath,
        targetPlatform: TargetPlatform.ios,
        fatal: false,
      );
      expect(success1, false);

      final String firstErrorLog = logger.errorText;
      expect(firstErrorLog, contains('blocked by system'));

      const headerLine = '------------------------------------------------------------------------';
      expect(headerLine.allMatches(logger.errorText).length, 2);

      final bool success2 = await shaderCompiler.compileShader(
        input: fileSystem.file(fragPath),
        outputPath: outputPath,
        targetPlatform: TargetPlatform.ios,
        fatal: false,
      );
      expect(success2, false);

      expect(headerLine.allMatches(logger.errorText).length, 2);
    });
  });
}
