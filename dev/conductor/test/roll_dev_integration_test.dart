// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor/repository.dart';
import 'package:conductor/roll_dev.dart' show rollDev;
import 'package:conductor/version.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import './common.dart';

void main() {
  group('roll-dev', () {
    late TestStdio stdio;
    late Platform platform;
    late ProcessManager processManager;
    late FileSystem fileSystem;
    const String usageString = 'Usage: flutter conductor.';

    late Checkouts checkouts;
    late FrameworkRepository frameworkUpstream;
    late FrameworkRepository framework;
    late Directory tempDir;

    setUp(() {
      platform = const LocalPlatform();
      fileSystem = const LocalFileSystem();
      processManager = const LocalProcessManager();
      stdio = TestStdio(verbose: true);
      tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_conductor_checkouts.');
      checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: tempDir,
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      frameworkUpstream = FrameworkRepository(checkouts, localUpstream: true);

      // This repository has [frameworkUpstream] set as its push/pull remote.
      framework = FrameworkRepository(
        checkouts,
        name: 'test-framework',
        fetchRemote: Remote(name: RemoteName.upstream, url: 'file://${frameworkUpstream.checkoutDirectory.path}/'),
      );
    });

    test('increment m', () {
      final Version initialVersion = framework.flutterVersion();

      final String latestCommit = framework.authorEmptyCommit();

      final FakeArgResults fakeArgResults = FakeArgResults(
        level: 'm',
        commit: latestCommit,
        // Ensure this test passes after a dev release with hotfixes
        force: true,
        remote: 'upstream',
      );

      expect(
        rollDev(
          usage: usageString,
          argResults: fakeArgResults,
          stdio: stdio,
          repository: framework,
        ),
        true,
      );
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
  }, onPlatform: <String, dynamic>{
    'windows': const Skip('Flutter Conductor only supported on macos/linux'),
  });
}
