import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';

import 'package:flutter_conductor/git.dart';
import 'package:flutter_conductor/globals.dart';
import 'package:flutter_conductor/main.dart' show run;
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

    test('integration test', () {
      final Checkouts checkouts = Checkouts(
        platform: platform,
        fileSystem: fileSystem,
        git: git,
        cleanFirst: true,
      );

      final Repository frameworkFakeUpstream = checkouts.addRepo(
        name: 'framework-fake-upstream',
        upstream: kUpstreamRemote,
        git: git,
        stdio: stdio,
        platform: platform,
        fileSystem: fileSystem,
        localUpstream: true,
      );

      final Repository framework = checkouts.addRepo(
        name: 'framework',
        upstream: 'file://${frameworkFakeUpstream.checkoutDirectory.path}/',
        git: git,
        stdio: stdio,
        platform: platform,
        fileSystem: fileSystem,
      );

      final String latestCommit = framework.authorEmptyCommit();

      final FakeArgResults fakeArgResults = FakeArgResults(
        level: 'm',
        commit: latestCommit,
        origin: 'origin',
      );

      run(
        usage: usageString,
        argResults: fakeArgResults,
        stdio: stdio,
        fileSystem: fileSystem,
        platform: platform,
        repository: framework,
      );
    });
  });
}
