// ignore_for_file: avoid_print, prefer_final_locals, omit_obvious_local_variable_types, specify_nonobvious_local_variable_types, unnecessary_await_in_return, always_put_control_body_on_new_line, prefer_foreach, inference_failure_on_instance_creation, sort_constructors_first

import 'dart:convert';
import 'dart:io';

/// A helper class to orchestrate the Flutter cherry-pick (CP) process.
class CherryPickHelper {
  /// The original PR number on the master branch.
  final int pr;

  /// The target channel for the cherry-pick (either 'stable' or 'beta').
  final String channel;

  /// The path to the local Flutter repository.
  final String repoPath;

  /// Detailed data about the original PR, fetched from GitHub.
  Map<String, Object?>? originalPrData;

  /// Creates a new [CherryPickHelper] instance.
  CherryPickHelper({required this.pr, required this.channel, required this.repoPath});

  /// Helper to execute shell commands in the Flutter repository directory.
  ///
  /// Throws an error and exits with code 1 if the command fails, unless
  /// [allowFailure] is set to true.
  Future<ProcessResult> runCmd(List<String> cmd, {bool allowFailure = false}) async {
    final result = await Process.run(cmd[0], cmd.sublist(1), workingDirectory: repoPath);
    if (result.exitCode != 0 && !allowFailure) {
      print('Command failed: ${cmd.join(' ')}');
      print('Stdout: ${result.stdout}');
      print('Stderr: ${result.stderr}');
      exit(1);
    }
    return result;
  }

  /// Fetches the details of the original PR from GitHub using `gh`.
  ///
  /// Verifies that the PR is in the `MERGED` state.
  Future<Map<String, Object?>> getOriginalPrDetails() async {
    print('Fetching details for original PR #$pr...');
    final result = await runCmd([
      'gh',
      'pr',
      'view',
      pr.toString(),
      '--json',
      'title,body,mergeCommit,state,url',
    ]);

    final Object? decoded = jsonDecode(result.stdout as String);
    if (decoded case Map<String, Object?> prMap) {
      originalPrData = prMap;
      if (prMap['state'] != 'MERGED') {
        print('Error: PR #$pr is not merged (State: ${prMap['state']}).');
        exit(1);
      }
      return prMap;
    } else {
      print('Error: Failed to parse PR details as a JSON map.');
      exit(1);
    }
  }

  /// Adds the cherry-pick label (`cp: stable` or `cp: beta`) to the original PR.
  Future<void> addLabel() async {
    print('Adding "cp: $channel" label to PR #$pr...');
    await runCmd(['gh', 'pr', 'edit', pr.toString(), '--add-label', 'cp:$channel']);
  }

  /// Dynamically retrieves the release candidate branch name for the target channel.
  ///
  /// Reads the version file `bin/internal/release-candidate-branch.version` from
  /// the remote branch (or falls back to local branch).
  Future<String> getCandidateBranch() async {
    print('Locating candidate branch for $channel...');
    var result = await runCmd([
      'git',
      'show',
      'origin/$channel:bin/internal/release-candidate-branch.version',
    ], allowFailure: true);
    if (result.exitCode != 0) {
      print(
        'Warning: Could not read candidate branch from origin/$channel. Trying to read locally...',
      );
      result = await runCmd([
        'git',
        'show',
        '$channel:bin/internal/release-candidate-branch.version',
      ], allowFailure: true);
      if (result.exitCode != 0) {
        print('Error: Failed to locate candidate branch version file.');
        exit(1);
      }
    }
    final String branch = (result.stdout as String).trim();
    print('Found candidate branch: $branch');
    return branch;
  }

