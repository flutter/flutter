// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/commands/run.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  group('run', () {
    testUsingContext('fails when target not found', () async {
      final RunCommand command = RunCommand();
      applyMocksToCommand(command);
      try {
        await createTestCommandRunner(command).run(<String>['run', '-t', 'abc123']);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode ?? 1, 1);
      }
    });
  });
}
