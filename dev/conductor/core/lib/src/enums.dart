// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The current phase of the release process.
enum ReleasePhase {
  // Verify engine CI is green before opening framework PR.
  VERIFY_ENGINE_CI,

  PUBLISH_VERSION,

  // Package artifacts verified to exist on cloud storage.
  VERIFY_RELEASE,

  // No further work to be done.
  RELEASE_COMPLETED,
}

/// Defines the next phase based on the current phase.
ReleasePhase nextPhase(ReleasePhase currentPhase) {
  return switch (currentPhase) {
    ReleasePhase.VERIFY_ENGINE_CI => ReleasePhase.PUBLISH_VERSION,
    ReleasePhase.PUBLISH_VERSION => ReleasePhase.VERIFY_RELEASE,
    ReleasePhase.VERIFY_RELEASE => ReleasePhase.RELEASE_COMPLETED,
    ReleasePhase.RELEASE_COMPLETED => ReleasePhase.RELEASE_COMPLETED,
  };
}

/// The type of release being created.
///
/// This determines how the version will be calculated.
enum ReleaseType {
  // All pre-release metadata from previous beta releases will be discarded. The
  // z must be 0.
  STABLE_INITIAL,

  // Increment z.
  STABLE_HOTFIX,

  // Compute x, y, and m from the candidate branch name. z and n should be 0.
  BETA_INITIAL,

  // Increment n.
  BETA_HOTFIX,
}

/// Simple state class for serializing repository state, distinct from the full Repository implementation
class RepositoryState {
  RepositoryState({
    required this.candidateBranch,
    required this.startingGitHead,
    required this.currentGitHead,
    required this.checkoutPath,
    required this.upstream,
    required this.mirror,
    this.dartRevision,
    required this.workingBranch,
  });

  final String candidateBranch;
  final String startingGitHead;
  final String currentGitHead;
  final String checkoutPath;
  final RemoteState upstream;
  final RemoteState mirror;
  final String? dartRevision;
  final String workingBranch;

  Map<String, dynamic> toJson() => {
    'candidateBranch': candidateBranch,
    'startingGitHead': startingGitHead,
    'currentGitHead': currentGitHead,
    'checkoutPath': checkoutPath,
    'upstream': upstream.toJson(),
    'mirror': mirror.toJson(),
    if (dartRevision != null) 'dartRevision': dartRevision,
    'workingBranch': workingBranch,
  };

  static RepositoryState fromJson(Map<String, dynamic> json) => RepositoryState(
    candidateBranch: json['candidateBranch'] as String,
    startingGitHead: json['startingGitHead'] as String,
    currentGitHead: json['currentGitHead'] as String,
    checkoutPath: json['checkoutPath'] as String,
    upstream: RemoteState.fromJson(json['upstream'] as Map<String, dynamic>),
    mirror: RemoteState.fromJson(json['mirror'] as Map<String, dynamic>),
    dartRevision: json['dartRevision'] as String?,
    workingBranch: json['workingBranch'] as String,
  );
}

class RemoteState {
  const RemoteState({required this.name, required this.url});

  final String name;
  final String url;

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
  };

  static RemoteState fromJson(Map<String, dynamic> json) => RemoteState(
    name: json['name'] as String,
    url: json['url'] as String,
  );
}

/// State for the entire release process
class ConductorState {
  ConductorState({
    required this.releaseChannel,
    required this.releaseVersion,
    required this.engine,
    required this.framework,
    required this.createdDate,
    required this.lastUpdatedDate,
    required this.logs,
    required this.currentPhase,
    required this.conductorVersion,
    required this.releaseType,
  });

  final String releaseChannel;
  final String releaseVersion;
  final RepositoryState engine;
  final RepositoryState framework;
  final DateTime createdDate;
  final DateTime lastUpdatedDate;
  final List<String> logs;
  final String conductorVersion;
  final ReleaseType releaseType;
  ReleasePhase currentPhase;

  Map<String, dynamic> toJson() => {
    'releaseChannel': releaseChannel,
    'releaseVersion': releaseVersion,
    'engine': engine.toJson(),
    'framework': framework.toJson(),
    'createdDate': createdDate.toIso8601String(),
    'lastUpdatedDate': lastUpdatedDate.toIso8601String(),
    'logs': logs,
    'currentPhase': currentPhase.name,
    'conductorVersion': conductorVersion,
    'releaseType': releaseType.name,
  };

  static ConductorState fromJson(Map<String, dynamic> json) => ConductorState(
    releaseChannel: json['releaseChannel'] as String,
    releaseVersion: json['releaseVersion'] as String,
    engine: RepositoryState.fromJson(json['engine'] as Map<String, dynamic>),
    framework: RepositoryState.fromJson(json['framework'] as Map<String, dynamic>),
    createdDate: DateTime.parse(json['createdDate'] as String),
    lastUpdatedDate: DateTime.parse(json['lastUpdatedDate'] as String),
    logs: (json['logs'] as List<dynamic>).cast<String>(),
    currentPhase: ReleasePhase.values.byName(json['currentPhase'] as String),
    conductorVersion: json['conductorVersion'] as String,
    releaseType: ReleaseType.values.byName(json['releaseType'] as String),
  );
}
