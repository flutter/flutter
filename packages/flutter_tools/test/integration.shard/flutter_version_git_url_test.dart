// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/git.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = createResolvedTempDirectorySync('flutter_version_git_url_test.');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  test('FlutterVersion strips credentials expanded by git insteadOf config', () {
    final Directory repoDir = tempDir.childDirectory('flutter')..createSync();
    repoDir.childDirectory('bin').childDirectory('cache').createSync(recursive: true);

    void runGit(List<String> args) {
      final ProcessResult result = processManager.runSync(
        <String>['git', ...args],
        workingDirectory: repoDir.path,
        environment: <String, String>{
          ...platform.environment,
          'GIT_CONFIG_GLOBAL': tempDir.childFile('empty_gitconfig').path,
          'GIT_CONFIG_NOSYSTEM': '1',
        },
      );
      expect(result.exitCode, 0, reason: 'git ${args.join(' ')} failed: ${result.stderr}');
    }

    runGit(<String>['init', '-b', 'master']);
    runGit(<String>['config', 'user.email', 'test@example.com']);
    runGit(<String>['config', 'user.name', 'Test User']);
    runGit(<String>['remote', 'add', 'origin', 'https://github.com/flutter/flutter.git']);
    repoDir.childFile('README.md').writeAsStringSync('test');
    runGit(<String>['add', 'README.md']);
    runGit(<String>['commit', '-m', 'initial']);
    runGit(<String>['tag', '3.32.0']);

    const secretToken = 'ghp_test_secret_token_12345';
    final File globalGitConfig = tempDir.childFile('gitconfig')
      ..writeAsStringSync('''
[url "https://$secretToken@github.com/"]
  insteadOf = https://github.com/
''');

    final env = <String, String>{
      ...platform.environment,
      'GIT_CONFIG_GLOBAL': globalGitConfig.path,
      'GIT_CONFIG_NOSYSTEM': '1',
    };
    final testPlatform = FakePlatform.fromPlatform(platform)..environment = env;
    final logger = BufferLogger.test();
    final git = Git(
      currentPlatform: testPlatform,
      runProcessWith: ProcessUtils(processManager: processManager, logger: logger),
    );

    // Verify git itself expands the insteadOf rule before testing FlutterVersion.
    final String rawUrl = git
        .runSync(<String>['remote', 'get-url', 'origin'], workingDirectory: repoDir.path)
        .stdout
        .trim();
    expect(rawUrl, contains(secretToken));

    final version = FlutterVersion(
      cache: _FakeCache(),
      fs: fileSystem,
      git: git,
      flutterRoot: repoDir.path,
      isOmitLegacyVersionFileEnabled: () => true,
      logger: logger,
      platform: testPlatform,
    );

    expect(version.repositoryUrl, 'https://github.com/flutter/flutter.git');
    expect(version.repositoryUrl, isNot(contains(secretToken)));

    version.ensureVersionFile();
    final String cachedJson = FlutterVersion.getVersionFile(
      fileSystem,
      repoDir.path,
    ).readAsStringSync();
    expect(cachedJson, contains('"repositoryUrl": "https://github.com/flutter/flutter.git"'));
    expect(cachedJson, isNot(contains(secretToken)));
  });
}

class _FakeCache extends Fake implements Cache {
  @override
  String get engineRevision => 'abcdefg';

  @override
  String get devToolsVersion => '2.8.0';

  @override
  String get dartSdkVersion => '3.8.0';
}
