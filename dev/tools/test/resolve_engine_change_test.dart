// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('posix')
library;

import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:test/test.dart';

void main() {
  const FileSystem localFs = LocalFileSystem();
  final Directory flutterRoot = _findFlutterRoot(localFs);

  Directory? tmpDir;
  late Directory repoDir;
  late File outputFile;

  Map<String, String> hermeticGitEnv([Map<String, String> extra = const <String, String>{}]) {
    return <String, String>{
      'PATH': io.Platform.environment['PATH'] ?? '',
      'HOME': tmpDir!.path,
      'GIT_CONFIG_NOSYSTEM': '1',
      ...extra,
    };
  }

  io.ProcessResult runGit(List<String> args, {Directory? dir}) {
    final io.ProcessResult result = io.Process.runSync(
      'git',
      args,
      workingDirectory: (dir ?? repoDir).path,
      environment: hermeticGitEnv(),
      includeParentEnvironment: false,
    );
    if (result.exitCode != 0) {
      fail(
        'git ${args.join(" ")} failed (${result.exitCode}):\n'
        'stdout: ${result.stdout}\nstderr: ${result.stderr}',
      );
    }
    return result;
  }

  String revParse(String ref, {Directory? dir}) {
    return (runGit(<String>['rev-parse', ref], dir: dir).stdout as String).trim();
  }

  String commitFiles(Map<String, String> files, String message) {
    for (final MapEntry<String, String> entry in files.entries) {
      localFs.file(localFs.path.join(repoDir.path, entry.key))
        ..createSync(recursive: true)
        ..writeAsStringSync(entry.value);
    }
    runGit(<String>['add', '--all']);
    runGit(<String>['commit', '-m', message]);
    return revParse('HEAD');
  }

  Map<String, String> runResolveEngineChange(Map<String, String> env) {
    if (outputFile.existsSync()) {
      outputFile.deleteSync();
    }
    outputFile.createSync(recursive: true);

    final String scriptPath = localFs.path.join(
      repoDir.path,
      '.github',
      'scripts',
      'resolve_engine_change.sh',
    );
    final io.ProcessResult result = io.Process.runSync(
      'bash',
      <String>[scriptPath],
      workingDirectory: repoDir.path,
      environment: hermeticGitEnv(<String, String>{'GITHUB_OUTPUT': outputFile.path, ...env}),
      includeParentEnvironment: false,
    );
    if (result.exitCode != 0) {
      fail(
        'resolve_engine_change.sh failed (${result.exitCode}):\n'
        'stdout: ${result.stdout}\nstderr: ${result.stderr}',
      );
    }

    final outputs = <String, String>{};
    for (final String line in outputFile.readAsLinesSync()) {
      final int eq = line.indexOf('=');
      if (eq > 0) {
        outputs[line.substring(0, eq)] = line.substring(eq + 1);
      }
    }
    return outputs;
  }

  setUp(() {
    final Directory temp = localFs.systemTempDirectory.createTempSync(
      'resolve_engine_change_test.',
    );
    tmpDir = temp;
    repoDir = temp.childDirectory('repo')..createSync(recursive: true);
    outputFile = temp.childFile('github_output.txt');

    for (final scriptName in <String>[
      'did_engine_change.sh',
      'git_files_changed.sh',
      'resolve_engine_change.sh',
    ]) {
      final File src = flutterRoot.childFile(localFs.path.join('.github', 'scripts', scriptName));
      final File dst = repoDir.childFile(localFs.path.join('.github', 'scripts', scriptName));
      dst.parent.createSync(recursive: true);
      src.copySync(dst.path);
      io.Process.runSync('chmod', <String>['+x', dst.path]);
    }

    runGit(<String>['init', '--initial-branch', 'master']);
    runGit(<String>['config', '--local', 'user.email', 'test@example.com']);
    runGit(<String>['config', '--local', 'user.name', 'Test User']);
    runGit(<String>['config', '--local', 'commit.gpgsign', 'false']);
    runGit(<String>['config', '--local', 'core.hooksPath', '/dev/null']);
    commitFiles(<String, String>{
      'DEPS': 'vars = {}',
      'engine/src/flutter/lib/ui/window.dart': '// window v0',
      'packages/flutter/lib/widgets.dart': '// widgets v0',
    }, 'Initial master commit');

    runGit(<String>['remote', 'add', 'origin', repoDir.path]);
    runGit(<String>['fetch', 'origin']);
  });

  tearDown(() {
    final temp = tmpDir;
    tmpDir = null;
    if (temp != null && temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  test('direct master PR with framework-only changes reports changed=false', () {
    final String masterSha = revParse('master');
    runGit(<String>['switch', '-c', 'framework-only']);
    final String headSha = commitFiles(<String, String>{
      'packages/flutter/lib/widgets.dart': '// widgets v1',
    }, 'Framework edit');

    final Map<String, String> out = runResolveEngineChange(<String, String>{
      'EVENT_NAME': 'pull_request',
      'GITHUB_REPOSITORY': 'flutter/flutter',
      'PR_BASE_REF': 'master',
      'PR_BASE_SHA': masterSha,
      'PR_HEAD_SHA': headSha,
    });

    expect(out, <String, String>{'changed': 'false', 'engine_sha': ''});
  });

  test('direct master PR with engine + framework commits reports changed=true and PR head SHA', () {
    final String masterSha = revParse('master');
    runGit(<String>['switch', '-c', 'engine-and-framework']);
    commitFiles(<String, String>{
      'engine/src/flutter/lib/ui/window.dart': '// window v1',
    }, 'Add dart:ui symbol');
    final String headSha = commitFiles(<String, String>{
      'packages/flutter/lib/widgets.dart': '// widgets using v1',
    }, 'Use dart:ui symbol in framework');

    final Map<String, String> out = runResolveEngineChange(<String, String>{
      'EVENT_NAME': 'pull_request',
      'GITHUB_REPOSITORY': 'flutter/flutter',
      'PR_BASE_REF': 'master',
      'PR_BASE_SHA': masterSha,
      'PR_HEAD_SHA': headSha,
    });

    expect(out, <String, String>{'changed': 'true', 'engine_sha': headSha});
  });

  test('stacked child PR touching only packages/ detects ancestor engine SHA', () {
    runGit(<String>['switch', '-c', 's1-framework']);
    commitFiles(<String, String>{'packages/flutter/lib/s1.dart': '// s1'}, 's1 framework prep');

    runGit(<String>['switch', '-c', 's2-engine']);
    final String s2Sha = commitFiles(<String, String>{
      'engine/src/flutter/lib/ui/window.dart': '// window + updateHitTestRegions',
    }, 's2 add dart:ui symbol');

    runGit(<String>['switch', '-c', 's3-framework']);
    final String s3Sha = commitFiles(<String, String>{
      'packages/flutter/lib/widgets.dart': '// call updateHitTestRegions',
    }, 's3 call dart:ui symbol');

    runGit(<String>['switch', '-c', 's4-framework']);
    final String s4Sha = commitFiles(<String, String>{
      'packages/flutter/lib/rendering.dart': '// more framework work',
    }, 's4 more framework work');

    // Verify s3 (--base s2-engine)
    runGit(<String>['checkout', s3Sha]);
    expect(
      runResolveEngineChange(<String, String>{
        'EVENT_NAME': 'pull_request',
        'GITHUB_REPOSITORY': 'flutter/flutter',
        'PR_BASE_REF': 's2-engine',
        'PR_BASE_SHA': s2Sha,
        'PR_HEAD_SHA': s3Sha,
      }),
      <String, String>{'changed': 'true', 'engine_sha': s2Sha},
    );

    // Verify s4 (--base s3-framework) also resolves back to s2Sha
    runGit(<String>['checkout', s4Sha]);
    expect(
      runResolveEngineChange(<String, String>{
        'EVENT_NAME': 'pull_request',
        'GITHUB_REPOSITORY': 'flutter/flutter',
        'PR_BASE_REF': 's3-framework',
        'PR_BASE_SHA': s3Sha,
        'PR_HEAD_SHA': s4Sha,
      }),
      <String, String>{'changed': 'true', 'engine_sha': s2Sha},
    );
  });

  test('stacked child PR with no engine changes anywhere in stack reports changed=false', () {
    runGit(<String>['switch', '-c', 's1-framework']);
    final String s1Sha = commitFiles(<String, String>{
      'packages/flutter/lib/s1.dart': '// s1',
    }, 's1 framework');

    runGit(<String>['switch', '-c', 's2-framework']);
    final String s2Sha = commitFiles(<String, String>{
      'packages/flutter/lib/s2.dart': '// s2',
    }, 's2 framework');

    expect(
      runResolveEngineChange(<String, String>{
        'EVENT_NAME': 'pull_request',
        'GITHUB_REPOSITORY': 'flutter/flutter',
        'PR_BASE_REF': 's1-framework',
        'PR_BASE_SHA': s1Sha,
        'PR_HEAD_SHA': s2Sha,
      }),
      <String, String>{'changed': 'false', 'engine_sha': ''},
    );
  });

  test(
    'fork PR compares against upstream/master rather than stale fork master or stacked base',
    () {
      // Advance upstream/master with an engine commit while leaving fork's origin/master stale.
      runGit(<String>['remote', 'add', 'upstream', repoDir.path]);
      final String staleForkMasterSha = revParse('master');
      commitFiles(<String, String>{
        'engine/src/flutter/lib/ui/window.dart': '// upstream landed engine change',
      }, 'Upstream engine commit');
      runGit(<String>['fetch', 'upstream']);
      // Reset local master + origin/master back to staleForkMasterSha to simulate a lagging fork.
      runGit(<String>['update-ref', 'refs/heads/master', staleForkMasterSha]);
      runGit(<String>['fetch', 'origin']);

      // 1. Framework-only branch off upstream/master targeting stale fork master -> changed=false.
      runGit(<String>['switch', '-c', 'fork-s1', 'upstream/master']);
      final String forkS1Sha = commitFiles(<String, String>{
        'packages/flutter/lib/widgets.dart': '// fork framework edit',
      }, 'Fork s1 framework edit');

      expect(
        runResolveEngineChange(<String, String>{
          'EVENT_NAME': 'pull_request',
          'GITHUB_REPOSITORY': 'user/flutter',
          'PR_BASE_REF': 'master',
          'PR_BASE_SHA': staleForkMasterSha,
          'PR_HEAD_SHA': forkS1Sha,
        }),
        <String, String>{'changed': 'false', 'engine_sha': ''},
      );

      // 2. Stacked engine branch (fork-s2) + framework child branch (fork-s3) -> changed=true.
      runGit(<String>['switch', '-c', 'fork-s2']);
      final String forkS2Sha = commitFiles(<String, String>{
        'engine/src/flutter/lib/ui/window.dart': '// fork dart:ui addition',
      }, 'Fork s2 dart:ui edit');

      runGit(<String>['switch', '-c', 'fork-s3']);
      final String forkS3Sha = commitFiles(<String, String>{
        'packages/flutter/lib/rendering.dart': '// fork framework callsite',
      }, 'Fork s3 framework callsite');

      expect(
        runResolveEngineChange(<String, String>{
          'EVENT_NAME': 'pull_request',
          'GITHUB_REPOSITORY': 'user/flutter',
          'PR_BASE_REF': 'fork-s2',
          'PR_BASE_SHA': forkS2Sha,
          'PR_HEAD_SHA': forkS3Sha,
        }),
        <String, String>{'changed': 'true', 'engine_sha': forkS3Sha},
      );
    },
  );

  test('merge_group event diffs against MERGE_GROUP_BASE_SHA', () {
    final String baseSha = revParse('master');
    runGit(<String>['switch', '-c', 'gh-readonly-queue/master/pr-123']);
    final String headSha = commitFiles(<String, String>{
      'DEPS': 'vars = {"rolled": True}',
    }, 'Merge group commit');

    expect(
      runResolveEngineChange(<String, String>{
        'EVENT_NAME': 'merge_group',
        'MERGE_GROUP_BASE_SHA': baseSha,
        'PR_HEAD_SHA': headSha,
      }),
      <String, String>{'changed': 'true', 'engine_sha': headSha},
    );
  });

  test('release-candidate marker and remote-less workflow_dispatch are handled cleanly', () {
    final String masterSha = revParse('master');
    runGit(<String>['switch', '-c', 'rc-marker']);
    final String headSha = commitFiles(<String, String>{
      'bin/internal/release-candidate-branch.version': 'flutter-3.50-candidate.0',
    }, 'Update release candidate marker');

    expect(
      runResolveEngineChange(<String, String>{
        'EVENT_NAME': 'pull_request',
        'GITHUB_REPOSITORY': 'flutter/flutter',
        'PR_BASE_REF': 'master',
        'PR_BASE_SHA': masterSha,
        'PR_HEAD_SHA': headSha,
      }),
      <String, String>{'changed': 'true', 'engine_sha': headSha},
    );

    // Remove remote tracking refs and verify workflow_dispatch falls back cleanly to HEAD.
    runGit(<String>['remote', 'remove', 'origin']);
    expect(
      runResolveEngineChange(<String, String>{
        'EVENT_NAME': 'workflow_dispatch',
        'PR_HEAD_SHA': headSha,
      }),
      <String, String>{'changed': 'false', 'engine_sha': ''},
    );
  });
}

Directory _findFlutterRoot(FileSystem fs) {
  Directory current = fs.currentDirectory;
  while (!current.childFile('DEPS').existsSync()) {
    if (current.path == current.parent.path) {
      throw StateError('Could not locate Flutter repository root from ${fs.currentDirectory.path}');
    }
    current = current.parent;
  }
  return current;
}
