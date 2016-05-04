// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/commands/listen.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';
import 'src/mocks.dart';

void main() {
  group('listen', () {
    testUsingContext('returns 1 when no device is connected', () {
      ListenCommand command = new ListenCommand(singleRun: true);
      applyMocksToCommand(command);
      return createTestCommandRunner(command).run(<String>['listen']).then((int code) {
        expect(code, 1);
      });
    });
  });
}
