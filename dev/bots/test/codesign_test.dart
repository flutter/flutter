// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';

import '../../../packages/flutter_tools/test/src/fake_process_manager.dart';
import '../suite_runners/verify_binaries_codesigned.dart';
import './common.dart';

void main() async {
  const String flutterRoot = '/a/b/c';
  late Context ctx;
  late List<String> allExpectedFiles;
  late String allFilesStdout = allExpectedFiles.join('\n');
  late List<String> allExpectedXcframeworks;
  late String allXcframeworksStdout;
  late List<String> withEntitlements;
  late FakeProcessManager processManager;

  setUp(() {
    processManager = FakeProcessManager.empty();
    ctx = Context(
      flutterRoot: flutterRoot,
      printer: (String _) {},
      processManager: processManager,
      fs: MemoryFileSystem.test(),
    );
    allExpectedFiles = ctx.binariesWithEntitlements + ctx.binariesWithoutEntitlements;
    allFilesStdout = allExpectedFiles.join('\n');
    allExpectedXcframeworks = ctx.signedXcframeworks;
    allXcframeworksStdout = allExpectedXcframeworks.join('\n');
    withEntitlements = ctx.binariesWithEntitlements;
  });

  group('verifyExist', () {
    test('Not all files found', () async {
      processManager.addCommands(
        <FakeCommand>[
          const FakeCommand(
            command: <String>[
              'find',
              '/a/b/c/bin/cache',
              '-type',
              'f',
            ],
            stdout: '/a/b/c/bin/cache/artifacts/engine/android-arm-profile/darwin-x64/gen_snapshot',
          ),
          const FakeCommand(
            command: <String>[
              'file',
              '--mime-type',
              '-b',
              '/a/b/c/bin/cache/artifacts/engine/android-arm-profile/darwin-x64/gen_snapshot',
            ],
            stdout: 'application/x-mach-binary',
          ),
        ],
      );
      await expectLater(
        () => ctx.verifyExist(),
        throwsExceptionWith('Did not find all expected binaries!'),
      );
      expect(processManager, hasNoRemainingExpectations);
    });

    test('All files found', () async {
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'find',
            '$flutterRoot/bin/cache',
            '-type',
            'f',
          ],
          stdout: allFilesStdout,
        ),
        ...allExpectedFiles.map((String file) => FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            file,
          ],
          stdout: 'application/x-mach-binary',
        )),
      ]);
      await expectLater(ctx.verifyExist(), completes);
      expect(processManager, hasNoRemainingExpectations);
    });
  });

  group('find paths', () {
    test('All binary files found', () async {
      final FakeCommand findCmd = FakeCommand(
        command: const <String>[
          'find',
          '$flutterRoot/bin/cache',
          '-type',
          'f',],
        stdout: allFilesStdout,
      );
      processManager.addCommand(findCmd);
      for (final String expectedFile in allExpectedFiles) {
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              'file',
              '--mime-type',
              '-b',
              expectedFile,
            ],
            stdout: 'application/x-mach-binary',
          )
        );
      }
      final List<String> foundFiles = await ctx.findBinaryPaths('$flutterRoot/bin/cache');
      expect(foundFiles, allExpectedFiles);
      expect(processManager, hasNoRemainingExpectations);
    });

    test('Empty file list', () async {
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            'find',
            '$flutterRoot/bin/cache',
            '-type',
            'f',
          ],
        ),
      );
      final List<String> foundFiles = await ctx.findBinaryPaths('$flutterRoot/bin/cache');
      expect(foundFiles, isEmpty);
      expect(processManager, hasNoRemainingExpectations);
    });

    test('All xcframeworks files found', () async {
      processManager.addCommand(FakeCommand(
        command: const <String>[
          'find',
          '$flutterRoot/bin/cache',
          '-type',
          'd',
          '-name',
          '*xcframework',
        ],
        stdout: allXcframeworksStdout,
      ));
      final List<String> foundFiles = await ctx.findXcframeworksPaths('$flutterRoot/bin/cache');
      expect(foundFiles, allExpectedXcframeworks);
      expect(processManager, hasNoRemainingExpectations);
    });

    group('isBinary', () {
      test('isTrue', () async {
        const String fileToCheck = '/a/b/c/one.zip';
        const FakeCommand findCmd = FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            fileToCheck,
          ],
          stdout: 'application/x-mach-binary',
        );
        processManager.addCommand(findCmd);
        final bool result = await ctx.isBinary(fileToCheck);
        expect(result, isTrue);
      });

      test('isFalse', () async {
        const String fileToCheck = '/a/b/c/one.zip';
        const FakeCommand findCmd = FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            fileToCheck,
          ],
          stdout: 'text/xml',
        );
        processManager.addCommand(findCmd);
        final bool result = await ctx.isBinary(fileToCheck);
        expect(result, isFalse);
      });
    });

    group('hasExpectedEntitlements', () {
      test('expected entitlements', () async {
        const String fileToCheck = '/a/b/c/one.zip';
        const FakeCommand codesignCmd = FakeCommand(
          command: <String>[
            'codesign',
            '--display',
            '--entitlements',
            ':-',
            fileToCheck,
          ],
        );
        processManager.addCommand(codesignCmd);
        final bool result = await ctx.hasExpectedEntitlements(fileToCheck);
        expect(result, isTrue);
      });

      test('unexpected entitlements', () async {
        const String fileToCheck = '/a/b/c/one.zip';
        const FakeCommand codesignCmd = FakeCommand(
          command: <String>[
            'codesign',
            '--display',
            '--entitlements',
            ':-',
            fileToCheck,
          ],
          exitCode: 1,
        );
        processManager.addCommand(codesignCmd);
        final bool result = await ctx.hasExpectedEntitlements(fileToCheck);
        expect(result, isFalse);
      });
    });
  });

  group('verifySignatures', () {
    test('succeeds if every binary is codesigned and has correct entitlements', () async {
      final FakeCommand findCmd = FakeCommand(
        command: const <String>[
          'find',
          '$flutterRoot/bin/cache',
          '-type',
          'f',
        ],
        stdout: allFilesStdout,
      );
      processManager.addCommand(findCmd);
      for (final String expectedFile in allExpectedFiles) {
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              'file',
              '--mime-type',
              '-b',
              expectedFile,
            ],
            stdout: 'application/x-mach-binary',
          )
        );
      }
      processManager.addCommand(
        FakeCommand(
          command: const <String>[
            'find',
            '$flutterRoot/bin/cache',
            '-type',
            'd',
            '-name',
            '*xcframework',
          ],
          stdout: allXcframeworksStdout,
        ),
      );
      for (final String expectedFile in allExpectedFiles) {
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              'codesign',
              '-vvv',
              expectedFile,
            ],
          )
        );
        if (withEntitlements.contains(expectedFile)) {
          processManager.addCommand(
            FakeCommand(
              command: <String>[
                'codesign',
                '--display',
                '--entitlements',
                ':-',
                expectedFile,
              ],
              stdout: Context.expectedEntitlements.join('\n'),
            )
          );
        }
      }

      for (final String expectedXcframework in allExpectedXcframeworks) {
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              'codesign',
              '-vvv',
              expectedXcframework,
            ],
          )
        );
      }
      await expectLater(ctx.verifySignatures(), completes);
      expect(processManager, hasNoRemainingExpectations);
    });

    test('fails if binaries do not have the right entitlements', () async {
      final FakeCommand findCmd = FakeCommand(
        command: const <String>[
          'find',
          '$flutterRoot/bin/cache',
          '-type',
          'f',
        ],
        stdout: allFilesStdout,
      );
      processManager.addCommand(findCmd);
      for (final String expectedFile in allExpectedFiles) {
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              'file',
              '--mime-type',
              '-b',
              expectedFile,
            ],
            stdout: 'application/x-mach-binary',
          )
        );
      }
      processManager.addCommand(
        FakeCommand(
          command: const <String>[
            'find',
            '$flutterRoot/bin/cache',
            '-type',
            'd',
            '-name',
            '*xcframework',
          ],
          stdout: allXcframeworksStdout,
        ),
      );
      for (final String expectedFile in allExpectedFiles) {
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              'codesign',
              '-vvv',
              expectedFile,
            ],
          )
        );
        if (withEntitlements.contains(expectedFile)) {
          processManager.addCommand(
            FakeCommand(
              command: <String>[
                'codesign',
                '--display',
                '--entitlements',
                ':-',
                expectedFile,
              ],
            )
          );
        }
      }
      for (final String expectedXcframework in allExpectedXcframeworks) {
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              'codesign',
              '-vvv',
              expectedXcframework,
            ],
          )
        );
      }

      expect(
        () async => ctx.verifySignatures(),
        throwsExceptionWith('Test failed because files found with the wrong entitlements'),
      );
    });
  });
}
