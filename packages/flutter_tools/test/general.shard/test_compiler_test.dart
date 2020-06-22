// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/test_compiler.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/testbed.dart';

final Platform linuxPlatform = FakePlatform(
  operatingSystem: 'linux',
  environment: <String, String>{},
);

void main() {
  group(TestCompiler, () {
    Testbed testbed;
    FakeTestCompiler testCompiler;
    MockResidentCompiler residentCompiler;

    setUp(() {
      testbed = Testbed(
        overrides: <Type, Generator>{
          Platform: () => linuxPlatform,
        },
        setup: () async {
          globals.fs.file('pubspec.yaml').createSync();
          globals.fs.file('.packages').writeAsStringSync('flutter_test:flutter_test/');
          globals.fs.file('test/foo.dart').createSync(recursive: true);
          residentCompiler = MockResidentCompiler();
          testCompiler = FakeTestCompiler(
            BuildMode.debug,
            false,
            FlutterProject.current(),
            residentCompiler,
          );
        },
      );
    });

    test('Reports a dill file when compile is successful', () => testbed.run(() async {
      when(residentCompiler.recompile(
        any,
        <Uri>[Uri.parse('test/foo.dart')],
        outputPath: testCompiler.outputDill.path,
        packageConfig: anyNamed('packageConfig'),
      )).thenAnswer((Invocation invocation) async {
        globals.fs.file('abc.dill').createSync();
        return const CompilerOutput('abc.dill', 0, <Uri>[]);
      });

      expect(await testCompiler.compile(Uri.parse('test/foo.dart')), 'test/foo.dart.dill');
      expect(globals.fs.file('test/foo.dart.dill'), exists);
    }));

    test('Reports null when a compile fails', () => testbed.run(() async {
      when(residentCompiler.recompile(
        any,
        <Uri>[Uri.parse('test/foo.dart')],
        outputPath: testCompiler.outputDill.path,
        packageConfig: anyNamed('packageConfig'),
      )).thenAnswer((Invocation invocation) async {
        globals.fs.file('abc.dill').createSync();
        return const CompilerOutput('abc.dill', 1, <Uri>[]);
      });

      expect(await testCompiler.compile(Uri.parse('test/foo.dart')), null);
      expect(globals.fs.file('test/foo.dart.dill'), isNot(exists));
      verify(residentCompiler.shutdown()).called(1);
    }));

    test('Disposing test compiler shuts down backing compiler', () => testbed.run(() async {
      testCompiler.compiler = residentCompiler;

      expect(testCompiler.compilerController.isClosed, false);

      await testCompiler.dispose();

      expect(testCompiler.compilerController.isClosed, true);
      verify(residentCompiler.shutdown()).called(1);
    }));

    test('Reports an error when there is no dependency on flutter_test', () => testbed.run(() async {
      globals.fs.file('.packages').writeAsStringSync('\n');

      expect(await testCompiler.compile(Uri.parse('test/foo.dart')), null);
      expect(testLogger.errorText, contains('Error: cannot run without a dependency on "package:flutter_test"'));
      verifyNever(residentCompiler.recompile(
        any,
        <Uri>[Uri.parse('test/foo.dart')],
        outputPath: testCompiler.outputDill.path,
        packageConfig: anyNamed('packageConfig'),
      ));
    }));
  });
}

/// Override the creation of the Resident Compiler to simplify testing.
class FakeTestCompiler extends TestCompiler {
  FakeTestCompiler(
    BuildMode buildMode,
    bool trackWidgetCreation,
    FlutterProject flutterProject,
    this.residentCompiler,
  ) : super(buildMode, trackWidgetCreation, flutterProject, <String>[]);

  final MockResidentCompiler residentCompiler;

  @override
  Future<ResidentCompiler> createCompiler() async {
    return residentCompiler;
  }
}

class MockResidentCompiler extends Mock implements ResidentCompiler {}
