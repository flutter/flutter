import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';

import 'package:flutter_conductor/git.dart';
import 'package:flutter_conductor/globals.dart';
import 'package:flutter_conductor/repository.dart';
import 'package:flutter_conductor/stdio.dart';

import './common.dart';

void main() {
  group('test', () {
    Git git;
    Stdio stdio;
    Platform platform;
    FileSystem fileSystem;

    setUp(() {
      git = const Git();
      stdio = VerboseStdio(
        stdout: io.stdout,
        stderr: io.stderr,
        stdin: io.stdin,
      );
      platform = const LocalPlatform();
      fileSystem = const LocalFileSystem();
    });

    test('does things', () {
      final Repository frameworkFakeUpstream = Repository(
        name: 'framework-fake-upstream',
        upstream: kUpstreamRemote,
        git: git,
        stdio: stdio,
        platform: platform,
        fileSystem: fileSystem,
      );

      frameworkFakeUpstream.ensureCloned();

      final Repository framework = Repository(
        name: 'framework',
        upstream: kUpstreamRemote,
        git: git,
        stdio: stdio,
        platform: platform,
        fileSystem: fileSystem,
      );

      framework.ensureCloned();
    });
  });
}
