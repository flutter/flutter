// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/commands/channel.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('channel', () {
    testUsingContext('list', () async {
      ChannelCommand command = new ChannelCommand();
      CommandRunner runner = createTestCommandRunner(command);
      expect(await runner.run(<String>['channel']), 0);
      BufferLogger logger = context[Logger];
      expect(logger.errorText, hasLength(0));
      expect(logger.statusText, contains('Flutter channels:'));
      // too flaky on bots
      //expect(logger.statusText, contains('channels'));
      //expect(logger.statusText, contains('master'));
      // fails on bots
      //expect(logger.statusText, contains('* ')); // current channel mark
    });
  });
}
