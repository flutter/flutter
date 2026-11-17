// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Process exit codes returned by `dashboard_presubmit.dart`.
abstract final class ExitCodes {
  static const int success = 0;
  static const int error = 1;
  static const int staleCiYaml = 2;
  static const int authRequired = 3;
}

/// Shared constants for `flutter-dashboard` (`flutter/cocoon`), Firebase Auth,
/// and GitHub API calls.
abstract final class DashboardConstants {
  static const String defaultOwner = 'flutter';
  static const String defaultRepo = 'flutter';
  static const String defaultBaseRef = 'master';

  static const String dashboardBaseUrl = 'https://flutter-dashboard.appspot.com';
  static const String presubmitGuardPath = '/api/public/get-presubmit-guard';
  static const String presubmitJobPath = '/api/public/get-presubmit-job';
  static const String rerunFailedJobPath = '/api/rerun-failed-job';
  static const String rerunAllFailedJobsPath = '/api/rerun-all-failed-jobs';

  static const String idTokenHeader = 'X-Flutter-IdToken';
  static const String idTokenEnvVar = 'FLUTTER_DASHBOARD_ID_TOKEN';
  static const String accessTokenEnvVar = 'FLUTTER_DASHBOARD_ACCESS_TOKEN';
  static const String refreshTokenEnvVar = 'FLUTTER_DASHBOARD_REFRESH_TOKEN';
  static const String firebaseApiKeyEnvVar = 'FLUTTER_DASHBOARD_FIREBASE_API_KEY';

  static const String firebaseProjectId = 'flutter-dashboard';
  static const String firebaseExpectedIssuer = 'https://securetoken.google.com/flutter-dashboard';
  static const String cocoonFirebaseOptionsUrl =
      'https://raw.githubusercontent.com/flutter/cocoon/main/dashboard/lib/firebase_options.dart';

  static String firebaseSignInWithIdpUrl(String apiKey) =>
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp'
      '?key=${Uri.encodeQueryComponent(apiKey)}';

  static String firebaseSecureTokenUrl(String apiKey) =>
      'https://securetoken.googleapis.com/v1/token?key=${Uri.encodeQueryComponent(apiKey)}';

  static const String googleProviderId = 'google.com';
  static const String googleEmailSuffix = '@google.com';
  static const String serviceAccountEmailSuffix = '.gserviceaccount.com';
  static const String configDirName = 'flutter_dashboard';
  static const String credentialsFileName = 'credentials.json';

  static const String ciYamlCheckName = 'ci.yaml validation';
  static const String rootCiYamlPath = '.ci.yaml';
  static const String engineCiYamlPath = 'engine/src/flutter/.ci.yaml';
  static const ciYamlPaths = <String>[rootCiYamlPath, engineCiYamlPath];

  static String presubmitDashboardUrl({required String repo, required String sha}) =>
      '$dashboardBaseUrl/#/presubmit?repo=${Uri.encodeQueryComponent(repo)}'
      '&sha=${Uri.encodeQueryComponent(sha)}';
}

/// Classification of a Cocoon presubmit job status (`TaskStatus` in `flutter/cocoon`).
enum JobDisposition {
  succeeded,
  suppressedFlake,
  pending,
  failed;

  static JobDisposition fromStatus(String rawStatus) {
    final String normalized = rawStatus.trim();
    return switch (normalized) {
      'Succeeded' || 'Skipped' => .succeeded,
      'Neutral' => .suppressedFlake,
      'New' || 'In Progress' || 'Queued' || 'Pending' || 'Waiting For Backfill' => .pending,
      'Failed' || 'Infra Failure' || 'Cancelled' || 'Timed Out' || 'Action Required' => .failed,
      _ => throw DashboardException('Unrecognized Cocoon job status: "$rawStatus".'),
    };
  }
}

/// Exception thrown when an API or CLI precondition fails.
@immutable
class DashboardException implements Exception {
  const DashboardException(this.message, {this.exitCode = ExitCodes.error});

  final String message;
  final int exitCode;

  @override
  String toString() => message;
}

/// Exception thrown when Firebase authentication is missing or rejected.
@immutable
class DashboardAuthException extends DashboardException {
  const DashboardAuthException(super.message) : super(exitCode: ExitCodes.authRequired);
}

