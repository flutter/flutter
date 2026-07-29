// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'tool_subsharding.dart';

/// Reads and decodes the `LUCI_CONTEXT` JSON file, or returns null if it is not
/// set or cannot be read.
///
/// `LUCI_CONTEXT` is a file path (in the `LUCI_CONTEXT` environment variable)
/// pointing at a JSON document that LUCI populates for the running build.
Map<String, Object?>? readLuciContext([Map<String, String>? environment]) {
  final Map<String, String> env = environment ?? Platform.environment;
  final String? luciContextPath = env['LUCI_CONTEXT'];
  if (luciContextPath == null || luciContextPath.isEmpty) {
    return null;
  }
  final file = File(luciContextPath);
  if (!file.existsSync()) {
    return null;
  }
  final Object? decoded = json.decode(file.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    return null;
  }
  return decoded;
}

/// A client for the [ResultDB Recorder][recorder] `BatchCreateTestResults` API.
///
/// This uploads test results directly to the build's ResultDB invocation using
/// the `update_token` from `LUCI_CONTEXT["resultdb"]["current_invocation"]`.
///
/// This works even when the build is not running under `rdb stream` (which is
/// the case for the Flutter recipe): bbagent creates the invocation and exposes
/// `current_invocation` in `LUCI_CONTEXT`, without needing a separate result
/// streaming sidecar.
///
/// [recorder]: https://pkg.go.dev/go.chromium.org/luci/resultdb/proto/v1
class ResultDbRecorder {
  ResultDbRecorder({
    required this.host,
    required this.invocation,
    required this.updateToken,
    HttpClient? httpClient,
  }) : _client = httpClient ?? HttpClient();

  /// The ResultDB hostname (for example, `results.api.luci.app`).
  final String host;

  /// The invocation name (for example, `invocations/build-123`).
  final String invocation;

  /// The token that authorizes writes to [invocation].
  final String updateToken;

  final HttpClient _client;

  /// Creates a [ResultDbRecorder] from the `LUCI_CONTEXT`, or returns null if
  /// ResultDB is not configured for the current invocation.
  static ResultDbRecorder? fromEnvironment([Map<String, String>? environment]) {
    final Object? resultdb = readLuciContext(environment)?['resultdb'];
    if (resultdb is! Map<String, Object?>) {
      return null;
    }
    final Object? host = resultdb['hostname'];
    final Object? current = resultdb['current_invocation'];
    if (host is! String || current is! Map<String, Object?>) {
      return null;
    }
    final Object? name = current['name'];
    final Object? updateToken = current['update_token'];
    if (name is! String || updateToken is! String) {
      return null;
    }
    return ResultDbRecorder(host: host, invocation: name, updateToken: updateToken);
  }

  /// Reports the given [testResults] to the invocation via
  /// `BatchCreateTestResults`.
  ///
  /// Throws an [HttpException] if the server responds with a non-200 status.
  Future<void> reportTestResults(List<LuciTestResult> testResults) async {
    if (testResults.isEmpty) {
      return;
    }
    final Uri url = Uri.parse(
      'https://$host/prpc/luci.resultdb.v1.Recorder/BatchCreateTestResults',
    );
    for (final List<LuciTestResult> batch in _batches(testResults)) {
      final HttpClientRequest request = await _client.postUrl(url);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      // The Recorder authorizes writes to the invocation via this header.
      request.headers.set('update-token', updateToken);
      request.add(
        utf8.encode(
          json.encode(<String, Object?>{
            'invocation': invocation,
            'requests': <Map<String, Object?>>[
              for (final LuciTestResult result in batch)
                <String, Object?>{'testResult': result.toJson()},
            ],
          }),
        ),
      );
      final HttpClientResponse response = await request.close();
      final String body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'ResultDB BatchCreateTestResults failed with status ${response.statusCode}: $body',
        );
      }
    }
  }

  /// Closes the underlying HTTP client.
  void close() {
    _client.close(force: true);
  }
}

/// The maximum number of test results to send in a single request.
const int _kBatchSize = 500;

/// Splits [testResults] into batches of at most [_kBatchSize].
Iterable<List<LuciTestResult>> _batches(List<LuciTestResult> testResults) sync* {
  for (var i = 0; i < testResults.length; i += _kBatchSize) {
    final int end = (i + _kBatchSize < testResults.length) ? i + _kBatchSize : testResults.length;
    yield testResults.sublist(i, end);
  }
}

/// A ResultDB [structured test id][id] (`testIdStructured`).
///
/// Using a structured id lets the "Test Results" UI present the test file and
/// the individual test name as separate columns.
///
/// [id]: https://pkg.go.dev/go.chromium.org/luci/resultdb/proto/v1#TestIdentifier
class LuciStructuredTestId {
  const LuciStructuredTestId({
    required this.moduleName,
    required this.caseName,
    this.moduleScheme = 'flat',
    this.moduleVariant = const <String, String>{},
  });

