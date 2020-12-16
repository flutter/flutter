// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'package:dev_tools/codesign.dart' show CodesignCommand;
import 'package:dev_tools/globals.dart' show ConductorException;
import 'package:dev_tools/repository.dart' show Checkouts;
import 'package:dev_tools/stdio.dart' show VerboseStdio;

import './common.dart';

/// Verify all binaries in the Flutter cache are expected by Conductor.
void main() {
  test('validate the expected binaries from the conductor codesign command are present in the cache', () async {
    const Platform platform = LocalPlatform();
    const FileSystem fileSystem = LocalFileSystem();
    const ProcessManager processManager = LocalProcessManager();
    final Checkouts checkouts = Checkouts(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      stdio: VerboseStdio.local(),
    );

    final CommandRunner<void> runner = CommandRunner<void>('codesign-test', '')
        ..addCommand(CodesignCommand(checkouts: checkouts));

    try {
      await runner.run(<String>[
        'codesign',
        '--verify',
        // Only verify if the correct binaries are in the cache
        '--no-signatures',
      ]);
    } on ConductorException {
      print(fixItInstructions);
      rethrow;
    }
  }, onPlatform: <String, dynamic>{
    'windows': const Skip('codesign command is only supported on macos'),
    'linux': const Skip('codesign command is only supported on macos'),
  });
}

const String fixItInstructions = '''
Codesign integration test failed.

This means that the binary files found in the Flutter cache do not match those
expected by the conductor tool (either an expected file was not found in the
cache or an unexpected file was found in the cache).

This usually happens either during an engine roll or a change to the caching
logic in flutter_tools. If this is a valid change, then the conductor source
code should be updated, specifically either the [binariesWithEntitlements] or
[binariesWithoutEntitlements] lists, depending on if the file should have macOS
entitlements applied during codesigning.
''';
