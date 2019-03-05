// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_runner/build_runner.dart';
import 'package:flutter_tools/src/codegen.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group(CodeGeneratingKernelCompiler, () {
    final MockBuildRunner mockBuildRunner = MockBuildRunner();
    final MockFileSystem mockFileSystem = MockFileSystem();
    final MockFile packagesFile = MockFile();
    final MockFile dillFile = MockFile();
    final MockFile outputFile = MockFile();

    when(mockFileSystem.file('main.app.dill')).thenReturn(dillFile);
    when(mockFileSystem.file('.packages')).thenReturn(packagesFile);
    when(mockFileSystem.file('output.app.dill')).thenReturn(outputFile);
    when(packagesFile.exists()).thenAnswer((Invocation invocation) async => true);
    when(dillFile.exists()).thenAnswer((Invocation invocation) async => true);
    when(outputFile.exists()).thenAnswer((Invocation invocation) async => true);
    when(dillFile.readAsBytes()).thenAnswer((Invocation invocation) async => <int>[0, 1, 2, 3]);

    testUsingContext('delegates to build_runner', () async {
      const CodeGeneratingKernelCompiler kernelCompiler = CodeGeneratingKernelCompiler();
      when(mockBuildRunner.build(
        aot: anyNamed('aot'),
        extraFrontEndOptions: anyNamed('extraFrontEndOptions'),
        linkPlatformKernelIn: anyNamed('linkPlatformKernelIn'),
        mainPath: anyNamed('mainPath'),
        targetProductVm: anyNamed('targetProductVm'),
        trackWidgetCreation: anyNamed('trackWidgetCreation'),
      )).thenAnswer((Invocation invocation) async {
        return CodeGenerationResult(fs.file('.packages'), fs.file('main.app.dill'));
      });
      final CompilerOutput buildResult = await kernelCompiler.compile(
        outputFilePath: 'output.app.dill',
      );
      expect(buildResult.outputFilename, 'output.app.dill');
      expect(buildResult.errorCount, 0);
      verify(outputFile.writeAsBytes(<int>[0, 1, 2, 3])).called(1);
    }, overrides: <Type, Generator>{
      CodeGenerator: () => mockBuildRunner,
      FileSystem: () => mockFileSystem,
    });
  });
}

class MockBuildRunner extends Mock implements BuildRunner {}
class MockFileSystem extends Mock implements FileSystem {}
class MockFile extends Mock implements File {}
