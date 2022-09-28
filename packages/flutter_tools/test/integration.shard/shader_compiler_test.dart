// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/targets/shader_compiler.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';

void main() {
  late BufferLogger logger;

  setUp(() {
    logger = BufferLogger.test();
  });

  testUsingContext('impellerc .iplr output has correct permissions', () async {
    if (globals.platform.isWindows) {
      return;
    }

    final String flutterRoot = getFlutterRoot();
    final String inkSparklePath = globals.fs.path.join(flutterRoot,
      'packages', 'flutter', 'lib', 'src', 'material', 'shaders',
      'ink_sparkle.frag');
    final Directory tmpDir = globals.fs.systemTempDirectory.createTempSync(
      'shader_compiler_test.',
    );
    final String inkSparkleOutputPath = globals.fs.path.join(
      tmpDir.path, 'ink_sparkle.frag',
    );

    final ShaderCompiler shaderCompiler = ShaderCompiler(
      processManager: globals.processManager,
      logger: logger,
      fileSystem: globals.fs,
      artifacts: globals.artifacts!,
    );
    final bool compileResult = await shaderCompiler.compileShader(
      input: globals.fs.file(inkSparklePath),
      outputPath: inkSparkleOutputPath,
      target: ShaderTarget.sksl,
    );
    final File resultFile = globals.fs.file(inkSparkleOutputPath);


    expect(compileResult, true);
    expect(resultFile.existsSync(), true);

    final int expectedMode = int.parse('644', radix: 8);
    expect(resultFile.statSync().mode & expectedMode, equals(expectedMode));
  });
}
