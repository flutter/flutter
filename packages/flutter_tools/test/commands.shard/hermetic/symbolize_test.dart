// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/symbolize.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';


void main() {
  MemoryFileSystem fileSystem;
  MockStdio stdio;
  SymbolizeCommand command;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    stdio = MockStdio();
    command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolicationService: MockDwarfSymbolicationService(),
    );
    applyMocksToCommand(command);
  });


  testUsingContext('symbolize exits when --debug-info argument is missing', () async {
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize']);

    expect(result, throwsToolExit(message: '"--debug-info" is required to symbolicate stack traces.'));
  });

  testUsingContext('symbolize exits when --debug-info file is missing', () async {
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize', '--debug-info=app.debug']);

    expect(result, throwsToolExit(message: 'app.debug does not exist.'));
  });

  testUsingContext('symbolize exits when --input file is missing', () async {
    fileSystem.file('app.debug').createSync();
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize', '--debug-info=app.debug', '--input=foo.stack', '--output=results/foo.result']);

    expect(result, throwsToolExit(message: ''));
  });
}

class MockDwarfSymbolicationService extends Mock implements DwarfSymbolicationService {}