  /// Polls GitHub for the automatically generated cherry-pick PR.
  ///
  /// Looks for an open PR targeting [candidateBranch] that references
  /// the original PR number or title in its title.
  Future<int?> pollForPr(String candidateBranch) async {
    print('Polling for automated cherry-pick PR targeting $candidateBranch...');
    const int attempts = 8;
    for (int i = 0; i < attempts; i++) {
      await Future.delayed(const Duration(seconds: 15));
      print('Polling attempt ${i + 1}/$attempts...');
      final result = await runCmd([
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
      if (decoded case List<Object?> prs) {
        for (final Object? prData in prs) {
          if (prData case {'number': int number, 'title': String title}) {
            final String? originalTitle = originalPrData?['title'] as String?;
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
    print('Starting manual cherry-pick fallback...');
    await runCmd(['git', 'fetch', 'origin', candidateBranch]);

    final String branchName = 'cherry-pick-$pr-to-$channel';
    print('Creating local branch $branchName from origin/$candidateBranch...');
    await runCmd(['git', 'checkout', '-B', branchName, 'origin/$candidateBranch']);

    final String sha = switch (originalPrData) {
      {'mergeCommit': {'oid': String oid}} => oid,
      _ => throw StateError('Could not find merge commit SHA in PR data'),
    };

    print('Attempting to cherry-pick commit $sha...');
    final result = await runCmd(['git', 'cherry-pick', sha], allowFailure: true);

    if (result.exitCode == 0) {
      print('Cherry-pick succeeded without conflicts.');
      return await pushAndCreatePr(candidateBranch);
    } else {
      print('Cherry-pick encountered conflicts!');
      print(result.stderr);

      final statusResult = await runCmd(['git', 'status', '--porcelain']);
      final String statusOutput = statusResult.stdout as String;
      final List<String> conflictedFiles = <String>[];

      for (final String line in statusOutput.split('\n')) {
        if (line.trim().isEmpty) continue;
        // Identify conflicted files in porcelain output
        if (line.startsWith('UU') ||
            line.startsWith('AA') ||
            line.startsWith('U') ||
            line.contains('UU')) {
          if (line.length > 3) {
            conflictedFiles.add(line.substring(3).trim());
          }
        }
      }

      // Fallback parser if the above didn't catch it
      if (conflictedFiles.isEmpty) {
        for (final String line in statusOutput.split('\n')) {
          if (line.trim().isEmpty) continue;
          if (line.startsWith('U') || line.startsWith(' D') || line.startsWith('D ')) {
            if (line.length > 3) {
              conflictedFiles.add(line.substring(3).trim());
            }
          }
        }
      }

      print('\n=== CONFLICTED FILES ===');
      for (final String f in conflictedFiles) {
        print(f);
      }
      print('========================\n');
      print('Please resolve these conflicts in your editor, then run the continue action.');
      exit(2);
    }
  }

  /// Continues the manual cherry-pick after conflicts have been resolved by the user.
  Future<int> continueManualCp(String candidateBranch) async {
    print('Continuing manual cherry-pick...');
    final statusResult = await runCmd(['git', 'status', '--porcelain']);
    final String statusOutput = statusResult.stdout as String;
    if (statusOutput.contains('UU') || statusOutput.startsWith('U')) {
      print('Error: There are still unresolved conflicts.');
      exit(1);
    }

    try {
      final result = await Process.run(
        'git',
        ['cherry-pick', '--continue'],
        workingDirectory: repoPath,
        environment: <String, String>{'GIT_EDITOR': 'true'},
      );
      if (result.exitCode != 0) {
        print('Failed to continue cherry-pick.');
        print('Stdout: ${result.stdout}');
        print('Stderr: ${result.stderr}');
        exit(1);
      }
    } catch (e) {
      print('Failed to continue cherry-pick: $e');
      exit(1);
    }

    return await pushAndCreatePr(candidateBranch);
  }

  /// Pushes the local cherry-pick branch and creates a pull request targeting [candidateBranch].
  Future<int> pushAndCreatePr(String candidateBranch) async {
    final String branchName = 'cherry-pick-$pr-to-$channel';
    print('Pushing branch $branchName to origin...');
    await runCmd(['git', 'push', '-u', 'origin', 'HEAD', '--force']);

    final String originalTitle = originalPrData?['title'] as String? ?? '';
    final String title = '[$channel] $originalTitle';
    final String body = 'Cherry-pick of #$pr to $channel';
    print('Creating pull request: $title...');
    final result = await runCmd([
      'gh',
      'pr',
      'create',
      '--base',
      candidateBranch,
      '--title',
      title,
      '--body',
      body,
    ]);

    final String prUrl = (result.stdout as String).trim();
    final String prNumberStr = prUrl.split('/').last;
    final int? prNumber = int.tryParse(prNumberStr);
    if (prNumber == null) {
      print('Error: Could not parse PR number from URL: $prUrl');
      exit(1);
    }
    print('Created PR #$prNumber: $prUrl');

    print('Adding "cp: review" label to PR #$prNumber...');
    await runCmd(['gh', 'pr', 'edit', prNumber.toString(), '--add-label', 'cp: review']);

    return prNumber;
  }
}

void main(List<String> arguments) async {
  int? pr;
  String? channel;
  String? action;
  String repoPath = '.';

  for (int i = 0; i < arguments.length; i++) {
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

  if (pr == null || channel == null || action == null) {
    print(
      'Usage: dart flutter_cp.dart --pr <pr> --channel <stable|beta> --action <start|continue> [--repo-path <path>]',
    );
    exit(1);
  }

  final CherryPickHelper helper = CherryPickHelper(pr: pr, channel: channel, repoPath: repoPath);
  await helper.getOriginalPrDetails();
  final String candidateBranch = await helper.getCandidateBranch();

  if (action == 'start') {
    await helper.addLabel();
    // Wait a bit before polling to let GitHub Actions trigger
    await Future.delayed(const Duration(seconds: 5));
    final int? cpPr = await helper.pollForPr(candidateBranch);
    if (cpPr != null) {
      print('SUCCESS:AUTOMATED:$cpPr');
      exit(0);
    } else {
      print('Automated cherry-pick did not create a PR. Falling back to manual...');
      final int manualPr = await helper.startManualCp(candidateBranch);
      print('SUCCESS:MANUAL:$manualPr');
      exit(0);
    }
  } else if (action == 'continue') {
    final int manualPr = await helper.continueManualCp(candidateBranch);
    print('SUCCESS:MANUAL:$manualPr');
    exit(0);
  }
}
