// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:link_hook/link_hook.dart';
import 'package:test/test.dart';

void main() {
  test('invoke native function', () {
    // Tests are run in debug mode.
    expect(difference(24, 18), 24 - 18);
  });

  test('ffigen-generated file is up-to-date', () async {
    final String packageRoot = File.fromUri(Platform.script).parent.path;
    final ProcessResult result = await Process.run('dart', <String>[
      'run',
      'ffigen',
      '--config',
      'ffigen.yaml',
    ], workingDirectory: packageRoot);
    if (result.exitCode != 0) {
      fail('ffigen failed:\n\n${result.stderr}\n\n${result.stdout}');
    }

    final ProcessResult gitStatus = await Process.run('git', <String>[
      'status',
      '--porcelain',
      'lib/link_hook_bindings_generated.dart',
    ], workingDirectory: packageRoot);
    if (gitStatus.exitCode != 0) {
      fail('git status failed: ${gitStatus.stderr}');
    }

    if (gitStatus.stdout.toString().isNotEmpty) {
      fail(
        'lib/link_hook_bindings_generated.dart is not up to date. '
        'Please run `dart run ffigen --config ffigen.yaml` and commit the changes.',
      );
    }
  });
}
