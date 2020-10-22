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
    const String usageString = 'Usage: flutter conductor.';

    setUp(() {
      stdio = VerboseStdio(
        stdout: io.stdout,
        stderr: io.stderr,
        stdin: io.stdin,
      );
      platform = const LocalPlatform();
      fileSystem = const LocalFileSystem();
    });

    test('integration test', () {
      final Repository frameworkFakeUpstream = Repository(
        name: 'framework-fake-upstream',
        upstream: kUpstreamRemote,
        git: Git(kUpstreamRemote),
        stdio: stdio,
        platform: platform,
        fileSystem: fileSystem,
      );

      final Repository framework = Repository(
        name: 'framework',
        upstream: frameworkFakeUpstream.directory.path,
        git: Git(frameworkFakeUpstream.directory.path),
        stdio: stdio,
        platform: platform,
        fileSystem: fileSystem,
      );

      final FakeArgResults fakeArgResults = FakeArgResults(
        level: 'm',
        commit: 'abc123',
        origin: 'origin',
        justPrint: true,
      );

      run(
        usage: usageString,
        argResults: fakeArgResults,
        git: git,
        stdio: stdio,
        fileSystem: fileSystem,
        platform: platform,
        repository: framework,
      );
    });
  });
}
