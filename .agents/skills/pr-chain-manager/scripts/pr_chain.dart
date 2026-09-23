// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

/// Manages stacked PR branches for the Android Embedder C-API migration.
///
/// Default branch slug: `android-embedder-migration-v10/*`
/// Ensures topological consistency, automated cascading rebases, and PR base synchronization.
void main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(0);
  }

  final String command = args[0];
  final Map<String, String> flags = _parseFlags(args.sublist(1));

  final String slug = flags['slug'] ?? 'android-embedder-migration-v10';
  final String baseBranch = flags['base'] ?? 'upstream/master';
  final bool dryRun = flags.containsKey('dry-run');

  final manager = PRChainManager(slug: slug, baseBranch: baseBranch, dryRun: dryRun);

  try {
    switch (command) {
      case 'status':
        await manager.showStatus();
      case 'verify':
        final bool isConsistent = await manager.verifyChain();
        exit(isConsistent ? 0 : 1);
      case 'rebase':
        final String? fromBranch = flags['from'];
        await manager.cascadeRebase(fromBranch: fromBranch);
      case 'push':
        await manager.pushChain();
      case 'sync-gh':
        await manager.syncGitHubPrs();
      default:
        stderr.writeln('Unknown command: $command');
        _printUsage();
        exit(1);
    }
  } catch (e, stack) {
    stderr.writeln('Error executing $command: $e');
    if (flags.containsKey('verbose')) {
      stderr.writeln(stack);
    }
    exit(1);
  }
}

void _printUsage() {
  stdout.writeln('''
PR Chain Manager: Automates cascading rebases and branch consistency for stacked PRs.

Usage:
  dart pr_chain.dart <command> [options]

Commands:
  status        Display topological status, commit SHAs, and ancestor alignment for all branches in the chain.
  verify        Verify that each downstream branch is an ancestor descendant of its predecessor (exit 0 if clean, 1 if broken).
  rebase        Cascade rebase from a modified branch downstream through the remainder of the chain.
  push          Push all branches in the chain to origin with --force-with-lease.
  sync-gh       Update GitHub PR base branches so each PR points to its parent branch in the chain.

Options:
  --slug=<slug>  Branch prefix slug to track (default: android-embedder-migration-v10).
  --base=<base>  Root upstream base branch (default: upstream/master).
  --from=<name>  Branch name or version to start cascading rebase from (rebase only).
  --dry-run      Print planned git operations without executing them.
  --verbose      Print verbose error traces and process execution details.
  --help, -h     Show this help message.
''');
}

Map<String, String> _parseFlags(List<String> args) {
  final flags = <String, String>{};
  for (final arg in args) {
    if (arg.startsWith('--')) {
      final int equalsIndex = arg.indexOf('=');
      if (equalsIndex != -1) {
        flags[arg.substring(2, equalsIndex)] = arg.substring(equalsIndex + 1);
      } else {
        flags[arg.substring(2)] = 'true';
      }
    }
  }
  return flags;
}

class BranchInfo {
  BranchInfo({
    required this.name,
    required this.versionKey,
    required this.headSha,
    required this.subject,
  });

  final String name;
  final String versionKey;
  final String headSha;
  final String subject;

  String? parentBranch;
  bool isAlignedWithParent = false;
  int commitsAheadOfParent = 0;
}

class PRChainManager {
  PRChainManager({required this.slug, required this.baseBranch, required this.dryRun});

  final String slug;
  final String baseBranch;
  final bool dryRun;

  /// Retrieves and sorts all branches matching `slug/*`.
  Future<List<BranchInfo>> getChainBranches() async {
    final ProcessResult result = await _runGit(<String>[
      'branch',
      '--list',
      '$slug/*',
      '--format=%(refname:short)|%(objectname:short)|%(subject)',
    ]);

    if (result.exitCode != 0) {
      throw Exception('Failed to list branches: ${result.stderr}');
    }

    final String stdoutText = (result.stdout as String).trim();
    if (stdoutText.isEmpty) {
      return <BranchInfo>[];
    }

    final branches = <BranchInfo>[];
    for (final String line in stdoutText.split('\n')) {
      final List<String> parts = line.split('|');
      if (parts.length < 3) {
        continue;
      }
      final String branchName = parts[0].trim();
      final String headSha = parts[1].trim();
      final String subject = parts.sublist(2).join('|').trim();

      final String suffix = branchName.substring('$slug/'.length);
      branches.add(
        BranchInfo(name: branchName, versionKey: suffix, headSha: headSha, subject: subject),
      );
    }

    branches.sort((BranchInfo a, BranchInfo b) => _compareVersions(a.versionKey, b.versionKey));

    // Connect parents and check ancestor relationships.
    for (var i = 0; i < branches.length; i++) {
      final BranchInfo current = branches[i];
      final String parent = (i == 0) ? baseBranch : branches[i - 1].name;
      current.parentBranch = parent;

      // Check if parent is ancestor of current.
      final ProcessResult ancestorCheck = await _runGit(<String>[
        'merge-base',
        '--is-ancestor',
        parent,
        current.name,
      ]);
      current.isAlignedWithParent = (ancestorCheck.exitCode == 0);

      // Check commits ahead of parent.
      final ProcessResult countCheck = await _runGit(<String>[
        'rev-list',
        '--count',
        '$parent..${current.name}',
      ]);
      if (countCheck.exitCode == 0) {
        current.commitsAheadOfParent = int.tryParse((countCheck.stdout as String).trim()) ?? 0;
      }
    }

    return branches;
  }

