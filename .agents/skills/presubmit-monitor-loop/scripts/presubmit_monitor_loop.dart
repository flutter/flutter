// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Automated CLI tool to monitor presubmit checks on a Flutter PR,
/// detect dashboard check status, fetch failure logs from Buildbucket,
/// and drive the presubmit remediation loop until all checks pass.
void main(List<String> args) async {
  final PresubmitOptions options = _parseArgs(args);
  if (options.showHelp || (options.prNumber == null && options.commitSha == null)) {
    _printUsage();
    exit(options.showHelp ? 0 : 1);
  }

  final monitor = PresubmitMonitor(options);
  final int exitCode = await monitor.run();
  exit(exitCode);
}

class PresubmitOptions {
  PresubmitOptions(
    this.prNumber,
    this.commitSha,
    this.watch,
    this.pollInterval,
    this.timeout,
    this.fetchLogs,
    this.showHelp,
  );

  final int? prNumber;
  final String? commitSha;
  final bool watch;
  final Duration pollInterval;
  final Duration timeout;
  final bool fetchLogs;
  final bool showHelp;
}

PresubmitOptions _parseArgs(List<String> args) {
  int? pr;
  String? commit;
  var watch = true;
  var pollInterval = const Duration(seconds: 30);
  const timeout = Duration(hours: 4);
  var fetchLogs = true;
  var help = false;

  for (var i = 0; i < args.length; i++) {
    final String arg = args[i];
    if (arg == '--help' || arg == '-h') {
      help = true;
    } else if (arg == '--no-watch') {
      watch = false;
    } else if (arg == '--no-fetch-logs') {
      fetchLogs = false;
    } else if (arg.startsWith('--pr=')) {
      pr = int.tryParse(arg.substring(5));
    } else if (arg == '--pr' && i + 1 < args.length) {
      pr = int.tryParse(args[++i]);
    } else if (arg.startsWith('--commit=')) {
      commit = arg.substring(9);
    } else if (arg == '--commit' && i + 1 < args.length) {
      commit = args[++i];
    } else if (arg.startsWith('--poll=')) {
      final int? secs = int.tryParse(arg.substring(7));
      if (secs != null) {
        pollInterval = Duration(seconds: secs);
      }
    } else if (int.tryParse(arg) != null && pr == null) {
      pr = int.parse(arg);
    } else if (arg.length == 40 && commit == null) {
      commit = arg;
    }
  }

  return PresubmitOptions(pr, commit, watch, pollInterval, timeout, fetchLogs, help);
}

void _printUsage() {
  stdout.writeln('Presubmit Monitor Loop CLI');
  stdout.writeln('Usage: dart presubmit_monitor_loop.dart [PR_NUMBER] [options]');
  stdout.writeln();
  stdout.writeln('Options:');
  stdout.writeln('  --pr=<num>          GitHub PR number (e.g. 193259)');
  stdout.writeln('  --commit=<sha>      Commit SHA to monitor (auto-resolved from PR if omitted)');
  stdout.writeln('  --no-watch          Run a single check and exit immediately');
  stdout.writeln('  --poll=<seconds>    Poll interval in seconds (default: 30)');
  stdout.writeln('  --no-fetch-logs     Skip downloading raw failure logs');
  stdout.writeln('  --help, -h          Show this help message');
}

class BuildInfo {
  BuildInfo({required this.id, required this.builder});

  final String id;
  final String builder;
}

class CheckResult {
  CheckResult({
    required this.total,
    required this.successCount,
    required this.failureCount,
    required this.runningCount,
    required this.failures,
  });

  final int total;
  final int successCount;
  final int failureCount;
  final int runningCount;
  final List<BuildInfo> failures;

  bool get isComplete => runningCount == 0;
  bool get isGreen => isComplete && failureCount == 0 && total > 0;
}

class PresubmitMonitor {
  PresubmitMonitor(this.options);

  final PresubmitOptions options;
  final HttpClient _client = HttpClient();

  Future<int> run() async {
    final String? commit = await _resolveCommitSha();
    if (commit == null) {
      stderr.writeln('Error: Could not resolve commit SHA.');
      return 1;
    }

    stdout.writeln('====================================================');
    stdout.writeln('Presubmit Monitor Active');
    if (options.prNumber != null) {
      stdout.writeln('PR: https://github.com/flutter/flutter/pull/${options.prNumber}');
    }
    stdout.writeln('Commit: $commit');
    stdout.writeln('Poll Interval: ${options.pollInterval.inSeconds}s');
    stdout.writeln('====================================================\n');

    final stopwatch = Stopwatch()..start();
    while (true) {
      final String now = DateTime.now().toUtc().toIso8601String().substring(11, 19);
      final CheckResult checkResult = await _queryBuildbucket(commit);

      stdout.writeln(
        '[$now] Total: ${checkResult.total} | '
        'Success: ${checkResult.successCount} | '
        'Failed: ${checkResult.failureCount} | '
        'Running/Queued: ${checkResult.runningCount}',
      );

      if (!options.watch || checkResult.isComplete) {
        stdout.writeln('\nDashboard Checks stopped (all scheduled builds finished).');
        if (checkResult.isGreen) {
          stdout.writeln('>>> ALL CHECKS GREEN! Presubmit passed successfully. <<<');
          return 0;
        } else {
          stdout.writeln(
            '>>> FAILURES DETECTED (${checkResult.failureCount} builds failed). <<<\n',
          );
          await _reportFailures(checkResult.failures);
          return 2;
        }
      }

      if (stopwatch.elapsed > options.timeout) {
        stderr.writeln('Timed out waiting for presubmit after ${options.timeout.inHours} hours.');
        return 1;
      }

      await Future<void>.delayed(options.pollInterval);
    }
  }

