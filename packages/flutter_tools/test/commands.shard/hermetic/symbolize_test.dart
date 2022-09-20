// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/symbolize.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late FakeStdio stdio;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    stdio = FakeStdio();
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
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize']);

    expect(result, throwsToolExit(message: '"--debug-info" is required to symbolize stack traces.'));
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });

  testUsingContext('symbolize exits when --debug-info dwarf file is missing', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize', '--debug-info=app.debug']);

    expect(result, throwsToolExit(message: 'app.debug does not exist.'));
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });

  testUsingContext('symbolize exits when --debug-info dSYM is missing', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize', '--debug-info=app.dSYM']);

    expect(result, throwsToolExit(message: 'app.dSYM does not exist.'));
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });

  testUsingContext('symbolize exits when --input file is missing', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    fileSystem.file('app.debug').createSync();
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize', '--debug-info=app.debug', '--input=foo.stack', '--output=results/foo.result']);

    expect(result, throwsToolExit(message: ''));
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });

  testUsingContext('symbolize succeeds when DwarfSymbolizationService does not throw', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    fileSystem.file('app.debug').writeAsBytesSync(<int>[1, 2, 3]);
    fileSystem.file('foo.stack').writeAsStringSync('hello');

    await createTestCommandRunner(command)
      .run(const <String>['symbolize', '--debug-info=app.debug', '--input=foo.stack', '--output=results/foo.result']);

    expect(fileSystem.file('results/foo.result'), exists);
    expect(fileSystem.file('results/foo.result').readAsBytesSync(), <int>[104, 101, 108, 108, 111, 10]); // hello
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });

  testUsingContext('symbolize throws when DwarfSymbolizationService throws', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: ThrowingDwarfSymbolizationService(),
    );

    fileSystem.file('app.debug').writeAsBytesSync(<int>[1, 2, 3]);
    fileSystem.file('foo.stack').writeAsStringSync('hello');

    expect(
      createTestCommandRunner(command).run(const <String>[
        'symbolize', '--debug-info=app.debug', '--input=foo.stack', '--output=results/foo.result',
      ]),
      throwsToolExit(message: 'test'),
    );
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });
}

class ThrowingDwarfSymbolizationService extends Fake implements DwarfSymbolizationService {
  @override
  Future<void> decode({
    required Stream<List<int>> input,
    required IOSink output,
    required Uint8List symbols,
  }) async {
    throwToolExit('test');
  }
}
