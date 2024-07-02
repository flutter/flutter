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
        const Utf8Encoder().convert('Hello, World\n'),
      ]),
      symbols: Uint8List(0),
      output: IOSink(output.sink),
    ));

    await expectLater(
      output.stream.transform(utf8.decoder),
      emits('Hello, World'),
    );
  });


  testUsingContext('symbolize exits when --debug-info and --unit-id-debug-info arguments are missing', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize']);

    expect(result, throwsToolExit(message: 'Either "--debug-info" or "--unit-id-debug-info" is required to symbolize stack traces.'));
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

  testUsingContext('symbolize exits when --unit-id-debug-info dwarf file is missing', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize', '--unit-id-debug-info=$rootLoadingUnitId:app.debug']);

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

  testUsingContext('symbolize exits when --unit-id-debug-info dSYM is missing', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize', '--unit-id-debug-info=$rootLoadingUnitId:app.dSYM']);

    expect(result, throwsToolExit(message: 'app.dSYM does not exist.'));
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });

  testUsingContext('symbolize exits if --unit-id-debug-info is just given a path', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    fileSystem.file('app.debug').createSync();
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize', '--unit-id-debug-info=app.debug']);

    expect(result, throwsToolExit(message: 'The argument to "--unit-id-debug-info" must contain a unit ID and path,'
            ' separated by ":": "app.debug".'));
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });

  testUsingContext('symbolize exits if the unit id for --unit-id-debug-info is not a valid integer', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    fileSystem.file('app.debug').createSync();
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize', '--unit-id-debug-info=foo:app.debug']);

    expect(result, throwsToolExit(message: 'The argument to "--unit-id-debug-info" must begin with'
            ' a unit ID: "foo" is not an integer.'));
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });

  testUsingContext('symbolize exits when different paths are given for the root loading unit via --debug-info and --unit-id-debug-info', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    fileSystem.file('app.debug').createSync();
    fileSystem.file('app2.debug').createSync();
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize', '--debug-info=app.debug', '--unit-id-debug-info=$rootLoadingUnitId:app2.debug']);

    expect(result, throwsToolExit(message: 'Different paths were given for'
            ' the same loading unit $rootLoadingUnitId: "app.debug" and'
            ' "app2.debug".'));
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });

  testUsingContext('symbolize exits when different paths are given for a non-root loading unit via --unit-id-debug-info', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    fileSystem.file('app.debug').createSync();
    fileSystem.file('app2.debug').createSync();
    fileSystem.file('app3.debug').createSync();
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize', '--debug-info=app.debug', '--unit-id-debug-info=${rootLoadingUnitId+1}:app2.debug', '--unit-id-debug-info=${rootLoadingUnitId+1}:app3.debug']);

    expect(result, throwsToolExit(message: 'Different paths were given for'
            ' the same loading unit ${rootLoadingUnitId+1}: "app2.debug" and'
            ' "app3.debug".'));
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

  testUsingContext('symbolize exits when --debug-info argument is missing and --unit-id-debug-info is not provided for the root loading unit', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    fileSystem.file('app.debug').createSync();
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolize', '--unit-id-debug-info=${rootLoadingUnitId+1}:app.debug']);

    expect(result, throwsToolExit(message: 'Missing debug info for the root loading unit (id $rootLoadingUnitId).'));
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

  testUsingContext('symbolize succeeds when DwarfSymbolizationService with a single --unit-id-debug-info argument for the root loading unit does not throw', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    fileSystem.file('app.debug').writeAsBytesSync(<int>[1, 2, 3]);
    fileSystem.file('foo.stack').writeAsStringSync('hello');

    await createTestCommandRunner(command)
      .run(const <String>['symbolize', '--unit-id-debug-info=$rootLoadingUnitId:app.debug', '--input=foo.stack', '--output=results/foo.result']);

    expect(fileSystem.file('results/foo.result'), exists);
    expect(fileSystem.file('results/foo.result').readAsBytesSync(), <int>[104, 101, 108, 108, 111, 10]); // hello
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });

  testUsingContext('symbolize succeeds when DwarfSymbolizationService with --debug-info and --unit-id-debug-info arguments does not throw', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    fileSystem.file('app.debug').writeAsBytesSync(<int>[1, 2, 3]);
    fileSystem.file('app.debug-2.part.so').writeAsBytesSync(<int>[1, 2, 3]);
    fileSystem.file('foo.stack').writeAsStringSync('hello');

    await createTestCommandRunner(command)
      .run(const <String>['symbolize', '--debug-info=app.debug', '--unit-id-debug-info=${rootLoadingUnitId+1}:app.debug-2.part.so', '--input=foo.stack', '--output=results/foo.result']);

    expect(fileSystem.file('results/foo.result'), exists);
    expect(fileSystem.file('results/foo.result').readAsBytesSync(), <int>[104, 101, 108, 108, 111, 10]); // hello
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });

  testUsingContext('symbolize succeeds when DwarfSymbolizationService with multiple --unit-id-debug-info arguments does not throw', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: DwarfSymbolizationService.test(),
    );
    fileSystem.file('app.debug').writeAsBytesSync(<int>[1, 2, 3]);
    fileSystem.file('app.debug-2.part.so').writeAsBytesSync(<int>[1, 2, 3]);
    fileSystem.file('foo.stack').writeAsStringSync('hello');

    await createTestCommandRunner(command)
      .run(const <String>['symbolize', '--unit-id-debug-info=$rootLoadingUnitId:app.debug', '--unit-id-debug-info=${rootLoadingUnitId+1}:app.debug-2.part.so', '--input=foo.stack', '--output=results/foo.result']);

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

  testUsingContext('symbolize throws when DwarfSymbolizationService with a single --unit-id-debug-info argument for the root loading unit throws', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: ThrowingDwarfSymbolizationService(),
    );

    fileSystem.file('app.debug').writeAsBytesSync(<int>[1, 2, 3]);
    fileSystem.file('foo.stack').writeAsStringSync('hello');

    expect(
      createTestCommandRunner(command).run(const <String>[
        'symbolize', '--unit-id-debug-info=$rootLoadingUnitId:app.debug', '--input=foo.stack', '--output=results/foo.result',
      ]),
      throwsToolExit(message: 'test'),
    );
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });

  testUsingContext('symbolize throws when DwarfSymbolizationService with --debug-info and --unit-id-debug-info arguments throws', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: ThrowingDwarfSymbolizationService(),
    );

    fileSystem.file('app.debug').writeAsBytesSync(<int>[1, 2, 3]);
    fileSystem.file('app.debug-2.part.so').writeAsBytesSync(<int>[1, 2, 3]);
    fileSystem.file('foo.stack').writeAsStringSync('hello');

    expect(
      createTestCommandRunner(command).run(const <String>[
        'symbolize', '--debug-info=app.debug', '--unit-id-debug-info=${rootLoadingUnitId+1}:app.debug-2.part.so', '--input=foo.stack', '--output=results/foo.result',
      ]),
      throwsToolExit(message: 'test'),
    );
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });

  testUsingContext('symbolize throws when DwarfSymbolizationService with multiple --unit-id-debug-info arguments throws', () async {
    final SymbolizeCommand command = SymbolizeCommand(
      stdio: stdio,
      fileSystem: fileSystem,
      dwarfSymbolizationService: ThrowingDwarfSymbolizationService(),
    );

    fileSystem.file('app.debug').writeAsBytesSync(<int>[1, 2, 3]);
    fileSystem.file('app.debug-2.part.so').writeAsBytesSync(<int>[1, 2, 3]);
    fileSystem.file('foo.stack').writeAsStringSync('hello');

    expect(
      createTestCommandRunner(command).run(const <String>[
        'symbolize', '--unit-id-debug-info=$rootLoadingUnitId:app.debug', '--unit-id-debug-info=${rootLoadingUnitId+1}:app.debug-2.part.so', '--input=foo.stack', '--output=results/foo.result',
      ]),
      throwsToolExit(message: 'test'),
    );
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences.test(),
  });
}

class ThrowingDwarfSymbolizationService extends Fake implements DwarfSymbolizationService {
  @override
  Future<void> decodeWithUnits({
    required Stream<List<int>> input,
    required IOSink output,
    required Map<int, Uint8List> unitSymbols,
  }) async {
    throwToolExit('test');
  }
}