  /// Displays the status of the branch chain.
  Future<void> showStatus() async {
    final List<BranchInfo> chain = await getChainBranches();

    stdout.writeln('================================================================');
    stdout.writeln('PR Chain Status: Slug "$slug/*" (Root: $baseBranch)');
    stdout.writeln('================================================================');

    if (chain.isEmpty) {
      stdout.writeln('No branches found matching "$slug/*".');
      return;
    }

    final String currentBranch = await _getCurrentBranch();

    for (var i = 0; i < chain.length; i++) {
      final BranchInfo b = chain[i];
      final isCurrentMarker = (b.name == currentBranch) ? ' -> ' : '    ';
      final statusTag = b.isAlignedWithParent ? '[IN SYNC]' : '[OUT OF SYNC: NEEDS REBASE]';

      stdout.writeln('$isCurrentMarker#$i: ${b.name}');
      stdout.writeln('       Parent: ${b.parentBranch}');
      stdout.writeln('       Status: $statusTag (${b.commitsAheadOfParent} commits ahead)');
      stdout.writeln('       HEAD  : ${b.headSha} - ${b.subject}');
      stdout.writeln();
    }
  }

  /// Verifies that all branches in the chain are strictly descendants of their parent.
  Future<bool> verifyChain() async {
    final List<BranchInfo> chain = await getChainBranches();
    var allValid = true;

    for (final b in chain) {
      if (!b.isAlignedWithParent) {
        stderr.writeln('ERROR: Branch ${b.name} is NOT aligned with parent ${b.parentBranch}.');
        allValid = false;
      }
    }

    if (allValid) {
      stdout.writeln(
        'SUCCESS: All ${chain.length} branches in "$slug/*" are consistent and properly stacked.',
      );
    }
    return allValid;
  }

  /// Cascades rebases down the chain starting from a given branch or the first misaligned branch.
  Future<void> cascadeRebase({String? fromBranch}) async {
    final List<BranchInfo> chain = await getChainBranches();
    if (chain.isEmpty) {
      stdout.writeln('No branches found matching "$slug/*". Nothing to rebase.');
      return;
    }

    final String initialBranch = await _getCurrentBranch();

    var startIndex = 0;
    if (fromBranch != null) {
      final String resolvedFrom = fromBranch.startsWith('$slug/')
          ? fromBranch
          : '$slug/$fromBranch';
      startIndex = chain.indexWhere((BranchInfo b) => b.name == resolvedFrom);
      if (startIndex == -1) {
        throw Exception('Branch $fromBranch not found in chain.');
      }
    } else {
      // Find first branch that is out of sync.
      final int firstBroken = chain.indexWhere((BranchInfo b) => !b.isAlignedWithParent);
      if (firstBroken != -1) {
        startIndex = firstBroken;
      } else {
        stdout.writeln('All branches are already in sync. No rebase needed.');
        return;
      }
    }

    stdout.writeln(
      'Starting cascading rebase from index #$startIndex (${chain[startIndex].name})...',
    );

    for (var i = startIndex; i < chain.length; i++) {
      final BranchInfo current = chain[i];
      final String parent = (i == 0) ? baseBranch : chain[i - 1].name;

      stdout.writeln('\n------------------------------------------------------------');
      stdout.writeln('Rebasing #$i: ${current.name} onto $parent...');
      stdout.writeln('------------------------------------------------------------');

      if (dryRun) {
        stdout.writeln('[DRY-RUN] git checkout ${current.name}');
        stdout.writeln('[DRY-RUN] git rebase $parent');
        continue;
      }

      // Check out target branch.
      final ProcessResult checkoutResult = await _runGit(<String>['checkout', current.name]);
      if (checkoutResult.exitCode != 0) {
        throw Exception('Failed to checkout ${current.name}: ${checkoutResult.stderr}');
      }

      // Execute rebase onto parent.
      final ProcessResult rebaseResult = await _runGit(<String>['rebase', parent]);
      if (rebaseResult.exitCode != 0) {
        stderr.writeln('\n============================================================');
        stderr.writeln('CONFLICT DETECTED during rebase of ${current.name} onto $parent');
        stderr.writeln('============================================================');
        stderr.writeln(rebaseResult.stdout);
        stderr.writeln(rebaseResult.stderr);
        stderr.writeln('\nAction Required:');
        stderr.writeln('  1. Resolve conflicts in your working tree.');
        stderr.writeln('  2. Stage resolved files: git add <files>');
        stderr.writeln('  3. Resume rebase: git rebase --continue');
        stderr.writeln(
          '  4. Re-run "dart pr_chain.dart rebase" to cascade through the rest of the chain.',
        );
        exit(1);
      }

      stdout.writeln('Successfully rebased ${current.name}.');
    }

    if (!dryRun) {
      await _runGit(<String>['checkout', initialBranch]);
    }

    stdout.writeln('\n============================================================');
    stdout.writeln('Cascading rebase complete! All downstream branches are updated.');
    stdout.writeln('Run "dart pr_chain.dart push" to update remotes.');
    stdout.writeln('============================================================');
  }

