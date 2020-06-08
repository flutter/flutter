// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/codegen.dart';
import 'package:flutter_tools/src/commands/generate.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;
  MockCodeGenerator mockCodeGenerator;
  MockCodegenDaemon mockCodegenDaemon;

  setUpAll(() {
    Cache.disableLocking();
  });

  tearDownAll(() {
    Cache.enableLocking();
  });

  setUp(() {
    mockCodegenDaemon = MockCodegenDaemon();
    mockCodeGenerator = MockCodeGenerator();
    when(mockCodegenDaemon.buildResults).thenAnswer((Invocation invocation) {
      return Stream<CodegenStatus>.fromIterable(<CodegenStatus>[
        CodegenStatus.Started,
        CodegenStatus.Succeeded,
      ]);
    });
    when(mockCodeGenerator.daemon(any)).thenAnswer((Invocation invocation) async {
      return mockCodegenDaemon;
    });
    testbed = Testbed(overrides: <Type, Generator>{
      CodeGenerator: () => mockCodeGenerator,
    });
  });

  test('Outputs deprecation warning from flutter generate', () => testbed.run(() async {
    final GenerateCommand command = GenerateCommand();
    applyMocksToCommand(command);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart'))
      .createSync(recursive: true);
    globals.fs.currentDirectory
      .childDirectory('.dart_tool')
      .childDirectory('build')
      .childDirectory('abcdefg')
      .createSync(recursive: true);

    await createTestCommandRunner(command)
      .run(const <String>['generate']);

    expect(testLogger.errorText, contains(
      '"flutter generate" is deprecated, use "dart pub run build_runner" instead.'
    ));
    expect(testLogger.errorText, contains(
      'build_runner: 1.10.0'
    ));
  }));

  test('Outputs error information from flutter generate', () => testbed.run(() async {
    final GenerateCommand command = GenerateCommand();
    applyMocksToCommand(command);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart'))
      .createSync(recursive: true);

    globals.fs.currentDirectory
      .childDirectory('.dart_tool')
      .childDirectory('build')
      .childDirectory('abcdefg')
      .childDirectory('error_cache')
      .childFile('foo_error')
      ..createSync(recursive: true)
      ..writeAsStringSync(json.encode(<dynamic>[
        'foo builder',
        <dynamic>[
          'a',
          'b',
          StackTrace.current.toString(),
        ]
      ]));

    await createTestCommandRunner(command)
      .run(const <String>['generate']);

    expect(testLogger.errorText, contains('a'));
    expect(testLogger.errorText, contains('b'));
    expect(testLogger.errorText, contains('foo builder'));
    expect(testLogger.errorText, isNot(contains('Error reading error')));
  }));
}

class MockCodeGenerator extends Mock implements CodeGenerator { }
class MockCodegenDaemon extends Mock implements CodegenDaemon { }
