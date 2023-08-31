// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/features.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUp(() {
    Cache.disableLocking();
    Cache.flutterRoot = 'flutter';
  });

  testUsingContext('package_ffi template not enabled', () async {
    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    expect(
      runner.run(
        <String>[
          'create',
          '--no-pub',
          '--template=package_ffi',
          'my_ffi_package',
        ],
      ),
      throwsUsageException(
        message: '"package_ffi" is not an allowed value for option "template"',
      ),
    );
  }, overrides: <Type, Generator>{
    // If we graduate the feature to true by default, don't break this test.
    // ignore: avoid_redundant_argument_values
    FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: false),
  });
}
