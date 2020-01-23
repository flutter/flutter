// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/test/coverage_collector.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';

void main() {
  MockVMService mockVMService;

  setUp(() {
    mockVMService = MockVMService();
  });

  test('Coverage collector Can handle coverage sentinenl data', () async {
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getScripts', params: anyNamed('params')))
      .thenAnswer((Invocation invocation) async {
        return <String, Object>{'type': 'Sentinel', 'kind': 'Collected', 'valueAsString': '<collected>'};
      });
    final Map<String, Object> result = await collect(null, (String predicate) => true, connector: (Uri uri) async {
      return mockVMService;
    });

    expect(result, <String, Object>{'type': 'CodeCoverage', 'coverage': <Object>[]});
  });
}

class MockVMService extends Mock implements VMService {
  @override
  final MockVM vm = MockVM();
}

class MockVM extends Mock implements VM {
  @override
  final List<MockIsolate> isolates = <MockIsolate>[ MockIsolate() ];
}

class MockIsolate extends Mock implements Isolate {}

class MockProcess extends Mock implements Process {
  final Completer<int>completer = Completer<int>();

  @override
  Future<int> get exitCode => completer.future;
}
