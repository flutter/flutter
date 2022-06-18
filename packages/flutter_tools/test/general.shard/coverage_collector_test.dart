// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/test/coverage_collector.dart';
import 'package:vm_service/vm_service.dart';

import '../src/common.dart';
import '../src/fake_vm_services.dart';

void main() {
  testWithoutContext('Coverage collector Can handle coverage SentinelException', () async {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        FakeVmServiceRequest(
          method: 'getVersion',
          jsonResponse: Version(major: 3, minor: 51).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getVM',
          jsonResponse: (VM.parse(<String, Object>{})!
            ..isolates = <IsolateRef>[
              IsolateRef.parse(<String, Object>{
                'id': '1',
              })!,
            ]
          ).toJson(),
        ),
        const FakeVmServiceRequest(
          method: 'getScripts',
          args: <String, Object>{
            'isolateId': '1',
          },
          jsonResponse: <String, Object>{
            'type': 'Sentinel',
          },
        ),
      ],
    );

    final Map<String, Object?> result = await collect(
      null,
      <String>{'foo'},
      connector: (Uri? uri) async {
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
          method: 'getVersion',
          jsonResponse: Version(major: 3, minor: 51).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getVM',
          jsonResponse: (VM.parse(<String, Object>{})!
            ..isolates = <IsolateRef>[
              IsolateRef.parse(<String, Object>{
                'id': '1',
              })!,
            ]
          ).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getScripts',
          args: <String, Object>{
            'isolateId': '1',
          },
          jsonResponse: ScriptList(scripts: <ScriptRef>[
            ScriptRef(uri: 'package:foo/foo.dart', id: '1'),
            ScriptRef(uri: 'package:bar/bar.dart', id: '2'),
          ]).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getSourceReport',
          args: <String, Object>{
            'isolateId': '1',
            'reports': <Object>['Coverage'],
            'scriptId': '1',
            'forceCompile': true,
            'reportLines': true,
          },
          jsonResponse: SourceReport(
            ranges: <SourceReportRange>[
              SourceReportRange(
                scriptIndex: 0,
                startPos: 0,
                endPos: 0,
                compiled: true,
                coverage: SourceReportCoverage(
                  hits: <int>[1, 3],
                  misses: <int>[2],
                ),
              ),
            ],
            scripts: <ScriptRef>[
              ScriptRef(
                uri: 'package:foo/foo.dart',
                id: '1',
              ),
            ],
          ).toJson(),
        ),
      ],
    );

    final Map<String, Object?> result = await collect(
      null,
      <String>{'foo'},
      connector: (Uri? uri) async {
        return fakeVmServiceHost.vmService;
      },
    );

    expect(result, <String, Object>{
      'type': 'CodeCoverage',
      'coverage': <Object>[
        <String, Object>{
          'source': 'package:foo/foo.dart',
          'script': <String, Object>{
            'type': '@Script',
            'fixedId': true,
            'id': 'libraries/1/scripts/package%3Afoo%2Ffoo.dart',
            'uri': 'package:foo/foo.dart',
            '_kind': 'library',
          },
          'hits': <Object>[1, 1, 3, 1, 2, 0],
        },
      ],
    });
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  });

  testWithoutContext('Coverage collector with null libraryNames accepts all libraries', () async {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        FakeVmServiceRequest(
          method: 'getVersion',
          jsonResponse: Version(major: 3, minor: 51).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getVM',
          jsonResponse: (VM.parse(<String, Object>{})!
            ..isolates = <IsolateRef>[
              IsolateRef.parse(<String, Object>{
                'id': '1',
              })!,
            ]
          ).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getScripts',
          args: <String, Object>{
            'isolateId': '1',
          },
          jsonResponse: ScriptList(scripts: <ScriptRef>[
            ScriptRef(uri: 'package:foo/foo.dart', id: '1'),
            ScriptRef(uri: 'package:bar/bar.dart', id: '2'),
          ]).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getSourceReport',
          args: <String, Object>{
            'isolateId': '1',
            'reports': <Object>['Coverage'],
            'scriptId': '1',
            'forceCompile': true,
            'reportLines': true,
          },
          jsonResponse: SourceReport(
            ranges: <SourceReportRange>[
              SourceReportRange(
                scriptIndex: 0,
                startPos: 0,
                endPos: 0,
                compiled: true,
                coverage: SourceReportCoverage(
                  hits: <int>[1, 3],
                  misses: <int>[2],
                ),
              ),
            ],
            scripts: <ScriptRef>[
              ScriptRef(
                uri: 'package:foo/foo.dart',
                id: '1',
              ),
            ],
          ).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getSourceReport',
          args: <String, Object>{
            'isolateId': '1',
            'reports': <Object>['Coverage'],
            'scriptId': '2',
            'forceCompile': true,
            'reportLines': true,
          },
          jsonResponse: SourceReport(
            ranges: <SourceReportRange>[
              SourceReportRange(
                scriptIndex: 0,
                startPos: 0,
                endPos: 0,
                compiled: true,
                coverage: SourceReportCoverage(
                  hits: <int>[47, 21],
                  misses: <int>[32, 86],
                ),
              ),
            ],
            scripts: <ScriptRef>[
              ScriptRef(
                uri: 'package:bar/bar.dart',
                id: '2',
              ),
            ],
          ).toJson(),
        ),
      ],
    );

    final Map<String, Object?> result = await collect(
      null,
      null,
      connector: (Uri? uri) async {
        return fakeVmServiceHost.vmService;
      },
    );

    expect(result, <String, Object>{
      'type': 'CodeCoverage',
      'coverage': <Object>[
        <String, Object>{
          'source': 'package:foo/foo.dart',
          'script': <String, Object>{
            'type': '@Script',
            'fixedId': true,
            'id': 'libraries/1/scripts/package%3Afoo%2Ffoo.dart',
            'uri': 'package:foo/foo.dart',
            '_kind': 'library',
          },
          'hits': <Object>[1, 1, 3, 1, 2, 0],
        },
        <String, Object>{
          'source': 'package:bar/bar.dart',
          'script': <String, Object>{
            'type': '@Script',
            'fixedId': true,
            'id': 'libraries/1/scripts/package%3Abar%2Fbar.dart',
            'uri': 'package:bar/bar.dart',
            '_kind': 'library',
          },
          'hits': <Object>[47, 1, 21, 1, 32, 0, 86, 0],
        },
      ],
    });
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  });

  testWithoutContext('Coverage collector with libraryFilters', () async {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        FakeVmServiceRequest(
          method: 'getVersion',
          jsonResponse: Version(major: 3, minor: 57).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getVM',
          jsonResponse: (VM.parse(<String, Object>{})!
            ..isolates = <IsolateRef>[
              IsolateRef.parse(<String, Object>{
                'id': '1',
              })!,
            ]
          ).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getSourceReport',
          args: <String, Object>{
            'isolateId': '1',
            'reports': <Object>['Coverage'],
            'forceCompile': true,
            'reportLines': true,
            'libraryFilters': <Object>['package:foo/'],
          },
          jsonResponse: SourceReport(
            ranges: <SourceReportRange>[
              SourceReportRange(
                scriptIndex: 0,
                startPos: 0,
                endPos: 0,
                compiled: true,
                coverage: SourceReportCoverage(
                  hits: <int>[1, 3],
                  misses: <int>[2],
                ),
              ),
            ],
            scripts: <ScriptRef>[
              ScriptRef(
                uri: 'package:foo/foo.dart',
                id: '1',
              ),
            ],
          ).toJson(),
        ),
      ],
    );

    final Map<String, Object?> result = await collect(
      null,
      <String>{'foo'},
      connector: (Uri? uri) async {
        return fakeVmServiceHost.vmService;
      },
    );

    expect(result, <String, Object>{
      'type': 'CodeCoverage',
      'coverage': <Object>[
        <String, Object>{
          'source': 'package:foo/foo.dart',
          'script': <String, Object>{
            'type': '@Script',
            'fixedId': true,
            'id': 'libraries/1/scripts/package%3Afoo%2Ffoo.dart',
            'uri': 'package:foo/foo.dart',
            '_kind': 'library',
          },
          'hits': <Object>[1, 1, 3, 1, 2, 0],
        },
      ],
    });
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  });

  testWithoutContext('Coverage collector with libraryFilters and null libraryNames', () async {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        FakeVmServiceRequest(
          method: 'getVersion',
          jsonResponse: Version(major: 3, minor: 57).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getVM',
          jsonResponse: (VM.parse(<String, Object>{})!
            ..isolates = <IsolateRef>[
              IsolateRef.parse(<String, Object>{
                'id': '1',
              })!,
            ]
          ).toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getSourceReport',
          args: <String, Object>{
            'isolateId': '1',
            'reports': <Object>['Coverage'],
            'forceCompile': true,
            'reportLines': true,
          },
          jsonResponse: SourceReport(
            ranges: <SourceReportRange>[
              SourceReportRange(
                scriptIndex: 0,
                startPos: 0,
                endPos: 0,
                compiled: true,
                coverage: SourceReportCoverage(
                  hits: <int>[1, 3],
                  misses: <int>[2],
                ),
              ),
            ],
            scripts: <ScriptRef>[
              ScriptRef(
                uri: 'package:foo/foo.dart',
                id: '1',
              ),
            ],
          ).toJson(),
        ),
      ],
    );

    final Map<String, Object?> result = await collect(
      null,
      null,
      connector: (Uri? uri) async {
        return fakeVmServiceHost.vmService;
      },
    );

    expect(result, <String, Object>{
      'type': 'CodeCoverage',
      'coverage': <Object>[
        <String, Object>{
          'source': 'package:foo/foo.dart',
          'script': <String, Object>{
            'type': '@Script',
            'fixedId': true,
            'id': 'libraries/1/scripts/package%3Afoo%2Ffoo.dart',
            'uri': 'package:foo/foo.dart',
            '_kind': 'library',
          },
          'hits': <Object>[1, 1, 3, 1, 2, 0],
        },
      ],
    });
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  });
}
