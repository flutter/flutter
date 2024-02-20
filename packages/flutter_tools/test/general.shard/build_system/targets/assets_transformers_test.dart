// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';
import 'package:flutter_tools/src/cache.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fake_process_manager.dart';

void main() {
  group('asset transformers', () {
    final Artifacts artifacts = Artifacts.test();
    final FileSystem fileSystem = MemoryFileSystem();
    final Platform platform = FakePlatform();
    Cache.flutterRoot = Cache.defaultFlutterRoot(
      platform: platform,
      fileSystem: fileSystem,
      userMessages: UserMessages(),
    );

    final ProcessManager processManager = FakeProcessManager.list(
      <FakeCommand>[
        FakeCommand(
          command: <Pattern>[
            artifacts.getArtifactPath(Artifact.engineDartBinary),
            'run',
            'my_transformer',
            RegExp('--input=.*'),
            RegExp('--output=.*'),
            '-a',
            '-b',
            '--color',
            'green',
          ],
          onRun: (List<String> args) {
            final ArgResults parsedArgs = (ArgParser()
                ..addOption('input')
                ..addOption('output')
                ..addOption('color')
                ..addFlag('aaa', abbr: 'a')
                ..addFlag('bbb', abbr: 'b'))
              .parse(args);

            expect(parsedArgs['aaa'], true);
            expect(parsedArgs['bbb'], true);
            expect(parsedArgs['color'], 'green');

            fileSystem.file(parsedArgs['output']).createSync();
          },
        ),
      ],
    );
    testUsingContext('transforms assets declared with transformers', () async {
      final Environment environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: processManager,
        artifacts: Artifacts.test(),
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: platform,
        defines: <String, String>{},
      );

      await fileSystem.file('.packages').create();

      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('''
name: example
flutter:
  assets:
    - path: input.txt
      transformers:
        - package: my_transformer
          args: ["-a", "-b", "--color", "green"]
''');

      await fileSystem.file('input.txt').create(recursive: true);

      await const CopyAssets().build(environment);

      expect(fileSystem.file('${environment.buildDir.path}/flutter_assets/input.txt'), exists);
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });
  });
}
