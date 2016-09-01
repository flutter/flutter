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
      // The bots may return an empty list of channels (network hiccup?)
      // and when run locally the list of branches might be different
      // so we check for the header text rather than any specific channel name.
      expect(logger.statusText, contains('Flutter channels:'));
    });
  });
}