/// Minimal host environment abstraction for cross-platform path and permission
/// handling in production and hermetic unit tests.
@immutable
class HostEnvironment {
  const HostEnvironment({required this.environment, required this.isWindows});

  final Map<String, String> environment;
  final bool isWindows;
}

/// Pull request metadata retrieved from GitHub.
@immutable
class PullRequestMetadata {
  const PullRequestMetadata({
    required this.baseRef,
    required this.headSha,
    required this.number,
    required this.state,
    required this.title,
  });

  factory PullRequestMetadata.fromGitHubApiJson(Map<String, Object?> json) {
    final int? number = readJsonInt(json['number']);
    final String? state = readJsonString(json['state']);
    final String? title = readJsonString(json['title']);
    final String? headSha = switch (json['head']) {
      {'sha': final String sha} when sha.isNotEmpty => sha,
      _ => readJsonString(json['headRefOid']),
    };
    final String baseRef = switch (json['base']) {
      {'ref': final String ref} when ref.isNotEmpty => ref,
      _ => readJsonString(json['baseRefName']) ?? DashboardConstants.defaultBaseRef,
    };
    if (number == null || headSha == null || headSha.isEmpty) {
      throw const DashboardException('Invalid pull request metadata returned from GitHub.');
    }
    return PullRequestMetadata(
      baseRef: baseRef,
      headSha: headSha,
      number: number,
      state: state ?? 'UNKNOWN',
      title: title ?? '',
    );
  }

  final String baseRef;
  final String headSha;
  final int number;
  final String state;
  final String title;

  Map<String, Object?> toJson() => <String, Object?>{
    'number': number,
    'title': title,
    'state': state,
    'head_sha': headSha,
    'base_ref': baseRef,
  };
}

/// Single job entry inside a Cocoon presubmit stage.
@immutable
class PresubmitJobEntry {
  const PresubmitJobEntry({
    required this.disposition,
    required this.name,
    required this.stageName,
    required this.status,
  });

  final JobDisposition disposition;
  final String name;
  final String stageName;
  final String status;

  Map<String, Object?> toJson() => <String, Object?>{
    'stage': stageName,
    'name': name,
    'status': status,
    'disposition': disposition.name,
  };
}

/// Stage grouping from `/api/public/get-presubmit-guard`.
@immutable
class PresubmitStage {
  const PresubmitStage({required this.jobs, required this.name, this.createdAt});

  final int? createdAt;
  final List<PresubmitJobEntry> jobs;
  final String name;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    if (createdAt != null) 'created_at': createdAt,
    'jobs': <String, String>{for (final PresubmitJobEntry job in jobs) job.name: job.status},
  };
}

/// Parsed response from `/api/public/get-presubmit-guard`.
@immutable
class PresubmitGuardReport {
  const PresubmitGuardReport({
    required this.failedJobs,
    required this.guardStatus,
    required this.pendingJobs,
    required this.stages,
    required this.succeededJobs,
    required this.suppressedJobs,
    this.author,
    this.checkRunId,
    this.prNumber,
  });