  Future<String?> _resolveCommitSha() async {
    if (options.commitSha != null && options.commitSha!.isNotEmpty) {
      return options.commitSha;
    }
    if (options.prNumber == null) {
      return null;
    }

    try {
      final ProcessResult result = await Process.run('gh', <String>[
        'pr',
        'view',
        '${options.prNumber}',
        '--json',
        'headRefOid',
        '-q',
        '.headRefOid',
      ]);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        return result.stdout.toString().trim();
      }
    } catch (_) {}

    return null;
  }

  Future<CheckResult> _queryBuildbucket(String commitSha) async {
    const url = 'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds/SearchBuilds';
    final String payload = json.encode(<String, dynamic>{
      'predicate': <String, dynamic>{
        'builder': <String, dynamic>{'project': 'flutter'},
        'tags': <Map<String, String>>[
          <String, String>{'key': 'buildset', 'value': 'sha/git/$commitSha'},
        ],
      },
      'pageSize': 1000,
    });

    try {
      final HttpClientRequest request = await _client.postUrl(Uri.parse(url));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');
      request.write(payload);
      final HttpClientResponse response = await request.close();

      final String responseBody = await response.transform(utf8.decoder).join();
      final String cleanJson = responseBody.trim().startsWith(")]}'")
          ? responseBody.trim().substring(4).trim()
          : responseBody.trim();

      final data = json.decode(cleanJson)! as Map<String, dynamic>;
      final rawBuilds = data['builds'] as List<dynamic>?;
      final List<dynamic> builds = rawBuilds ?? <dynamic>[];

      var success = 0;
      var failure = 0;
      var running = 0;
      final failures = <BuildInfo>[];

      for (final b in builds) {
        final map = b as Map<String, dynamic>;
        final String status = map['status'] as String? ?? '';
        final String id = map['id']?.toString() ?? '';
        final Map<String, dynamic> builderMap =
            map['builder'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final String builder = builderMap['builder'] as String? ?? 'unknown';

        if (status == 'SUCCESS') {
          success++;
        } else if (status == 'FAILURE') {
          failure++;
          failures.add(BuildInfo(id: id, builder: builder));
        } else if (status == 'STARTED' || status == 'SCHEDULED') {
          running++;
        }
      }

      return CheckResult(
        total: builds.length,
        successCount: success,
        failureCount: failure,
        runningCount: running,
        failures: failures,
      );
    } catch (e) {
      stderr.writeln('Warning: Failed to query Buildbucket: $e');
      return CheckResult(
        total: 0,
        successCount: 0,
        failureCount: 0,
        runningCount: -1,
        failures: <BuildInfo>[],
      );
    }
  }

  Future<void> _reportFailures(List<BuildInfo> failures) async {
    stdout.writeln('Detailed Failure Breakdown:');
    stdout.writeln('----------------------------------------------------');
    for (final f in failures) {
      stdout.writeln('Builder: ${f.builder}');
      stdout.writeln('Build ID: ${f.id}');
      stdout.writeln('URL: https://cr-buildbucket.appspot.com/build/${f.id}');
      if (options.fetchLogs) {
        await _fetchAndPrintStepDetails(f.id);
      }
      stdout.writeln('----------------------------------------------------');
    }
  }

  Future<void> _fetchAndPrintStepDetails(String buildId) async {
    const url = 'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds/GetBuild';
    final String payload = json.encode(<String, dynamic>{
      'id': buildId,
      'fields': 'id,builder,steps',
    });

    try {
      final HttpClientRequest request = await _client.postUrl(Uri.parse(url));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');
      request.write(payload);
      final HttpClientResponse response = await request.close();

      final String responseText = await response.transform(utf8.decoder).join();
      final String cleanJson = responseText.trim().startsWith(")]}'")
          ? responseText.trim().substring(4).trim()
          : responseText.trim();

      final data = json.decode(cleanJson)! as Map<String, dynamic>;
      final rawSteps = data['steps'] as List<dynamic>?;
      final List<dynamic> steps = rawSteps ?? <dynamic>[];
      for (final s in steps) {
        final map = s as Map<String, dynamic>;
        if (map['status'] == 'FAILURE') {
          final String stepName = map['name'] as String? ?? 'unknown';
          stdout.writeln('  Failed Step: $stepName');
          final List<dynamic> logs = (map['logs'] as List<dynamic>?) ?? <dynamic>[];
          for (final dynamic l in logs) {
            final log = l as Map<String, dynamic>;
            final String logName = log['name'] as String? ?? '';
            final String viewUrl = log['viewUrl'] as String? ?? '';
            if (viewUrl.isNotEmpty && (logName == 'stdout' || logName == 'stdio')) {
              stdout.writeln('  Log: $viewUrl?format=raw');
            }
          }
        }
      }
    } catch (_) {}
  }
}