  /// The module name; for Flutter this is the test file relative to the repo
  /// root.
  final String moduleName;

  /// The scheme the module belongs to. `flat` has no intermediate (coarse/fine)
  /// hierarchy levels.
  final String moduleScheme;

  /// The module variant definition (empty for Flutter's tests).
  final Map<String, String> moduleVariant;

  /// The case name; for Flutter this is the individual test name.
  final String caseName;

  /// The JSON representation used by the ResultDB Recorder API.
  Map<String, Object?> toJson() => <String, Object?>{
    'moduleName': moduleName,
    'moduleScheme': moduleScheme,
    'moduleVariant': moduleVariant,
    'caseName': caseName,
  };
}

/// A single ResultDB [`TestResult`][result], describing the outcome of one
/// individual test case.
///
/// [result]: https://pkg.go.dev/go.chromium.org/luci/resultdb/proto/v1#TestResult
class LuciTestResult {
  const LuciTestResult({
    required this.testId,
    required this.resultId,
    required this.expected,
    required this.status,
    required this.duration,
  });

  /// The structured id identifying the test file and case.
  final LuciStructuredTestId testId;

  /// An id that is unique within the invocation for a given [testId].
  final String resultId;

  /// Whether this result is expected (`true`) rather than an unexpected
  /// regression (`false`).
  final bool expected;

  /// The ResultDB `TestStatus` enum value (`PASS`, `FAIL`, or `SKIP`).
  final String status;

  /// The test duration as a proto `Duration` string (for example, `0.100000s`).
  final String duration;

  /// The JSON representation used by the ResultDB Recorder API.
  Map<String, Object?> toJson() => <String, Object?>{
    'testIdStructured': testId.toJson(),
    'resultId': resultId,
    'expected': expected,
    'status': status,
    'duration': duration,
  };
}

/// Converts the parsed [results] into a list of [LuciTestResult]s, one per
/// (non-hidden) individual test case.
///
/// Each result uses a *structured* test id (`testIdStructured`) so the "Test
/// Results" tab can separate the file from the test name: the module name is the
/// test file (relative to the repo root) and the case name is the individual
/// test name. The `flat` scheme is used because it has no intermediate
/// (coarse/fine) hierarchy levels.
///
/// [workingDirectory] is the directory the shard ran `flutter test`/`dart test`
/// in; it is used to resolve relative suite paths. [rootDirectory], when
/// provided, is stripped from the front of the (resolved) suite path so that the
/// module name is reported relative to the repository root (for example,
/// `packages/flutter/test/foo_test.dart` instead of an absolute path or a bare
/// `test/foo_test.dart`).
///
/// When [expectFailure] is true, the entire `flutter test` invocation was
/// expected to fail (for example, the `test_smoke_test` negative tests run with
/// `expectFailure: true`). In that case every reported result is marked as
/// `expected`, so ResultDB records them as expected failures rather than
/// surfacing them as red regressions in the "Test Results" tab.
List<LuciTestResult> convertToLuciTestResultsFormat(
  TestFileReporterResults results, {
  bool expectFailure = false,
  String? workingDirectory,
  String? rootDirectory,
}) {
  final out = <LuciTestResult>[];
  var counter = 0;
  for (final TestResult testResult in results.testResults.values) {
    if (testResult.hidden) {
      continue;
    }
    final String rawSuitePath = results.allTestSpecs[testResult.suiteID]?.path ?? '';
    final String moduleName = rawSuitePath.isEmpty
        ? testResult.name
        : _repoRelativeSuitePath(rawSuitePath, workingDirectory, rootDirectory);
    out.add(
      LuciTestResult(
        // A structured test id: the module is the test file and the case is the
        // individual test name, so ResultDB presents them as separate columns.
        testId: LuciStructuredTestId(
          moduleName: _sanitizeModuleName(moduleName),
          caseName: _sanitizeCaseName(testResult.name),
        ),
        // Result ids must be unique within the invocation for a given test id.
        resultId: '${counter++}',
        expected: expectFailure || testResult.actual == testResult.expected,
        status: _sinkStatus(testResult),
        duration: '${testResult.seconds.toStringAsFixed(6)}s',
      ),
    );
  }
  return out;
}

