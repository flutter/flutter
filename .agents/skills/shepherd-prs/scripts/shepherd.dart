// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The possible shepherding actions that can be taken on a PR.
enum ShepherdAction { changeBase, updateBranch, applyCicd, rerunChecks, applyAutosubmit, none }

/// Represents a failed CI check.
class CheckFailure {
  CheckFailure({required this.name, required this.id, required this.type, this.rerunCount = 0});

  final String name;
  final String id;
  final String type; // 'check_run' or 'status_context'
  final int rerunCount;

  Map<String, dynamic> toJson() => {'name': name, 'id': id, 'type': type, 'rerunCount': rerunCount};
}

/// Summary of all checks running on a PR.
class ChecksSummary {
  ChecksSummary({
    required this.total,
    required this.passed,
    required this.failed,
    required this.running,
    required this.failures,
  });

  final int total;
  final int passed;
  final int failed;
  final int running;
  final List<CheckFailure> failures;

  Map<String, dynamic> toJson() => {
    'total': total,
    'passed': passed,
    'failed': failed,
    'running': running,
    'failures': failures.map((f) => f.toJson()).toList(),
  };
}

/// Represents a Pull Request in the repository.
class PullRequest {
  PullRequest({
    required this.number,
    required this.title,
    required this.author,
    required this.authorAssociation,
    required this.isBehind,
    required this.behindByCommits,
    required this.hasMergeConflicts,
    required this.labels,
    required this.checks,
    required this.baseRefName,
    required this.defaultBranchName,
    required this.headSha,
  });

  final int number;
  final String title;
  final String author;
  final String authorAssociation;
  final bool isBehind;
  final int behindByCommits;
  final bool hasMergeConflicts;
  final List<String> labels;
  final ChecksSummary checks;
  final String baseRefName;
  final String defaultBranchName;
  final String headSha;

  ShepherdAction get nextRecommendedAction {
    if (baseRefName != defaultBranchName) {
      return ShepherdAction.changeBase;
    }

    if (hasMergeConflicts) {
      return ShepherdAction.none;
    }

    if (isBehind && behindByCommits >= 50) {
      return ShepherdAction.updateBranch;
    }

    final bool hasCiYamlFailure = checks.failures.any(
      (CheckFailure f) => f.name.toLowerCase() == 'ci.yaml validation',
    );
    if (isBehind && hasCiYamlFailure) {
      return ShepherdAction.updateBranch;
    }

    final bool hasCicdLabel = labels.contains('CICD');
    final bool hasAutosubmitLabel = labels.contains('autosubmit');

    if (hasAutosubmitLabel) {
      return ShepherdAction.none;
    }

    if (!hasCicdLabel) {
      return ShepherdAction.applyCicd;
    }

    if (checks.failed > 0 && checks.failures.isNotEmpty) {
      return ShepherdAction.rerunChecks;
    }

    if (checks.running > 0) {
      return ShepherdAction.none;
    }

    if (checks.total > 0 && checks.passed == checks.total) {
      return ShepherdAction.applyAutosubmit;
    }

    return ShepherdAction.none;
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'title': title,
    'author': author,
    'authorAssociation': authorAssociation,
    'isBehind': isBehind,
    'behindByCommits': behindByCommits,
    'hasMergeConflicts': hasMergeConflicts,
    'labels': labels,
    'checks': checks.toJson(),
    'baseRefName': baseRefName,
    'defaultBranchName': defaultBranchName,
    'headSha': headSha,
    'nextRecommendedAction': nextRecommendedAction.name,
  };
}

/// Client to interface with the GitHub CLI (`gh`).
class GhClient {
  GhClient({required this.owner, required this.repo});

  final String owner;
  final String repo;

  Future<String> _runCommand(
    String command,
    List<String> arguments, {
    Map<String, String>? environment,
  }) async {
    final ProcessResult result = await Process.run(command, arguments, environment: environment);

    if (result.exitCode != 0) {
      throw ProcessException(
        command,
        arguments,
        'Command failed with exit code ${result.exitCode}.\nStderr: ${result.stderr}',
        result.exitCode,
      );
    }

    return result.stdout as String;
  }

