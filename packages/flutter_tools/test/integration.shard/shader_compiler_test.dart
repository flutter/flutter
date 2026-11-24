// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/tools/shader_compiler.dart';
import 'package:flutter_tools/src/cache.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late BufferLogger logger;
  late Artifacts artifacts;

  setUp(() {
    logger = BufferLogger.test();
    final String flutterRoot = getFlutterRoot();
    final cache = Cache.test(
      rootOverride: fileSystem.directory(flutterRoot),
      flutterRoot: flutterRoot,
      fileSystem: fileSystem,
      logger: logger,
      platform: platform,
      processManager: processManager,
    );
    artifacts = CachedArtifacts(
      fileSystem: fileSystem,
      cache: cache,
      platform: platform,
      operatingSystemUtils: cache.osUtils,
    );
  });

  Future<bool> testCompileShader(String source, {required bool targetSkslOnly}) async {
    final Directory tmpDir = fileSystem.systemTempDirectory.createTempSync('shader_compiler_test.');
    addTearDown(() => tryToDelete(tmpDir));
    final File file = tmpDir.childFile('test_shader.frag')..writeAsStringSync(source);
    final shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
      platform: platform,
    );
    return shaderCompiler.compileShader(
      input: file,
      outputPath: tmpDir.childFile('test_shader.frag.out').path,
      targetPlatform: targetSkslOnly
          // web_javascript compiles to sksl only.
          ? TargetPlatform.web_javascript
          // tester compiles to sksl and runtime-stage-vulkan
          : TargetPlatform.tester,
    );
  }

  testWithoutContext('impellerc .iplr output has correct permissions', () async {
    if (platform.isWindows) {
      return;
    }

    final String flutterRoot = getFlutterRoot();
    final String inkSparklePath = fileSystem.path.join(
      flutterRoot,
      'packages',
      'flutter',
      'lib',
      'src',
      'material',
      'shaders',
      'ink_sparkle.frag',
    );
    final Directory tmpDir = fileSystem.systemTempDirectory.createTempSync('shader_compiler_test.');
    addTearDown(() => tryToDelete(tmpDir));
    final String inkSparkleOutputPath = fileSystem.path.join(tmpDir.path, 'ink_sparkle.frag');

    final shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
      platform: platform,
    );
    final bool compileResult = await shaderCompiler.compileShader(
      input: fileSystem.file(inkSparklePath),
      outputPath: inkSparkleOutputPath,
      targetPlatform: TargetPlatform.tester,
    );
    final File resultFile = fileSystem.file(inkSparkleOutputPath);

    expect(compileResult, true);
    expect(resultFile.existsSync(), true);

    final int expectedMode = int.parse('644', radix: 8);
    expect(resultFile.statSync().mode & expectedMode, equals(expectedMode));
  });

  group('shader with inputs', () {
    const kShaderWithInput = '''
    in float foo;

    out vec4 fragColor;

    void main() {
      fragColor = vec4(1.0, 0.0, 0.0, 1.0);
    }
    ''';

    testWithoutContext('fails SkSL compilation', () async {
      await expectLater(
        () => testCompileShader(kShaderWithInput, targetSkslOnly: true),
        throwsA(isA<ShaderCompilerException>()),
      );
      expect(logger.errorText, contains('SkSL does not support inputs'));
    });

    testWithoutContext('succeeds with non-SkSL compilation', () async {
      final bool compileResult = await testCompileShader(kShaderWithInput, targetSkslOnly: false);
      expect(compileResult, true);
      expect(
        logger.errorText,
        matches(
          r'warning: Shader `.+` is incompatible with SkSL. '
          r'This shader will not load when running with the Skia backend.\n'
          r'impellerc failure: There was a compiler error: '
          r"SkSL does not support inputs: 'foo'",
        ),
      );
    });
  });

  group('shader with UBO', () {
    const kShaderWithUbo = '''
uniform Data {
  vec4 foo;
} data;

out vec4 fragColor;

void main() {
  fragColor = data.foo;
}
''';

    testWithoutContext('fails SkSL compilation', () async {
      await expectLater(
        () => testCompileShader(kShaderWithUbo, targetSkslOnly: true),
        throwsA(isA<ShaderCompilerException>()),
      );
      expect(logger.errorText, contains('SkSL does not support UBOs or SSBOs'));
    });

    testWithoutContext('succeeds with non-SkSL compilation', () async {
      final bool compileResult = await testCompileShader(kShaderWithUbo, targetSkslOnly: false);
      expect(compileResult, true);
      expect(
        logger.errorText,
        matches(
          r'warning: Shader `.+` is incompatible with SkSL. '
          r'This shader will not load when running with the Skia backend.\n'
          r'impellerc failure: There was a compiler error: '
          r"SkSL does not support UBOs or SSBOs: 'data'",
        ),
      );
    });
  });

  group('shader with texture arguments besides position or sampler', () {
    const kShaderWithTextureArguments = '''
uniform sampler2D tex;

out vec4 fragColor;

void main() {
  fragColor = texture(tex, vec2(0.5, 0.3), 0.5);
}
''';

    testWithoutContext('fails SkSL compilation', () async {
      await expectLater(
        () => testCompileShader(kShaderWithTextureArguments, targetSkslOnly: true),
        throwsA(isA<ShaderCompilerException>()),
      );
      expect(
        logger.errorText,
        contains('Only sampler and position arguments are supported in texture() calls'),
      );
    });

    testWithoutContext('succeeds with non-SkSL compilation', () async {
      final bool compileResult = await testCompileShader(
        kShaderWithTextureArguments,
        targetSkslOnly: false,
      );
      expect(compileResult, true);
      expect(
        logger.errorText,
        matches(
          r'warning: Shader `.+` is incompatible with SkSL. '
          r'This shader will not load when running with the Skia backend.\n'
          r'impellerc failure: There was a compiler error: '
          r'Only sampler and position arguments are supported in texture\(\) calls.',
        ),
      );
    });
  });

  group('shader with uint8 uniforms', () {
    const kShaderWithUint8Uniforms = '''
  #version 310 es

  layout(location = 0) uniform uint foo;
  layout(location = 0) out vec4 fragColor;

  void main() {}
  ''';

    testWithoutContext('fails SkSL compilation', () async {
      await expectLater(
        () => testCompileShader(kShaderWithUint8Uniforms, targetSkslOnly: true),
        throwsA(isA<ShaderCompilerException>()),
      );
      expect(logger.errorText, contains('SkSL does not support unsigned integers'));
    });

    testWithoutContext('fails with non-SkSL compilation', () async {
      await expectLater(
        () => testCompileShader(kShaderWithUint8Uniforms, targetSkslOnly: false),
        throwsA(isA<ShaderCompilerException>()),
      );
      expect(logger.errorText, contains('Non-floating-type struct member foo is not supported.'));
    });
  });

  group('shader with array initializer list', () {
    const kShaderWithArrayInitializer = '''
out vec4 fragColor;

void main() {
  float array_with_initializer_list[2] = {1.0, 0.0};
  fragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
''';

    testWithoutContext('fails SkSL compilation', () async {
      await expectLater(
        () => testCompileShader(kShaderWithArrayInitializer, targetSkslOnly: true),
        throwsA(isA<ShaderCompilerException>()),
      );
      expect(logger.errorText, contains('SkSL does not support array initializers'));
    });

    testWithoutContext('succeeds with non-SkSL compilation', () async {
      final bool compilationResult = await testCompileShader(
        kShaderWithArrayInitializer,
        targetSkslOnly: false,
      );
      expect(compilationResult, isTrue);
      expect(
        logger.errorText,
        matches(
          r'warning: Shader `.+` is incompatible with SkSL. '
          r'This shader will not load when running with the Skia backend.\n'
          r'impellerc failure: There was a compiler error: '
          r'SkSL does not support array initializers: .+',
        ),
      );
    });
  });
}
