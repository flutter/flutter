// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/test_compiler.dart';
import 'package:mockito/mockito.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('TestCompiler', () {
    testUsingContext('compiles test file with no errors', () async {
      fs.file('pubspec.yaml').createSync();
      fs.file('.packages').createSync();
      fs.file('test/foo.dart').createSync(recursive: true);
      final MockResidentCompiler residentCompiler = MockResidentCompiler();
      final TestCompiler testCompiler = FakeTestCompiler(
        false,
        FlutterProject.current(),
        residentCompiler,
      );
      when(residentCompiler.recompile(
        'test/foo.dart',
        <Uri>[Uri.parse('test/foo.dart')],
        outputPath: testCompiler.outputDill.path,
      )).thenAnswer((Invocation invocation) async {
        fs.file('abc.dill').createSync();
        return const CompilerOutput('abc.dill', 0, <Uri>[]);
      });

      expect(await testCompiler.compile('test/foo.dart'), 'test/foo.dart.dill');
      expect(fs.file('test/foo.dart.dill').existsSync(), true);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('does not compile test file with errors', () async {
      fs.file('pubspec.yaml').createSync();
      fs.file('.packages').createSync();
      fs.file('test/foo.dart').createSync(recursive: true);
      final MockResidentCompiler residentCompiler = MockResidentCompiler();
      final TestCompiler testCompiler = FakeTestCompiler(
        false,
        FlutterProject.current(),
        residentCompiler,
      );
      when(residentCompiler.recompile(
        'test/foo.dart',
        <Uri>[Uri.parse('test/foo.dart')],
        outputPath: testCompiler.outputDill.path,
      )).thenAnswer((Invocation invocation) async {
        fs.file('abc.dill').createSync();
        return const CompilerOutput('abc.dill', 1, <Uri>[]);
      });

      expect(await testCompiler.compile('test/foo.dart'), null);
      expect(fs.file('test/foo.dart.dill').existsSync(), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });
  });
}

/// Override the creation of the Resident Compiler to simplify testing.
class FakeTestCompiler extends TestCompiler {
  FakeTestCompiler(
    bool trackWidgetCreation,
    FlutterProject flutterProject,
    this.residentCompiler,
  ) : super(trackWidgetCreation, flutterProject);

  final MockResidentCompiler residentCompiler;

  @override
  Future<ResidentCompiler> createCompiler() async {
    return residentCompiler;
  }
}

class MockResidentCompiler extends Mock implements ResidentCompiler {}
