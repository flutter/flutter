//import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'package:flutter_conductor/roll_dev.dart' show rollDev;
import 'package:flutter_conductor/repository.dart';
import 'package:flutter_conductor/version.dart';

import './common.dart';

void main() {
  group('roll-dev', () {
    TestStdio stdio;
    Platform platform;
    ProcessManager processManager;
    FileSystem fileSystem;
    const String usageString = 'Usage: flutter conductor.';

    Checkouts checkouts;
    Repository frameworkUpstream;
    Repository framework;

    setUpAll(() {
      platform = const LocalPlatform();
      fileSystem = const LocalFileSystem();
      processManager = const LocalProcessManager();
      stdio = TestStdio(verbose: true);
      checkouts = Checkouts(
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
      );

      frameworkUpstream = checkouts.addRepo(
        repoType: RepositoryType.framework,
        name: 'framework-upstream',
        stdio: stdio,
        platform: platform,
        localUpstream: true,
        fileSystem: fileSystem,
        useExistingCheckout: false,
      );

      // This repository has [frameworkUpstream] set as its push/pull remote.
      framework = frameworkUpstream.cloneRepository('test-framework');
    });

    test('increment m', () {
      final Version initialVersion = framework.flutterVersion();

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
      expect(
        stdio.stdout,
        contains(RegExp(r'Publishing Flutter \d+\.\d+\.\d+-\d+\.\d+\.pre \(')),
      );

      final Version finalVersion = framework.flutterVersion();
      expect(
        initialVersion.toString() != finalVersion.toString(),
        true,
        reason: 'initialVersion = $initialVersion; finalVersion = $finalVersion',
      );
      expect(finalVersion.n, 0);
      expect(finalVersion.commits, null);
    });
  });
}