  factory PresubmitGuardReport.fromJson(Map<String, Object?> json) {
    final String guardStatus = readJsonString(json['guard_status']) ?? 'Unknown';
    final int? prNumber = readJsonInt(json['pr_num']);
    final int? checkRunId = readJsonInt(json['check_run_id']);
    final String? author = readJsonString(json['author']);

    final stages = <PresubmitStage>[];
    final failedJobs = <PresubmitJobEntry>[];
    final suppressedJobs = <PresubmitJobEntry>[];
    final pendingJobs = <PresubmitJobEntry>[];
    final succeededJobs = <PresubmitJobEntry>[];

    final Object? rawStages = json['stages'];
    if (rawStages is List<Object?>) {
      for (final Object? rawStage in rawStages) {
        if (rawStage is! Map<Object?, Object?>) {
          continue;
        }
        final Map<String, Object?> stageMap = _toStringKeyMap(rawStage);
        final String stageName = readJsonString(stageMap['name']) ?? 'default';
        final int? createdAt = readJsonInt(stageMap['created_at']);
        final stageJobs = <PresubmitJobEntry>[];
        final Object? rawJobs = stageMap['jobs'];
        if (rawJobs is Map<Object?, Object?>) {
          for (final MapEntry(:Object? key, :Object? value) in rawJobs.entries) {
            if (key is! String || value is! String) {
              continue;
            }
            final entry = PresubmitJobEntry(
              disposition: JobDisposition.fromStatus(value),
              name: key,
              stageName: stageName,
              status: value,
            );
            stageJobs.add(entry);
            switch (entry.disposition) {
              case .failed:
                failedJobs.add(entry);
              case .suppressedFlake:
                suppressedJobs.add(entry);
              case .pending:
                pendingJobs.add(entry);
              case .succeeded:
                succeededJobs.add(entry);
            }
          }
        }
        stages.add(
          PresubmitStage(
            createdAt: createdAt,
            jobs: List<PresubmitJobEntry>.unmodifiable(stageJobs),
            name: stageName,
          ),
        );
      }
    }

    return PresubmitGuardReport(
      author: author,
      checkRunId: checkRunId,
      failedJobs: List<PresubmitJobEntry>.unmodifiable(failedJobs),
      guardStatus: guardStatus,
      pendingJobs: List<PresubmitJobEntry>.unmodifiable(pendingJobs),
      prNumber: prNumber,
      stages: List<PresubmitStage>.unmodifiable(stages),
      succeededJobs: List<PresubmitJobEntry>.unmodifiable(succeededJobs),
      suppressedJobs: List<PresubmitJobEntry>.unmodifiable(suppressedJobs),
    );
  }

  final String? author;
  final int? checkRunId;
  final List<PresubmitJobEntry> failedJobs;
  final String guardStatus;
  final List<PresubmitJobEntry> pendingJobs;
  final int? prNumber;
  final List<PresubmitStage> stages;
  final List<PresubmitJobEntry> succeededJobs;
  final List<PresubmitJobEntry> suppressedJobs;

  PresubmitJobEntry? findJob(String jobName) {
    for (final PresubmitStage stage in stages) {
      for (final PresubmitJobEntry job in stage.jobs) {
        if (job.name == jobName) {
          return job;
        }
      }
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    if (prNumber != null) 'pr_num': prNumber,
    if (checkRunId != null) 'check_run_id': checkRunId,
    if (author != null) 'author': author,
    'guard_status': guardStatus,
    'failed_jobs': <Map<String, Object?>>[
      for (final PresubmitJobEntry job in failedJobs) job.toJson(),
    ],
    'suppressed_jobs': <Map<String, Object?>>[
      for (final PresubmitJobEntry job in suppressedJobs) job.toJson(),
    ],
    'pending_jobs': <Map<String, Object?>>[
      for (final PresubmitJobEntry job in pendingJobs) job.toJson(),
    ],
    'succeeded_count': succeededJobs.length,
    'stages': <Map<String, Object?>>[for (final PresubmitStage stage in stages) stage.toJson()],
  };
}

/// Single attempt entry returned by `/api/public/get-presubmit-job`.
@immutable
class PresubmitJobAttempt {
  const PresubmitJobAttempt({
    required this.attemptNumber,
    required this.jobName,
    required this.status,
    this.buildId,
    this.buildNumber,
    this.creationTime,
    this.endTime,
    this.startTime,
    this.summary,
  });

  factory PresubmitJobAttempt.fromJson(Map<String, Object?> json) {
    final Object? rawBuildId = json['build_id'];
    final String? buildId = switch (rawBuildId) {
      final String id when id.isNotEmpty => id,
      final int id => '$id',
      _ => null,
    };
    return PresubmitJobAttempt(
      attemptNumber: readJsonInt(json['attempt_number']) ?? 1,
      buildId: buildId,
      buildNumber: readJsonInt(json['build_number']),
      creationTime: readJsonInt(json['creation_time']),
      endTime: readJsonInt(json['end_time']),
      jobName: readJsonString(json['job_name']) ?? '',
      startTime: readJsonInt(json['start_time']),
      status: readJsonString(json['status']) ?? 'Unknown',
      summary: readJsonString(json['summary']),
    );
  }

