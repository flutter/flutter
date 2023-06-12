// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "breakpoints_with_mixin_lib1.dart";
import "breakpoints_with_mixin_lib2.dart";
import "breakpoints_with_mixin_lib3.dart";
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const String testFilename = "breakpoints_with_mixin_test.dart";
const int testCodeLineStart = 17;
const String lib3Filename = "breakpoints_with_mixin_lib3.dart";
const int lib3Bp1 = 7;
const int lib3Bp2 = 13;

void code() {
  Test1 test1 = Test1();
  test1.foo();
  Test2 test2 = Test2();
  test2.foo();
  Foo foo = Foo();
  foo.foo();
  Bar bar = Bar();
  bar.bar();
  test1.foo();
  test2.foo();
  foo.foo();
  bar.bar();
}

List<String> stops = [];

List<String> expected = [
  "$lib3Filename:$lib3Bp1:5 ($testFilename:${testCodeLineStart + 2}:9)",
  "$lib3Filename:$lib3Bp1:5 ($testFilename:${testCodeLineStart + 4}:9)",
  "$lib3Filename:$lib3Bp1:5 ($testFilename:${testCodeLineStart + 6}:7)",
  "$lib3Filename:$lib3Bp2:5 ($testFilename:${testCodeLineStart + 8}:7)",
  "$lib3Filename:$lib3Bp1:5 ($testFilename:${testCodeLineStart + 9}:9)",
  "$lib3Filename:$lib3Bp1:5 ($testFilename:${testCodeLineStart + 10}:9)",
  "$lib3Filename:$lib3Bp1:5 ($testFilename:${testCodeLineStart + 11}:7)",
  "$lib3Filename:$lib3Bp2:5 ($testFilename:${testCodeLineStart + 12}:7)",
];

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtUriAndLine(lib3Filename, lib3Bp1),
  setBreakpointAtUriAndLine(lib3Filename, lib3Bp2),
  resumeProgramRecordingStops(stops, true),
  checkRecordedStops(stops, expected)
];

main(args) {
  runIsolateTestsSynchronous(
    args,
    tests,
    'breakpoints_with_mixin_test.dart',
    testeeConcurrent: code,
    pause_on_start: true,
    pause_on_exit: true,
  );
}
