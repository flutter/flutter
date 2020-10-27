import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';

import 'package:flutter_conductor/git.dart';
import 'package:flutter_conductor/globals.dart';
import 'package:flutter_conductor/roll_dev.dart' show rollDev;
import 'package:flutter_conductor/repository.dart';
import 'package:flutter_conductor/stdio.dart';

import './common.dart';

void main() {
  group('test', () {
    Stdio stdio;
    Platform platform;
    FileSystem fileSystem;
    Git git;
    const String usageString = 'Usage: flutter conductor.';

    setUp(() {
      stdio = VerboseStdio(
        stdout: io.stdout,
        stderr: io.stderr,
        stdin: io.stdin,
      );
      platform = const LocalPlatform();
      fileSystem = const LocalFileSystem();
      git = const Git();
    });

    test('increment m', () {
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        git: git,
        platform: platform,
      );

      final Repository frameworkFakeUpstream = checkouts.addRepo(
        repoType: RepositoryType.framework,
        name: 'framework-fake-upstream',
        git: git,
        stdio: stdio,
        platform: platform,
        localUpstream: true,
        fileSystem: fileSystem,
      );

      final Repository framework =
          frameworkFakeUpstream.cloneRepository('test-framework');
      //final Repository framework = Repository(
      //  name: 'framework',
      //  upstream: 'file://${frameworkFakeUpstream.checkoutDirectory.path}/',
      //  git: git,
      //  stdio: stdio,
      //  parentDirectory: parentDirectory,
      //  platform: platform,
      //  fileSystem: fileSystem,
      //  localUpstream: true,
      //);

      final String latestCommit = framework.authorEmptyCommit();

      final FakeArgResults fakeArgResults = FakeArgResults(
        level: 'm',
        commit: latestCommit,
        remote: 'origin',
      );

      final bool success = rollDev(
        usage: usageString,
        argResults: fakeArgResults,
        stdio: stdio,
        fileSystem: fileSystem,
        platform: platform,
        repository: framework,
      );
      expect(success, true);
    });
  });
}
