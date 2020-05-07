// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/test/coverage_collector.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../src/common.dart';

void main() {
  testWithoutContext('Coverage collector Can handle coverage SentinelException', () async {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        FakeVmServiceRequest(
          method: 'getVM',
          jsonResponse: (vm_service.VM.parse(<String, Object>{})
            ..isolates = <vm_service.IsolateRef>[
              vm_service.IsolateRef.parse(<String, Object>{
                'id': '1'
              }),
            ]
          ).toJson(),
        ),
        const FakeVmServiceRequest(
          method: 'getScripts',
          args: <String, Object>{
            'isolateId': '1',
          },
          jsonResponse: <String, Object>{
            'type': 'Sentinel'
          }
        )
      ],
    );

    final Map<String, Object> result = await collect(
      null,
      (String predicate) => true,
      connector: (Uri uri) async {
        return fakeVmServiceHost.vmService;
      },
    );

    expect(result, <String, Object>{'type': 'CodeCoverage', 'coverage': <Object>[]});
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  });
}
