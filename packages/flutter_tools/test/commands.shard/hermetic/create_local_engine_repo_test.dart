// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/commands/create_local_engine_repo.dart';

import '../../integration.shard/test_utils.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('create_local_engine_repo_test', () {
    late FileSystem fileSystem;
    late Directory tempDir;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      tempDir = createResolvedTempDirectorySync('local_engine_repo.');
    });

    tearDown(() async {
      tryToDelete(tempDir);
    });

    testUsingContext('createLocalEngineRepo', () async {
      const String engineOutPath = 'out/android_release_arm';
      fileSystem.file('$engineOutPath/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem
          .file('$engineOutPath/armeabi_v7a_release.pom')
          .createSync(recursive: true);
      fileSystem
          .file('$engineOutPath/armeabi_v7a_release.jar')
          .createSync(recursive: true);
      fileSystem
          .file('$engineOutPath/armeabi_v7a_release.maven-metadata.xml')
          .createSync(recursive: true);
      fileSystem
          .file('$engineOutPath/flutter_embedding_release.jar')
          .createSync(recursive: true);
      fileSystem
          .file('$engineOutPath/flutter_embedding_release.pom')
          .createSync(recursive: true);
      fileSystem
          .file('$engineOutPath/flutter_embedding_release.maven-metadata.xml')
          .createSync(recursive: true);

      final Directory repoPath = fileSystem.directory('localEngineRepo');
      createLocalEngineRepo(
        engineOutPath: engineOutPath,
        localEngineRepoPath: repoPath.path,
        fileSystem: fileSystem,
      );
      expect(
          repoPath
              .childDirectory('io')
              .childDirectory('flutter')
              .childDirectory('flutter_embedding_release')
              .childDirectory('1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b')
              .childLink(
                  'flutter_embedding_release-1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b.pom')
              .existsSync(),
          true);
      expect(
          repoPath
              .childDirectory('io')
              .childDirectory('flutter')
              .childDirectory('flutter_embedding_release')
              .childDirectory('1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b')
              .childLink(
                  'flutter_embedding_release-1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b.jar')
              .existsSync(),
          true);
      expect(
          repoPath
              .childDirectory('io')
              .childDirectory('flutter')
              .childDirectory('flutter_embedding_release')
              .childLink('maven-metadata.xml')
              .existsSync(),
          true);
      expect(
          repoPath
              .childDirectory('io')
              .childDirectory('flutter')
              .childDirectory('armeabi_v7a_release')
              .childDirectory('1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b')
              .childLink(
                  'armeabi_v7a_release-1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b.pom')
              .existsSync(),
          true);
      expect(
          repoPath
              .childDirectory('io')
              .childDirectory('flutter')
              .childDirectory('armeabi_v7a_release')
              .childDirectory('1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b')
              .childLink(
                  'armeabi_v7a_release-1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b.jar')
              .existsSync(),
          true);
      expect(
          repoPath
              .childDirectory('io')
              .childDirectory('flutter')
              .childDirectory('armeabi_v7a_release')
              .childLink('maven-metadata.xml')
              .existsSync(),
          true);
    });

    testUsingContext('flutter create-local-engine-repo command', () async {
      final CreateLocalEngineRepoCommand command =
          CreateLocalEngineRepoCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>[
        'create-local-engine-repo',
        '--local-repo-path=${tempDir.path}',
        ...getLocalEngineArguments()
      ]);
      expect(
          tempDir.childDirectory('io').childDirectory('flutter').existsSync(),
          true);
    });

    testUsingContext('throws ToolExit when local engine is not specified',
        () async {
      final CreateLocalEngineRepoCommand command =
          CreateLocalEngineRepoCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await expectLater(() async {
        await runner.run(<String>[
          'create-local-engine-repo',
          '--local-repo-path=${tempDir.path}',
        ]);
      },
          throwsToolExit(
            message: 'Local engine is not specified',
          ));
    });
  });
}
