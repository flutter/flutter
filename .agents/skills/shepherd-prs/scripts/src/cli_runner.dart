// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:http/http.dart' as http;
import 'package:process/process.dart';

import 'auth_provider.dart';
import 'cocoon_client.dart';
import 'models.dart';

const int _orphanStaleThresholdMs = 300000;

const String _optionAccount = 'account';
const String _optionAccessToken = 'access-token';
const String _optionBaseRef = 'base-ref';
const String _optionBuilder = 'builder';
const String _optionCredentialsFile = 'credentials-file';
const String _optionDashboardUrl = 'dashboard-url';
const String _optionIdToken = 'id-token';
const String _optionOwner = 'owner';
const String _optionPr = 'pr';
const String _optionRefreshToken = 'refresh-token';
const String _optionRepo = 'repo';
const String _optionSha = 'sha';

const String _flagAllFailed = 'all-failed';
const String _flagCheck = 'check';
const String _flagDetails = 'details';
const String _flagDryRun = 'dry-run';
const String _flagJson = 'json';
const String _flagLogout = 'logout';
const String _flagSkipCiYamlCheck = 'skip-ci-yaml-check';

/// CLI command runner for inspecting and retriggering `flutter-dashboard`
/// (`flutter/cocoon`) presubmit jobs.
class DashboardCliRunner {
  DashboardCliRunner({
    required this._errSink,
    required this._fileSystem,
    required this._hostEnvironment,
    required this._httpClient,
    required this._outSink,
    required this._processManager,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final StringSink _errSink;
  final FileSystem _fileSystem;
  final HostEnvironment _hostEnvironment;
  final http.Client _httpClient;
  final StringSink _outSink;
  final ProcessManager _processManager;

  Future<int> run(List<String> arguments) async {
    final runner =
        CommandRunner<int>(
            'dashboard_presubmit.dart',
            'Inspect and retrigger failed flutter-dashboard (flutter/cocoon) presubmit jobs.',
          )
          ..addCommand(_StatusCommand(this))
          ..addCommand(_RerunCommand(this))
          ..addCommand(_LoginCommand(this));

    try {
      final int? code = await runner.run(arguments);
      if (code == null) {
        _outSink.writeln(runner.usage);
        return ExitCodes.success;
      }
      return code;
    } on UsageException catch (error) {
      _errSink.writeln(error);
      return ExitCodes.error;
    } on DashboardException catch (error) {
      _errSink.writeln('Error: ${error.message}');
      return error.exitCode;
    }
  }

  CocoonClient _createCocoonClient(String dashboardBaseUrl) => CocoonClient(
    dashboardBaseUrl: dashboardBaseUrl,
    httpClient: _httpClient,
    processManager: _processManager,
  );

  DashboardAuthProvider _createAuthProvider(String? credentialsFilePath) => DashboardAuthProvider(
    clock: _clock,
    credentialsFilePath: credentialsFilePath,
    fileSystem: _fileSystem,
    hostEnvironment: _hostEnvironment,
    httpClient: _httpClient,
    processManager: _processManager,
  );
}

final class _StatusCommand extends Command<int> {
  _StatusCommand(this._runner) {
    argParser
      ..addOption(_optionPr, abbr: 'p', help: 'Pull request number on GitHub.')
      ..addOption(_optionSha, abbr: 's', help: 'Commit SHA (optional when --pr is provided).')
      ..addOption(
        _optionBaseRef,
        help: 'Target branch ref for .ci.yaml comparison when --sha is used without --pr.',
      )
      ..addOption(
        _optionOwner,
        defaultsTo: DashboardConstants.defaultOwner,
        help: 'GitHub repository owner.',
      )
      ..addOption(
        _optionRepo,
        defaultsTo: DashboardConstants.defaultRepo,
        help: 'GitHub repository name.',
      )
      ..addMultiOption(
        _optionBuilder,
        abbr: 'b',
        help: 'Specific builder name(s) to fetch attempt details for.',
      )
      ..addFlag(
        _flagDetails,
        help: 'Fetch attempt history, build_id, and failure summaries for failed jobs.',
        negatable: false,
      )
      ..addFlag(
        _flagSkipCiYamlCheck,
        help: 'Skip GitHub ci.yaml validation and builder-removal checks.',
        negatable: false,
      )
      ..addOption(_optionDashboardUrl, defaultsTo: DashboardConstants.dashboardBaseUrl, hide: true)
      ..addFlag(_flagJson, help: 'Emit structured JSON output.', negatable: false);
  }

  final DashboardCliRunner _runner;

  @override
  String get name => 'status';

  @override
  String get description =>
      'Inspect flutter-dashboard presubmit status, suppressed flakes, and .ci.yaml safety.';

  @override
  Future<int> run() async {
    final ArgResults args = argResults!;
    final String owner = args.option(_optionOwner)!;
    final String repo = args.option(_optionRepo)!;
    final String dashboardBaseUrl = args.option(_optionDashboardUrl)!;
    final bool jsonOutput = args.flag(_flagJson);
    final bool includeDetails = args.flag(_flagDetails);
    final bool skipCiYamlCheck = args.flag(_flagSkipCiYamlCheck);
    final List<String> requestedBuilders = args.multiOption(_optionBuilder);

    final int? prNumber = _parseOptionalPrNumber(args.option(_optionPr), usageException);
    final String? explicitSha = _nonEmptyOption(args.option(_optionSha));
    if (prNumber == null && explicitSha == null) {
      usageException('Provide --pr <number> or --sha <commit_sha>.');
    }

    final CocoonClient client = _runner._createCocoonClient(dashboardBaseUrl);
    PullRequestMetadata? prMetadata;
    if (prNumber != null) {
      prMetadata = await client.fetchPullRequestMetadata(
        owner: owner,
        prNumber: prNumber,
        repo: repo,
      );
    }

    final String headSha = explicitSha ?? prMetadata!.headSha;
    final String? baseRef = _nonEmptyOption(args.option(_optionBaseRef)) ?? prMetadata?.baseRef;
    final PresubmitGuardReport guard = await client.getPresubmitGuard(repo: repo, sha: headSha);

    CiYamlSafetyReport? ciYamlSafety;
    if (!skipCiYamlCheck && baseRef != null) {
      ciYamlSafety = await client.verifyCiYamlSafety(
        baseRef: baseRef,
        headSha: headSha,
        owner: owner,
        repo: repo,
      );
    }

    final jobAttempts = <String, List<PresubmitJobAttempt>>{};
    final orphanedBuilders = <String>[];
    final int? checkRunId = guard.checkRunId;
    final int nowMs = _runner._clock().millisecondsSinceEpoch;
    final bool ciYamlUnsafe = ciYamlSafety != null && !ciYamlSafety.isSafe;

    if (checkRunId != null && (includeDetails || requestedBuilders.isNotEmpty)) {
      final buildersToInspect = <String>{
        if (includeDetails)
          for (final PresubmitJobEntry job in guard.failedJobs) job.name,
        if (includeDetails)
          for (final PresubmitJobEntry job in guard.pendingJobs)
            if (job.status == 'New') job.name,
        ...requestedBuilders,
      };
      for (final builder in buildersToInspect) {
        final List<PresubmitJobAttempt> attempts = await client.getPresubmitJob(
          checkRunId: checkRunId,
          jobName: builder,
        );
        jobAttempts[builder] = attempts;
        for (final attempt in attempts) {
          final int? createdAtMs = attempt.creationTime;
          final bool isStaleUnscheduled =
              ciYamlUnsafe ||
              (createdAtMs != null && nowMs - createdAtMs >= _orphanStaleThresholdMs);
          if (attempt.attemptNumber > 1 &&
              attempt.status == 'New' &&
              attempt.buildId == null &&
              isStaleUnscheduled) {
            orphanedBuilders.add(builder);
            break;
          }
        }
      }
    }

    final String dashboardUrl = DashboardConstants.presubmitDashboardUrl(repo: repo, sha: headSha);
    if (jsonOutput) {
      _runner._outSink.writeln(
        jsonEncode(<String, Object?>{
          'dashboard_url': dashboardUrl,
          'sha': headSha,
          if (prMetadata != null) 'pull_request': prMetadata.toJson(),
          'guard': guard.toJson(),
          if (ciYamlSafety != null) 'ci_yaml_safety': ciYamlSafety.toJson(),
          if (jobAttempts.isNotEmpty)
            'job_attempts': <String, Object?>{
              for (final MapEntry(:String key, :List<PresubmitJobAttempt> value)
                  in jobAttempts.entries)
                key: <Map<String, Object?>>[
                  for (final PresubmitJobAttempt attempt in value) attempt.toJson(),
                ],
            },
          if (orphanedBuilders.isNotEmpty) 'suspected_orphaned_rerun_builders': orphanedBuilders,
        }),
      );
      return ExitCodes.success;
    }

    _printHumanStatus(
      ciYamlSafety: ciYamlSafety,
      dashboardUrl: dashboardUrl,
      guard: guard,
      headSha: headSha,
      jobAttempts: jobAttempts,
      orphanedBuilders: orphanedBuilders,
      prMetadata: prMetadata,
    );
    return ExitCodes.success;
  }

  void _printHumanStatus({
    required CiYamlSafetyReport? ciYamlSafety,
    required String dashboardUrl,
    required PresubmitGuardReport guard,
    required String headSha,
    required Map<String, List<PresubmitJobAttempt>> jobAttempts,
    required List<String> orphanedBuilders,
    required PullRequestMetadata? prMetadata,
  }) {
    final StringSink out = _runner._outSink;
    if (prMetadata != null) {
      final PullRequestMetadata(:int number, :String title, :String state, :String baseRef) =
          prMetadata;
      out.writeln('PR #$number ($state, base: $baseRef): $title');
    }
    out
      ..writeln('Commit SHA: $headSha')
      ..writeln('Dashboard URL: $dashboardUrl')
      ..writeln('Guard Status: ${guard.guardStatus} (check_run_id: ${guard.checkRunId ?? 'none'})')
      ..writeln(
        'Jobs: ${guard.succeededJobs.length} succeeded, '
        '${guard.failedJobs.length} failed, '
        '${guard.suppressedJobs.length} suppressed (Neutral), '
        '${guard.pendingJobs.length} pending',
      );

    if (ciYamlSafety != null) {
      out.writeln(
        ciYamlSafety.isSafe
            ? '.ci.yaml Rerun Safety: SAFE'
            : '.ci.yaml Rerun Safety: UNSAFE - ${ciYamlSafety.failureReason}',
      );
      for (final String warning in ciYamlSafety.warnings) {
        out.writeln('Warning: $warning');
      }
    }

    if (orphanedBuilders.isNotEmpty) {
      out.writeln(
        'Warning: Builder(s) stuck in "New" on attempt > 1 with no Buildbucket build '
        '(likely orphaned by stale .ci.yaml): ${orphanedBuilders.join(', ')}',
      );
    }

    if (guard.suppressedJobs.isNotEmpty) {
      out.writeln('\nSuppressed Flakes (Neutral - non-blocking, do NOT rerun):');
      for (final PresubmitJobEntry job in guard.suppressedJobs) {
        out.writeln('  - ${job.name} [${job.stageName}]');
      }
    }

    if (guard.pendingJobs.isNotEmpty) {
      out.writeln('\nPending / In-Progress Jobs:');
      for (final PresubmitJobEntry job in guard.pendingJobs) {
        out.writeln('  - ${job.name} (${job.status}) [${job.stageName}]');
      }
    }

    if (guard.failedJobs.isNotEmpty) {
      out.writeln('\nFailed Jobs (rerunnable via flutter-dashboard):');
      for (final PresubmitJobEntry job in guard.failedJobs) {
        out.writeln('  - ${job.name} (${job.status}) [${job.stageName}]');
        final List<PresubmitJobAttempt>? attempts = jobAttempts[job.name];
        if (attempts != null) {
          for (final PresubmitJobAttempt attempt in attempts) {
            final PresubmitJobAttempt(
              :int attemptNumber,
              :String status,
              :String? buildId,
              :String? summary,
            ) = attempt;
            out.writeln(
              '      attempt #$attemptNumber: $status'
              '${buildId != null ? ' (build_id: $buildId)' : ''}',
            );
            if (summary != null && summary.trim().isNotEmpty) {
              out.writeln('      summary: ${summary.trim().split('\n').first}');
            }
          }
        }
      }
    }
  }
}

final class _RerunCommand extends Command<int> {
  _RerunCommand(this._runner) {
    argParser
      ..addOption(
        _optionPr,
        abbr: 'p',
        help: 'Pull request number on GitHub (required).',
        mandatory: true,
      )
      ..addFlag(
        _flagAllFailed,
        help: 'Retrigger all failed presubmit jobs on flutter-dashboard.',
        negatable: false,
      )
      ..addMultiOption(
        _optionBuilder,
        abbr: 'b',
        help: 'Specific failed builder name(s) to retrigger.',
      )
      ..addOption(
        _optionOwner,
        defaultsTo: DashboardConstants.defaultOwner,
        help: 'GitHub repository owner.',
      )
      ..addOption(
        _optionRepo,
        defaultsTo: DashboardConstants.defaultRepo,
        help: 'GitHub repository name.',
      )
      ..addOption(_optionIdToken, help: 'Explicit Firebase ID token for X-Flutter-IdToken.')
      ..addOption(
        _optionAccessToken,
        help: 'Google OAuth access token to exchange via Firebase signInWithIdp.',
      )
      ..addOption(_optionAccount, help: 'Google @google.com account email for gcloud token lookup.')
      ..addOption(
        _optionCredentialsFile,
        help: 'Override path to cached flutter-dashboard credentials file.',
      )
      ..addFlag(
        _flagDryRun,
        help: 'Validate preconditions and print targets without calling Cocoon rerun endpoints.',
        negatable: false,
      )
      ..addFlag(
        _flagSkipCiYamlCheck,
        help: 'Bypass ci.yaml validation and builder-removal safety checks (not recommended).',
        negatable: false,
      )
      ..addOption(_optionDashboardUrl, defaultsTo: DashboardConstants.dashboardBaseUrl, hide: true)
      ..addFlag(_flagJson, help: 'Emit structured JSON output.', negatable: false);
  }

  final DashboardCliRunner _runner;

  @override
  String get name => 'rerun';

  @override
  String get description =>
      'Retrigger failed flutter-dashboard presubmit jobs after verifying .ci.yaml safety.';

  @override
  Future<int> run() async {
    final ArgResults args = argResults!;
    final int prNumber = _parseRequiredPrNumber(args.option(_optionPr), usageException);
    final bool allFailed = args.flag(_flagAllFailed);
    final List<String> builders = args.multiOption(_optionBuilder);
    if (allFailed == builders.isNotEmpty) {
      usageException('Specify either --all-failed or one or more --builder <job_name> options.');
    }

    final String owner = args.option(_optionOwner)!;
    final String repo = args.option(_optionRepo)!;
    final String dashboardBaseUrl = args.option(_optionDashboardUrl)!;
    final bool dryRun = args.flag(_flagDryRun);
    final bool skipCiYamlCheck = args.flag(_flagSkipCiYamlCheck);
    final bool jsonOutput = args.flag(_flagJson);

    final CocoonClient client = _runner._createCocoonClient(dashboardBaseUrl);
    final PullRequestMetadata prMetadata = await client.fetchPullRequestMetadata(
      owner: owner,
      prNumber: prNumber,
      repo: repo,
    );
    final PullRequestMetadata(:String headSha, :String baseRef, :String state) = prMetadata;
    if (state.toLowerCase() != 'open') {
      throw DashboardException(
        'PR #$prNumber is not open (state: $state). Refusing to retrigger presubmit jobs.',
      );
    }

    final String dashboardUrl = DashboardConstants.presubmitDashboardUrl(repo: repo, sha: headSha);

    if (!skipCiYamlCheck) {
      final CiYamlSafetyReport safety = await client.verifyCiYamlSafety(
        baseRef: baseRef,
        headSha: headSha,
        owner: owner,
        repo: repo,
      );
      if (!safety.isSafe) {
        if (jsonOutput) {
          _runner._outSink.writeln(
            jsonEncode(<String, Object?>{
              'status': 'unsafe_ci_yaml',
              'pr': prNumber,
              'sha': headSha,
              'dashboard_url': dashboardUrl,
              'ci_yaml_safety': safety.toJson(),
            }),
          );
        } else {
          _runner._errSink
            ..writeln('Refusing to rerun PR #$prNumber ($headSha):')
            ..writeln(safety.failureReason);
        }
        return ExitCodes.staleCiYaml;
      }
    }

    final PresubmitGuardReport guard = await client.getPresubmitGuard(repo: repo, sha: headSha);
    final List<String> targetBuilders = _validateRerunTargets(
      allFailed: allFailed,
      guard: guard,
      requestedBuilders: builders,
    );

    if (targetBuilders.isEmpty) {
      if (jsonOutput) {
        _runner._outSink.writeln(
          jsonEncode(<String, Object?>{
            'status': 'nothing_to_rerun',
            'pr': prNumber,
            'sha': headSha,
            'dashboard_url': dashboardUrl,
            'suppressed_jobs': <String>[
              for (final PresubmitJobEntry job in guard.suppressedJobs) job.name,
            ],
          }),
        );
      } else {
        _runner._outSink.writeln(
          'No failed presubmit jobs to rerun on PR #$prNumber ($headSha).'
          '${guard.suppressedJobs.isNotEmpty ? ' (${guard.suppressedJobs.length} Neutral suppressed flake(s) ignored.)' : ''}',
        );
      }
      return ExitCodes.success;
    }

    if (dryRun) {
      if (jsonOutput) {
        _runner._outSink.writeln(
          jsonEncode(<String, Object?>{
            'status': 'dry_run',
            'mode': allFailed ? 'all_failed' : 'single_builder',
            'pr': prNumber,
            'sha': headSha,
            'builders': targetBuilders,
            'dashboard_url': dashboardUrl,
          }),
        );
      } else {
        _runner._outSink
          ..writeln('[DRY RUN] Pre-flight checks passed for PR #$prNumber ($headSha).')
          ..writeln('Would retrigger: ${targetBuilders.join(', ')}')
          ..writeln('Dashboard URL: $dashboardUrl');
      }
      return ExitCodes.success;
    }

    final DashboardAuthProvider authProvider = _runner._createAuthProvider(
      _nonEmptyOption(args.option(_optionCredentialsFile)),
    );
    final String? explicitIdToken = _nonEmptyOption(args.option(_optionIdToken));
    final String? explicitAccessToken = _nonEmptyOption(args.option(_optionAccessToken));
    final String? accountEmail = _nonEmptyOption(args.option(_optionAccount));

    final String idToken;
    try {
      idToken = await authProvider.resolveIdToken(
        accountEmail: accountEmail,
        explicitAccessToken: explicitAccessToken,
        explicitIdToken: explicitIdToken,
      );
    } on DashboardAuthException catch (authError) {
      return _handleUnauthenticatedFallback(
        checkRunId: guard.checkRunId,
        dashboardUrl: dashboardUrl,
        jsonOutput: jsonOutput,
        owner: owner,
        prNumber: prNumber,
        reason: authError.message,
        repo: repo,
        sha: headSha,
        targetBuilders: targetBuilders,
      );
    }

    if (allFailed) {
      final int? failureExitCode = await _executeRerunRequest(
        authProvider: authProvider,
        checkRunId: guard.checkRunId,
        dashboardUrl: dashboardUrl,
        endpointLabel: DashboardConstants.rerunAllFailedJobsPath,
        explicitIdToken: explicitIdToken,
        initialToken: idToken,
        jsonOutput: jsonOutput,
        owner: owner,
        prNumber: prNumber,
        repo: repo,
        send: (String token) => client.sendRerunAllFailedJobs(
          idToken: token,
          owner: owner,
          prNumber: prNumber,
          repo: repo,
        ),
        sha: headSha,
        targetBuilders: targetBuilders,
      );
      if (failureExitCode != null) {
        return failureExitCode;
      }
    } else {
      for (final builder in targetBuilders) {
        final int? failureExitCode = await _executeRerunRequest(
          authProvider: authProvider,
          checkRunId: guard.checkRunId,
          dashboardUrl: dashboardUrl,
          endpointLabel: '${DashboardConstants.rerunFailedJobPath} ("$builder")',
          explicitIdToken: explicitIdToken,
          initialToken: idToken,
          jsonOutput: jsonOutput,
          owner: owner,
          prNumber: prNumber,
          repo: repo,
          send: (String token) => client.sendRerunFailedJob(
            builder: builder,
            idToken: token,
            owner: owner,
            prNumber: prNumber,
            repo: repo,
          ),
          sha: headSha,
          targetBuilders: targetBuilders,
        );
        if (failureExitCode != null) {
          return failureExitCode;
        }
      }
    }

    if (jsonOutput) {
      _runner._outSink.writeln(
        jsonEncode(<String, Object?>{
          'status': 'retriggered',
          'pr': prNumber,
          'sha': headSha,
          'retriggered_builders': targetBuilders,
          'dashboard_url': dashboardUrl,
        }),
      );
    } else {
      _runner._outSink
        ..writeln(
          'Retriggered ${targetBuilders.length} failed job(s) on PR #$prNumber ($headSha): '
          '${targetBuilders.join(', ')}',
        )
        ..writeln('Track progress on flutter-dashboard: $dashboardUrl');
    }
    return ExitCodes.success;
  }

  Future<int?> _executeRerunRequest({
    required DashboardAuthProvider authProvider,
    required int? checkRunId,
    required String dashboardUrl,
    required String endpointLabel,
    required String? explicitIdToken,
    required String initialToken,
    required bool jsonOutput,
    required String owner,
    required int prNumber,
    required String repo,
    required Future<http.Response> Function(String token) send,
    required String sha,
    required List<String> targetBuilders,
  }) async {
    http.Response response = await send(initialToken);
    if ((response.statusCode == 401 || response.statusCode == 403) &&
        explicitIdToken == null &&
        authProvider.readStoredCredentials() != null) {
      try {
        final String refreshedToken = await authProvider.resolveIdToken(
          allowGcloudExchange: false,
          forceRefresh: true,
        );
        response = await send(refreshedToken);
      } on DashboardAuthException {
        // Keep original 401/403 response for fallback reporting below.
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      return _handleUnauthenticatedFallback(
        checkRunId: checkRunId,
        dashboardUrl: dashboardUrl,
        jsonOutput: jsonOutput,
        owner: owner,
        prNumber: prNumber,
        reason:
            'Cocoon rejected X-Flutter-IdToken on $endpointLabel '
            '(HTTP ${response.statusCode}): ${response.body.trim()}',
        repo: repo,
        sha: sha,
        targetBuilders: targetBuilders,
      );
    }
    if (response.statusCode != 200) {
      throw DashboardException(
        'POST $endpointLabel failed (HTTP ${response.statusCode}): ${response.body.trim()}',
      );
    }
    return null;
  }

  List<String> _validateRerunTargets({
    required bool allFailed,
    required PresubmitGuardReport guard,
    required List<String> requestedBuilders,
  }) {
    if (allFailed) {
      return <String>[for (final PresubmitJobEntry job in guard.failedJobs) job.name];
    }

    final validated = <String>[];
    for (final rawBuilder in requestedBuilders) {
      final String builder = rawBuilder.trim();
      if (builder.isEmpty) {
        continue;
      }
      final PresubmitJobEntry? entry = guard.findJob(builder);
      if (entry == null) {
        final String availableFailed = guard.failedJobs.isEmpty
            ? 'none'
            : guard.failedJobs.map((PresubmitJobEntry j) => j.name).join(', ');
        throw DashboardException(
          'Builder "$builder" was not found on this commit. '
          'Failed builders on this commit: $availableFailed.',
        );
      }
      switch (entry.disposition) {
        case .failed:
          if (!validated.contains(builder)) {
            validated.add(builder);
          }
        case .suppressedFlake:
          throw DashboardException(
            'Builder "$builder" has status "${entry.status}" (suppressed flake on '
            'flutter-dashboard). It does not block Dashboard Checks and should not be rerun.',
          );
        case .succeeded:
          throw DashboardException(
            'Builder "$builder" already succeeded (${entry.status}) and does not need a rerun.',
          );
        case .pending:
          throw DashboardException(
            'Builder "$builder" is already pending/running (${entry.status}).',
          );
      }
    }
    return validated;
  }

  int _handleUnauthenticatedFallback({
    required int? checkRunId,
    required String dashboardUrl,
    required bool jsonOutput,
    required String owner,
    required int prNumber,
    required String reason,
    required String repo,
    required String sha,
    required List<String> targetBuilders,
  }) {
    final String? gitHubChecksUrl = checkRunId != null
        ? 'https://github.com/$owner/$repo/pull/$prNumber/checks?check_run_id=$checkRunId'
        : null;
    if (jsonOutput) {
      _runner._outSink.writeln(
        jsonEncode(<String, Object?>{
          'status': 'auth_required',
          'reason': reason,
          'pr': prNumber,
          'sha': sha,
          'failed_builders': targetBuilders,
          'dashboard_url': dashboardUrl,
          if (gitHubChecksUrl != null) 'github_checks_url': gitHubChecksUrl,
        }),
      );
      return ExitCodes.authRequired;
    }

    final checkRunLine = gitHubChecksUrl != null
        ? '\n  - Or click "Re-run failed tests" on GitHub Checks: $gitHubChecksUrl'
        : '';
    _runner._errSink.writeln(
      '''
Authentication required to call Cocoon rerun API directly: $reason

Failed job(s) needing retrigger on PR #$prNumber:
  ${targetBuilders.join(', ')}

To retrigger in your browser (never use raw Buildbucket Retry Build links):
  - Open flutter-dashboard: $dashboardUrl$checkRunLine

To enable headless CLI reruns:
  - @google.com accounts: run `gcloud auth login`, then `dart .agents/skills/shepherd-prs/scripts/dashboard_presubmit.dart login`
  - GitHub OAuth flutter-dashboard sessions: pass `--id-token <jwt>` (`FLUTTER_DASHBOARD_ID_TOKEN`) or cache via `login --refresh-token <token>`''',
    );
    return ExitCodes.authRequired;
  }
}

final class _LoginCommand extends Command<int> {
  _LoginCommand(this._runner) {
    argParser
      ..addOption(
        _optionAccount,
        help: 'Google @google.com account email in `gcloud auth list` to exchange.',
      )
      ..addOption(
        _optionAccessToken,
        help: 'Explicit Google OAuth access token (defaults to `gcloud auth print-access-token`).',
      )
      ..addOption(
        _optionRefreshToken,
        help: 'Firebase refresh token from a Google or GitHub flutter-dashboard session.',
      )
      ..addOption(
        _optionCredentialsFile,
        help: 'Override path to cached flutter-dashboard credentials file.',
      )
      ..addFlag(
        _flagCheck,
        help: 'Verify whether valid or refreshable credentials are already available.',
        negatable: false,
      )
      ..addFlag(
        _flagLogout,
        help: 'Remove cached flutter-dashboard credentials from disk.',
        negatable: false,
      )
      ..addFlag(_flagJson, help: 'Emit structured JSON output.', negatable: false);
  }

  final DashboardCliRunner _runner;

  @override
  String get name => 'login';

  @override
  String get description =>
      'Bootstrap and cache flutter-dashboard Firebase credentials (0600) from Google or Firebase auth.';

  @override
  Future<int> run() async {
    final ArgResults args = argResults!;
    final bool checkOnly = args.flag(_flagCheck);
    final bool logout = args.flag(_flagLogout);
    final bool jsonOutput = args.flag(_flagJson);

    if (checkOnly && logout) {
      usageException('Cannot combine --check and --logout.');
    }

    final DashboardAuthProvider authProvider = _runner._createAuthProvider(
      _nonEmptyOption(args.option(_optionCredentialsFile)),
    );
    final String credentialsPath = authProvider.resolveCredentialsPath();

    if (logout) {
      final bool removed = authProvider.deleteStoredCredentials();
      if (jsonOutput) {
        _runner._outSink.writeln(
          jsonEncode(<String, Object?>{
            'status': 'logged_out',
            'removed': removed,
            'credentials_file': credentialsPath,
          }),
        );
      } else {
        _runner._outSink.writeln(
          removed
              ? 'Removed cached flutter-dashboard credentials at $credentialsPath.'
              : 'No cached flutter-dashboard credentials found at $credentialsPath.',
        );
      }
      return ExitCodes.success;
    }

    if (checkOnly) {
      await authProvider.resolveIdToken(
        accountEmail: _nonEmptyOption(args.option(_optionAccount)),
        explicitAccessToken: _nonEmptyOption(args.option(_optionAccessToken)),
      );
      final StoredDashboardCredentials? stored = authProvider.readStoredCredentials();
      if (jsonOutput) {
        _runner._outSink.writeln(
          jsonEncode(<String, Object?>{
            'status': 'authenticated',
            'credentials_file': credentialsPath,
            if (stored?.email != null) 'email': stored!.email,
          }),
        );
      } else {
        _runner._outSink.writeln(
          'Authenticated for flutter-dashboard'
          '${stored?.email != null ? ' as ${stored!.email}' : ''} '
          '(credentials: $credentialsPath).',
        );
      }
      return ExitCodes.success;
    }

    final StoredDashboardCredentials credentials = await authProvider.login(
      accountEmail: _nonEmptyOption(args.option(_optionAccount)),
      explicitAccessToken: _nonEmptyOption(args.option(_optionAccessToken)),
      explicitRefreshToken: _nonEmptyOption(args.option(_optionRefreshToken)),
    );
    if (jsonOutput) {
      _runner._outSink.writeln(
        jsonEncode(<String, Object?>{
          'status': 'authenticated',
          'credentials_file': credentialsPath,
          if (credentials.email != null) 'email': credentials.email,
        }),
      );
    } else {
      _runner._outSink.writeln(
        'Saved flutter-dashboard credentials (0600) to $credentialsPath'
        '${credentials.email != null ? ' for ${credentials.email}' : ''}.',
      );
    }
    return ExitCodes.success;
  }
}

int? _parseOptionalPrNumber(String? raw, Never Function(String) onUsageError) {
  final String? trimmed = _nonEmptyOption(raw);
  if (trimmed == null) {
    return null;
  }
  final String digits = trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
  final int? parsed = int.tryParse(digits);
  if (parsed == null || parsed <= 0) {
    onUsageError('Invalid --pr value "$raw": expected a positive pull request number.');
  }
  return parsed;
}

int _parseRequiredPrNumber(String? raw, Never Function(String) onUsageError) {
  final int? parsed = _parseOptionalPrNumber(raw, onUsageError);
  if (parsed == null) {
    onUsageError('Missing required --pr <number>.');
  }
  return parsed;
}

String? _nonEmptyOption(String? value) {
  if (value == null) {
    return null;
  }
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
