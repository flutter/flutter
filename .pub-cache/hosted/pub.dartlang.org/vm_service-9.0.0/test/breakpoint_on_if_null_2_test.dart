// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library breakpoint_in_parts_class;

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE = 21;
const String file = "breakpoint_on_if_null_2_test.dart";

dynamic compareWithMe = 43;

code() {
  compareWithMe = null;
  foo(42);
}

foo(dynamic args) {
  if (args == compareWithMe) {
    print("was null");
  }
  if (args != compareWithMe) {
    print("was not null");
  }
  if (args == 42) {
    print("was 42!");
  }
}

List<String> stops = [];

List<String> expected = [
  "$file:${LINE + 0}:12", // on '=='
  "$file:${LINE + 3}:12", // on '!='
  "$file:${LINE + 4}:5", // on 'print'
  "$file:${LINE + 6}:12", // on '=='
  "$file:${LINE + 7}:5", // on 'print'
  "$file:${LINE + 9}:1", // on ending '}'
];

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtUriAndLine(file, LINE),
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected)
];

main(args) {
  runIsolateTestsSynchronous(
    args,
    tests,
    'breakpoint_on_if_null_2_test.dart',
    testeeConcurrent: code,
    pause_on_start: true,
    pause_on_exit: true,
  );
}