  final int attemptNumber;
  final String? buildId;
  final int? buildNumber;
  final int? creationTime;
  final int? endTime;
  final String jobName;
  final int? startTime;
  final String status;
  final String? summary;

  Map<String, Object?> toJson() => <String, Object?>{
    'attempt_number': attemptNumber,
    'job_name': jobName,
    'status': status,
    if (buildId != null) 'build_id': buildId,
    if (buildNumber != null) 'build_number': buildNumber,
    if (creationTime != null) 'creation_time': creationTime,
    if (startTime != null) 'start_time': startTime,
    if (endTime != null) 'end_time': endTime,
    if (summary != null) 'summary': summary,
  };
}

/// Result of verifying `ci.yaml validation` and target-branch `.ci.yaml`
/// builder-removal safety before calling Cocoon's rerun endpoints.
@immutable
class CiYamlSafetyReport {
  const CiYamlSafetyReport({
    required this.isSafe,
    required this.removedBuilders,
    required this.warnings,
    this.checkRunConclusion,
    this.checkRunStatus,
    this.failureReason,
  });

  final String? checkRunConclusion;
  final String? checkRunStatus;
  final String? failureReason;
  final bool isSafe;
  final List<String> removedBuilders;
  final List<String> warnings;

  Map<String, Object?> toJson() => <String, Object?>{
    'is_safe': isSafe,
    if (checkRunStatus != null) 'check_run_status': checkRunStatus,
    if (checkRunConclusion != null) 'check_run_conclusion': checkRunConclusion,
    'removed_builders': removedBuilders,
    if (warnings.isNotEmpty) 'warnings': warnings,
    if (failureReason != null) 'failure_reason': failureReason,
  };
}

/// Cached Firebase refresh and ID token credentials stored on disk (`0600`).
@immutable
class StoredDashboardCredentials {
  const StoredDashboardCredentials({
    required this.refreshToken,
    this.email,
    this.expiresAtEpochMs,
    this.firebaseApiKey,
    this.idToken,
  });

  factory StoredDashboardCredentials.fromJson(Map<String, Object?> json) {
    final String? refreshToken = readJsonString(json['refresh_token']);
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const DashboardAuthException('Stored credentials file is missing refresh_token.');
    }
    return StoredDashboardCredentials(
      email: readJsonString(json['email']),
      expiresAtEpochMs: readJsonInt(json['expires_at_epoch_ms']),
      firebaseApiKey: readJsonString(json['firebase_api_key']),
      idToken: readJsonString(json['id_token']),
      refreshToken: refreshToken,
    );
  }

  final String? email;
  final int? expiresAtEpochMs;
  final String? firebaseApiKey;
  final String? idToken;
  final String refreshToken;

  Map<String, Object?> toJson() => <String, Object?>{
    'refresh_token': refreshToken,
    if (firebaseApiKey != null) 'firebase_api_key': firebaseApiKey,
    if (idToken != null) 'id_token': idToken,
    if (expiresAtEpochMs != null) 'expires_at_epoch_ms': expiresAtEpochMs,
    if (email != null) 'email': email,
  };
}

Map<String, Object?> decodeJsonObject(Object? decoded, {required String context}) {
  if (decoded is Map<Object?, Object?>) {
    return _toStringKeyMap(decoded);
  }
  throw DashboardException('Expected JSON object for $context, got ${decoded.runtimeType}.');
}

List<Map<String, Object?>> decodeJsonObjectList(Object? decoded, {required String context}) {
  if (decoded is List<Object?>) {
    return <Map<String, Object?>>[
      for (final Object? element in decoded)
        if (element is Map<Object?, Object?>) _toStringKeyMap(element),
    ];
  }
  throw DashboardException('Expected JSON list for $context, got ${decoded.runtimeType}.');
}

String? readJsonString(Object? value) => value is String ? value : null;

int? readJsonInt(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  final String text => int.tryParse(text),
  _ => null,
};

Map<String, Object?> _toStringKeyMap(Map<Object?, Object?> raw) => <String, Object?>{
  for (final MapEntry(:Object? key, :Object? value) in raw.entries)
    if (key is String) key: value,
};
