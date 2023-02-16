// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/precache.dart';

import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  tearDownAll(() {
    Cache.enableLocking();
  });

  late FakeProcessManager processManager;
  late BufferLogger logger;

  setUp(() {
    processManager = FakeProcessManager.empty();
    logger = BufferLogger.test();
  });

  testUsingContext('foo', () async {
    final PrecacheCommand command = PrecacheCommand(
      cache: Cache.test(processManager: processManager),
      featureFlags: TestFeatureFlags(),
      logger: logger,
      platform: FakePlatform(),
    );
    await createTestCommandRunner(command).run(const <String>[
      'precache',
      '--all-platforms',
      '--force',
    ]);
    print('status: ${logger.statusText}');
    print('trace: ${logger.traceText}');
    print('warning: ${logger.warningText}');
    print('error: ${logger.errorText}');
  }, overrides: <Type, Generator>{
    Logger: () => logger,
  });
}
