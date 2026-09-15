// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/run.dart';
import 'package:flutter_tools/src/device.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  testUsingContext(
    'run --release --trace-systrace propagates traceSystrace to DebuggingOptions',
    () async {
      final command = RunCommand();
      await expectLater(
        () =>
            createTestCommandRunner(command).run(<String>['run', '--release', '--trace-systrace']),
        throwsToolExit(),
      );

      final DebuggingOptions options = await command.createDebuggingOptions();

      // In release mode, traceSystrace should be enabled if requested.
      expect(options.traceSystrace, true);
    },
    overrides: <Type, Generator>{
      Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    },
  );
}
