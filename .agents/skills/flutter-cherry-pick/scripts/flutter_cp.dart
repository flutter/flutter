// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

/// A helper class to orchestrate the Flutter cherry-pick (CP) process.
class CherryPickHelper {
  /// Creates a new [CherryPickHelper] instance.
  CherryPickHelper({required this.pr, required this.channel, required this.repoPath});

  /// The original PR number on the master branch.
  final int pr;

  /// The target channel for the cherry-pick (either 'stable' or 'beta').
  final String channel;

  /// The path to the local Flutter repository.
  final String repoPath;

  /// Detailed data about the original PR, fetched from GitHub.
  Map<String, Object?>? originalPrData;

  /// Helper to execute shell commands in the Flutter repository directory.
  ///
  /// Throws an error and exits with code 1 if the command fails, unless
  /// [allowFailure] is set to true.
  Future<ProcessResult> runCmd(List<String> cmd, {bool allowFailure = false}) async {
    final ProcessResult result = await Process.run(
      cmd[0],
      cmd.sublist(1),
      workingDirectory: repoPath,
    );
    if (result.exitCode != 0 && !allowFailure) {
      _error('Command failed: ${cmd.join(' ')}');
      _error('Stdout: ${result.stdout}');
      _error('Stderr: ${result.stderr}');
      exit(1);
    }
    return result;
  }

  /// Fetches the details of the original PR from GitHub using `gh`.
  ///
  /// Verifies that the PR is in the `MERGED` state.
  Future<Map<String, Object?>> getOriginalPrDetails() async {
    _info('Fetching details for original PR #$pr...');
    final ProcessResult result = await runCmd([
      'gh',
      'pr',
      'view',
      pr.toString(),
      '--json',
      'title,body,mergeCommit,state,url',
    ]);

    final Object? decoded = jsonDecode(result.stdout as String);
    if (decoded case final Map<String, Object?> prMap) {
      originalPrData = prMap;
      if (prMap['state'] != 'MERGED') {
        _error('Error: PR #$pr is not merged (State: ${prMap['state']}).');
        exit(1);
      }
      return prMap;
    } else {
      _error('Error: Failed to parse PR details as a JSON map.');
      exit(1);
    }
  }

  /// Adds the cherry-pick label (`cp: stable` or `cp: beta`) to the original PR.
  Future<void> addLabel() async {
    final String label = switch (channel) {
      'stable' => 'cp: stable',
      'beta' => 'cp: beta',
      _ => throw ArgumentError('Invalid channel "$channel". Must be "stable" or "beta".'),
    };
    _info('Adding "$label" label to PR #$pr...');
    await runCmd([
      'gh',
      'api',
      '-X',
      'POST',
      'repos/flutter/flutter/issues/$pr/labels',
      '-F',
      'labels[]=$label',
    ]);
  }

  /// Dynamically retrieves the release candidate branch name for the target channel.
  ///
  /// Reads the version file `bin/internal/release-candidate-branch.version` from
  /// the remote branch (or falls back to local branch).
  /// Parses the owner from a GitHub git/https URL.
  String? parseOwner(String url) {
    final regExp = RegExp(r'(?:github\.com[:/])([^/]+)/');
    final Match? match = regExp.firstMatch(url);
    return match?.group(1);
  }

  /// Detects the upstream and fork remotes, and the fork owner.
  Future<Map<String, String>> detectRemotes() async {
    final ProcessResult result = await runCmd(['git', 'remote', '-v']);
    final output = result.stdout as String;

    String? upstream;
    String? fork;
    String? forkOwner;

    for (final String line in output.split('\n')) {
      if (line.trim().isEmpty) {
        continue;
      }
      final List<String> parts = line.split('\t');
      if (parts.length < 2) {
        continue;
      }
      final String name = parts[0];
      final String urlAndType = parts[1];
      final String url = urlAndType.split(' ')[0];

      if (url.contains('flutter/flutter')) {
        upstream = name;
      } else {
        fork = name;
        forkOwner = parseOwner(url);
      }
    }

    upstream ??= 'origin';
    fork ??= 'origin';

    return {'upstream': upstream, 'fork': fork, 'forkOwner': forkOwner ?? ''};
  }

