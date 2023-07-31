// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:coverage/coverage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'collect_coverage_mock_test.mocks.dart';

SourceReportRange _range(int scriptIndex, SourceReportCoverage coverage) =>
    SourceReportRange(
      scriptIndex: scriptIndex,
      startPos: null,
      endPos: null,
      compiled: null,
      error: null,
      coverage: coverage,
      possibleBreakpoints: null,
      branchCoverage: null,
    );

Script _script(List<List<int>> tokenPosTable) => Script(
      uri: null,
      library: null,
      id: '',
      lineOffset: null,
      columnOffset: null,
      source: null,
      tokenPosTable: tokenPosTable,
    );

MockVmService _mockService(int majorVersion, int minorVersion) {
  final service = MockVmService();
  final isoRef = IsolateRef(
    id: 'isolate',
    number: null,
    name: null,
    isSystemIsolate: null,
  );
  final isoGroupRef = IsolateGroupRef(
    id: 'isolateGroup',
    number: null,
    name: null,
    isSystemIsolateGroup: null,
  );
  when(service.getVM()).thenAnswer((_) async => VM(
        name: null,
        architectureBits: null,
        hostCPU: null,
        operatingSystem: null,
        targetCPU: null,
        version: null,
        pid: null,
        startTime: null,
        isolates: [isoRef],
        isolateGroups: [isoGroupRef],
        systemIsolates: null,
        systemIsolateGroups: null,
      ));
  when(service.getIsolateGroup('isolateGroup'))
      .thenAnswer((_) async => IsolateGroup(
            id: 'isolateGroup',
            number: null,
            name: null,
            isSystemIsolateGroup: null,
            isolates: [isoRef],
          ));
  when(service.getVersion()).thenAnswer(
      (_) async => Version(major: majorVersion, minor: minorVersion));
  return service;
}

@GenerateMocks([VmService])
void main() {
  group('Mock VM Service', () {
    test('Collect coverage', () async {
      final service = _mockService(3, 0);
      when(service.getSourceReport('isolate', ['Coverage'], forceCompile: true))
          .thenAnswer((_) async => SourceReport(
                ranges: [
                  _range(
                    0,
                    SourceReportCoverage(
                      hits: [15],
                      misses: [32],
                    ),
                  ),
                  _range(
                    1,
                    SourceReportCoverage(
                      hits: [75],
                      misses: [34],
                    ),
                  ),
                ],
                scripts: [
                  ScriptRef(
                    uri: 'package:foo/foo.dart',
                    id: 'foo',
                  ),
                  ScriptRef(
                    uri: 'package:bar/bar.dart',
                    id: 'bar',
                  ),
                ],
              ));
      when(service.getObject('isolate', 'foo'))
          .thenAnswer((_) async => _script([
                [12, 15, 7],
                [47, 32, 19],
              ]));
      when(service.getObject('isolate', 'bar'))
          .thenAnswer((_) async => _script([
                [52, 34, 10],
                [95, 75, 3],
              ]));

      final jsonResult = await collect(Uri(), false, false, false, null,
          serviceOverrideForTesting: service);
      final result = await HitMap.parseJson(
          jsonResult['coverage'] as List<Map<String, dynamic>>);

      expect(result.length, 2);
      expect(result['package:foo/foo.dart']?.lineHits, {12: 1, 47: 0});
      expect(result['package:bar/bar.dart']?.lineHits, {95: 1, 52: 0});
    });

    test('Collect coverage, report lines', () async {
      final service = _mockService(3, 51);
      when(service.getSourceReport('isolate', ['Coverage'],
              forceCompile: true, reportLines: true))
          .thenAnswer((_) async => SourceReport(
                ranges: [
                  _range(
                    0,
                    SourceReportCoverage(
                      hits: [12],
                      misses: [47],
                    ),
                  ),
                  _range(
                    1,
                    SourceReportCoverage(
                      hits: [95],
                      misses: [52],
                    ),
                  ),
                ],
                scripts: [
                  ScriptRef(
                    uri: 'package:foo/foo.dart',
                    id: 'foo',
                  ),
                  ScriptRef(
                    uri: 'package:bar/bar.dart',
                    id: 'bar',
                  ),
                ],
              ));

      final jsonResult = await collect(Uri(), false, false, false, null,
          serviceOverrideForTesting: service);
      final result = await HitMap.parseJson(
          jsonResult['coverage'] as List<Map<String, dynamic>>);

      expect(result.length, 2);
      expect(result['package:foo/foo.dart']?.lineHits, {12: 1, 47: 0});
      expect(result['package:bar/bar.dart']?.lineHits, {95: 1, 52: 0});
    });

    test('Collect coverage, scoped output, no library filters', () async {
      final service = _mockService(3, 0);
      when(service.getScripts('isolate')).thenAnswer((_) async => ScriptList(
            scripts: [
              ScriptRef(
                uri: 'package:foo/foo.dart',
                id: 'foo',
              ),
              ScriptRef(
                uri: 'package:bar/bar.dart',
                id: 'bar',
              ),
            ],
          ));
      when(service.getSourceReport('isolate', ['Coverage'],
              scriptId: 'foo', forceCompile: true))
          .thenAnswer((_) async => SourceReport(
                ranges: [
                  _range(
                    0,
                    SourceReportCoverage(
                      hits: [15],
                      misses: [32],
                    ),
                  ),
                ],
                scripts: [
                  ScriptRef(
                    uri: 'package:foo/foo.dart',
                    id: 'foo',
                  ),
                ],
              ));
      when(service.getObject('isolate', 'foo'))
          .thenAnswer((_) async => _script([
                [12, 15, 7],
                [47, 32, 19],
              ]));

      final jsonResult = await collect(Uri(), false, false, false, {'foo'},
          serviceOverrideForTesting: service);
      final result = await HitMap.parseJson(
          jsonResult['coverage'] as List<Map<String, dynamic>>);

      expect(result.length, 1);
      expect(result['package:foo/foo.dart']?.lineHits, {12: 1, 47: 0});
    });

    test('Collect coverage, scoped output, library filters', () async {
      final service = _mockService(3, 57);
      when(service.getSourceReport('isolate', ['Coverage'],
              forceCompile: true,
              reportLines: true,
              libraryFilters: ['package:foo/']))
          .thenAnswer((_) async => SourceReport(
                ranges: [
                  _range(
                    0,
                    SourceReportCoverage(
                      hits: [12],
                      misses: [47],
                    ),
                  ),
                ],
                scripts: [
                  ScriptRef(
                    uri: 'package:foo/foo.dart',
                    id: 'foo',
                  ),
                ],
              ));

      final jsonResult = await collect(Uri(), false, false, false, {'foo'},
          serviceOverrideForTesting: service);
      final result = await HitMap.parseJson(
          jsonResult['coverage'] as List<Map<String, dynamic>>);

      expect(result.length, 1);
      expect(result['package:foo/foo.dart']?.lineHits, {12: 1, 47: 0});
    });
  });
}
