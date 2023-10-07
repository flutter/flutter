// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/logs.dart';

import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('logs', () {
    setUp(() {
      Cache.disableLocking();
    });

    tearDown(() {
      Cache.enableLocking();
    });

    testUsingContext('fail with a bad device id', () async {
      final LogsCommand command = LogsCommand();
      await expectLater(
        () => createTestCommandRunner(command).run(<String>['-d', 'abc123', 'logs']),
        throwsA(isA<ToolExit>().having((ToolExit error) => error.exitCode, 'exitCode', anyOf(isNull, 1))),
      );
    });
  });
}
