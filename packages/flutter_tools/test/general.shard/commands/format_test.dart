// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/commands/format.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  testUsingContext('flutter format forward all arguments to dart format and '
    'prints deprecation warning', () async {
    final CommandRunner<void> runner = CommandRunner<void>('flutter', 'test')
      ..addCommand(FormatCommand());
    await runner.run(<String>['format', 'a', 'b', 'c']);

    expect(testLogger.errorText, contains('"flutter format" is deprecated'));
    expect((globals.processManager as FakeProcessManager).hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
          'format',
          'a',
          'b',
          'c',
        ],
      )
    ])
  });
}
