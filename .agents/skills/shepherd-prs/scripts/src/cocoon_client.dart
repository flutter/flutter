// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show ProcessResult;

import 'package:http/http.dart' as http;
import 'package:process/process.dart';
import 'package:yaml/yaml.dart';

import 'models.dart';

const String _ghExecutable = 'gh';
const String _gitHubApiBaseUrl = 'https://api.github.com';
const String _gitHubRawAcceptHeader = 'application/vnd.github.raw+json';
const String _gitHubJsonAcceptHeader = 'application/vnd.github+json';
const String _userAgent = 'flutter-shepherd-prs-cli';

final class _GitHubNotFoundException extends DashboardException {
  const _GitHubNotFoundException(super.message);
}

/// HTTP and `gh` client for `flutter-dashboard` (`flutter/cocoon`) and GitHub
/// pre-flight verification.
class CocoonClient {
  CocoonClient({
    required this._httpClient,
    required this._processManager,
    String dashboardBaseUrl = DashboardConstants.dashboardBaseUrl,
  }) : _dashboardBaseUrl = dashboardBaseUrl.endsWith('/')
           ? dashboardBaseUrl.substring(0, dashboardBaseUrl.length - 1)
           : dashboardBaseUrl;

  final String _dashboardBaseUrl;
  final http.Client _httpClient;
  final ProcessManager _processManager;

  /// Queries `GET /api/public/get-presubmit-guard` for [repo] and [sha].
  Future<PresubmitGuardReport> getPresubmitGuard({
    required String repo,
    required String sha,
  }) async {
    final Uri uri = Uri.parse(
      '$_dashboardBaseUrl${DashboardConstants.presubmitGuardPath}'
      '?repo=${Uri.encodeQueryComponent(repo)}&sha=${Uri.encodeQueryComponent(sha)}',
    );
    final http.Response response = await _httpClient.get(
      uri,
      headers: const <String, String>{'User-Agent': _userAgent},
    );
    if (response.statusCode != 200) {
      throw DashboardException(
        'GET ${DashboardConstants.presubmitGuardPath} failed for $repo@$sha '
        '(HTTP ${response.statusCode}): ${_trimBody(response.body)}',
      );
    }
    final Object? decoded = _decodeJsonBody(
      response.body,
      context: DashboardConstants.presubmitGuardPath,
    );
    return PresubmitGuardReport.fromJson(
      decodeJsonObject(decoded, context: DashboardConstants.presubmitGuardPath),
    );
  }

  /// Queries `GET /api/public/get-presubmit-job` for [checkRunId] and [jobName].
  Future<List<PresubmitJobAttempt>> getPresubmitJob({
    required int checkRunId,
    required String jobName,
  }) async {
    final Uri uri = Uri.parse(
      '$_dashboardBaseUrl${DashboardConstants.presubmitJobPath}'
      '?check_run_id=$checkRunId&job_name=${Uri.encodeComponent(jobName)}',
    );
    final http.Response response = await _httpClient.get(
      uri,
      headers: const <String, String>{'User-Agent': _userAgent},
    );
    if (response.statusCode != 200) {
      throw DashboardException(
        'GET ${DashboardConstants.presubmitJobPath} failed for "$jobName" '
        '(HTTP ${response.statusCode}): ${_trimBody(response.body)}',
      );
    }
    final Object? decoded = _decodeJsonBody(
      response.body,
      context: DashboardConstants.presubmitJobPath,
    );
    final List<Map<String, Object?>> rawList = decodeJsonObjectList(
      decoded,
      context: DashboardConstants.presubmitJobPath,
    );
    return <PresubmitJobAttempt>[for (final Map<String, Object?> item in rawList) .fromJson(item)];
  }

  /// Triggers `POST /api/rerun-failed-job` for a single failed [builder].
  Future<http.Response> sendRerunFailedJob({
    required String builder,
    required String idToken,
    required String owner,
    required int prNumber,
    required String repo,
  }) => _httpClient.post(
    Uri.parse('$_dashboardBaseUrl${DashboardConstants.rerunFailedJobPath}'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'User-Agent': _userAgent,
      DashboardConstants.idTokenHeader: idToken,
    },
    body: jsonEncode(<String, Object?>{
      'owner': owner,
      'repo': repo,
      'pr': prNumber,
      'builder': builder,
    }),
  );

