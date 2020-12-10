// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:dev_tools/codesign.dart';
import 'package:dev_tools/globals.dart';
import 'package:dev_tools/repository.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';

import '../../../packages/flutter_tools/test/src/fake_process_manager.dart';
import './common.dart';

void main() {
  group('codesign command', () {
    const String checkoutsParentDirectory = '/path/to/directory/';
    CommandRunner<void> runner;
    Checkouts checkouts;
    MemoryFileSystem fileSystem;
    FakePlatform platform;
    TestStdio stdio;
    FakeProcessManager processManager;

    void createRunner({
      String operatingSystem = 'macos',
      List<FakeCommand> commands,
    }) {
      stdio = TestStdio();
      fileSystem = MemoryFileSystem.test();
      platform = FakePlatform(operatingSystem: operatingSystem);
      processManager = FakeProcessManager.list(commands ?? <FakeCommand>[]);
      checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      runner = CommandRunner<void>('codesign-test', '')
        ..addCommand(CodesignCommand(checkouts: checkouts));
    }

    test('throws exception if not run from macos', () async {
      createRunner(operatingSystem: 'linux');
      expect(
        () async => await runner.run(<String>['codesign']),
        throwsExceptionWith('Error! Expected operating system "macos"'),
      );
    });

    test('throws exception if verify flag is not provided', () async {
      createRunner();
      expect(
        () async => await runner.run(<String>['codesign']),
        throwsExceptionWith(
          'Sorry, but codesigning is not implemented yet. Please pass the --$kVerify flag to verify signatures'),
      );
    });

    test('blah', () async {
      createRunner(commands: <FakeCommand>[
        const FakeCommand(command: <String>[
          'git',
          'clone',
          '--',
          kUpstreamRemote,
          '${checkoutsParentDirectory}checkouts/framework',
        ])
      ]);
      expect(
        () async => await runner.run(<String>['codesign', '--$kVerify']),
        throwsExceptionWith(
          'Sorry, but codesigning is not implemented yet. Please pass the --$kVerify flag to verify signatures'),
      );
    });

  });
}
