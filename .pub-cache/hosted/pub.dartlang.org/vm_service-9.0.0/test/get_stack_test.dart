// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--verbose_debug

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 33;
const LINE_B = 35;

Future<void> testMain() async {
  await func1();
}

Future func1() async => await func2();
Future func2() async => await func3();
Future func3() async => await func4();
Future func4() async => await func5();
Future func5() async => await func6();
Future func6() async => await func7();
Future func7() async => await func8();
Future func8() async => await func9();
Future func9() async => await func10();
Future func10() async {
  debugger(); // LINE_A
  await 0;
  debugger(); // LINE_B
  print("Hello, world!");
}

void expectFrame(
    final frame, final kindExpectation, final codeNameExpectation) {
  expect(frame.kind, kindExpectation);
  expect(frame.code?.name, codeNameExpectation);
}

void expectFrames(final frames, final expectKindAndCodeName) {
  for (int i = 0; i < expectKindAndCodeName.length; i++) {
    expectFrame(
        frames[i], expectKindAndCodeName[i][0], expectKindAndCodeName[i][1]);
  }
}

final tests = <IsolateTest>[
  // Before the first await.
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  // At LINE_A we're still running sync. so no asyncCausalFrames.
  (VmService service, IsolateRef isolateRef) async {
    final result = await service.getStack(isolateRef.id!);

    expect(result.frames, hasLength(16));
    expect(result.asyncCausalFrames, isNull);
    expect(result.awaiterFrames, hasLength(16));

    expectFrames(result.frames, [
      [equals('Regular'), endsWith(' func10')],
      [equals('Regular'), endsWith(' func9')],
      [equals('Regular'), endsWith(' func8')],
      [equals('Regular'), endsWith(' func7')],
      [equals('Regular'), endsWith(' func6')],
      [equals('Regular'), endsWith(' func5')],
      [equals('Regular'), endsWith(' func4')],
      [equals('Regular'), endsWith(' func3')],
      [equals('Regular'), endsWith(' func2')],
      [equals('Regular'), endsWith(' func1')],
      [equals('Regular'), endsWith(' testMain')],
    ]);

    expectFrames(result.awaiterFrames, [
      [equals('AsyncActivation'), endsWith(' func10')],
      [equals('AsyncActivation'), endsWith(' func9')],
      [equals('AsyncActivation'), endsWith(' func8')],
      [equals('AsyncActivation'), endsWith(' func7')],
      [equals('AsyncActivation'), endsWith(' func6')],
      [equals('AsyncActivation'), endsWith(' func5')],
      [equals('AsyncActivation'), endsWith(' func4')],
      [equals('AsyncActivation'), endsWith(' func3')],
      [equals('AsyncActivation'), endsWith(' func2')],
      [equals('AsyncActivation'), endsWith(' func1')],
      [equals('AsyncActivation'), endsWith(' testMain')],
    ]);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  // After resuming the continuation - i.e. running async.
  (VmService service, IsolateRef isolateRef) async {
    final result = await service.getStack(isolateRef.id!);

    expect(result.frames, hasLength(6));
    expect(result.asyncCausalFrames, hasLength(26));
    expect(result.awaiterFrames, hasLength(13));

    expectFrames(result.frames!, [
      [equals('Regular'), endsWith(' func10')],
      [equals('Regular'), endsWith(' _RootZone.runUnary')],
      [equals('Regular'), anything], // Internal mech. ..
      [equals('Regular'), anything],
      [equals('Regular'), anything],
      [equals('Regular'), endsWith(' _RawReceivePortImpl._handleMessage')],
    ]);

    expectFrames(result.asyncCausalFrames, [
      [equals('Regular'), endsWith(' func10')],
      [equals('AsyncSuspensionMarker'), isNull],
      [equals('AsyncCausal'), endsWith(' func9')],
      [equals('AsyncSuspensionMarker'), isNull],
      [equals('AsyncCausal'), endsWith(' func8')],
      [equals('AsyncSuspensionMarker'), isNull],
      [equals('AsyncCausal'), endsWith(' func7')],
      [equals('AsyncSuspensionMarker'), isNull],
      [equals('AsyncCausal'), endsWith(' func6')],
      [equals('AsyncSuspensionMarker'), isNull],
      [equals('AsyncCausal'), endsWith(' func5')],
      [equals('AsyncSuspensionMarker'), isNull],
      [equals('AsyncCausal'), endsWith(' func4')],
      [equals('AsyncSuspensionMarker'), isNull],
      [equals('AsyncCausal'), endsWith(' func3')],
      [equals('AsyncSuspensionMarker'), isNull],
      [equals('AsyncCausal'), endsWith(' func2')],
      [equals('AsyncSuspensionMarker'), isNull],
      [equals('AsyncCausal'), endsWith(' func1')],
      [equals('AsyncSuspensionMarker'), isNull],
      [equals('AsyncCausal'), endsWith(' testMain')],
      [equals('AsyncSuspensionMarker'), isNull],
    ]);

    expectFrames(result.awaiterFrames, [
      [equals('AsyncActivation'), endsWith(' func10')],
      [equals('AsyncActivation'), endsWith(' func9')],
      [equals('AsyncActivation'), endsWith(' func8')],
      [equals('AsyncActivation'), endsWith(' func7')],
      [equals('AsyncActivation'), endsWith(' func6')],
      [equals('AsyncActivation'), endsWith(' func5')],
      [equals('AsyncActivation'), endsWith(' func4')],
      [equals('AsyncActivation'), endsWith(' func3')],
      [equals('AsyncActivation'), endsWith(' func2')],
      [equals('AsyncActivation'), endsWith(' func1')],
      [equals('AsyncActivation'), endsWith(' testMain')],
      [equals('AsyncActivation'), endsWith(' _ServiceTesteeRunner.run')],
      [equals('AsyncActivation'), endsWith(' runIsolateTests')],
    ]);
  },
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'get_stack_test.dart',
      testeeConcurrent: testMain,
    );
