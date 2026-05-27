import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/cache.dart';

import 'context.dart';
import 'test_flutter_command_runner.dart';

void main() {
  group('SkillsCommand Tests', () {
    late FileSystem memoryFileSystem;
    late ProcessManager fakeProcessManager;
    late Cache testCache;

    setUpAll(() {
      Cache.disableLocking();
    });

    tearDownAll(() {
      Cache.enableLocking();
    });

    setUp(() {
      memoryFileSystem = MemoryFileSystem.test();
      // Ensure the tooling layout expectations exist in memory
      memoryFileSystem.directory('bin/cache').createSync(recursive: true);
      fakeProcessManager = FakeProcessManager.any();

      // Initialize a standalone test cache locked away from local system state
      testCache = Cache.test(fileSystem: memoryFileSystem, processManager: fakeProcessManager);
    });

    testUsingContext(
      'install subcommand fails if pubspec.yaml is missing',
      () async {
        final args = <String>['skills', 'install', 'clear_logs_skill'];

        expect(
          () => createTestCommandRunner().run(args),
          throwsA(
            isA<ToolExit>().having(
              (ToolExit e) => e.message,
              'message',
              contains('No pubspec.yaml found'),
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => fakeProcessManager,
        Cache: () => testCache,
      },
    );

    testUsingContext(
      'install subcommand successfully writes markdown footprint',
      () async {
        memoryFileSystem.file('pubspec.yaml').createSync();

        final args = <String>['skills', 'install', 'clear_logs_skill'];

        await createTestCommandRunner().run(args);

        final File targetFile = memoryFileSystem.file('.flutter_skills/clear_logs_skill.md');
        expect(targetFile.existsSync(), isTrue);
      },
      overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => fakeProcessManager,
        Cache: () => testCache,
      },
    );

    testUsingContext(
      'remove subcommand purges file and sweeps container folder',
      () async {
        memoryFileSystem.file('pubspec.yaml').createSync();

        final File targetFile = memoryFileSystem.file('.flutter_skills/clear_logs_skill.md');
        targetFile.createSync(recursive: true);

        final args = <String>['skills', 'remove', 'clear_logs_skill'];

        await createTestCommandRunner().run(args);

        expect(targetFile.existsSync(), isFalse);
        expect(memoryFileSystem.directory('.flutter_skills').existsSync(), isFalse);
      },
      overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => fakeProcessManager,
        Cache: () => testCache,
      },
    );
  });
}
