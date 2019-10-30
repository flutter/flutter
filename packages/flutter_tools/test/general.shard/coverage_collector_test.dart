// Copyright 2019 The Chromium Authors. All rights reserved.
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

  test('Coverage collector can handle null scripts value', () async {
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getScripts', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <Map<String, Object>>[
          <String, Object>{'uri': 'some_uri', 'id': 'some_id'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getSourceReport', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'ranges': <Map<String, Object>>[<String, Object>{}]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getObject', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{};
    });
    final Map<String, Object> result = await collect(null, (String predicate) => true, connector: (Uri uri) async {
      return mockVMService;
    });

    expect(result, <String, Object>{'type': 'CodeCoverage', 'coverage': <Object>[]});
  });

  test('Coverage collector can handle null ranges value', () async {
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getScripts', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <Map<String, Object>>[
          <String, Object>{'uri': 'some_uri', 'id': 'some_id'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getSourceReport', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{'scripts': <String, Object>{}};
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getObject', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{};
    });
    final Map<String, Object> result = await collect(null, (String predicate) => true, connector: (Uri uri) async {
      return mockVMService;
    });

    expect(result, <String, Object>{'type': 'CodeCoverage', 'coverage': <Object>[]});
  });

  test('Coverage collector can handle null scriptIndex values', () async {
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getScripts', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <Map<String, Object>>[
          <String, Object>{'uri': 'some_uri', 'id': 'some_id'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getSourceReport', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <String, Object>{'uri': 'some_uri', 'id': 'some_id'},
        'ranges': <Map<String, Object>>[
          <String, Object>{'coverage': <String, Object>{}}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getObject', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{};
    });
    final Map<String, Object> result = await collect(null, (String predicate) => true, connector: (Uri uri) async {
      return mockVMService;
    });

    expect(result, <String, Object>{'type': 'CodeCoverage', 'coverage': <Object>[]});
  });

  test('Coverage collector can handle null scriptRef values', () async {
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getScripts', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <Map<String, Object>>[
          <String, Object>{'uri': 'some_uri', 'id': 'some_id'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getSourceReport', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <String, Object>{'uri': 'some_uri', 'id': 'some_id'},
        'ranges': <Map<String, Object>>[
          <String, Object>{'coverage': <String, Object>{}, 'scriptIndex': 'some_value'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getObject', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{};
    });
    final Map<String, Object> result = await collect(null, (String predicate) => true, connector: (Uri uri) async {
      return mockVMService;
    });

    expect(result, <String, Object>{'type': 'CodeCoverage', 'coverage': <Object>[]});
  });

  test('Coverage collector can handle null scriptRef uri values', () async {
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getScripts', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <Map<String, Object>>[
          <String, Object>{'uri': 'some_uri', 'id': 'some_id'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getSourceReport', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <String, Object>{'uri': 'some_uri', 'id': 'some_id', 'index_0': <String, Object>{}},
        'ranges': <Map<String, Object>>[
          <String, Object>{'coverage': <String, Object>{}, 'scriptIndex': 'index_0'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getObject', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{};
    });
    final Map<String, Object> result = await collect(null, (String predicate) => true, connector: (Uri uri) async {
      return mockVMService;
    });

    expect(result, <String, Object>{'type': 'CodeCoverage', 'coverage': <Object>[]});
  });

  test('Coverage collector can handle null scriptRef id values', () async {
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getScripts', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <Map<String, Object>>[
          <String, Object>{'uri': 'some_uri', 'id': 'some_id'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getSourceReport', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <String, Object>{
          'uri': 'some_uri',
          'id': 'some_id',
          'index_0': <String, Object>{'uri': 'some_uri'}
        },
        'ranges': <Map<String, Object>>[
          <String, Object>{'coverage': <String, Object>{}, 'scriptIndex': 'index_0'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getObject', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{};
    });
    final Map<String, Object> result = await collect(null, (String predicate) => true, connector: (Uri uri) async {
      return mockVMService;
    });

    expect(result, <String, Object>{'type': 'CodeCoverage', 'coverage': <Object>[]});
  });

  test('Coverage collector can handle null scriptById values', () async {
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getScripts', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <Map<String, Object>>[
          <String, Object>{'uri': 'some_uri', 'id': 'some_id'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getSourceReport', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <String, Object>{
          'uri': 'some_uri',
          'id': 'some_id',
          'index_0': <String, Object>{'uri': 'some_uri', 'id': '01'},
        },
        'ranges': <Map<String, Object>>[
          <String, Object>{'coverage': <String, Object>{}, 'scriptIndex': 'index_0'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getObject', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{};
    });
    final Map<String, Object> result = await collect(null, (String predicate) => true, connector: (Uri uri) async {
      return mockVMService;
    });

    expect(result, <String, Object>{'type': 'CodeCoverage', 'coverage': <Object>[]});
  });

  test('Coverage collector can handle null tokenPosTable values', () async {
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getScripts', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <Map<String, Object>>[
          <String, Object>{'uri': 'some_uri', 'id': 'some_id'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getSourceReport', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <String, Object>{
          'uri': 'some_uri',
          'id': 'some_id',
          'index_0': <String, Object>{'uri': 'some_uri', 'id': '01'},
          '01': <String, Object>{},
        },
        'ranges': <Map<String, Object>>[
          <String, Object>{'coverage': <String, Object>{}, 'scriptIndex': 'index_0'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getObject', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{};
    });
    final Map<String, Object> result = await collect(null, (String predicate) => true, connector: (Uri uri) async {
      return mockVMService;
    });

    expect(result, <String, Object>{
      'type': 'CodeCoverage',
      'coverage': <Map<String, Object>>[
        <String, Object>{
          'source': 'some_uri',
          'script': <String, Object>{
            'type': '@Script',
            'fixedId': true,
            'id': 'libraries/1/scripts/some_uri',
            'uri': 'some_uri',
            '_kind': 'library'
          },
          'hits': <Map<String, Object>>[]
        }
      ]
    });
  });

  test('Coverage collector can handle null hits values', () async {
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getScripts', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <Map<String, Object>>[
          <String, Object>{'uri': 'some_uri', 'id': 'some_id'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getSourceReport', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <String, Object>{
          'uri': 'some_uri',
          'id': 'some_id',
          'index_0': <String, Object>{'uri': 'some_uri', 'id': '01'},
          '01': <String, Object>{'tokenPosTable': <dynamic>[]},
        },
        'ranges': <Map<String, Object>>[
          <String, Object>{'coverage': <String, Object>{}, 'scriptIndex': 'index_0'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getObject', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{};
    });
    final Map<String, Object> result = await collect(null, (String predicate) => true, connector: (Uri uri) async {
      return mockVMService;
    });

    expect(result, <String, Object>{
      'type': 'CodeCoverage',
      'coverage': <Map<String, Object>>[
        <String, Object>{
          'source': 'some_uri',
          'script': <String, Object>{
            'type': '@Script',
            'fixedId': true,
            'id': 'libraries/1/scripts/some_uri',
            'uri': 'some_uri',
            '_kind': 'library'
          },
          'hits': <Map<String, Object>>[]
        }
      ]
    });
  });

  test('Coverage collector can handle null misses values', () async {
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getScripts', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <Map<String, Object>>[
          <String, Object>{'uri': 'some_uri', 'id': 'some_id'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getSourceReport', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <String, Object>{
          'uri': 'some_uri',
          'id': 'some_id',
          'index_0': <String, Object>{'uri': 'some_uri', 'id': '01'},
          '01': <String, Object>{'tokenPosTable': <dynamic>[]},
        },
        'ranges': <Map<String, Object>>[
          <String, Object>{
            'coverage': <String, Object>{'hits': <dynamic>[]},
            'scriptIndex': 'index_0'
          }
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getObject', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{};
    });
    final Map<String, Object> result = await collect(null, (String predicate) => true, connector: (Uri uri) async {
      return mockVMService;
    });

    expect(result, <String, Object>{
      'type': 'CodeCoverage',
      'coverage': <Map<String, Object>>[
        <String, Object>{
          'source': 'some_uri',
          'script': <String, Object>{
            'type': '@Script',
            'fixedId': true,
            'id': 'libraries/1/scripts/some_uri',
            'uri': 'some_uri',
            '_kind': 'library'
          },
          'hits': <Map<String, Object>>[]
        }
      ]
    });
  });

  test('Coverage collector should process hits and misses', () async {
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getScripts', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <Map<String, Object>>[
          <String, Object>{'uri': 'some_uri', 'id': 'some_id'}
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getSourceReport', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{
        'scripts': <String, Object>{
          'uri': 'some_uri',
          'id': 'some_id',
          'index_0': <String, Object>{'uri': 'some_uri', 'id': '01'},
          '01': <String, Object>{
            'tokenPosTable': <dynamic>[
              <int>[1, 100, 5, 101, 8],
              <int>[2, 102, 7],
            ]
          },
        },
        'ranges': <Map<String, Object>>[
          <String, Object>{
            'coverage': <String, Object>{
              'hits': <dynamic>[100, 101],
              'misses': <dynamic>[102],
            },
            'scriptIndex': 'index_0'
          }
        ]
      };
    });
    when(mockVMService.vm.isolates.first.invokeRpcRaw('getObject', params: anyNamed('params')))
        .thenAnswer((Invocation invocation) async {
      return <String, Object>{};
    });
    final Map<String, Object> result = await collect(null, (String predicate) => true, connector: (Uri uri) async {
      return mockVMService;
    });

    expect(result, <String, Object>{
      'type': 'CodeCoverage',
      'coverage': <Map<String, Object>>[
        <String, Object>{
          'source': 'some_uri',
          'script': <String, Object>{
            'type': '@Script',
            'fixedId': true,
            'id': 'libraries/1/scripts/some_uri',
            'uri': 'some_uri',
            '_kind': 'library'
          },
          'hits': <int>[1, 2, 2, 0]
        }
      ]
    });
  });
}

class MockVMService extends Mock implements VMService {
  @override
  final MockVM vm = MockVM();
}

class MockVM extends Mock implements VM {
  @override
  final List<MockIsolate> isolates = <MockIsolate>[MockIsolate()];
}

class MockIsolate extends Mock implements Isolate {}

class MockProcess extends Mock implements Process {
  final Completer<int> completer = Completer<int>();

  @override
  Future<int> get exitCode => completer.future;
}