  /// Dynamically retrieves the release candidate branch name for the target channel.
  ///
  /// Reads the version file `bin/internal/release-candidate-branch.version` from
  /// the remote branch (or falls back to local branch).
  Future<String> getCandidateBranch() async {
    final Map<String, String> remotes = await detectRemotes();
    final String upstream = remotes['upstream']!;
    _info('Locating candidate branch for $channel using remote $upstream...');
    ProcessResult result = await runCmd([
      'git',
      'show',
      '$upstream/$channel:bin/internal/release-candidate-branch.version',
    ], allowFailure: true);
    if (result.exitCode != 0) {
      _error(
        'Warning: Could not read candidate branch from $upstream/$channel. Trying to read locally...',
      );
      result = await runCmd([
        'git',
        'show',
        '$channel:bin/internal/release-candidate-branch.version',
      ], allowFailure: true);
      if (result.exitCode != 0) {
        _error('Error: Failed to locate candidate branch version file.');
        exit(1);
      }
    }
    final String branch = (result.stdout as String).trim();
    _info('Found candidate branch: $branch');
    return branch;
  }

  /// Polls GitHub for the automatically generated cherry-pick PR.
  ///
  /// Looks for an open PR targeting [candidateBranch] that references
  /// the original PR number or title in its title.
  Future<int?> pollForPr(String candidateBranch) async {
    _info('Polling for automated cherry-pick PR targeting $candidateBranch...');
    const attempts = 8;
    for (var i = 0; i < attempts; i++) {
      await Future<void>.delayed(const Duration(seconds: 15));
      _info('Polling attempt ${i + 1}/$attempts...');
      final ProcessResult result = await runCmd([
        'gh',
        'pr',
        'list',
        '--state',
        'open',
        '--base',
        candidateBranch,
        '--json',
        'number,title,headRefName,createdAt',
      ]);

      final Object? decoded = jsonDecode(result.stdout as String);
      if (decoded case final List<Object?> prs) {
        for (final prData in prs) {
          if (prData case {'number': final int number, 'title': final String title}) {
            final originalTitle = originalPrData?['title'] as String?;
            if (title.contains(pr.toString()) ||
                (originalTitle != null && title.contains(originalTitle))) {
              return number;
            }
          }
        }
      }
    }
    return null;
  }

  /// Initiates the manual cherry-pick fallback process.
  ///
  /// Checks out a new local branch from the target [candidateBranch] and
  /// attempts to cherry-pick the original merge commit. If conflicts occur,
  /// it prints the conflicted files and exits with code 2.
  Future<int> startManualCp(String candidateBranch) async {
    final Map<String, String> remotes = await detectRemotes();
    final String upstream = remotes['upstream']!;
    _info('Starting manual cherry-pick fallback...');
    await runCmd(['git', 'fetch', upstream, candidateBranch]);

    final branchName = 'cherry-pick-$pr-to-$channel';
    _info('Creating local branch $branchName from $upstream/$candidateBranch...');
    await runCmd(['git', 'checkout', '-B', branchName, '$upstream/$candidateBranch']);

    final String sha = switch (originalPrData) {
      {'mergeCommit': {'oid': final String oid}} => oid,
      _ => throw StateError('Could not find merge commit SHA in PR data'),
    };

    _info('Attempting to cherry-pick commit $sha...');
    final ProcessResult result = await runCmd(['git', 'cherry-pick', sha], allowFailure: true);

    if (result.exitCode == 0) {
      _info('Cherry-pick succeeded without conflicts.');
      return pushAndCreatePr(candidateBranch);
    } else {
      _error('Cherry-pick encountered conflicts!');
      _error(result.stderr);

      final ProcessResult statusResult = await runCmd(['git', 'status', '--porcelain']);
      final statusOutput = statusResult.stdout as String;
      final conflictedFiles = <String>[];

      for (final String line in statusOutput.split('\n')) {
        if (line.length > 3) {
          final String status = line.substring(0, 2);
          final bool isConflicted = status.contains('U') || status == 'AA' || status == 'DD';
          if (isConflicted) {
            conflictedFiles.add(line.substring(3).trim());
          }
        }
      }

      _info('\n=== CONFLICTED FILES ===');
      conflictedFiles.forEach(_info);
      _info('========================\n');
      _info('Please resolve these conflicts in your editor, then run the continue action.');
      exit(2);
    }
  }

