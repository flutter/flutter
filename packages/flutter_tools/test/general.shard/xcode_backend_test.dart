// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../../bin/xcode_backend.dart';
import '../src/common.dart';
import '../src/fake_process_manager.dart';

void main() {
  late MemoryFileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem();
  });

  group('build', () {
    test('exits with useful error message when build mode not set', () {
      final Directory buildDir = fileSystem.directory('/path/to/builds')
        ..createSync(recursive: true);
      final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
        ..createSync(recursive: true);
      final File pipe = fileSystem.file('/tmp/pipe')
        ..createSync(recursive: true);
      const String buildMode = 'Debug';
      final TestContext context = TestContext(
        <String>['build'],
        <String, String>{
          'ACTION': 'build',
          'BUILT_PRODUCTS_DIR': buildDir.path,
          'FLUTTER_ROOT': flutterRoot.path,
          'INFOPLIST_PATH': 'Info.plist',
        },
        commands: <FakeCommand>[
          FakeCommand(
            command: <String>[
              '${flutterRoot.path}/bin/flutter',
              'assemble',
              '--no-version-check',
              '--output=${buildDir.path}/',
              '-dTargetPlatform=ios',
              '-dTargetFile=lib/main.dart',
              '-dBuildMode=${buildMode.toLowerCase()}',
              '-dIosArchs=',
              '-dSdkRoot=',
              '-dSplitDebugInfo=',
              '-dTreeShakeIcons=',
              '-dTrackWidgetCreation=',
              '-dDartObfuscation=',
              '-dAction=build',
              '--ExtraGenSnapshotOptions=',
              '--DartDefines=',
              '--ExtraFrontEndOptions=',
              'debug_ios_bundle_flutter_assets',
            ],
          ),
        ],
        fileSystem: fileSystem,
        scriptOutputStreamFile: pipe,
      );
      expect(
          () => context.run(),
          throwsException,
      );
      expect(
        context.stderr,
        contains('ERROR: Unknown FLUTTER_BUILD_MODE: null.\n'),
      );
    });
    test('calls flutter assemble', () {
      final Directory buildDir = fileSystem.directory('/path/to/builds')
        ..createSync(recursive: true);
      final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
        ..createSync(recursive: true);
      final File pipe = fileSystem.file('/tmp/pipe')
        ..createSync(recursive: true);
      const String buildMode = 'Debug';
      final TestContext context = TestContext(
        <String>['build'],
        <String, String>{
          'BUILT_PRODUCTS_DIR': buildDir.path,
          'CONFIGURATION': buildMode,
          'FLUTTER_ROOT': flutterRoot.path,
          'INFOPLIST_PATH': 'Info.plist',
        },
        commands: <FakeCommand>[
          FakeCommand(
            command: <String>[
              '${flutterRoot.path}/bin/flutter',
              'assemble',
              '--no-version-check',
              '--output=${buildDir.path}/',
              '-dTargetPlatform=ios',
              '-dTargetFile=lib/main.dart',
              '-dBuildMode=${buildMode.toLowerCase()}',
              '-dIosArchs=',
              '-dSdkRoot=',
              '-dSplitDebugInfo=',
              '-dTreeShakeIcons=',
              '-dTrackWidgetCreation=',
              '-dDartObfuscation=',
              '-dAction=',
              '--ExtraGenSnapshotOptions=',
              '--DartDefines=',
              '--ExtraFrontEndOptions=',
              'debug_ios_bundle_flutter_assets',
            ],
          ),
        ],
        fileSystem: fileSystem,
        scriptOutputStreamFile: pipe,
      )..run();
      final List<String> streamedLines = pipe.readAsLinesSync();
      // Ensure after line splitting, the exact string 'done' appears
      expect(streamedLines, contains('done'));
      expect(streamedLines, contains(' └─Compiling, linking and signing...'));
      expect(
        context.stdout,
        contains('built and packaged successfully.'),
      );
      expect(context.stderr, isEmpty);
    });

    test('forwards all env variables to flutter assemble', () {
      final Directory buildDir = fileSystem.directory('/path/to/builds')
        ..createSync(recursive: true);
      final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
        ..createSync(recursive: true);
      const String archs = 'arm64';
      const String buildMode = 'Release';
      const String dartObfuscation = 'false';
      const String dartDefines = 'flutter.inspector.structuredErrors%3Dtrue';
      const String expandedCodeSignIdentity = 'F1326572E0B71C3C8442805230CB4B33B708A2E2';
      const String extraFrontEndOptions = '--some-option';
      const String extraGenSnapshotOptions = '--obfuscate';
      const String sdkRoot = '/path/to/sdk';
      const String splitDebugInfo = '/path/to/split/debug/info';
      const String trackWidgetCreation = 'true';
      const String treeShake = 'true';
      final TestContext context = TestContext(
        <String>['build'],
        <String, String>{
          'ACTION': 'install',
          'ARCHS': archs,
          'BUILT_PRODUCTS_DIR': buildDir.path,
          'CODE_SIGNING_REQUIRED': 'YES',
          'CONFIGURATION': buildMode,
          'DART_DEFINES': dartDefines,
          'DART_OBFUSCATION': dartObfuscation,
          'EXPANDED_CODE_SIGN_IDENTITY': expandedCodeSignIdentity,
          'EXTRA_FRONT_END_OPTIONS': extraFrontEndOptions,
          'EXTRA_GEN_SNAPSHOT_OPTIONS': extraGenSnapshotOptions,
          'FLUTTER_ROOT': flutterRoot.path,
          'INFOPLIST_PATH': 'Info.plist',
          'SDKROOT': sdkRoot,
          'SPLIT_DEBUG_INFO': splitDebugInfo,
          'TRACK_WIDGET_CREATION': trackWidgetCreation,
          'TREE_SHAKE_ICONS': treeShake,
        },
        commands: <FakeCommand>[
          FakeCommand(
            command: <String>[
              '${flutterRoot.path}/bin/flutter',
              'assemble',
              '--no-version-check',
              '--output=${buildDir.path}/',
              '-dTargetPlatform=ios',
              '-dTargetFile=lib/main.dart',
              '-dBuildMode=${buildMode.toLowerCase()}',
              '-dIosArchs=$archs',
              '-dSdkRoot=$sdkRoot',
              '-dSplitDebugInfo=$splitDebugInfo',
              '-dTreeShakeIcons=$treeShake',
              '-dTrackWidgetCreation=$trackWidgetCreation',
              '-dDartObfuscation=$dartObfuscation',
              '-dAction=install',
              '--ExtraGenSnapshotOptions=$extraGenSnapshotOptions',
              '--DartDefines=$dartDefines',
              '--ExtraFrontEndOptions=$extraFrontEndOptions',
              '-dCodesignIdentity=$expandedCodeSignIdentity',
              'release_ios_bundle_flutter_assets',
            ],
          ),
        ],
        fileSystem: fileSystem,
      )..run();
      expect(
        context.stdout,
        contains('built and packaged successfully.'),
      );
      expect(context.stderr, isEmpty);
    });
  });

  group('test_observatory_bonjour_service', () {
    test('handles when the Info.plist is missing', () {
      final Directory buildDir = fileSystem.directory('/path/to/builds');
      buildDir.createSync(recursive: true);
      final TestContext context = TestContext(
        <String>['test_observatory_bonjour_service'],
        <String, String>{
          'CONFIGURATION': 'Debug',
          'BUILT_PRODUCTS_DIR': buildDir.path,
          'INFOPLIST_PATH': 'Info.plist',
        },
        commands: <FakeCommand>[],
        fileSystem: fileSystem,
      )..run();
      expect(
        context.stdout,
        contains(
            'Info.plist does not exist. Skipping _dartobservatory._tcp NSBonjourServices insertion.'),
      );
    });
  });
}

class TestContext extends Context {
  TestContext(
    List<String> arguments,
    Map<String, String> environment, {
    required this.fileSystem,
    required List<FakeCommand> commands,
    File? scriptOutputStreamFile,
  })  : processManager = FakeProcessManager.list(commands),
        super(arguments: arguments, environment: environment, scriptOutputStreamFile: scriptOutputStreamFile);

  final FileSystem fileSystem;
  final FakeProcessManager processManager;

  String stdout = '';
  String stderr = '';

  @override
  bool existsDir(String path) {
    return fileSystem.directory(path).existsSync();
  }

  @override
  bool existsFile(String path) {
    return fileSystem.file(path).existsSync();
  }

  @override
  ProcessResult runSync(
    String bin,
    List<String> args, {
    bool verbose = false,
    bool allowFail = false,
    String? workingDirectory,
  }) {
    return processManager.runSync(
      <dynamic>[bin, ...args],
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }

  @override
  void echoError(String message) {
    stderr += '$message\n';
  }

  @override
  void echo(String message) {
    stdout += message;
  }

  @override
  Never exitApp(int code) {
    // This is an exception for the benefit of unit tests.
    // The real implementation calls `exit(code)`.
    throw Exception('App exited with code $code');
  }
}