  /// Triggers `POST /api/rerun-all-failed-jobs` for [prNumber].
  Future<http.Response> sendRerunAllFailedJobs({
    required String idToken,
    required String owner,
    required int prNumber,
    required String repo,
  }) => _httpClient.post(
    Uri.parse('$_dashboardBaseUrl${DashboardConstants.rerunAllFailedJobsPath}'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'User-Agent': _userAgent,
      DashboardConstants.idTokenHeader: idToken,
    },
    body: jsonEncode(<String, Object?>{'owner': owner, 'repo': repo, 'pr': prNumber}),
  );

  /// Fetches PR metadata (`headSha`, `baseRef`, `state`, `title`) from GitHub.
  Future<PullRequestMetadata> fetchPullRequestMetadata({
    required String owner,
    required int prNumber,
    required String repo,
  }) async {
    final String body = await _fetchGitHubEndpoint(
      'repos/$owner/$repo/pulls/$prNumber',
      acceptHeader: _gitHubJsonAcceptHeader,
    );
    final Object? decoded = _decodeJsonBody(body, context: 'GitHub pull request #$prNumber');
    return PullRequestMetadata.fromGitHubApiJson(
      decodeJsonObject(decoded, context: 'GitHub pull request #$prNumber'),
    );
  }

  /// Verifies that `ci.yaml validation` passed on [headSha] AND that tip-of-tree
  /// [baseRef] has not removed or renamed any non-`bringup: true` builder from
  /// `.ci.yaml` or `engine/src/flutter/.ci.yaml`.
  ///
  /// Fails closed if GitHub check-runs or `.ci.yaml` contents cannot be fetched.
  Future<CiYamlSafetyReport> verifyCiYamlSafety({
    required String baseRef,
    required String headSha,
    required String owner,
    required String repo,
  }) async {
    final warnings = <String>[];
    String? checkStatus;
    String? checkConclusion;
    String? checkFailureText;

    try {
      final String encodedCheckName = Uri.encodeComponent(DashboardConstants.ciYamlCheckName);
      final String checkRunsBody = await _fetchGitHubEndpoint(
        'repos/$owner/$repo/commits/$headSha/check-runs?check_name=$encodedCheckName',
        acceptHeader: _gitHubJsonAcceptHeader,
      );
      final Map<String, Object?> checkRunsJson = decodeJsonObject(
        _decodeJsonBody(checkRunsBody, context: 'GitHub check-runs for $headSha'),
        context: 'GitHub check-runs for $headSha',
      );
      final Object? rawRuns = checkRunsJson['check_runs'];
      if (rawRuns is List<Object?> && rawRuns.isNotEmpty) {
        final Map<String, Object?> latestRun = _selectLatestCheckRun(rawRuns);
        checkStatus = readJsonString(latestRun['status']);
        checkConclusion = readJsonString(latestRun['conclusion']);
        if (latestRun['output'] case {'text': final String text} when text.trim().isNotEmpty) {
          checkFailureText = text.trim();
        } else if (latestRun['output'] case {'summary': final String summary}
            when summary.trim().isNotEmpty) {
          checkFailureText = summary.trim();
        }
      }
    } on DashboardException catch (error) {
      return CiYamlSafetyReport(
        failureReason:
            'Failed to verify "${DashboardConstants.ciYamlCheckName}" on $headSha: '
            '${error.message}',
        isSafe: false,
        removedBuilders: const <String>[],
        warnings: const <String>[],
      );
    }

    if (checkStatus == null) {
      warnings.add('Check run "${DashboardConstants.ciYamlCheckName}" was not found on $headSha.');
    } else if (checkStatus != 'completed') {
      return CiYamlSafetyReport(
        checkRunConclusion: checkConclusion,
        checkRunStatus: checkStatus,
        failureReason:
            '"${DashboardConstants.ciYamlCheckName}" on $headSha is still "$checkStatus". '
            'Wait for it to complete before retriggering presubmit jobs.',
        isSafe: false,
        removedBuilders: const <String>[],
        warnings: List<String>.unmodifiable(warnings),
      );
    } else if (checkConclusion != 'success' && checkConclusion != 'neutral') {
      final detail = checkFailureText != null ? '\n$checkFailureText' : '';
      return CiYamlSafetyReport(
        checkRunConclusion: checkConclusion,
        checkRunStatus: checkStatus,
        failureReason:
            '"${DashboardConstants.ciYamlCheckName}" failed ($checkConclusion) on $headSha. '
            'Update the PR branch with `$baseRef` instead of rerunning; rerunning now would '
            'orphan the new attempt in Firestore.$detail',
        isSafe: false,
        removedBuilders: const <String>[],
        warnings: List<String>.unmodifiable(warnings),
      );
    }

    final removedBuilders = <String>[];
    for (final String ciYamlPath in DashboardConstants.ciYamlPaths) {
      final allowMissingFile = ciYamlPath == DashboardConstants.engineCiYamlPath;
      final String? headYaml;
      final String? baseYaml;
      try {
        headYaml = await _fetchCiYamlFile(
          allowMissing: allowMissingFile,
          filePath: ciYamlPath,
          owner: owner,
          ref: headSha,
          repo: repo,
        );
        baseYaml = await _fetchCiYamlFile(
          allowMissing: allowMissingFile,
          filePath: ciYamlPath,
          owner: owner,
          ref: baseRef,
          repo: repo,
        );
      } on DashboardException catch (error) {
        return CiYamlSafetyReport(
          checkRunConclusion: checkConclusion,
          checkRunStatus: checkStatus,
          failureReason:
              'Failed to fetch $ciYamlPath to verify builder-removal safety between '
              '$headSha and `$baseRef`: ${error.message}',
          isSafe: false,
          removedBuilders: const <String>[],
          warnings: List<String>.unmodifiable(warnings),
        );
      }

      if (headYaml == null || baseYaml == null) {
        warnings.add('$ciYamlPath not present at $headSha or $baseRef; skipped.');
        continue;
      }
      final List<String> missingInBase = findRemovedNonBringupBuilders(
        baseCiYaml: baseYaml,
        headCiYaml: headYaml,
      );
      for (final builder in missingInBase) {
        removedBuilders.add('$builder ($ciYamlPath)');
      }
    }

    if (removedBuilders.isNotEmpty) {
      return CiYamlSafetyReport(
        checkRunConclusion: checkConclusion,
        checkRunStatus: checkStatus,
        failureReason:
            'PR branch $headSha contains non-bringup builder(s) that were removed or renamed on '
            'tip-of-tree `$baseRef`: ${removedBuilders.join(', ')}. '
            'Cocoon (`RerunFailedJob` / `RerunAllFailedJobs`) commits `attempt_number: N + 1` '
            'to Firestore before `CiYamlFetcher.getCiYamlByCommit`, so calling `/api/rerun-*` '
            'on this commit would fail validation and permanently orphan the attempt in `"New"`. '
            'Merge `$baseRef` / update the branch instead.',
        isSafe: false,
        removedBuilders: List<String>.unmodifiable(removedBuilders),
        warnings: List<String>.unmodifiable(warnings),
      );
    }

    return CiYamlSafetyReport(
      checkRunConclusion: checkConclusion,
      checkRunStatus: checkStatus,
      isSafe: true,
      removedBuilders: const <String>[],
      warnings: List<String>.unmodifiable(warnings),
    );
  }

