// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/build_system/targets/icon_tree_shaker.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/mocks.dart' as mocks;

final Platform _kNoAnsiPlatform = FakePlatform(stdoutSupportsAnsi: false);

void main() {
  BufferLogger logger;
  MemoryFileSystem fs;
  MockProcessManager mockProcessManager;
  MockProcess fontSubsetProcess;
  MockArtifacts mockArtifacts;
  DevFSStringContent fontManifestContent;

  const String dartPath = '/flutter/dart';
  const String constFinderPath = '/flutter/const_finder.snapshot.dart';
  const String fontSubsetPath = '/flutter/font-subset';

  const String inputPath = '/input/fonts/MaterialIcons-Regular.ttf';
  const String outputPath = '/output/fonts/MaterialIcons-Regular.ttf';
  const String relativePath = 'fonts/MaterialIcons-Regular.ttf';

  List<String> getConstFinderArgs(String appDillPath) => <String>[
    dartPath,
    constFinderPath,
    '--kernel-file', appDillPath,
    '--class-library-uri', 'package:flutter/src/widgets/icon_data.dart',
    '--class-name', 'IconData',
  ];

  const List<String> fontSubsetArgs = <String>[
    fontSubsetPath,
    outputPath,
    inputPath,
  ];

  void _addConstFinderInvocation(
    String appDillPath, {
    int exitCode = 0,
    String stdout = '',
    String stderr = '',
  }) {
    when(mockProcessManager.run(getConstFinderArgs(appDillPath))).thenAnswer((_) async {
      return ProcessResult(0, exitCode, stdout, stderr);
    });
  }

  void _resetFontSubsetInvocation({
    int exitCode = 0,
    String stdout = '',
    String stderr = '',
    @required mocks.CompleterIOSink stdinSink,
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
    mockArtifacts = MockArtifacts();

    fs = MemoryFileSystem();
    logger = BufferLogger(
      terminal: AnsiTerminal(
        stdio: mocks.MockStdio(),
        platform: _kNoAnsiPlatform,
      ),
      outputPreferences: OutputPreferences.test(showColor: false),
    );

    fs.file(constFinderPath).createSync(recursive: true);
    fs.file(dartPath).createSync(recursive: true);
    fs.file(fontSubsetPath).createSync(recursive: true);
    when(mockArtifacts.getArtifactPath(Artifact.constFinder)).thenReturn(constFinderPath);
    when(mockArtifacts.getArtifactPath(Artifact.fontSubset)).thenReturn(fontSubsetPath);
    when(mockArtifacts.getArtifactPath(Artifact.engineDartBinary)).thenReturn(dartPath);
  });

  Environment _createEnvironment(Map<String, String> defines) {
    return Environment.test(
      fs.directory('/icon_test')..createSync(recursive: true),
      defines: defines,
      artifacts: mockArtifacts,
      processManager: FakeProcessManager.any(),
      fileSystem: fs,
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
      fileSystem: fs,
      artifacts: mockArtifacts,
    );

    expect(
      logger.errorText,
      'Font subetting is not supported in debug mode. The --tree-shake-icons flag will be ignored.\n',
    );
    expect(iconTreeShaker.enabled, false);

    final bool subsets = await iconTreeShaker.subsetFont(
      inputPath: inputPath,
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
      fileSystem: fs,
      artifacts: mockArtifacts,
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
      fileSystem: fs,
      artifacts: mockArtifacts,
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
      fileSystem: fs,
      artifacts: mockArtifacts,
    );

    expect(
      () => iconTreeShaker.subsetFont(
        inputPath: inputPath,
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );
  });

  testWithoutContext('The happy path', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);
    fs.file(inputPath).createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fs,
      artifacts: mockArtifacts,
    );

    final mocks.CompleterIOSink stdinSink = mocks.CompleterIOSink();
    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);
    _resetFontSubsetInvocation(stdinSink: stdinSink);

    bool subsetted = await iconTreeShaker.subsetFont(
      inputPath: inputPath,
      outputPath: outputPath,
      relativePath: relativePath,
    );
    expect(stdinSink.writes, <List<int>>[utf8.encode('59470\n')]);
    _resetFontSubsetInvocation(stdinSink: stdinSink);

    expect(subsetted, true);
    subsetted = await iconTreeShaker.subsetFont(
      inputPath: inputPath,
      outputPath: outputPath,
      relativePath: relativePath,
    );
    expect(subsetted, true);
    expect(stdinSink.writes, <List<int>>[utf8.encode('59470\n')]);

    verify(mockProcessManager.run(getConstFinderArgs(appDill.path))).called(1);
    verify(mockProcessManager.start(fontSubsetArgs)).called(2);
  });

  testWithoutContext('Non-constant instances', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);
    fs.file(inputPath).createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fs,
      artifacts: mockArtifacts,
    );

    _addConstFinderInvocation(appDill.path, stdout: constFinderResultWithInvalid);

    expect(
      iconTreeShaker.subsetFont(
        inputPath: inputPath,
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsToolExit(
        message: 'Avoid non-constant invocations of IconData or try to build again with --no-tree-shake-icons.',
      ),
    );

    verify(mockProcessManager.run(getConstFinderArgs(appDill.path))).called(1);
    verifyNever(mockProcessManager.start(fontSubsetArgs));
  });

  testWithoutContext('Non-zero font-subset exit code', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);
    fs.file(inputPath).createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fs,
      artifacts: mockArtifacts,
    );

    final mocks.CompleterIOSink stdinSink = mocks.CompleterIOSink();
    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);
    _resetFontSubsetInvocation(exitCode: -1, stdinSink: stdinSink);

    expect(
      iconTreeShaker.subsetFont(
        inputPath: inputPath,
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );

    verify(mockProcessManager.run(getConstFinderArgs(appDill.path))).called(1);
    verifyNever(mockProcessManager.start(fontSubsetArgs));
  });

  testWithoutContext('font-subset throws on write to sdtin', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);
    fs.file(inputPath).createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fs,
      artifacts: mockArtifacts,
    );

    final mocks.CompleterIOSink stdinSink = mocks.CompleterIOSink(throwOnAdd: true);
    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);
    _resetFontSubsetInvocation(exitCode: -1, stdinSink: stdinSink);

    expect(
      iconTreeShaker.subsetFont(
        inputPath: inputPath,
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );

    verify(mockProcessManager.run(getConstFinderArgs(appDill.path))).called(1);
    verifyNever(mockProcessManager.start(fontSubsetArgs));
  });

  testWithoutContext('Invalid font manifest', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);
    fs.file(inputPath).createSync(recursive: true);

    fontManifestContent = DevFSStringContent(invalidFontManifestJson);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fs,
      artifacts: mockArtifacts,
    );

    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);

    expect(
      iconTreeShaker.subsetFont(
        inputPath: inputPath,
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );

    verify(mockProcessManager.run(getConstFinderArgs(appDill.path))).called(1);
    verifyNever(mockProcessManager.start(fontSubsetArgs));
  });

  testWithoutContext('ConstFinder non-zero exit', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);
    fs.file(inputPath).createSync(recursive: true);

    fontManifestContent = DevFSStringContent(invalidFontManifestJson);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: mockProcessManager,
      fileSystem: fs,
      artifacts: mockArtifacts,
    );

    _addConstFinderInvocation(appDill.path, exitCode: -1);

    expect(
      iconTreeShaker.subsetFont(
        inputPath: inputPath,
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );

    verify(mockProcessManager.run(getConstFinderArgs(appDill.path))).called(1);
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
        "asset": "fonts/MaterialIcons-Regular.ttf"
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
      "asset": "fonts/MaterialIcons-Regular.ttf"
    }
  ]
}
''';

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockArtifacts extends Mock implements Artifacts {}
