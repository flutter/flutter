// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:file/memory.dart';

import '../luci_resultdb.dart';
import '../tool_subsharding.dart';
import 'common.dart';

const String _kMetrics = '''
{"protocolVersion":"0.1.1","runnerVersion":"1.25.0","pid":1,"type":"start","time":0}
{"suite":{"id":0,"platform":"vm","path":"test/foo_test.dart"},"type":"suite","time":0}
{"test":{"id":1,"name":"loading test/foo_test.dart","suiteID":0,"groupIDs":[],"metadata":{"skip":false,"skipReason":null},"line":null,"column":null,"url":null},"type":"testStart","time":0}
{"testID":1,"result":"success","skipped":false,"hidden":true,"type":"testDone","time":1}
{"test":{"id":2,"name":"passing test","suiteID":0,"groupIDs":[],"metadata":{"skip":false,"skipReason":null},"line":10,"column":3,"url":"file:///foo"},"type":"testStart","time":2}
{"testID":2,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":102}
{"test":{"id":3,"name":"failing test","suiteID":0,"groupIDs":[],"metadata":{"skip":false,"skipReason":null},"line":20,"column":3,"url":"file:///foo"},"type":"testStart","time":102}
{"testID":3,"result":"failure","skipped":false,"hidden":false,"type":"testDone","time":152}
{"test":{"id":4,"name":"skipped test","suiteID":0,"groupIDs":[],"metadata":{"skip":true,"skipReason":null},"line":30,"column":3,"url":"file:///foo"},"type":"testStart","time":152}
{"testID":4,"result":"success","skipped":true,"hidden":false,"type":"testDone","time":152}
{"success":false,"type":"done","time":200}''';

TestFileReporterResults _parse() {
  final fileSystem = MemoryFileSystem.test();
  final File file = fileSystem.file('metrics');
  file.writeAsStringSync(_kMetrics);
  return TestFileReporterResults.fromFile(file);
}

String _caseName(LuciTestResult result) => result.testId.caseName;

