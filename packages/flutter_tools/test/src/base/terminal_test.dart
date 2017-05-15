// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/terminal.dart';
import 'package:test/test.dart';

import '../context.dart';


void main() {
  group('character input prompt', () {
    AnsiTerminal terminalUnderTest;

    setUp(() {
      terminalUnderTest = new TestTerminal();
    });

    testUsingContext('character prompt', () async {
      mockStdInStream = new Stream<String>.fromFutures(<Future<String>>[
        new Future<String>.value('d'), // Not in accepted list.
        new Future<String>.value('b'),
      ]).asBroadcastStream();
      final String choice =
          await terminalUnderTest.promptForCharInput(
            <String>['a', 'b', 'c'],
            prompt: 'Please choose something',
          );
      expect(choice, 'b');
      expect(testLogger.statusText, '''
Please choose something [a|b|c]: d
Please choose something [a|b|c]: b
''');
    });
  });
}

Stream<String> mockStdInStream;

class TestTerminal extends AnsiTerminal {
  @override
  Stream<String> get onCharInput {
    return mockStdInStream;
  }
}
