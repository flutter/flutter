// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/mocks.dart';
import '../src/testbed.dart';

void main() {
  group(WebCompiler, () {
    MockProcessManager mockProcessManager;
    Testbed testBed;

    setUp(() {
      mockProcessManager = MockProcessManager();
      testBed = Testbed(setup: () async {
        final String engineDartPath = artifacts.getArtifactPath(Artifact.engineDartBinary);
        when(mockProcessManager.start(any)).thenAnswer((Invocation invocation) async => FakeProcess());
        when(mockProcessManager.canRun(engineDartPath)).thenReturn(true);

      }, overrides: <Type, Generator>{
        ProcessManager: () => mockProcessManager,
      });
    });

    test('invokes dart2js with correct arguments', () => testBed.run(() async {
      await webCompiler.compile(target: 'lib/main.dart');

      verify(mockProcessManager.start(<String>[
        'bin/cache/dart-sdk/bin/dart',
        'bin/cache/dart-sdk/bin/snapshots/dart2js.dart.snapshot',
        'lib/main.dart',
        '-o',
        'build/web/main.dart.js',
        '--libraries-spec=bin/cache/flutter_web_sdk/libraries.json',
        '-m',
      ])).called(1);

    }));
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
