import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/net.dart';
import 'package:flutter_tools/src/cache.dart';

import 'context.dart';
import 'fake_http_client.dart';
import 'test_flutter_command_runner.dart';

void main() {
  group('SkillsCommand Tests', () {
    late FileSystem memoryFileSystem;
    late ProcessManager fakeProcessManager;
    late Cache testCache;
    late FakeHttpClient fakeHttpClient;

    const skillsReadme = '''
# Flutter Agent Skills

## Available Skills

| Skill | Description | Example prompt |
|---|---|---|
| [flutter-use-http-package](skills/flutter-use-http-package/SKILL.md) | Use the `http` package to execute GET, POST, PUT, or DELETE requests. Use when you need to fetch from or send data to a REST API. | Use the http package to fetch the list of products from the API |
''';

    const skillContent = '''
---
name: flutter-use-http-package
description: Use the `http` package to execute GET, POST, PUT, or DELETE requests.
---

# Using the HTTP Package

Do the thing.
''';

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
      fakeHttpClient = FakeHttpClient.list(<FakeRequest>[
        FakeRequest(
          Uri.parse('https://raw.githubusercontent.com/flutter/skills/main/README.md'),
          response: FakeResponse(body: skillsReadme.codeUnits),
        ),
        FakeRequest(
          Uri.parse(
            'https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-use-http-package/SKILL.md',
          ),
          response: FakeResponse(body: skillContent.codeUnits),
        ),
      ]);

      // Initialize a standalone test cache locked away from local system state
      testCache = Cache.test(fileSystem: memoryFileSystem, processManager: fakeProcessManager);
    });

    testUsingContext(
      'install subcommand fails if pubspec.yaml is missing',
      () async {
        final args = <String>['skills', 'install', 'flutter-use-http-package'];

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
        HttpClientFactory: () =>
            () => fakeHttpClient,
      },
    );

    testUsingContext(
      'install subcommand successfully writes markdown footprint',
      () async {
        memoryFileSystem.file('pubspec.yaml').createSync();

        final args = <String>['skills', 'install', 'flutter-use-http-package'];

        await createTestCommandRunner().run(args);

        final File targetFile = memoryFileSystem.file(
          '.flutter_skills/flutter-use-http-package.md',
        );
        expect(targetFile.existsSync(), isTrue);
      },
      overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => fakeProcessManager,
        Cache: () => testCache,
        HttpClientFactory: () =>
            () => fakeHttpClient,
      },
    );

    testUsingContext(
      'remove subcommand purges file and sweeps container folder',
      () async {
        memoryFileSystem.file('pubspec.yaml').createSync();

        final File targetFile = memoryFileSystem.file(
          '.flutter_skills/flutter-use-http-package.md',
        );
        targetFile.createSync(recursive: true);

        final args = <String>['skills', 'remove', 'flutter-use-http-package'];

        await createTestCommandRunner().run(args);

        expect(targetFile.existsSync(), isFalse);
        expect(memoryFileSystem.directory('.flutter_skills').existsSync(), isFalse);
      },
      overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => fakeProcessManager,
        Cache: () => testCache,
        HttpClientFactory: () =>
            () => fakeHttpClient,
      },
    );
  });
}
