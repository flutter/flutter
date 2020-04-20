// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/symbolize.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';


void main() {
  MemoryFileSystem fileSystem;
  MockStdio stdio;
  SymbolizeCommand command;
  MockDwarfSymbolizationService mockDwarfSymbolizationService;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    stdio = MockStdio();
    mockDwarfSymbolizationService = MockDwarfSymbolizationService();
    command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: mockDwarfSymbolizationService,
    );
    applyMocksToCommand(command);
  });

  testUsingContext('Regression test for type error in codec', () async {
    final DwarfSymbolizationService symbolizationService = DwarfSymbolizationService.test();
    final StreamController<List<int>> output = StreamController<List<int>>();

    unawaited(symbolizationService.decode(
      input: Stream<Uint8List>.fromIterable(<Uint8List>[
        utf8.encode('Hello, World\n') as Uint8List,
      ]),
      symbols: Uint8List(0),
      output: IOSink(output.sink),
    ));

    await expectLater(
      output.stream.transform(utf8.decoder),
      emits('Hello, World'),
    );
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

  testUsingContext('symbolize succeedes when DwarfSymbolizationService does not throw', () async {
    fileSystem.file('app.debug').writeAsBytesSync(<int>[1, 2, 3]);
    fileSystem.file('foo.stack').writeAsStringSync('hello');

    when(mockDwarfSymbolizationService.decode(
      input: anyNamed('input'),
      output: anyNamed('output'),
      symbols: anyNamed('symbols'))
    ).thenAnswer((Invocation invocation) async {
      // Data is passed correctly to service
      expect((await (invocation.namedArguments[#input] as Stream<List<int>>).toList()).first,
        utf8.encode('hello'));
      expect(invocation.namedArguments[#symbols] as Uint8List, <int>[1, 2, 3,]);
      return;
    });

    await createTestCommandRunner(command)
      .run(const <String>['symbolize', '--debug-info=app.debug', '--input=foo.stack', '--output=results/foo.result']);
  });

  testUsingContext('symbolize throws when DwarfSymbolizationService throws', () async {
    fileSystem.file('app.debug').writeAsBytesSync(<int>[1, 2, 3]);
    fileSystem.file('foo.stack').writeAsStringSync('hello');

    when(mockDwarfSymbolizationService.decode(
      input: anyNamed('input'),
      output: anyNamed('output'),
      symbols: anyNamed('symbols'))
    ).thenThrow(ToolExit('test'));

    expect(
      createTestCommandRunner(command).run(const <String>[
        'symbolize', '--debug-info=app.debug', '--input=foo.stack', '--output=results/foo.result']),
      throwsToolExit(message: 'test'),
    );
  });
}

class MockDwarfSymbolizationService extends Mock implements DwarfSymbolizationService {}
