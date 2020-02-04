// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/codegen.dart';
import 'package:flutter_tools/src/commands/generate.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
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

  test('Outputs error information from flutter generate', () => testbed.run(() async {
    final GenerateCommand command = GenerateCommand();
    final BufferLogger bufferLogger = logger;
    applyMocksToCommand(command);
    fs.file(fs.path.join('lib', 'main.dart'))
      ..createSync(recursive: true);

    fs.currentDirectory
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

    expect(bufferLogger.errorText, contains('a'));
    expect(bufferLogger.errorText, contains('b'));
    expect(bufferLogger.errorText, contains('foo builder'));
    expect(bufferLogger.errorText, isNot(contains('Error reading error')));
  }));
}

class MockCodeGenerator extends Mock implements CodeGenerator { }
class MockCodegenDaemon extends Mock implements CodegenDaemon { }
