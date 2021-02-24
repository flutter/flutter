// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert';
import 'dart:io' hide Directory, File;

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/build_system/targets/icon_tree_shaker.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fakes.dart';

final Platform kNoAnsiPlatform = FakePlatform(stdoutSupportsAnsi: false);
const List<int> _kTtfHeaderBytes = <int>[0, 1, 0, 0, 0, 15, 0, 128, 0, 3, 0, 112];

const String inputPath = '/input/fonts/MaterialIcons-Regular.otf';
const String outputPath = '/output/fonts/MaterialIcons-Regular.otf';
const String relativePath = 'fonts/MaterialIcons-Regular.otf';

void main() {
  BufferLogger logger;
  MemoryFileSystem fileSystem;
  MockProcessManager mockProcessManager;
  MockProcess fontSubsetProcess;
  Artifacts artifacts;
  DevFSStringContent fontManifestContent;

  String dartPath;
  String constFinderPath;
  String fontSubsetPath;
  List<String> fontSubsetArgs;

  List<String> _getConstFinderArgs(String appDillPath) => <String>[
    dartPath,
    '--disable-dart-dev',
    constFinderPath,
    '--kernel-file', appDillPath,
    '--class-library-uri', 'package:flutter/src/widgets/icon_data.dart',
    '--class-name', 'IconData',
  ];

  void _addConstFinderInvocation(
    String appDillPath, {
    int exitCode = 0,
    String stdout = '',
    String stderr = '',
  }) {
    when(mockProcessManager.run(_getConstFinderArgs(appDillPath))).thenAnswer((_) async {
      return ProcessResult(0, exitCode, stdout, stderr);
    });
  }

  void _resetFontSubsetInvocation({
    int exitCode = 0,
    String stdout = '',
    String stderr = '',
    @required CompleterIOSink stdinSink,
  }) {
    assert(stdinSink != null);
    stdinSink.writes.clear();
    when(fontSubsetProcess.exitCode).thenAnswer((_) async => exitCode);
    when(fontSubsetProcess.stdout).thenAnswer((_) => Stream<List<int>>.fromIterable(<List<int>>[utf8.encode(stdout)]));
    when(fontSubsetProcess.stderr).thenAnswer((_) => Stream<List<int>>.fromIterable(<List<int>>[utf8.encode(stderr)]));
    when(fontSubsetProcess.stdin).thenReturn(stdinSink);
    when(mockProcessManager.start(fontSubsetArgs)).thenAnswer((_) async {
      return fontSubsetProcess;
    });
  }

  setUp(() {
    fontManifestContent = DevFSStringContent(validFontManifestJson);

    mockProcessManager = MockProcessManager();
    fontSubsetProcess = MockProcess();
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger(
      terminal: AnsiTerminal(
        stdio: FakeStdio(),
        platform: kNoAnsiPlatform,
      ),
      outputPreferences: OutputPreferences.test(showColor: false),
    );

    dartPath = artifacts.getArtifactPath(Artifact.engineDartBinary);
    constFinderPath = artifacts.getArtifactPath(Artifact.constFinder);
    fontSubsetPath = artifacts.getArtifactPath(Artifact.fontSubset);

    fontSubsetArgs = <String>[
      fontSubsetPath,
      outputPath,
      inputPath,
    ];

    fileSystem.file(constFinderPath).createSync(recursive: true);
    fileSystem.file(dartPath).createSync(recursive: true);
    fileSystem.file(fontSubsetPath).createSync(recursive: true);
    fileSystem.file(inputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(_kTtfHeaderBytes);
  });

  Environment _createEnvironment(Map<String, String> defines) {
    return Environment.test(
      fileSystem.directory('/icon_test')..createSync(recursive: true),
      defines: defines,
      artifacts: artifacts,
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );
  }

  testWithoutContext('Prints error in debug mode environment', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'debug',
    });

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      logger.errorText,
      'Font subsetting is not supported in debug mode. The --tree-shake-icons'
      ' flag will be ignored.\n',
    );
    expect(iconTreeShaker.enabled, false);

    final bool subsets = await iconTreeShaker.subsetFont(
      input: fileSystem.file(inputPath),
      outputPath: outputPath,
      relativePath: relativePath,
    );
    expect(subsets, false);

    verifyNever(mockProcessManager.run(any));
    verifyNever(mockProcessManager.start(any));
  });

  testWithoutContext('Does not get enabled without font manifest', () {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      null,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      logger.errorText,
      isEmpty,
    );
    expect(iconTreeShaker.enabled, false);
    verifyNever(mockProcessManager.run(any));
    verifyNever(mockProcessManager.start(any));
  });

  testWithoutContext('Gets enabled', () {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      logger.errorText,
      isEmpty,
    );
    expect(iconTreeShaker.enabled, true);
    verifyNever(mockProcessManager.run(any));
    verifyNever(mockProcessManager.start(any));
  });

  test('No app.dill throws exception', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      () async => await iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );
  });

  testWithoutContext('Can subset a font', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    final CompleterIOSink stdinSink = CompleterIOSink();
    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);
    _resetFontSubsetInvocation(stdinSink: stdinSink);

    bool subsetted = await iconTreeShaker.subsetFont(
      input: fileSystem.file(inputPath),
      outputPath: outputPath,
      relativePath: relativePath,
    );
    expect(stdinSink.writes, <List<int>>[utf8.encode('59470\n')]);
    _resetFontSubsetInvocation(stdinSink: stdinSink);

    expect(subsetted, true);
    subsetted = await iconTreeShaker.subsetFont(
      input: fileSystem.file(inputPath),
      outputPath: outputPath,
      relativePath: relativePath,
    );
    expect(subsetted, true);
    expect(stdinSink.writes, <List<int>>[utf8.encode('59470\n')]);

    verify(mockProcessManager.run(_getConstFinderArgs(appDill.path))).called(1);
    verify(mockProcessManager.start(fontSubsetArgs)).called(2);
  });

  testWithoutContext('Does not subset a non-supported font', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    final CompleterIOSink stdinSink = CompleterIOSink();
    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);
    _resetFontSubsetInvocation(stdinSink: stdinSink);

    final File notAFont = fileSystem.file('input/foo/bar.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('I could not think of a better string');
    final bool subsetted = await iconTreeShaker.subsetFont(
      input: notAFont,
      outputPath: outputPath,
      relativePath: relativePath,
    );
    expect(subsetted, false);

    verifyNever(mockProcessManager.run(_getConstFinderArgs(appDill.path)));
    verifyNever(mockProcessManager.start(fontSubsetArgs));
  });

  testWithoutContext('Does not subset an invalid ttf font', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    final CompleterIOSink stdinSink = CompleterIOSink();
    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);
    _resetFontSubsetInvocation(stdinSink: stdinSink);

    final File notAFont = fileSystem.file(inputPath)
      ..writeAsBytesSync(<int>[0, 1, 2]);
    final bool subsetted = await iconTreeShaker.subsetFont(
      input: notAFont,
      outputPath: outputPath,
      relativePath: relativePath,
    );

    expect(subsetted, false);
    verifyNever(mockProcessManager.run(_getConstFinderArgs(appDill.path)));
    verifyNever(mockProcessManager.start(fontSubsetArgs));
  });

  testWithoutContext('Non-constant instances', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    _addConstFinderInvocation(appDill.path, stdout: constFinderResultWithInvalid);

    await expectLater(
      () async => await iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsToolExit(
        message:
          'Avoid non-constant invocations of IconData or try to build'
          ' again with --no-tree-shake-icons.',
      ),
    );

    verify(mockProcessManager.run(_getConstFinderArgs(appDill.path))).called(1);
    verifyNever(mockProcessManager.start(fontSubsetArgs));
  });

  testWithoutContext('Non-zero font-subset exit code', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);
    fileSystem.file(inputPath).createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    final CompleterIOSink stdinSink = CompleterIOSink();
    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);
    _resetFontSubsetInvocation(exitCode: -1, stdinSink: stdinSink);

    await expectLater(
      () async => await iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );

    verify(mockProcessManager.run(_getConstFinderArgs(appDill.path))).called(1);
    verify(mockProcessManager.start(fontSubsetArgs)).called(1);
  });

  testWithoutContext('font-subset throws on write to sdtin', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    final CompleterIOSink stdinSink = CompleterIOSink(throwOnAdd: true);
    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);
    _resetFontSubsetInvocation(exitCode: -1, stdinSink: stdinSink);

    await expectLater(
      () async => await iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );

    verify(mockProcessManager.run(_getConstFinderArgs(appDill.path))).called(1);
    verify(mockProcessManager.start(fontSubsetArgs)).called(1);
  });

  testWithoutContext('Invalid font manifest', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);

    fontManifestContent = DevFSStringContent(invalidFontManifestJson);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);

    await expectLater(
      () async => await iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );

    verify(mockProcessManager.run(_getConstFinderArgs(appDill.path))).called(1);
    verifyNever(mockProcessManager.start(fontSubsetArgs));
  });

  testWithoutContext('ConstFinder non-zero exit', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);

    fontManifestContent = DevFSStringContent(invalidFontManifestJson);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    _addConstFinderInvocation(appDill.path, exitCode: -1);

    await expectLater(
      () async => await iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );

    verify(mockProcessManager.run(_getConstFinderArgs(appDill.path))).called(1);
    verifyNever(mockProcessManager.start(fontSubsetArgs));
  });
}

