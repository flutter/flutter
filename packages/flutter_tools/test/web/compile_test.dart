// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/context.dart';

void main() {
  final MockProcessManager mockProcessManager = MockProcessManager();
  final MockProcess mockProcess = MockProcess();
  final BufferLogger mockLogger = BufferLogger();

  testUsingContext('invokes dart2js with correct arguments', () async {
    const WebCompiler webCompiler = WebCompiler();
    final String engineDartPath = artifacts.getArtifactPath(Artifact.engineDartBinary);
    final String dart2jsPath = artifacts.getArtifactPath(Artifact.dart2jsSnapshot);
    final String flutterWebSdkPath = artifacts.getArtifactPath(Artifact.flutterWebSdk);
    final String librariesPath = fs.path.join(flutterWebSdkPath, 'libraries.json');

    when(mockProcess.stdout).thenAnswer((Invocation invocation) => const Stream<List<int>>.empty());
    when(mockProcess.stderr).thenAnswer((Invocation invocation) => const Stream<List<int>>.empty());
    when(mockProcess.exitCode).thenAnswer((Invocation invocation) async => 0);
    when(mockProcessManager.start(any)).thenAnswer((Invocation invocation) async => mockProcess);
    when(mockProcessManager.canRun(engineDartPath)).thenReturn(true);

    await webCompiler.compile(target: 'lib/main.dart');

    final String outputPath = fs.path.join('build', 'web', 'main.dart.js');
    verify(mockProcessManager.start(<String>[
      engineDartPath,
      dart2jsPath,
      'lib/main.dart',
      '-o',
      outputPath,
      '--libraries-spec=$librariesPath',
      '-m',
    ])).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    Logger: () => mockLogger,
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
