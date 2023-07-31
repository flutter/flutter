// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

String leafFunction() {
  return "some constant";
}

void testFunction() {
  debugger();
  leafFunction();
  debugger();
}

bool allRangesCompiled(coverage) {
  for (int i = 0; i < coverage['ranges'].length; i++) {
    if (!coverage['ranges'][i]['compiled']) {
      return false;
    }
  }
  return true;
}

IsolateTest coverageTest(Map<String, dynamic> expectedRange,
    {required bool reportLines}) {
  return (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final stack = await service.getStack(isolateId);

    // Make sure we are in the right place.
    expect(stack.frames!.length, greaterThanOrEqualTo(1));
    expect(stack.frames![0].function!.name, 'testFunction');

    final root =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    FuncRef funcRef =
        root.functions!.singleWhere((f) => f.name == 'leafFunction');
    Func func = await service.getObject(isolateId, funcRef.id!) as Func;
    final location = func.location!;

    final report = await service.getSourceReport(
      isolateId,
      [SourceReportKind.kCoverage],
      scriptId: location.script!.id,
      tokenPos: location.tokenPos,
      endTokenPos: location.endTokenPos,
      forceCompile: true,
      reportLines: reportLines,
    );
    expect(report.ranges!.length, 1);
    expect(report.ranges![0].toJson(), expectedRange);
    expect(report.scripts!.length, 1);
    expect(
      report.scripts![0].uri,
      endsWith('coverage_leaf_function_test.dart'),
    );
  };
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  coverageTest(
    {
      'scriptIndex': 0,
      'startPos': 399,
      'endPos': 449,
      'compiled': true,
      'coverage': {
        'hits': [],
        'misses': [399]
      }
    },
    reportLines: false,
  ),
  coverageTest(
    {
      'scriptIndex': 0,
      'startPos': 399,
      'endPos': 449,
      'compiled': true,
      'coverage': {
        'hits': [],
        'misses': [13]
      }
    },
    reportLines: true,
  ),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  coverageTest(
    {
      'scriptIndex': 0,
      'startPos': 399,
      'endPos': 449,
      'compiled': true,
      'coverage': {
        'hits': [399],
        'misses': []
      }
    },
    reportLines: false,
  ),
  coverageTest(
    {
      'scriptIndex': 0,
      'startPos': 399,
      'endPos': 449,
      'compiled': true,
      'coverage': {
        'hits': [13],
        'misses': []
      }
    },
    reportLines: true,
  ),
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'coverage_leaf_function_test.dart',
      testeeConcurrent: testFunction,
    );
