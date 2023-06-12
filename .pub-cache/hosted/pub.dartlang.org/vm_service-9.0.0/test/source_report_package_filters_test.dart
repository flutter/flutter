// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:math';
import 'package:test/test.dart';
import 'package:test_package/has_part.dart';
import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void testFunction() {
  // Use functions from various packages, so we can get coverage for them.
  print(sqrt(123)); // dart:math
  print(anything); // package:test/test.dart
  print(decodeBase64("SGkh")); // package:vm_service/vm_service.dart
  print(removeAdjacentDuplicates([])); // common/service_test_common.dart
  foo(); // package:test_package/has_part.dart

  debugger();
}

IsolateTest filterTestImpl(List<String> filters, Function(Set<String>) check) {
  return (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;

    final report = await service.getSourceReport(
      isolateId,
      [SourceReportKind.kCoverage],
      forceCompile: true,
      libraryFilters: filters,
    );
    check(Set.of(report.scripts!.map((s) => s.uri!)));
  };
}

IsolateTest filterTestExactlyMatches(
        List<String> filters, List<String> expectedScripts) =>
    filterTestImpl(filters, (Set<String> scripts) {
      expect(scripts, unorderedEquals(expectedScripts));
    });

IsolateTest filterTestContains(
        List<String> filters, List<String> expectedScripts) =>
    filterTestImpl(filters, (Set<String> scripts) {
      expect(scripts, containsAll(expectedScripts));
    });

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  filterTestExactlyMatches(
    ['package:test_pack'],
    [
      'package:test_package/has_part.dart',
      'package:test_package/the_part.dart',
      'package:test_package/the_part_2.dart',
    ],
  ),
  filterTestExactlyMatches(
    ['package:test_package/'],
    [
      'package:test_package/has_part.dart',
      'package:test_package/the_part.dart',
      'package:test_package/the_part_2.dart',
    ],
  ),
  filterTestExactlyMatches(
    ['zzzzzzzzzzz'],
    [],
  ),
  filterTestContains(
    ['dart:math'],
    ['dart:math'],
  ),
  filterTestContains(
    ['package:test/', 'package:vm'],
    ['package:test/test.dart', 'package:vm_service/vm_service.dart'],
  ),
  resumeIsolate,
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'source_report_package_filters_test.dart',
      testeeConcurrent: testFunction,
    );
