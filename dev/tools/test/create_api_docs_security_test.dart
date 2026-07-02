// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:platform/platform.dart';
import 'package:test/test.dart';
import '../../../packages/flutter_tools/test/src/fake_process_manager.dart';
import '../create_api_docs.dart' as apidocs;

void main() {
  test('runPubProcess preserves malicious payload as a single argv token', () async {
    const String payload = '--output=/tmp; echo COMMAND_STUFFING';
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <Pattern>['/flutter/bin/flutter', 'pub', payload],
      ),
    ]);

    final MemoryFileSystem filesystem = MemoryFileSystem.test();
    apidocs.FlutterInformation.instance = apidocs.FlutterInformation(
      platform: FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/flutter'}),
      processManager: processManager,
      filesystem: filesystem,
    );

    await apidocs.runPubProcess(
      arguments: <String>[payload],
      processManager: processManager,
      filesystem: filesystem,
    );

    expect(processManager, hasNoRemainingExpectations);
  });
}