  /// Continues the manual cherry-pick after conflicts have been resolved by the user.
  Future<int> continueManualCp(String candidateBranch) async {
    _info('Continuing manual cherry-pick...');
    final ProcessResult statusResult = await runCmd(['git', 'status', '--porcelain']);
    final statusOutput = statusResult.stdout as String;
    if (statusOutput.contains('UU') || statusOutput.startsWith('U')) {
      _error('Error: There are still unresolved conflicts.');
      exit(1);
    }

    try {
      final ProcessResult result = await Process.run(
        'git',
        ['cherry-pick', '--continue'],
        workingDirectory: repoPath,
        environment: <String, String>{'GIT_EDITOR': 'true'},
      );
      if (result.exitCode != 0) {
        _error('Failed to continue cherry-pick.');
        _error('Stdout: ${result.stdout}');
        _error('Stderr: ${result.stderr}');
        exit(1);
      }
    } catch (e) {
      _error('Failed to continue cherry-pick: $e');
      exit(1);
    }

    return pushAndCreatePr(candidateBranch);
  }

  /// Pushes the local cherry-pick branch and creates a pull request targeting [candidateBranch].
  Future<int> pushAndCreatePr(String candidateBranch) async {
    final Map<String, String> remotes = await detectRemotes();
    final String fork = remotes['fork']!;
    final String forkOwner = remotes['forkOwner']!;
    final String upstream = remotes['upstream']!;

    final branchName = 'cherry-pick-$pr-to-$channel';
    _info('Pushing branch $branchName to $fork...');
    await runCmd(['git', 'push', '-u', fork, 'HEAD', '--force']);

    final String originalTitle = originalPrData?['title'] as String? ?? '';
    final title = '[$channel] $originalTitle';
    final body = 'Cherry-pick of #$pr to $channel';
    _info('Creating pull request: $title...');

    final createCmd = <String>[
      'gh',
      'pr',
      'create',
      '--base',
      candidateBranch,
      '--title',
      title,
      '--body',
      body,
    ];

    if (forkOwner.isNotEmpty && fork != upstream) {
      createCmd.addAll(['--head', '$forkOwner:$branchName']);
    }

    final ProcessResult result = await runCmd(createCmd);

    final String prUrl = (result.stdout as String).trim();
    final String prNumberStr = prUrl.split('/').last;
    final int? prNumber = int.tryParse(prNumberStr);
    if (prNumber == null) {
      _error('Error: Could not parse PR number from URL: $prUrl');
      exit(1);
    }
    _info('Created PR #$prNumber: $prUrl');

    _info('Adding "cp: review" label to PR #$prNumber...');
    await runCmd([
      'gh',
      'api',
      '-X',
      'POST',
      'repos/flutter/flutter/issues/$prNumber/labels',
      '-F',
      'labels[]=cp: review',
    ]);

    return prNumber;
  }
}

void main(List<String> arguments) async {
  int? pr;
  String? channel;
  String? action;
  var repoPath = '.';

  for (var i = 0; i < arguments.length; i++) {
    final String arg = arguments[i];
    if (arg == '--pr' && i + 1 < arguments.length) {
      pr = int.tryParse(arguments[++i]);
    } else if (arg == '--channel' && i + 1 < arguments.length) {
      channel = arguments[++i];
    } else if (arg == '--action' && i + 1 < arguments.length) {
      action = arguments[++i];
    } else if (arg == '--repo-path' && i + 1 < arguments.length) {
      repoPath = arguments[++i];
    }
  }

  if (pr == null ||
      channel == null ||
      action == null ||
      (channel != 'stable' && channel != 'beta')) {
    _error(
      'Usage: dart flutter_cp.dart --pr <pr> --channel <stable|beta> --action <start|continue> [--repo-path <path>]',
    );
    exit(1);
  }

  final helper = CherryPickHelper(pr: pr, channel: channel, repoPath: repoPath);
  await helper.getOriginalPrDetails();
  final String candidateBranch = await helper.getCandidateBranch();

  if (action == 'start') {
    await helper.addLabel();
    // Wait a bit before polling to let GitHub Actions trigger
    await Future<void>.delayed(const Duration(seconds: 5));
    final int? cpPr = await helper.pollForPr(candidateBranch);
    if (cpPr != null) {
      _info('SUCCESS:AUTOMATED:$cpPr');
      exit(0);
    } else {
      _info('Automated cherry-pick did not create a PR. Falling back to manual...');
      final int manualPr = await helper.startManualCp(candidateBranch);
      _info('SUCCESS:MANUAL:$manualPr');
      exit(0);
    }
  } else if (action == 'continue') {
    final int manualPr = await helper.continueManualCp(candidateBranch);
    _info('SUCCESS:MANUAL:$manualPr');
    exit(0);
  }
}

void _info(Object? message) {
  stdout.writeln(message);
}

void _error(Object? message) {
  stderr.writeln(message);
}
