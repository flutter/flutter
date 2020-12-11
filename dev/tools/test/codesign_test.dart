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
    const String flutterCache =
        '${checkoutsParentDirectory}checkouts/framework/bin/cache';
    const String flutterBin =
        '${checkoutsParentDirectory}checkouts/framework/bin/flutter';
    const String revision = 'abcd1234';
    CommandRunner<void> runner;
    Checkouts checkouts;
    MemoryFileSystem fileSystem;
    FakePlatform platform;
    TestStdio stdio;
    FakeProcessManager processManager;
    const List<String> cachedBinaries = <String>[
      '$flutterCache/dart',
      '$flutterCache/dartaotruntime',
    ];

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

    test('succeeds if every binary is codesigned and has correct entitlements', () async {
      final List<FakeCommand> codesignCheckCommands = <FakeCommand>[];
      for (final String bin in cachedBinaries) {
        codesignCheckCommands.add(
          FakeCommand(
            command: <String>['codesign', '-vvv', bin],
          ),
        );
        codesignCheckCommands.add(
          FakeCommand(
            command: <String>['codesign', '--display', '--entitlements', ':-', bin],
            stdout: expectedEntitlements.join('\n'),
          )
        );
      }
      createRunner(commands: <FakeCommand>[
        const FakeCommand(command: <String>[
          'git',
          'clone',
          '--',
          kUpstreamRemote,
          '${checkoutsParentDirectory}checkouts/framework',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'checkout',
          revision,
        ]),
        const FakeCommand(command: <String>[
          flutterBin,
          'help',
        ]),
        const FakeCommand(command: <String>[
          flutterBin,
          'help',
        ]),
        const FakeCommand(command: <String>[
          flutterBin,
          'precache',
          '--ios',
          '--macos',
        ]),
        FakeCommand(
          command: const <String>[
            'find',
            '${checkoutsParentDirectory}checkouts/framework/bin/cache',
            '-type',
            'f',
            '-perm',
            '+111',
          ],
          stdout: cachedBinaries.join('\n'),
        ),
        for (String bin in cachedBinaries)
          FakeCommand(
            command: <String>['file', '--mime-type', '-b', bin],
            stdout: 'application/x-mach-binary',
          ),
        ...codesignCheckCommands,
      ]);
      await runner.run(<String>['codesign', '--$kVerify', '--$kRevision', revision]);
    });

    test('fails if a single binary is not codesigned', () async {
      final List<FakeCommand> codesignCheckCommands = <FakeCommand>[];
      codesignCheckCommands.add(
        const FakeCommand(
          command: <String>['codesign', '-vvv', '$flutterCache/dart'],
        ),
      );
      codesignCheckCommands.add(
        FakeCommand(
          command: const <String>['codesign', '--display', '--entitlements', ':-', '$flutterCache/dart'],
          stdout: expectedEntitlements.join('\n'),
        )
      );
      // Not signed
      codesignCheckCommands.add(
        const FakeCommand(
          command: <String>['codesign', '-vvv', '$flutterCache/dartaotruntime'],
          exitCode: 1,
        ),
      );
      codesignCheckCommands.add(
        FakeCommand(
          command: const <String>['codesign', '--display', '--entitlements', ':-', '$flutterCache/dartaotruntime'],
          stdout: expectedEntitlements.join('\n'),
        )
      );
      createRunner(commands: <FakeCommand>[
        const FakeCommand(command: <String>[
          'git',
          'clone',
          '--',
          kUpstreamRemote,
          '${checkoutsParentDirectory}checkouts/framework',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'checkout',
          revision,
        ]),
        const FakeCommand(command: <String>[
          flutterBin,
          'help',
        ]),
        const FakeCommand(command: <String>[
          flutterBin,
          'help',
        ]),
        const FakeCommand(command: <String>[
          flutterBin,
          'precache',
          '--ios',
          '--macos',
        ]),
        FakeCommand(
          command: const <String>[
            'find',
            '${checkoutsParentDirectory}checkouts/framework/bin/cache',
            '-type',
            'f',
            '-perm',
            '+111',
          ],
          stdout: cachedBinaries.join('\n'),
        ),
        for (String bin in cachedBinaries)
          FakeCommand(
            command: <String>['file', '--mime-type', '-b', bin],
            stdout: 'application/x-mach-binary',
          ),
        ...codesignCheckCommands,
      ]);
      expect(
        () async => await runner.run(<String>['codesign', '--$kVerify', '--$kRevision', revision]),
        throwsExceptionWith('Test failed because unsigned binaries detected.'),
      );
    });

    test('fails if a single binary has the wrong entitlements', () async {
      final List<FakeCommand> codesignCheckCommands = <FakeCommand>[];
      codesignCheckCommands.add(
        const FakeCommand(
          command: <String>['codesign', '-vvv', '$flutterCache/dart'],
        ),
      );
      codesignCheckCommands.add(
        FakeCommand(
          command: const <String>['codesign', '--display', '--entitlements', ':-', '$flutterCache/dart'],
          stdout: expectedEntitlements.join('\n'),
        )
      );
      codesignCheckCommands.add(
        const FakeCommand(
          command: <String>['codesign', '-vvv', '$flutterCache/dartaotruntime'],
        ),
      );
      // No entitlements
      codesignCheckCommands.add(
        const FakeCommand(
          command: <String>['codesign', '--display', '--entitlements', ':-', '$flutterCache/dartaotruntime'],
        )
      );
      createRunner(commands: <FakeCommand>[
        const FakeCommand(command: <String>[
          'git',
          'clone',
          '--',
          kUpstreamRemote,
          '${checkoutsParentDirectory}checkouts/framework',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'checkout',
          revision,
        ]),
        const FakeCommand(command: <String>[
          flutterBin,
          'help',
        ]),
        const FakeCommand(command: <String>[
          flutterBin,
          'help',
        ]),
        const FakeCommand(command: <String>[
          flutterBin,
          'precache',
          '--ios',
          '--macos',
        ]),
        FakeCommand(
          command: const <String>[
            'find',
            '${checkoutsParentDirectory}checkouts/framework/bin/cache',
            '-type',
            'f',
            '-perm',
            '+111',
          ],
          stdout: cachedBinaries.join('\n'),
        ),
        for (String bin in cachedBinaries)
          FakeCommand(
            command: <String>['file', '--mime-type', '-b', bin],
            stdout: 'application/x-mach-binary',
          ),
        ...codesignCheckCommands,
      ]);
      expect(
        () async => await runner.run(<String>['codesign', '--$kVerify', '--$kRevision', revision]),
        throwsExceptionWith('Test failed because files found with the wrong entitlements'),
      );
    });
  });
}
