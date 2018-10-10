// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/commands/trace.dart';

import 'src/common.dart';
import 'src/context.dart';
import 'src/mocks.dart';

void main() {
  group('trace', () {
    testUsingContext('returns 1 when no Android device is connected', () async {
      final TraceCommand command = TraceCommand();
      applyMocksToCommand(command);
      try {
        await createTestCommandRunner(command).run(<String>['trace']);
        fail('Exception expected');
      } on ToolExit catch (e) {
        expect(e.exitCode ?? 1, 1);
      }
    });
  });
}
