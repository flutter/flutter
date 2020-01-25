// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/symbolicate.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';


const String exampleTrace = '''
E/flutter (26942): [ERROR:flutter/lib/ui/ui_dart_state.cc(157)] Unhandled Exception: Foo
E/flutter (26942): Warning: This VM has been configured to produce stack traces that violate the Dart standard.
E/flutter (26942): *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
E/flutter (26942): pid: 26942, tid: 26984, name 1.ui
E/flutter (26942): isolate_instructions: 7a25c21000 vm_instructions: 7a25c1c000
E/flutter (26942):     #00 abs 0000007a25c90df7 virt 0000000000076df7 /data/app/io.flutter.examples.hello_world-DpDLl8tmpaYp74McZaFTNw==/lib/arm64/libapp.so
E/flutter (26942):     #01 abs 0000007a25c9e213 virt 0000000000084213 /data/app/io.flutter.examples.hello_world-DpDLl8tmpaYp74McZaFTNw==/lib/arm64/libapp.so
E/flutter (26942):     #02 abs 0000007a25c81433 virt 0000000000067433 /data/app/io.flutter.examples.hello_world-DpDLl8tmpaYp74McZaFTNw==/lib/arm64/libapp.so
E/flutter (26942):     #03 abs 0000007a25c24147 virt 000000000000a147 /data/app/io.flutter.examples.hello_world-DpDLl8tmpaYp74McZaFTNw==/lib/arm64/libapp.so
E/flutter (26942):     #04 abs 0000007a25c2439f virt 000000000000a39f /data/app/io.flutter.examples.hello_world-DpDLl8tmpaYp74McZaFTNw==/lib/arm64/libapp.so
E/flutter (26942):     #05 abs 0000007a25c27d6b virt 000000000000dd6b /data/app/io.flutter.examples.hello_world-DpDLl8tmpaYp74McZaFTNw==/lib/arm64/libapp.so
E/flutter (26942):     #06 abs 0000007a25c25823 virt 000000000000b823 /data/app/io.flutter.examples.hello_world-DpDLl8tmpaYp74McZaFTNw==/lib/arm64/libapp.so
E/flutter (26942):     #07 abs 0000007a25c2659f virt 000000000000c59f /data/app/io.flutter.examples.hello_world-DpDLl8tmpaYp74McZaFTNw==/lib/arm64/libapp.so
E/flutter (26942):     #08 abs 0000007a25c81507 virt 0000000000067507 /data/app/io.flutter.examples.hello_world-DpDLl8tmpaYp74McZaFTNw==/lib/arm64/libapp.so
E/flutter (26942):     #09 abs 0000007a25c9e213 virt 0000000000084213 /data/app/io.flutter.examples.hello_world-DpDLl8tmpaYp74McZaFTNw==/lib/arm64/libapp.so
E/flutter (26942):     #10 abs 0000007a25c4f597 virt 0000000000035597 /data/app/io.flutter.examples.hello_world-DpDLl8tmpaYp74McZaFTNw==/lib/arm64/libapp.so
E/flutter (26942):     #11 abs 0000007a25c9e287 virt 0000000000084287 /data/app/io.flutter.examples.hello_world-DpDLl8tmpaYp74McZaFTNw==/lib/arm64/libapp.so
E/flutter (26942):     #12 abs 0000007a25c4fa13 virt 0000000000035a13 /data/app/io.flutter.examples.hello_world-DpDLl8tmpaYp74McZaFTNw==/lib/arm64/libapp.so
E/flutter (26942):
''';

void main() {
  MemoryFileSystem fileSystem;
  MockStdio stdio;
  SymbolicateCommand command;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    stdio = MockStdio();
    command = SymbolicateCommand(stdio: stdio, fileSystem: fileSystem);
    applyMocksToCommand(command);
  });


  testUsingContext('symbolciate exits when --debug-info argument is missing', () async {
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolicate']);

    expect(result, throwsToolExit(message: '"--debug-info" is required to symbolicate stack traces.'));
  });

  testUsingContext('symbolciate exits when --debug-info file is missing', () async {
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolicate', '--debug-info=app.debug']);

    expect(result, throwsToolExit(message: 'app.debug does not exist.'));
  });

  testUsingContext('symbolciate exits when --input is provided without --output', () async {
    fileSystem.file('app.debug').createSync();
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolicate', '--debug-info=app.debug', '--input=foo.stack']);

    expect(result, throwsToolExit(message: '"--input" and "--output" are only supported when both are provided.'));
  });

  testUsingContext('symbolciate exits when --output is provided without --input', () async {
    fileSystem.file('app.debug').createSync();
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolicate', '--debug-info=app.debug', '--output=foo.stack']);

    expect(result, throwsToolExit(message: '"--input" and "--output" are only supported when both are provided.'));
  });

  testUsingContext('symbolciate exits when --input file is missing', () async {
    fileSystem.file('app.debug').createSync();
    final Future<void> result = createTestCommandRunner(command)
      .run(const <String>['symbolicate', '--debug-info=app.debug', '--input=foo.stack', '--output=results/foo.result']);

    expect(result, throwsToolExit(message: ''));
  });
}