/// Returns [suitePath] as a forward-slash path relative to the repository root.
///
/// Suite paths reported by the test runner may be absolute (e.g.
/// `/b/s/w/.../flutter/dev/foo/bar_test.dart`) or relative to the directory the
/// shard ran in (e.g. `test/bar_test.dart` for a `packages/flutter` shard).
/// Relative paths are first resolved against [workingDirectory], then
/// [rootDirectory] (the repo root) is stripped, so every module name is a
/// consistent, repo-relative path regardless of where the shard ran.
String _repoRelativeSuitePath(String suitePath, String? workingDirectory, String? rootDirectory) {
  var p = suitePath;
  if (workingDirectory != null && workingDirectory.isNotEmpty && !_isAbsolutePath(p)) {
    p = '${_stripTrailingSeparators(workingDirectory)}/$p';
  }
  // Normalize separators so the id is stable and readable across platforms.
  p = p.replaceAll(r'\', '/');
  if (rootDirectory != null && rootDirectory.isNotEmpty) {
    final root = '${_stripTrailingSeparators(rootDirectory.replaceAll(r'\', '/'))}/';
    if (p.startsWith(root)) {
      p = p.substring(root.length);
    }
  }
  return p;
}

/// Whether [p] is an absolute path on POSIX (`/foo`) or Windows (`C:\foo`,
/// `C:/foo` or `\foo`).
bool _isAbsolutePath(String p) {
  if (p.isEmpty) {
    return false;
  }
  if (p.startsWith('/') || p.startsWith(r'\')) {
    return true;
  }
  // Windows drive-letter path, e.g. `C:\...` or `C:/...`.
  return p.length >= 3 && p[1] == ':' && (p[2] == r'\' || p[2] == '/');
}

/// Removes any trailing `/` or `\` separators from [p].
String _stripTrailingSeparators(String p) {
  int end = p.length;
  while (end > 0 && (p[end - 1] == '/' || p[end - 1] == r'\')) {
    end--;
  }
  return p.substring(0, end);
}

/// The maximum length, in bytes, of a structured test id module name.
const int _kMaxModuleNameBytes = 300;

/// The maximum length, in bytes, of a structured test id case name.
const int _kMaxCaseNameBytes = 512;

/// Makes [moduleName] safe for a ResultDB structured test id.
///
/// The module name must be non-empty, printable UTF-8 of at most
/// [_kMaxModuleNameBytes] bytes. Colons are allowed (they commonly appear in
/// build target names), so no escaping is required.
String _sanitizeModuleName(String moduleName) {
  // Replace control characters (including newlines/tabs) with spaces.
  String sanitized = moduleName.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ');
  if (sanitized.isEmpty) {
    sanitized = 'unknown';
  }
  return _truncateToBytes(sanitized, _kMaxModuleNameBytes);
}

/// Makes [caseName] safe for a ResultDB structured (non-legacy) test id case
/// name.
///
/// Unlike the legacy id format, a non-legacy scheme's case name must:
///  * escape `\` and `:` with a backslash (`:` denotes hierarchy separators),
///  * not start with a character in U+0020..U+002C (unless it is `*fixture`),
///  * be non-empty, printable UTF-8 of at most [_kMaxCaseNameBytes] bytes.
///
/// Keeping this robust prevents a single unusual test name from causing the
/// whole batch of results to be rejected.
String _sanitizeCaseName(String caseName) {
  // Replace control characters (including newlines/tabs) with spaces.
  String sanitized = caseName.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ');
  // "*fixture" is a reserved value (used for setup/teardown); leave it as-is.
  if (sanitized != '*fixture') {
    // Escape backslashes first, then colons (order matters).
    sanitized = sanitized.replaceAll(r'\', r'\\').replaceAll(':', r'\:');
  }
  if (sanitized.isEmpty) {
    sanitized = 'unnamed test';
  }
  // The first character must not be in U+0020..U+002C (space and !"#$%&'()*+,).
  final int first = sanitized.codeUnitAt(0);
  if (sanitized != '*fixture' && first >= 0x20 && first <= 0x2c) {
    sanitized = '_$sanitized';
  }
  sanitized = _truncateToBytes(sanitized, _kMaxCaseNameBytes);
  // Truncation must not leave a dangling (unpaired) trailing backslash, which
  // would be an invalid escape sequence.
  return _stripDanglingBackslash(sanitized);
}

/// Truncates [value] so its UTF-8 encoding is at most [maxBytes] bytes, without
/// splitting a UTF-16 code unit.
String _truncateToBytes(String value, int maxBytes) {
  while (utf8.encode(value).length > maxBytes) {
    value = value.substring(0, value.length - 1);
  }
  return value;
}

/// Removes a trailing backslash if it would be left unpaired (for example after
/// truncation), so the value remains a valid escaped string.
String _stripDanglingBackslash(String value) {
  var trailing = 0;
  for (int i = value.length - 1; i >= 0 && value[i] == r'\'; i--) {
    trailing++;
  }
  if (trailing.isOdd) {
    return value.substring(0, value.length - 1);
  }
  return value;
}

/// Maps a parsed [testResult] to a ResultDB `TestStatus` enum value.
String _sinkStatus(TestResult testResult) {
  if (testResult.skipped) {
    return 'SKIP';
  }
  return testResult.actual == 'PASS' ? 'PASS' : 'FAIL';
}
