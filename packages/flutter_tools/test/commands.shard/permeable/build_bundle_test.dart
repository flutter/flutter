// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/bundle.dart';
import 'package:flutter_tools/src/bundle_builder.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_bundle.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  Cache.disableLocking();
  late Directory tempDir;
  late FakeBundleBuilder fakeBundleBuilder;
  final FileSystemStyle fileSystemStyle = globals.fs.path.separator == '/' ?
    FileSystemStyle.posix : FileSystemStyle.windows;

  setUp(() {
    tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');

    fakeBundleBuilder = FakeBundleBuilder();
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  MemoryFileSystem fsFactory() {
    return MemoryFileSystem.test(style: fileSystemStyle);
  }

  Future<BuildBundleCommand> runCommandIn(String projectPath, { List<String>? arguments }) async {
    final BuildBundleCommand command = BuildBundleCommand(
        logger: BufferLogger.test(),
        bundleBuilder: fakeBundleBuilder,
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>[
      'bundle',
      ...?arguments,
      '--target=$projectPath/lib/main.dart',
      '--no-pub',
    ]);
    return command;
  }

  testUsingContext('bundle getUsage indicate that project is a module', () async {
    final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);

    final BuildBundleCommand command = await runCommandIn(projectPath);

    expect((await command.usageValues).commandBuildBundleIsModule, true);
  });

  testUsingContext('bundle getUsage indicate that project is not a module', () async {
    final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=app']);

    final BuildBundleCommand command = await runCommandIn(projectPath);

    expect((await command.usageValues).commandBuildBundleIsModule, false);
  });

  testUsingContext('bundle getUsage indicate the target platform', () async {
    final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=app']);

    final BuildBundleCommand command = await runCommandIn(projectPath);

    expect((await command.usageValues).commandBuildBundleTargetPlatform, 'android-arm');
  });

  testUsingContext('bundle fails to build for Windows if feature is disabled', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync(recursive: true);
    globals.fs.file('.packages').createSync(recursive: true);
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    expect(() => runner.run(<String>[
      'bundle',
      '--no-pub',
      '--target-platform=windows-x64',
    ]), throwsToolExit(message: 'Windows is not a supported target platform.'));
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(),
  });

  testUsingContext('bundle fails to build for Linux if feature is disabled', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    expect(() => runner.run(<String>[
      'bundle',
      '--no-pub',
      '--target-platform=linux-x64',
    ]), throwsToolExit(message: 'Linux is not a supported target platform.'));
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(),
  });

  testUsingContext('bundle fails to build for macOS if feature is disabled', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    expect(() => runner.run(<String>[
      'bundle',
      '--no-pub',
      '--target-platform=darwin',
    ]), throwsToolExit(message: 'macOS is not a supported target platform.'));
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(),
  });

  testUsingContext('bundle --tree-shake-icons fails', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    expect(() => runner.run(<String>[
      'bundle',
      '--no-pub',
      '--release',
      '--tree-shake-icons',
    ]), throwsToolExit(message: 'tree-shake-icons'));
  }, overrides: <Type, Generator>{
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('bundle can build for Windows if feature is enabled', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--target-platform=windows-x64',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('bundle can build for Linux if feature is enabled', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--target-platform=linux-x64',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('bundle can build for macOS if feature is enabled', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--target-platform=darwin',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('passes track widget creation through', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--debug',
      '--target-platform=android-arm',
      '--track-widget-creation',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
      expect(environment.defines, <String, String>{
        kBuildMode: 'debug',
        kTargetPlatform: 'android-arm',
        kTargetFile: globals.fs.path.join('lib', 'main.dart'),
        kTrackWidgetCreation: 'true',
        kFileSystemScheme: 'org-dartlang-root',
        kIconTreeShakerFlag: 'false',
        kDeferredComponents: 'false',
        kDartObfuscation: 'false',
      });
    }),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('passes dart-define through', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--debug',
      '--target-platform=android-arm',
      '--dart-define=foo=bar',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
      expect(environment.defines, <String, String>{
        kBuildMode: 'debug',
        kTargetPlatform: 'android-arm',
        kTargetFile: globals.fs.path.join('lib', 'main.dart'),
        kTrackWidgetCreation: 'true',
        kFileSystemScheme: 'org-dartlang-root',
        kDartDefines: 'Zm9vPWJhcg==',
        kIconTreeShakerFlag: 'false',
        kDeferredComponents: 'false',
        kDartObfuscation: 'false',
      });
    }),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('passes filesystem-scheme through', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--debug',
      '--target-platform=android-arm',
      '--filesystem-scheme=org-dartlang-root2',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
      expect(environment.defines, <String, String>{
        kBuildMode: 'debug',
        kTargetPlatform: 'android-arm',
        kTargetFile: globals.fs.path.join('lib', 'main.dart'),
        kTrackWidgetCreation: 'true',
        kFileSystemScheme: 'org-dartlang-root2',
        kIconTreeShakerFlag: 'false',
        kDeferredComponents: 'false',
        kDartObfuscation: 'false',
      });
    }),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('passes filesystem-roots through', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--debug',
      '--target-platform=android-arm',
      '--filesystem-root=test1,test2',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
      expect(environment.defines, <String, String>{
        kBuildMode: 'debug',
        kTargetPlatform: 'android-arm',
        kTargetFile: globals.fs.path.join('lib', 'main.dart'),
        kTrackWidgetCreation: 'true',
        kFileSystemScheme: 'org-dartlang-root',
        kFileSystemRoots: 'test1,test2',
        kIconTreeShakerFlag: 'false',
        kDeferredComponents: 'false',
        kDartObfuscation: 'false',
      });
    }),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('passes extra frontend-options through', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--debug',
      '--target-platform=android-arm',
      '--extra-front-end-options=--testflag,--testflag2',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
      expect(environment.defines, <String, String>{
        kBuildMode: 'debug',
        kTargetPlatform: 'android-arm',
        kTargetFile: globals.fs.path.join('lib', 'main.dart'),
        kTrackWidgetCreation: 'true',
        kFileSystemScheme: 'org-dartlang-root',
        kExtraFrontEndOptions: '--testflag,--testflag2',
        kIconTreeShakerFlag: 'false',
        kDeferredComponents: 'false',
        kDartObfuscation: 'false',
      });
    }),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('passes extra gen_snapshot-options through', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--debug',
      '--target-platform=android-arm',
      '--extra-gen-snapshot-options=--testflag,--testflag2',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
      expect(environment.defines, <String, String>{
        kBuildMode: 'debug',
        kTargetPlatform: 'android-arm',
        kTargetFile: globals.fs.path.join('lib', 'main.dart'),
        kTrackWidgetCreation: 'true',
        kFileSystemScheme: 'org-dartlang-root',
        kExtraGenSnapshotOptions: '--testflag,--testflag2',
        kIconTreeShakerFlag: 'false',
        kDeferredComponents: 'false',
        kDartObfuscation: 'false',
      });
    }),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('passes profile options through', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--profile',
      '--dart-define=foo=bar',
      '--target-platform=android-arm',
      '--track-widget-creation',
      '--filesystem-scheme=org-dartlang-root',
      '--filesystem-root=test1,test2',
      '--extra-gen-snapshot-options=--testflag,--testflag2',
      '--extra-front-end-options=--testflagFront,--testflagFront2',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
      expect(environment.defines, <String, String>{
        kBuildMode: 'profile',
        kTargetPlatform: 'android-arm',
        kTargetFile: globals.fs.path.join('lib', 'main.dart'),
        kDartDefines: 'Zm9vPWJhcg==',
        kTrackWidgetCreation: 'true',
        kFileSystemScheme: 'org-dartlang-root',
        kFileSystemRoots: 'test1,test2',
        kExtraGenSnapshotOptions: '--testflag,--testflag2',
        kExtraFrontEndOptions: '--testflagFront,--testflagFront2',
        kIconTreeShakerFlag: 'false',
        kDeferredComponents: 'false',
        kDartObfuscation: 'false',
      });
    }),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('passes release options through', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--release',
      '--dart-define=foo=bar',
      '--target-platform=android-arm',
      '--track-widget-creation',
      '--filesystem-scheme=org-dartlang-root',
      '--filesystem-root=test1,test2',
      '--extra-gen-snapshot-options=--testflag,--testflag2',
      '--extra-front-end-options=--testflagFront,--testflagFront2',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
      expect(environment.defines, <String, String>{
        kBuildMode: 'release',
        kTargetPlatform: 'android-arm',
        kTargetFile: globals.fs.path.join('lib', 'main.dart'),
        kDartDefines: 'Zm9vPWJhcg==',
        kTrackWidgetCreation: 'true',
        kFileSystemScheme: 'org-dartlang-root',
        kFileSystemRoots: 'test1,test2',
        kExtraGenSnapshotOptions: '--testflag,--testflag2',
        kExtraFrontEndOptions: '--testflagFront,--testflagFront2',
        kIconTreeShakerFlag: 'false',
        kDeferredComponents: 'false',
        kDartObfuscation: 'false',
      });
    }),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('--dart-define-from-file successfully forwards values to build env', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    await globals.fs.file('config1.json').writeAsString(
      '''
        {
          "kInt": 1,
          "kDouble": 1.1,
          "name": "denghaizhu",
          "title": "this is title from config json file",
          "nullValue": null,
          "containEqual": "sfadsfv=432f"
        }
      '''
    );
    await globals.fs.file('config2.json').writeAsString(
        '''
        {
          "body": "this is body from config json file"
        }
      '''
    );
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--dart-define-from-file=config1.json',
      '--dart-define-from-file=config2.json',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
      expect(
        _decodeDartDefines(environment),
        containsAllInOrder(const <String>[
          'kInt=1',
          'kDouble=1.1',
          'name=denghaizhu',
          'title=this is title from config json file',
          'nullValue=null',
          'containEqual=sfadsfv=432f',
          'body=this is body from config json file',
        ]),
      );
    }),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('values from --dart-define supersede values from --dart-define-from-file', () async {
    globals.fs
        .file(globals.fs.path.join('lib', 'main.dart'))
        .createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    globals.fs.file('.env').writeAsStringSync('''
        MY_VALUE=VALUE_FROM_ENV_FILE
      ''');
    final CommandRunner<void> runner =
        createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--dart-define=MY_VALUE=VALUE_FROM_COMMAND',
      '--dart-define-from-file=.env',
    ]);

  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true),
            (Target target, Environment environment) {
          expect(
            _decodeDartDefines(environment),
            containsAllInOrder(const <String>[
              'MY_VALUE=VALUE_FROM_ENV_FILE',
              'MY_VALUE=VALUE_FROM_COMMAND',
            ]),
          );
        }),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('--dart-define-from-file correctly parses a valid env file', () async {
    globals.fs
        .file(globals.fs.path.join('lib', 'main.dart'))
        .createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    await globals.fs.file('.env').writeAsString('''
        # comment
        kInt=1
        kDouble=1.1 # should be double

        name=piotrfleury
        title=this is title from config env file
        empty=

        doubleQuotes="double quotes 'value'#=" # double quotes
        singleQuotes='single quotes "value"#=' # single quotes
        backQuotes=`back quotes "value" '#=` # back quotes

        hashString="some-#-hash-string-value"

        # Play around with spaces around the equals sign.
        spaceBeforeEqual =value
        spaceAroundEqual = value
        spaceAfterEqual= value

      ''');
    await globals.fs.file('.env2').writeAsString('''
        # second comment

        body=this is body from config env file
      ''');
    final CommandRunner<void> runner =
        createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--dart-define-from-file=.env',
      '--dart-define-from-file=.env2',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true),
            (Target target, Environment environment) {
          expect(
            _decodeDartDefines(environment),
            containsAllInOrder(const <String>[
              'kInt=1',
              'kDouble=1.1',
              'name=piotrfleury',
              'title=this is title from config env file',
              'empty=',
              "doubleQuotes=double quotes 'value'#=",
              'singleQuotes=single quotes "value"#=',
              'backQuotes=back quotes "value" \'#=',
              'hashString=some-#-hash-string-value',
              'spaceBeforeEqual=value',
              'spaceAroundEqual=value',
              'spaceAfterEqual=value',
              'body=this is body from config env file'
            ]),
          );
        }),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('--dart-define-from-file option env file throws a ToolExit when .env file contains a multiline value', () async {
    globals.fs
        .file(globals.fs.path.join('lib', 'main.dart'))
        .createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    await globals.fs.file('.env').writeAsString('''
        # single line value
        name=piotrfleury

        # multi-line value
        multiline = """ Welcome to .env demo
        a simple counter app with .env file support
        for more info, check out the README.md file
        Thanks! """ # This is the welcome message that will be displayed on the counter app

      ''');
    final CommandRunner<void> runner =
        createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    expect(() => runner.run(<String>[
      'bundle',
      '--no-pub',
      '--dart-define-from-file=.env',
    ]), throwsToolExit(message: 'Multi-line value is not supported: multiline = """ Welcome to .env demo'));
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('--dart-define-from-file option works with mixed file formats',
      () async {
    globals.fs
        .file(globals.fs.path.join('lib', 'main.dart'))
        .createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    await globals.fs.file('.env').writeAsString('''
        kInt=1
        kDouble=1.1
        name=piotrfleury
        title=this is title from config env file
      ''');
    await globals.fs.file('config.json').writeAsString('''
        {
          "body": "this is body from config json file"
        }
      ''');
    final CommandRunner<void> runner =
        createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--dart-define-from-file=.env',
      '--dart-define-from-file=config.json',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true),
            (Target target, Environment environment) {
          expect(
            _decodeDartDefines(environment),
            containsAllInOrder(const <String>[
              'kInt=1',
              'kDouble=1.1',
              'name=piotrfleury',
              'title=this is title from config env file',
              'body=this is body from config json file',
            ]),
          );
        }),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('test --dart-define-from-file option if conflict', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    await globals.fs.file('config1.json').writeAsString(
        '''
        {
          "kInt": 1,
          "kDouble": 1.1,
          "name": "denghaizhu",
          "title": "this is title from config json file"
        }
      '''
    );
    await globals.fs.file('config2.json').writeAsString(
        '''
        {
          "kInt": "2"
        }
      '''
    );
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--dart-define-from-file=config1.json',
      '--dart-define-from-file=config2.json',
    ]);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
      expect(
        _decodeDartDefines(environment),
        containsAllInOrder(<String>['kInt=2', 'kDouble=1.1', 'name=denghaizhu', 'title=this is title from config json file']),
      );
    }),
    FileSystem: fsFactory,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('test --dart-define-from-file option by invalid file type', () {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    globals.fs.directory('config').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    expect(() => runner.run(<String>[
      'bundle',
      '--no-pub',
      '--dart-define-from-file=config',
    ]), throwsToolExit(message: 'Did not find the file passed to "--dart-define-from-file". Path: config'));
  }, overrides: <Type, Generator>{
    FileSystem: fsFactory,
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('test --dart-define-from-file option by corrupted json', () async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    await globals.fs.file('config.json').writeAsString(
        '''
        {
          "kInt": 1Error json format
          "kDouble": 1.1,
          "name": "denghaizhu",
          "title": "this is title from config json file"
        }
      '''
    );
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand(
      logger: BufferLogger.test(),
    ));

    expect(() => runner.run(<String>[
      'bundle',
      '--no-pub',
      '--dart-define-from-file=config.json',
    ]), throwsToolExit(message: 'Json config define file "--dart-define-from-file=config.json" format err'));
  }, overrides: <Type, Generator>{
    FileSystem: fsFactory,
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
    ProcessManager: () => FakeProcessManager.any(),
  });
}

Iterable<String> _decodeDartDefines(Environment environment) {
  final String encodedDefines = environment.defines[kDartDefines]!;
  const Utf8Decoder byteDecoder = Utf8Decoder();
  return encodedDefines
      .split(',')
      .map<Uint8List>(base64.decode)
      .map<String>(byteDecoder.convert);
}

class FakeBundleBuilder extends Fake implements BundleBuilder {
  @override
  Future<void> build({
    required TargetPlatform platform,
    required BuildInfo buildInfo,
    FlutterProject? project,
    String? mainPath,
    String manifestPath = defaultManifestPath,
    String? applicationKernelFilePath,
    String? depfilePath,
    String? assetDirPath,
    Uri? nativeAssets,
    @visibleForTesting BuildSystem? buildSystem,
  }) async {}
}
