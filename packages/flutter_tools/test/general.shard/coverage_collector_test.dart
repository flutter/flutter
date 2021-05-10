// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/test/coverage_collector.dart';
import 'package:vm_service/vm_service.dart';

import '../src/common.dart';
import '../src/fake_vm_services.dart';

void main() {
  testWithoutContext('Coverage collector Can handle coverage SentinelException', () async {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        FakeVmServiceRequest(
          method: 'getVM',
          jsonResponse: (VM.parse(<String, Object>{})
            ..isolates = <IsolateRef>[
              IsolateRef.parse(<String, Object>{
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

  testWithoutContext('Coverage collector processes coverage and script data', () async {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        FakeVmServiceRequest(
          method: 'getVM',
          jsonResponse: (VM.parse(<String, Object>{})
            ..isolates = <IsolateRef>[
              IsolateRef.parse(<String, Object>{
                'id': '1'
              }),
            ]
          ).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getScripts',
          args: <String, Object>{
            'isolateId': '1',
          },
          jsonResponse: ScriptList(scripts: <ScriptRef>[
            ScriptRef(uri: 'foo.dart', id: '1'),
          ]).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getSourceReport',
          args: <String, Object>{
            'isolateId': '1',
            'reports': <Object>['Coverage'],
            'scriptId': '1',
            'forceCompile': true,
          },
          jsonResponse: SourceReport(
            ranges: <SourceReportRange>[
              SourceReportRange(
                scriptIndex: 0,
                startPos: 0,
                endPos: 0,
                compiled: true,
                coverage: SourceReportCoverage(
                  hits: <int>[],
                  misses: <int>[],
                ),
              ),
            ],
            scripts: <ScriptRef>[
              ScriptRef(
                uri: 'foo.dart',
                id: '1',
              ),
            ],
          ).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getObject',
          args: <String, Object>{
            'isolateId': '1',
            'objectId': '1',
          },
          jsonResponse: Script(
            uri: 'foo.dart',
            id: '1',
            library: LibraryRef(name: '', id: '1111', uri: 'foo.dart'),
            tokenPosTable: <List<int>>[],
          ).toJson(),
        ),
      ],
    );

    final Map<String, Object> result = await collect(
      null,
      (String predicate) => true,
      connector: (Uri uri) async {
        return fakeVmServiceHost.vmService;
      },
    );

    expect(result, <String, Object>{'type': 'CodeCoverage', 'coverage': <Object>[
      <String, Object>{
        'source': 'foo.dart',
        'script': <String, Object>{
          'type': '@Script',
          'fixedId': true,
          'id': 'libraries/1/scripts/foo.dart',
          'uri': 'foo.dart',
          '_kind': 'library',
        },
        'hits': <Object>[],
      },
    ]});
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  });
}
