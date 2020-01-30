// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/build_system/targets/font_subset.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/mocks.dart' as mocks;

final Platform _kNoAnsiPlatform =
    FakePlatform.fromPlatform(const LocalPlatform())
      ..stdoutSupportsAnsi = false;

void main() {
  BufferLogger logger;
  MemoryFileSystem fs;
  MockProcessManager mockProcessManager;
  MockArtifacts mockArtifacts;

  const String inputPath = '/input/font.ttf';
  const String outputPath = '/output/font.ttf';
  const String relativePath = 'font.ttf';

  setUp(() {
    mockProcessManager = MockProcessManager();
    fs = MemoryFileSystem();
    mockArtifacts = MockArtifacts();
    logger = BufferLogger(
      terminal: AnsiTerminal(
        stdio: mocks.MockStdio(),
        platform: _kNoAnsiPlatform,
      ),
      outputPreferences: OutputPreferences.test(showColor: false),
    );
  });

  Environment _createEnvironment(Map<String, String> defines) {
    final Directory directory = globals.fs.directory('/does-not-matter');
    return Environment(
      cacheDir: directory,
      flutterRootDir: directory,
      outputDir: directory,
      projectDir: directory,
      buildDir: directory,
      defines: defines,
    );
  }

  test('Prints error in debug mode environment', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kFontSubsetFlag: 'true',
      kBuildMode: 'debug',
    });

    final FontSubset fontSubset = FontSubset(
      environment,
      DevFSStringContent(''),
      logger: logger,
      processManager: mockProcessManager,
      fs: fs,
      artifacts: mockArtifacts,
    );

    expect(
      logger.errorText,
      'Font subetting is not supported in debug mode. The --tree-shake-icons flag will be ignored.\n',
    );
    expect(fontSubset.enabled, false);

    final bool subsets = await fontSubset.subsetFont(
      inputPath: inputPath,
      outputPath: outputPath,
      relativePath: relativePath,
    );
    expect(subsets, false);

    verifyNever(mockProcessManager.run(any));
    verifyNever(mockProcessManager.start(any));
  });

  test('Gets enabled', () {
    final Environment environment = _createEnvironment(<String, String>{
      kFontSubsetFlag: 'true',
      kBuildMode: 'release',
    });

    final FontSubset fontSubset = FontSubset(
      environment,
      DevFSStringContent(''),
      logger: logger,
      processManager: mockProcessManager,
      fs: fs,
      artifacts: mockArtifacts,
    );

    expect(
      logger.errorText,
      isEmpty,
    );
    expect(fontSubset.enabled, true);
    verifyNever(mockProcessManager.run(any));
    verifyNever(mockProcessManager.start(any));
  });

  test('Runs const finder on first call to subsetFont, but not subsequent calls', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kFontSubsetFlag: 'true',
      kBuildMode: 'release',
    });

    fs.file(inputPath).createSync(recursive: true);

    final FontSubset fontSubset = FontSubset(
      environment,
      DevFSStringContent(''),
      logger: logger,
      processManager: mockProcessManager,
      fs: fs,
      artifacts: mockArtifacts,
    );

    final bool subsetted = await fontSubset.subsetFont(
      inputPath: inputPath,
      outputPath: outputPath,
      relativePath: relativePath,
    );

    expect(subsetted, true);
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockArtifacts extends Mock implements Artifacts {}