  /// Returns non-`bringup: true` target names present in [headCiYaml] that no
  /// longer exist in [baseCiYaml].
  static List<String> findRemovedNonBringupBuilders({
    required String baseCiYaml,
    required String headCiYaml,
  }) {
    final Set<String> baseTargets = _extractAllTargetNames(baseCiYaml);
    final List<({bool isBringup, String name})> headTargets = _extractTargetsWithBringup(
      headCiYaml,
    );
    final removed = <String>[];
    for (final (:bool isBringup, :String name) in headTargets) {
      if (!isBringup && !baseTargets.contains(name)) {
        removed.add(name);
      }
    }
    return removed;
  }

  static Set<String> _extractAllTargetNames(String yamlSource) {
    final names = <String>{};
    for (final (isBringup: _, :String name) in _extractTargetsWithBringup(yamlSource)) {
      names.add(name);
    }
    return names;
  }

  static List<({bool isBringup, String name})> _extractTargetsWithBringup(String yamlSource) {
    final Object? document;
    try {
      document = loadYaml(yamlSource);
    } on YamlException catch (error) {
      throw DashboardException('Failed to parse .ci.yaml content: $error');
    }
    if (document is! YamlMap) {
      return const <({bool isBringup, String name})>[];
    }
    final Object? rawTargets = document['targets'];
    if (rawTargets is! YamlList) {
      return const <({bool isBringup, String name})>[];
    }
    final results = <({bool isBringup, String name})>[];
    for (final Object? entry in rawTargets) {
      if (entry is! YamlMap) {
        continue;
      }
      final Object? rawName = entry['name'];
      if (rawName is! String || rawName.isEmpty) {
        continue;
      }
      results.add((isBringup: entry['bringup'] == true, name: rawName));
    }
    return results;
  }

