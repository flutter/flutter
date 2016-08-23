// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/channel.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('channel', () {
    Logger oldLogger;
    BufferLogger logger;

    setUp(() {
      Cache.disableLocking();
      logger = new BufferLogger();
      Cache.flutterRoot = '../..';
      context[DeviceManager] = new MockDeviceManager();
      oldLogger = context[Logger];
      context[Logger] = logger;
    });

    tearDown(() {
      context[Logger] = oldLogger;
    });

    test('list', () async {
      ChannelCommand command = new ChannelCommand();
      CommandRunner runner = createTestCommandRunner(command);
      expect(await runner.run(<String>['channel']), 0);
      expect(logger.errorText, hasLength(0));
      expect(logger.statusText, contains('channels'));
      expect(logger.statusText, contains('master'));
      // fails on bots
      //expect(logger.statusText, contains('* ')); // current channel mark
    });
  });
}