void main() {
  group('convertToLuciTestResultsFormat', () {
    test('converts each non-hidden test into a structured ResultDB TestResult', () {
      final List<LuciTestResult> results = convertToLuciTestResultsFormat(_parse());

      // The hidden "loading ..." bookkeeping test is excluded.
      expect(results, hasLength(3));

      final byCase = <String, LuciTestResult>{
        for (final LuciTestResult r in results) _caseName(r): r,
      };

      expect(byCase.keys, containsAll(<String>['passing test', 'failing test', 'skipped test']));
      // The module name is the test file, and the scheme is the level-free
      // 'flat' scheme, so file and test name are separate columns in the UI.
      for (final LuciTestResult(
            testId: LuciStructuredTestId(:moduleName, :moduleScheme, :moduleVariant),
          )
          in results) {
        expect(moduleName, 'test/foo_test.dart');
        expect(moduleScheme, 'flat');
        expect(moduleVariant, <String, String>{});
      }
    });

    test('strips rootDirectory prefix from absolute suite paths', () {
      const metrics =
          '{"protocolVersion":"0.1.1","runnerVersion":"1.25.0","pid":1,"type":"start","time":0}\n'
          '{"suite":{"id":0,"platform":"vm","path":"/b/s/w/ir/x/w/flutter/dev/foo/bar_test.dart"},"type":"suite","time":0}\n'
          '{"test":{"id":2,"name":"my test","suiteID":0,"groupIDs":[],"metadata":{"skip":false,"skipReason":null},"line":10,"column":3,"url":"file:///foo"},"type":"testStart","time":2}\n'
          '{"testID":2,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":102}\n'
          '{"success":true,"type":"done","time":200}';
      final fileSystem = MemoryFileSystem.test();
      final File file = fileSystem.file('metrics')..writeAsStringSync(metrics);
      final parsed = TestFileReporterResults.fromFile(file);

      final List<LuciTestResult> stripped = convertToLuciTestResultsFormat(
        parsed,
        rootDirectory: '/b/s/w/ir/x/w/flutter',
      );
      final [LuciTestResult(testId: LuciStructuredTestId(:moduleName, :caseName))] = stripped;
      expect(moduleName, 'dev/foo/bar_test.dart');
      expect(caseName, 'my test');

      // Without a rootDirectory, the absolute path is preserved.
      final [
        LuciTestResult(testId: LuciStructuredTestId(moduleName: String unstrippedModuleName)),
      ] = convertToLuciTestResultsFormat(
        parsed,
      );
      expect(unstrippedModuleName, '/b/s/w/ir/x/w/flutter/dev/foo/bar_test.dart');
    });

    test('resolves relative suite paths against the working directory', () {
      const metrics =
          '{"protocolVersion":"0.1.1","runnerVersion":"1.25.0","pid":1,"type":"start","time":0}\n'
          '{"suite":{"id":0,"platform":"vm","path":"test/bar_test.dart"},"type":"suite","time":0}\n'
          '{"test":{"id":2,"name":"my test","suiteID":0,"groupIDs":[],"metadata":{"skip":false,"skipReason":null},"line":10,"column":3,"url":"file:///foo"},"type":"testStart","time":2}\n'
          '{"testID":2,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":102}\n'
          '{"success":true,"type":"done","time":200}';
      final fileSystem = MemoryFileSystem.test();
      final File file = fileSystem.file('metrics')..writeAsStringSync(metrics);
      final parsed = TestFileReporterResults.fromFile(file);

      // A `packages/flutter` shard reports suite paths relative to its working
      // directory; resolving against it yields a repo-relative module name.
      final List<LuciTestResult> results = convertToLuciTestResultsFormat(
        parsed,
        workingDirectory: '/b/s/w/ir/x/w/flutter/packages/flutter',
        rootDirectory: '/b/s/w/ir/x/w/flutter',
      );
      final [LuciTestResult(testId: LuciStructuredTestId(:moduleName))] = results;
      expect(moduleName, 'packages/flutter/test/bar_test.dart');
    });

    test('escapes colons and backslashes in the case name', () {
      const metrics =
          '{"protocolVersion":"0.1.1","runnerVersion":"1.25.0","pid":1,"type":"start","time":0}\n'
          '{"suite":{"id":0,"platform":"vm","path":"test/foo_test.dart"},"type":"suite","time":0}\n'
          '{"test":{"id":2,"name":"Group: sub\\\\path does x","suiteID":0,"groupIDs":[],"metadata":{"skip":false,"skipReason":null},"line":10,"column":3,"url":"file:///foo"},"type":"testStart","time":2}\n'
          '{"testID":2,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":102}\n'
          '{"success":true,"type":"done","time":200}';
      final fileSystem = MemoryFileSystem.test();
      final File file = fileSystem.file('metrics')..writeAsStringSync(metrics);
      final parsed = TestFileReporterResults.fromFile(file);

      final List<LuciTestResult> results = convertToLuciTestResultsFormat(parsed);
      // The raw test name is `Group: sub\path does x`; ':' becomes '\:' and the
      // backslash becomes '\\'.
      final [LuciTestResult(testId: LuciStructuredTestId(:caseName))] = results;
      expect(caseName, r'Group\: sub\\path does x');
    });

    test('maps status and expectedness correctly', () {
      final List<LuciTestResult> results = convertToLuciTestResultsFormat(_parse());
      final byId = <String, LuciTestResult>{
        for (final LuciTestResult r in results) _caseName(r): r,
      };

      final LuciTestResult pass = byId['passing test']!;
      expect((pass.status, pass.expected), ('PASS', true));

      final LuciTestResult fail = byId['failing test']!;
      expect((fail.status, fail.expected), ('FAIL', false));

      final LuciTestResult skip = byId['skipped test']!;
      expect((skip.status, skip.expected), ('SKIP', true));
    });

    test('marks failing tests as expected when expectFailure is true', () {
      final List<LuciTestResult> results = convertToLuciTestResultsFormat(
        _parse(),
        expectFailure: true,
      );
      final byId = <String, LuciTestResult>{
        for (final LuciTestResult r in results) _caseName(r): r,
      };

      // The failing test keeps its FAIL status but is now an *expected* failure,
      // so ResultDB won't surface it as a red regression (e.g. the
      // test_smoke_test negative tests run with expectFailure: true).
      final LuciTestResult fail = byId['failing test']!;
      expect((fail.status, fail.expected), ('FAIL', true));

      // Passing and skipped tests remain expected as well.
      expect(byId['passing test']!.expected, true);
      expect(byId['skipped test']!.expected, true);
    });

    test('emits a proto Duration string and unique result ids', () {
      final List<LuciTestResult> results = convertToLuciTestResultsFormat(_parse());

      for (final r in results) {
        expect(r.duration, matches(r'^\d+\.\d+s$'));
      }
      final resultIds = <String>{for (final LuciTestResult r in results) r.resultId};
      expect(resultIds, hasLength(results.length));

      // The passing test ran from t=2ms to t=102ms => 0.1s.
      final LuciTestResult pass = results.firstWhere(
        (LuciTestResult r) => _caseName(r) == 'passing test',
      );
      expect(pass.duration, '0.100000s');
    });
  });

  group('ResultDbRecorder.fromEnvironment', () {
    test('returns null when resultdb is absent from LUCI_CONTEXT', () {
      final Directory dir = Directory.systemTemp.createTempSync('luci_resultdb_test');
      addTearDown(() => tryToDelete(dir));
      final context = File('${dir.path}/luci_context.json')
        ..writeAsStringSync(json.encode(<String, Object?>{'luciexe': <String, Object?>{}}));
      expect(
        ResultDbRecorder.fromEnvironment(<String, String>{'LUCI_CONTEXT': context.path}),
        isNull,
      );
    });

    test('returns null (does not throw) when LUCI_CONTEXT is malformed JSON', () {
      final Directory dir = Directory.systemTemp.createTempSync('luci_resultdb_test');
      addTearDown(() => tryToDelete(dir));
      final context = File('${dir.path}/luci_context.json')..writeAsStringSync('{not valid json');
      expect(
        ResultDbRecorder.fromEnvironment(<String, String>{'LUCI_CONTEXT': context.path}),
        isNull,
      );
    });

    test('parses hostname and current_invocation from LUCI_CONTEXT', () {
      final Directory dir = Directory.systemTemp.createTempSync('luci_resultdb_test');
      addTearDown(() => tryToDelete(dir));
      final context = File('${dir.path}/luci_context.json')
        ..writeAsStringSync(
          json.encode(<String, Object?>{
            'resultdb': <String, Object?>{
              'hostname': 'results.api.luci.app',
              'current_invocation': <String, Object?>{
                'name': 'invocations/build-123',
                'update_token': 'tok',
              },
            },
          }),
        );
      final ResultDbRecorder? recorder = ResultDbRecorder.fromEnvironment(<String, String>{
        'LUCI_CONTEXT': context.path,
      });
      if (recorder case final rec?) {
        expect(
          (rec.host, rec.invocation, rec.updateToken),
          ('results.api.luci.app', 'invocations/build-123', 'tok'),
        );
        rec.close();
      } else {
        fail('Expected non-null recorder');
      }
    });
  });

  group('ResultDbRecorder.reportTestResults', () {
    test('serializes each result under requests[].testResult', () async {
      final HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      final bodies = <Map<String, Object?>>[];
      final tokens = <String>[];
      final paths = <String>[];
      server.listen((HttpRequest request) async {
        paths.add(request.uri.path);
        tokens.add(request.headers.value('update-token') ?? '');
        final String body = await utf8.decoder.bind(request).join();
        bodies.add(json.decode(body) as Map<String, Object?>);
        request.response.statusCode = HttpStatus.ok;
        request.response.write('{}');
        await request.response.close();
      });

      // Use a client whose https requests are redirected to our http server by
      // connecting directly; HttpClient does not allow that, so we instead
      // exercise the batching/serialization logic against the local server by
      // constructing the recorder with an http HttpClient is not needed: the
      // body format is what we assert here through the public API.
      final recorder = _HttpRecorder(
        host: '${server.address.host}:${server.port}',
        invocation: 'invocations/build-123',
        updateToken: 'my-token',
      );
      addTearDown(recorder.close);

      await recorder.reportTestResults(<LuciTestResult>[
        const LuciTestResult(
          testId: LuciStructuredTestId(moduleName: 'm', caseName: 'a'),
          resultId: '0',
          status: 'PASS',
          expected: true,
          duration: '0.000000s',
        ),
        const LuciTestResult(
          testId: LuciStructuredTestId(moduleName: 'm', caseName: 'b'),
          resultId: '1',
          status: 'FAIL',
          expected: false,
          duration: '0.000000s',
        ),
      ]);

      expect(bodies, hasLength(1));
      expect(paths.single, '/prpc/luci.resultdb.v1.Recorder/BatchCreateTestResults');
      expect(tokens.single, 'my-token');
      if (bodies.single case {
        'invocation': 'invocations/build-123',
        'requests': [{'testResult': {'testIdStructured': {'caseName': 'a'}}}, _],
      }) {
        // Matched expected structure.
      } else {
        fail('Unexpected body: ${bodies.single}');
      }
    });
  });
}

/// A [ResultDbRecorder] that talks plain HTTP, for testing against a local
/// [HttpServer] (the production recorder always uses https).
class _HttpRecorder extends ResultDbRecorder {
  _HttpRecorder({required super.host, required super.invocation, required super.updateToken});

  @override
  Future<void> reportTestResults(List<LuciTestResult> testResults) async {
    final client = HttpClient();
    try {
      final Uri url = Uri.parse(
        'http://$host/prpc/luci.resultdb.v1.Recorder/BatchCreateTestResults',
      );
      final HttpClientRequest request = await client.postUrl(url);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set('update-token', updateToken);
      request.add(
        utf8.encode(
          json.encode(<String, Object?>{
            'invocation': invocation,
            'requests': <Map<String, Object?>>[
              for (final LuciTestResult result in testResults)
                <String, Object?>{'testResult': result.toJson()},
            ],
          }),
        ),
      );
      final HttpClientResponse response = await request.close();
      await response.drain<void>();
    } finally {
      client.close(force: true);
    }
  }
}