  Future<String?> _fetchCiYamlFile({
    required bool allowMissing,
    required String filePath,
    required String owner,
    required String ref,
    required String repo,
  }) async {
    final String encodedRef = Uri.encodeQueryComponent(ref);
    try {
      return await _fetchGitHubEndpoint(
        'repos/$owner/$repo/contents/$filePath?ref=$encodedRef',
        acceptHeader: _gitHubRawAcceptHeader,
      );
    } on _GitHubNotFoundException {
      if (allowMissing) {
        return null;
      }
      rethrow;
    }
  }

  Future<String> _fetchGitHubEndpoint(String endpoint, {required String acceptHeader}) async {
    if (_processManager.canRun(_ghExecutable)) {
      final ProcessResult result = await _processManager.run(<String>[
        _ghExecutable,
        'api',
        '-H',
        'Accept: $acceptHeader',
        endpoint,
      ]);
      if (result.exitCode == 0) {
        return '${result.stdout}';
      }
      final String errText = '${result.stderr}'.trim();
      if (errText.contains('HTTP 404') || errText.contains('404 Not Found')) {
        throw _GitHubNotFoundException('`gh api $endpoint` returned 404: $errText');
      }
      throw DashboardException('`gh api $endpoint` failed (exit ${result.exitCode}): $errText');
    }

    final Uri uri = Uri.parse('$_gitHubApiBaseUrl/$endpoint');
    final http.Response response = await _httpClient.get(
      uri,
      headers: <String, String>{'Accept': acceptHeader, 'User-Agent': _userAgent},
    );
    if (response.statusCode == 404) {
      throw _GitHubNotFoundException('GET $uri returned HTTP 404.');
    }
    if (response.statusCode != 200) {
      throw DashboardException(
        'GET $uri failed (HTTP ${response.statusCode}): ${_trimBody(response.body)}',
      );
    }
    return response.body;
  }

  static Map<String, Object?> _selectLatestCheckRun(List<Object?> rawRuns) {
    Map<String, Object?>? best;
    var bestId = -1;
    for (final item in rawRuns) {
      if (item is! Map<Object?, Object?>) {
        continue;
      }
      final Map<String, Object?> map = decodeJsonObject(item, context: 'check_run');
      final int id = readJsonInt(map['id']) ?? 0;
      if (best == null || id >= bestId) {
        best = map;
        bestId = id;
      }
    }
    return best ?? const <String, Object?>{};
  }

  static Object? _decodeJsonBody(String body, {required String context}) {
    try {
      return jsonDecode(body);
    } on FormatException catch (error) {
      throw DashboardException('Invalid JSON from $context: ${error.message} (${_trimBody(body)})');
    }
  }

  static String _trimBody(String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) {
      return 'empty body';
    }
    return trimmed.length <= 240 ? trimmed : '${trimmed.substring(0, 240)}...';
  }
}
