// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library wip.console_test;

import 'dart:async';

import 'package:test/test.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'test_setup.dart';

void main() {
  group('WipConsole', () {
    WipConsole? console; // ignore: deprecated_member_use
    List<ConsoleMessageEvent> events = [];
    var subs = <StreamSubscription>[];

    Future checkMessages(int expectedCount) async {
      // make sure all messages have been delivered
      await Future.delayed(const Duration(seconds: 1));
      expect(events, hasLength(expectedCount));
      for (int i = 0; i < expectedCount; i++) {
        if (i == 0) {
          // Clearing adds this message.
          expect(events[i].text, 'console.clear');
        } else {
          expect(events[i].text, 'message $i');
        }
      }
    }

    setUp(() async {
      // ignore: deprecated_member_use
      console = (await wipConnection).console;
      events.clear();
      subs.add(console!.onMessage.listen(events.add));
    });

    tearDown(() async {
      await console?.disable();
      console = null;
      await closeConnection();
      for (var s in subs) {
        s.cancel();
      }
      subs.clear();
    });

    test('receives new console messages', () async {
      await console!.enable();
      await navigateToPage('console_test.html');
      await checkMessages(4);
    });

    test('receives old console messages', () async {
      await navigateToPage('console_test.html');
      await console!.enable();
      await checkMessages(4);
    });

    test('does not receive messages if not enabled', () async {
      await navigateToPage('console_test.html');
      await checkMessages(0);
    });
  });
}