  /// Pushes all branches in the chain to origin with --force-with-lease.
  Future<void> pushChain() async {
    final List<BranchInfo> chain = await getChainBranches();
    if (chain.isEmpty) {
      stdout.writeln('No branches found to push.');
      return;
    }

    stdout.writeln('Pushing ${chain.length} branches in "$slug/*" with --force-with-lease...');

    for (final b in chain) {
      stdout.writeln('Pushing ${b.name} -> origin...');
      if (dryRun) {
        stdout.writeln('[DRY-RUN] git push origin ${b.name} --force-with-lease');
      } else {
        final ProcessResult result = await _runGit(<String>[
          'push',
          'origin',
          b.name,
          '--force-with-lease',
        ]);
        if (result.exitCode != 0) {
          stderr.writeln('Failed to push ${b.name}: ${result.stderr}');
          exit(1);
        }
      }
    }

    stdout.writeln('All branches pushed successfully!');
  }

  /// Syncs GitHub PR base branches using the gh CLI.
  Future<void> syncGitHubPrs() async {
    final List<BranchInfo> chain = await getChainBranches();
    if (chain.isEmpty) {
      return;
    }

    stdout.writeln('Verifying and updating GitHub PR base branches via `gh`...');

    for (var i = 0; i < chain.length; i++) {
      final BranchInfo current = chain[i];
      final String expectedBase = (i == 0) ? 'master' : chain[i - 1].name;

      final ProcessResult prView = await Process.run('gh', <String>[
        'pr',
        'view',
        current.name,
        '--repo',
        'flutter/flutter',
        '--json',
        'number,baseRefName',
      ]);

      if (prView.exitCode != 0) {
        stdout.writeln('No open GitHub PR found for ${current.name} on flutter/flutter.');
        continue;
      }

      final data = jsonDecode(prView.stdout as String) as Map<String, dynamic>;
      final prNumber = data['number'] as int;
      final actualBase = data['baseRefName'] as String;

      if (actualBase != expectedBase) {
        stdout.writeln(
          'PR #$prNumber (${current.name}): updating base from $actualBase -> $expectedBase',
        );
        if (!dryRun) {
          await Process.run('gh', <String>[
            'pr',
            'edit',
            prNumber.toString(),
            '--repo',
            'flutter/flutter',
            '--base',
            expectedBase,
          ]);
        }
      } else {
        stdout.writeln('PR #$prNumber (${current.name}): base is correctly set to $expectedBase.');
      }
    }
  }

  Future<String> _getCurrentBranch() async {
    final ProcessResult result = await _runGit(<String>['branch', '--show-current']);
    return (result.stdout as String).trim();
  }

  Future<ProcessResult> _runGit(List<String> args) {
    return Process.run(
      'git',
      args,
      environment: <String, String>{
        'PATH': '${Platform.environment['PATH']}:/usr/local/google/home/boetger/src/depot_tools',
      },
    );
  }

  static int _compareVersions(String a, String b) {
    final versionRegex = RegExp(r'^(\d+)\.(\d+)');
    final Match? matchA = versionRegex.firstMatch(a);
    final Match? matchB = versionRegex.firstMatch(b);

    if (matchA != null && matchB != null) {
      final int majorA = int.parse(matchA.group(1)!);
      final int minorA = int.parse(matchA.group(2)!);
      final int majorB = int.parse(matchB.group(1)!);
      final int minorB = int.parse(matchB.group(2)!);

      if (majorA != majorB) {
        return majorA.compareTo(majorB);
      }
      if (minorA != minorB) {
        return minorA.compareTo(minorB);
      }
    }
    return a.compareTo(b);
  }
}
