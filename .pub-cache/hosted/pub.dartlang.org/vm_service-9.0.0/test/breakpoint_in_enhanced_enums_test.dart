// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedOptions=--enable-experiment=enhanced-enums

// @dart=2.17

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 23;
const int LINE_B = LINE_A + 11;
const int LINE_C = LINE_B + 4;
const int LINE_D = LINE_C + 4;
const int LINE_E = LINE_D + 5;
const int LINE_F = LINE_E + 4;
const int LINE_G = LINE_F + 5;
const int LINE_H = LINE_G + 4;

mixin M on Object {
  int mixedInMethod() {
    print('mixedInMethod'); // LINE_A
    return 0;
  }
}

enum E with M {
  e1,
  e2,
  e3;

  void instanceMethod() {
    print('instanceMethod'); // LINE_B
  }

  static void staticMethod() {
    print('staticMethod'); // LINE_C
  }

  int get getter {
    print('getter'); // LINE_D
    return 0;
  }

  set setter(int x) {
    print('setter'); // LINE_E
  }

  static int get staticGetter {
    print('staticGetter'); // LINE_F
    return 0;
  }

  static set staticSetter(int x) {
    print('staticSetter'); // LINE_G
  }

  String toString() {
    print('overriden toString'); // LINE_H
    return '';
  }
}

void testMain() {
  E.staticMethod();
  E.staticGetter;
  E.staticSetter = 42;
  final e = E.e1;
  e.mixedInMethod();
  e.instanceMethod();
  e.getter;
  e.setter = 42;
  e.toString();
}

const lines = <int>[
  LINE_C,
  LINE_F,
  LINE_G,
  LINE_A,
  LINE_B,
  LINE_D,
  LINE_E,
  LINE_H,
];

const fileName = 'breakpoint_in_enhanced_enums_test.dart';
final expected = <String>[
  for (final line in lines) '$fileName:$line:5',
];

final stops = <String>[];

final tests = <IsolateTest>[
  hasPausedAtStart,
  for (final line in lines) setBreakpointAtLine(line),
  resumeProgramRecordingStops(stops, false),
  checkRecordedStops(stops, expected),
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      fileName,
      testeeConcurrent: testMain,
      pause_on_start: true,
      pause_on_exit: true,
      experiments: ['enhanced-enums'],
    );
