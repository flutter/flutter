// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/tools/shader_compiler.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';

void main() {
  late BufferLogger logger;

  setUp(() {
    logger = BufferLogger.test();
  });

  Future<bool> testCompileShader(String source, {required bool targetSkslOnly}) async {
    final Directory tmpDir = globals.fs.systemTempDirectory.createTempSync('shader_compiler_test.');
    final File file = tmpDir.childFile('test_shader.frag')..writeAsStringSync(source);
    final shaderCompiler = ShaderCompiler(
      processManager: globals.processManager,
      logger: logger,
      fileSystem: globals.fs,
      artifacts: globals.artifacts!,
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

  testUsingContext('impellerc .iplr output has correct permissions', () async {
    if (globals.platform.isWindows) {
      return;
    }

    final String flutterRoot = getFlutterRoot();
    final String inkSparklePath = globals.fs.path.join(
      flutterRoot,
      'packages',
      'flutter',
      'lib',
      'src',
      'material',
      'shaders',
      'ink_sparkle.frag',
    );
    final Directory tmpDir = globals.fs.systemTempDirectory.createTempSync('shader_compiler_test.');
    final String inkSparkleOutputPath = globals.fs.path.join(tmpDir.path, 'ink_sparkle.frag');

    final shaderCompiler = ShaderCompiler(
      processManager: globals.processManager,
      logger: logger,
      fileSystem: globals.fs,
      artifacts: globals.artifacts!,
    );
    final bool compileResult = await shaderCompiler.compileShader(
      input: globals.fs.file(inkSparklePath),
      outputPath: inkSparkleOutputPath,
      targetPlatform: TargetPlatform.tester,
    );
    final File resultFile = globals.fs.file(inkSparkleOutputPath);

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

    testUsingContext('fails SkSL compilation', () async {
      await expectLater(
        () => testCompileShader(kShaderWithInput, targetSkslOnly: true),
        throwsA(isA<ShaderCompilerException>()),
      );
      expect(logger.errorText, contains('SkSL does not support inputs'));
    });

    testUsingContext('succeeds with non-SkSL compilation', () async {
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

    testUsingContext('fails SkSL compilation', () async {
      await expectLater(
        () => testCompileShader(kShaderWithUbo, targetSkslOnly: true),
        throwsA(isA<ShaderCompilerException>()),
      );
      expect(logger.errorText, contains('SkSL does not support UBOs or SSBOs'));
    });

    testUsingContext('succeeds with non-SkSL compilation', () async {
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

    testUsingContext('fails SkSL compilation', () async {
      await expectLater(
        () => testCompileShader(kShaderWithTextureArguments, targetSkslOnly: true),
        throwsA(isA<ShaderCompilerException>()),
      );
      expect(
        logger.errorText,
        contains('Only sampler and position arguments are supported in texture() calls'),
      );
    });

    testUsingContext('succeeds with non-SkSL compilation', () async {
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

    testUsingContext('fails SkSL compilation', () async {
      await expectLater(
        () => testCompileShader(kShaderWithUint8Uniforms, targetSkslOnly: true),
        throwsA(isA<ShaderCompilerException>()),
      );
      expect(logger.errorText, contains('SkSL does not support unsigned integers'));
    });

    testUsingContext('fails with non-SkSL compilation', () async {
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

    testUsingContext('fails SkSL compilation', () async {
      await expectLater(
        () => testCompileShader(kShaderWithArrayInitializer, targetSkslOnly: true),
        throwsA(isA<ShaderCompilerException>()),
      );
      expect(logger.errorText, contains('SkSL does not support array initializers'));
    });

    testUsingContext('succeeds with non-SkSL compilation', () async {
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
