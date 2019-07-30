// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/assemble.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;
  MockBuildSystem mockBuildSystem;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    mockBuildSystem = MockBuildSystem();
    testbed = Testbed(overrides: <Type, Generator>{
      BuildSystem: ()  => mockBuildSystem,
    });
  });

  test('Can run a build', () => testbed.run(() async {
    when(mockBuildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
        .thenAnswer((Invocation invocation) async {
      return BuildResult(true, const <String, ExceptionMeasurement>{}, const <String, PerformanceMeasurement>{});
    });
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());
    await commandRunner.run(<String>['assemble', 'unpack_macos']);
    final BufferLogger bufferLogger = logger;

    expect(bufferLogger.statusText.trim(), 'build succeeded');
  }));
}

class MockBuildSystem extends Mock implements BuildSystem {}