  Future<dynamic> _getApi(String path, {List<String>? options}) async {
    final args = <String>['api', path];
    if (options != null) {
      args.addAll(options);
    }
    final String output = await _runCommand('gh', args);
    return jsonDecode(output);
  }

  Future<String> getViewerLogin() async {
    final response = await _getApi('/user') as Map<String, dynamic>;
    return response['login'] as String;
  }

  Future<int> getCommitsBehind(String defaultBranchName, String headSha) async {
    try {
      final response =
          await _getApi('/repos/$owner/$repo/compare/$defaultBranchName...$headSha')
              as Map<String, dynamic>;
      return response['behind_by'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<dynamic>> _runSearchQuery(String queryStr, String viewerLogin) async {
    final graphqlQuery =
        '''
      query(\$queryStr: String!) {
        search(query: \$queryStr, type: ISSUE, first: 50) {
          nodes {
            ... on PullRequest {
              number
              title
              author {
                login
              }
              authorAssociation
              baseRefName
              repository {
                defaultBranchRef {
                  name
                }
              }
              labels(first: 20) {
                nodes {
                  name
                }
              }
              mergeable
              commits(last: 1) {
                nodes {
                  commit {
                    oid
                    statusCheckRollup {
                      state
                      contexts(first: 100) {
                        nodes {
                          __typename
                          ... on CheckRun {
                            id
                            databaseId
                            name
                            status
                            conclusion
                          }
                          ... on StatusContext {
                            id
                            context
                            state
                          }
                        }
                      }
                    }
                  }
                }
              }
              reviews(author: "$viewerLogin", last: 10) {
                nodes {
                  state
                }
              }
            }
          }
        }
      }
    ''';

    final args = <String>[
      'api',
      'graphql',
      '-F',
      'query=$graphqlQuery',
      '-f',
      'queryStr=$queryStr',
    ];

    final String output = await _runCommand('gh', args);
    final payload = jsonDecode(output) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to query GitHub GraphQL API: $payload');
    }

    final search = data['search'] as Map<String, dynamic>;
    return search['nodes'] as List<dynamic>;
  }

  Future<List<PullRequest>> fetchApprovedPRs(String viewerLogin) async {
    final reviewedQueryStr =
        'repo:$owner/$repo is:pr is:open review:approved reviewed-by:$viewerLogin';
    final authoredQueryStr = 'repo:$owner/$repo is:pr is:open author:$viewerLogin';

    final List<List<dynamic>> results = await Future.wait([
      _runSearchQuery(reviewedQueryStr, viewerLogin),
      _runSearchQuery(authoredQueryStr, viewerLogin),
    ]);

    final Map<int, dynamic> uniqueNodes = {};
    for (final Map<String, dynamic> node in results[0].cast<Map<String, dynamic>>()) {
      final number = node['number'] as int;
      uniqueNodes[number] = node;
    }
    for (final Map<String, dynamic> node in results[1].cast<Map<String, dynamic>>()) {
      final number = node['number'] as int;
      uniqueNodes[number] = node;
    }

    final Iterable<Future<PullRequest?>> prFutures = uniqueNodes.values.map((dynamic node) async {
      final prData = node as Map<String, dynamic>;

      final authorData = prData['author'] as Map<String, dynamic>?;
      final author = authorData != null ? authorData['login'] as String : 'unknown';
      final isOwnPr = author == viewerLogin;

      final reviews = prData['reviews'] as Map<String, dynamic>?;
      final List<dynamic>? reviewNodes = reviews != null
          ? reviews['nodes'] as List<dynamic>?
          : null;
      final bool hasViewerApproval =
          reviewNodes != null &&
          reviewNodes.any((dynamic r) => (r as Map<String, dynamic>)['state'] == 'APPROVED');

      final authorAssociation = prData['authorAssociation'] as String;
      const members = {'MEMBER', 'OWNER', 'COLLABORATOR'};
      final bool isThirdParty = !members.contains(authorAssociation.toUpperCase());

      if (!isOwnPr && !isThirdParty) {
        return null;
      }

      if (isThirdParty && !hasViewerApproval) {
        return null;
      }

      final number = prData['number'] as int;
      final title = prData['title'] as String;
      final baseRefName = prData['baseRefName'] as String;

      final repositoryData = prData['repository'] as Map<String, dynamic>;
      final defaultBranchRef = repositoryData['defaultBranchRef'] as Map<String, dynamic>?;
      final defaultBranchName = defaultBranchRef != null
          ? defaultBranchRef['name'] as String
          : 'main';

      final labelsSection = prData['labels'] as Map<String, dynamic>;
      final labelNodes = labelsSection['nodes'] as List<dynamic>;
      final List<String> labels = labelNodes
          .map((dynamic l) => (l as Map<String, dynamic>)['name'] as String)
          .toList();

      final String mergeable = prData['mergeable'] as String? ?? 'UNKNOWN';
      final hasMergeConflicts = mergeable == 'CONFLICTING';

      final commitsSection = prData['commits'] as Map<String, dynamic>;
      final commitsNodes = commitsSection['nodes'] as List<dynamic>;

      var headSha = '';
      var checksSummary = ChecksSummary(total: 0, passed: 0, failed: 0, running: 0, failures: []);

      if (commitsNodes.isNotEmpty) {
        final firstCommitNode = commitsNodes.first as Map<String, dynamic>;
        final headCommitData = firstCommitNode['commit'] as Map<String, dynamic>;
        headSha = headCommitData['oid'] as String;

        final rollup = headCommitData['statusCheckRollup'] as Map<String, dynamic>?;
        checksSummary = _parseChecks(rollup);
      }

      final int behindCommits = await getCommitsBehind(defaultBranchName, headSha);
      final bool isBehind = behindCommits > 0;

      return PullRequest(
        number: number,
        title: title,
        author: author,
        authorAssociation: authorAssociation,
        isBehind: isBehind,
        behindByCommits: behindCommits,
        hasMergeConflicts: hasMergeConflicts,
        labels: labels,
        checks: checksSummary,
        baseRefName: baseRefName,
        defaultBranchName: defaultBranchName,
        headSha: headSha,
      );
    });

    final List<PullRequest?> resultsList = await Future.wait(prFutures);
    return resultsList.whereType<PullRequest>().toList();
  }

  ChecksSummary _parseChecks(Map<String, dynamic>? rollup) {
    if (rollup == null) {
      return ChecksSummary(total: 0, passed: 0, failed: 0, running: 0, failures: <CheckFailure>[]);
    }

    final contexts = rollup['contexts'] as Map<String, dynamic>?;
    if (contexts == null) {
      return ChecksSummary(total: 0, passed: 0, failed: 0, running: 0, failures: <CheckFailure>[]);
    }

    final nodes = contexts['nodes'] as List<dynamic>;
    var total = 0;
    var passed = 0;
    var failed = 0;
    var running = 0;
    final failures = <CheckFailure>[];

    for (final dynamic node in nodes) {
      if (node == null) {
        continue;
      }
      total++;
      final data = node as Map<String, dynamic>;
      final typename = data['__typename'] as String;

      if (typename == 'CheckRun') {
        final name = data['name'] as String;
        final id = data['id'] as String;
        final databaseId = data['databaseId'] as int?;
        final runId = databaseId != null ? databaseId.toString() : id;
        final status = data['status'] as String;
        final conclusion = data['conclusion'] as String?;

        if (status == 'COMPLETED') {
          if (conclusion == 'SUCCESS' || conclusion == 'SKIPPED' || conclusion == 'NEUTRAL') {
            passed++;
          } else {
            failed++;
            failures.add(CheckFailure(name: name, id: runId, type: 'check_run'));
          }
        } else {
          running++;
        }
      } else if (typename == 'StatusContext') {
        final context = data['context'] as String;
        final id = data['id'] as String;
        final state = data['state'] as String;

        if (state == 'SUCCESS') {
          passed++;
        } else if (state == 'PENDING') {
          running++;
        } else {
          failed++;
          failures.add(CheckFailure(name: context, id: id, type: 'status_context'));
        }
      }
    }

    return ChecksSummary(
      total: total,
      passed: passed,
      failed: failed,
      running: running,
      failures: failures,
    );
  }

  Future<void> updateBranch(int prNumber) async {
    await _runCommand('gh', <String>[
      'api',
      '-X',
      'PUT',
      '/repos/$owner/$repo/pulls/$prNumber/update-branch',
    ]);
  }

  Future<void> addLabel(int prNumber, String label) async {
    await _runCommand('gh', <String>[
      'pr',
      'edit',
      prNumber.toString(),
      '--repo',
      '$owner/$repo',
      '--add-label',
      label,
    ]);
  }

  Future<void> changeBaseBranch(int prNumber, String baseBranch) async {
    await _runCommand('gh', <String>[
      'pr',
      'edit',
      prNumber.toString(),
      '--repo',
      '$owner/$repo',
      '--base',
      baseBranch,
    ]);
  }
}

/// Service coordinating the landing actions (idempotent state machine steps) for PRs.
class ShepherdService {
  ShepherdService(this.ghClient, {this.maxRetries = 2});

  final GhClient ghClient;
  final int maxRetries;
  final String _stateFilePath = '.dart_tool/shepherd_state.json';

  Future<Map<String, dynamic>> _loadState() async {
    try {
      final file = File(_stateFilePath);
      if (file.existsSync()) {
        final String content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  Future<void> _saveState(Map<String, dynamic> state) async {
    try {
      final file = File(_stateFilePath);
      final Directory directory = file.parent;
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
      await file.writeAsString(jsonEncode(state), flush: true);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _syncAndGetState(List<PullRequest> prs) async {
    final Map<String, dynamic> state = await _loadState();
    final syncedState = <String, dynamic>{};

    for (final pr in prs) {
      final prKey = pr.number.toString();
      final String currentHead = pr.headSha;

      final existingPrState = state[prKey] as Map<String, dynamic>?;
      if (existingPrState != null && existingPrState['headSha'] == currentHead) {
        syncedState[prKey] = existingPrState;
      } else {
        syncedState[prKey] = <String, dynamic>{'headSha': currentHead, 'retries': <String, int>{}};
      }
    }

    await _saveState(syncedState);
    return syncedState;
  }

  Future<String> shepherdPR(
    PullRequest pr,
    Map<String, dynamic> globalState, {
    required bool dryRun,
  }) async {
    final prKey = pr.number.toString();
    final ShepherdAction action = pr.nextRecommendedAction;
    final prPrefix = '[#${pr.number}]';

    if (action == ShepherdAction.none) {
      if (pr.labels.contains('autosubmit')) {
        return '$prPrefix Status: AUTOSUBMIT applied. Waiting for merge bot.';
      }
      if (pr.hasMergeConflicts) {
        return '$prPrefix WARNING: PR has merge conflicts. Manual intervention required.';
      }
      if (pr.checks.running > 0) {
        return '$prPrefix Status: CI tests running (${pr.checks.passed}/${pr.checks.total} passed). Waiting for completion.';
      }
      return '$prPrefix Status: Up-to-date and waiting.';
    }

    if (action == ShepherdAction.changeBase) {
      if (dryRun) {
        return '$prPrefix [DRY RUN] Would change target base branch to "${pr.defaultBranchName}" (currently "${pr.baseRefName}").';
      }
      try {
        await ghClient.changeBaseBranch(pr.number, pr.defaultBranchName);
        return '$prPrefix SUCCESS: Changed target base branch to "${pr.defaultBranchName}" (was "${pr.baseRefName}").';
      } catch (e) {
        return '$prPrefix ERROR: Failed to change target base branch: $e';
      }
    }

    if (action == ShepherdAction.updateBranch) {
      if (dryRun) {
        return '$prPrefix [DRY RUN] Would update branch (behind by ${pr.behindByCommits} commits).';
      }
      try {
        await ghClient.updateBranch(pr.number);
        return '$prPrefix SUCCESS: Triggered branch update (was behind by ${pr.behindByCommits} commits).';
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('workflow') && errStr.contains('scope')) {
          return '$prPrefix ERROR: Failed to update branch because your GitHub CLI token lacks the "workflow" scope.\n'
              '  Remediation: Run the following command in your terminal and try again:\n'
              '    gh auth refresh -h github.com -s workflow';
        }
        return '$prPrefix ERROR: Failed to update branch: $e';
      }
    }

    if (action == ShepherdAction.applyCicd) {
      if (dryRun) {
        return '$prPrefix [DRY RUN] Would apply "CICD" label to start testing.';
      }
      try {
        await ghClient.addLabel(pr.number, 'CICD');
        return '$prPrefix SUCCESS: Applied "CICD" label to trigger CI.';
      } catch (e) {
        return '$prPrefix ERROR: Failed to apply "CICD" label: $e';
      }
    }

    if (action == ShepherdAction.applyAutosubmit) {
      if (dryRun) {
        return '$prPrefix [DRY RUN] Would apply "autosubmit" label to land the PR.';
      }
      try {
        await ghClient.addLabel(pr.number, 'autosubmit');
        return '$prPrefix SUCCESS: Applied "autosubmit" label (all checks green).';
      } catch (e) {
        return '$prPrefix ERROR: Failed to apply "autosubmit" label: $e';
      }
    }

    if (action == ShepherdAction.rerunChecks) {
      final prState = globalState[prKey] as Map<String, dynamic>;
      final retriesMap = Map<String, int>.from(
        prState['retries'] as Map<dynamic, dynamic>? ?? <dynamic, dynamic>{},
      );

      final failuresToRerun = <CheckFailure>[];
      final skippedFailures = <String>[];

      for (final CheckFailure failure in pr.checks.failures) {
        final int currentRerunCount = retriesMap[failure.name] ?? 0;

        if (currentRerunCount < maxRetries) {
          failuresToRerun.add(failure);
          retriesMap[failure.name] = currentRerunCount + 1;
        } else {
          skippedFailures.add('${failure.name} (already retried $currentRerunCount times)');
        }
      }

      if (failuresToRerun.isEmpty) {
        return '$prPrefix WARNING: All failed checks have exceeded the retry limit ($maxRetries). Manual intervention required.\n'
            '  Skipped: ${skippedFailures.join(", ")}';
      }

      final logs = <String>[];
      for (final failure in failuresToRerun) {
        final int? attempt = retriesMap[failure.name];
        logs.add(
          '$prPrefix WARNING: Check "${failure.name}" (attempt $attempt/$maxRetries) cannot be re-run via the API due to GitHub App permission policies. Please click the "Details" link on the failed check in GitHub to open the LUCI build page, and click the "Retry Build" button.',
        );
      }

      if (!dryRun) {
        prState['retries'] = retriesMap;
        await _saveState(globalState);
      }

      if (skippedFailures.isNotEmpty) {
        logs.add(
          '$prPrefix WARNING: Skipped re-running the following checks (retry limit exceeded): ${skippedFailures.join(", ")}',
        );
      }

      return logs.join('\n');
    }

    return '$prPrefix Status: No action taken.';
  }

  Future<List<String>> runShepherding({
    required String viewerLogin,
    int? targetPrNumber,
    required bool dryRun,
  }) async {
    final List<PullRequest> prs = await ghClient.fetchApprovedPRs(viewerLogin);
    final eligiblePrs = prs;

    if (eligiblePrs.isEmpty) {
      return <String>[
        'No open PRs authored by you or approved third-party PRs found requiring shepherding.',
      ];
    }

    final Map<String, dynamic> globalState = await _syncAndGetState(eligiblePrs);
    final List<String> logs = [];

    if (targetPrNumber != null) {
      final PullRequest targetPr = eligiblePrs.firstWhere(
        (pr) => pr.number == targetPrNumber,
        orElse: () => throw ArgumentError(
          'PR #$targetPrNumber is not in your open PR or approved third-party PR list.',
        ),
      );
      final String log = await shepherdPR(targetPr, globalState, dryRun: dryRun);
      logs.add(log);
    } else {
      for (final pr in eligiblePrs) {
        final String log = await shepherdPR(pr, globalState, dryRun: dryRun);
        logs.add(log);
      }
    }

    return logs;
  }
}

void main(List<String> args) async {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    _printJsonUsage();
    exit(0);
  }

  var owner = 'flutter';
  var repo = 'flutter';
  String? command;
  var runAll = false;
  int? prNumber;
  var dryRun = false;

  for (var i = 0; i < args.length; i++) {
    final String arg = args[i];
    if (arg == 'list' || arg == 'run') {
      command = arg;
    } else if (arg == '--owner') {
      if (i + 1 < args.length) {
        owner = args[++i];
      }
    } else if (arg == '--repo') {
      if (i + 1 < args.length) {
        repo = args[++i];
      }
    } else if (arg == '--all') {
      runAll = true;
    } else if (arg == '--pr') {
      if (i + 1 < args.length) {
        prNumber = int.tryParse(args[++i]);
      }
    } else if (arg == '--dry-run') {
      dryRun = true;
    }
  }

  if (command == null) {
    _printJsonError('Missing subcommand ("list" or "run").');
    exit(64);
  }

  final ghClient = GhClient(owner: owner, repo: repo);
  final shepherdService = ShepherdService(ghClient);

  try {
    try {
      final ProcessResult result = await Process.run('gh', <String>['api', '/user']);
      if (result.exitCode != 0) {
        _printJsonError(
          'GitHub CLI ("gh") is not authenticated. Please run "gh auth login" first.',
        );
        exit(1);
      }
    } on ProcessException catch (_) {
      _printJsonError('GitHub CLI ("gh") is not installed. Please install it first.');
      exit(1);
    }

    final String viewerLogin = await ghClient.getViewerLogin();

    if (command == 'list') {
      final List<PullRequest> prs = await ghClient.fetchApprovedPRs(viewerLogin);
      final eligiblePrs = prs;
      print(jsonEncode(eligiblePrs.map((PullRequest pr) => pr.toJson()).toList()));
    } else if (command == 'run') {
      if (!runAll && prNumber == null) {
        _printJsonError('You must specify either --all or --pr <number> to run shepherding.');
        exit(64);
      }

      final List<String> logs = await shepherdService.runShepherding(
        viewerLogin: viewerLogin,
        targetPrNumber: prNumber,
        dryRun: dryRun,
      );

      print(
        jsonEncode(<String, dynamic>{
          'timestamp': DateTime.now().toIso8601String(),
          'dryRun': dryRun,
          'logs': logs,
        }),
      );
    }
  } catch (e) {
    _printJsonError(e.toString());
    exit(1);
  }
}

void _printJsonError(String message) {
  print(jsonEncode(<String, dynamic>{'error': message}));
}

void _printJsonUsage() {
  print(
    jsonEncode(<String, dynamic>{
      'usage': 'dart shepherd.dart <command> [options]',
      'commands': <String, String>{
        'list': 'List approved, open third-party PRs.',
        'run': 'Execute shepherding actions on approved PRs.',
      },
      'options': <String, String>{
        '--owner <name>': 'GitHub repository owner (default: flutter).',
        '--repo <name>': 'GitHub repository name (default: flutter).',
        '--all': 'Shepherd all eligible approved PRs (only for "run" command).',
        '--pr <number>': 'Shepherd a specific PR by number (only for "run" command).',
        '--dry-run': 'Evaluate actions without executing them.',
      },
    }),
  );
}
