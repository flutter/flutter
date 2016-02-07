// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/commands/logs.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:test/test.dart';

import 'src/mocks.dart';
import 'src/test_context.dart';

main() => defineTests();

defineTests() {
  group('logs', () {
    testUsingContext('fail with a bad device id', () {
      LogsCommand command = new LogsCommand();
      applyMocksToCommand(command);
      CommandRunner runner = new FlutterCommandRunner()..addCommand(command);
      return runner.run(<String>['-d', 'abc123', 'logs']).then((int code) {
        expect(code, equals(1));
      });
    });
  });
}
