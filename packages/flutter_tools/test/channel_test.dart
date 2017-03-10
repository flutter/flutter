// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/channel.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('channel', () {
    setUpAll(() {
      Cache.disableLocking();
    });

    testUsingContext('list', () async {
      final ChannelCommand command = new ChannelCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel']);
      expect(testLogger.errorText, hasLength(0));
      // The bots may return an empty list of channels (network hiccup?)
      // and when run locally the list of branches might be different
      // so we check for the header text rather than any specific channel name.
      expect(testLogger.statusText, contains('Flutter channels:'));
    });
  });
}