const String validConstFinderResult = '''
{
  "constantInstances": [
    {
      "codePoint": 59470,
      "fontFamily": "MaterialIcons",
      "fontPackage": null,
      "matchTextDirection": false
    }
  ],
  "nonConstantLocations": []
}
''';

const String constFinderResultWithInvalid = '''
{
  "constantInstances": [
    {
      "codePoint": 59470,
      "fontFamily": "MaterialIcons",
      "fontPackage": null,
      "matchTextDirection": false
    }
  ],
  "nonConstantLocations": [
    {
      "file": "file:///Path/to/hello_world/lib/file.dart",
      "line": 19,
      "column": 11
    }
  ]
}
''';

const String validFontManifestJson = '''
[
  {
    "family": "MaterialIcons",
    "fonts": [
      {
        "asset": "fonts/MaterialIcons-Regular.otf"
      }
    ]
  },
  {
    "family": "GalleryIcons",
    "fonts": [
      {
        "asset": "packages/flutter_gallery_assets/fonts/private/gallery_icons/GalleryIcons.ttf"
      }
    ]
  },
  {
    "family": "packages/cupertino_icons/CupertinoIcons",
    "fonts": [
      {
        "asset": "packages/cupertino_icons/assets/CupertinoIcons.ttf"
      }
    ]
  }
]
''';

const String invalidFontManifestJson = '''
{
  "famly": "MaterialIcons",
  "fonts": [
    {
      "asset": "fonts/MaterialIcons-Regular.otf"
    }
  ]
}
''';

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
