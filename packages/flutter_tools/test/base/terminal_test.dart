// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/globals.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('output preferences', () {
    testUsingContext('can wrap output', () async {
      printStatus('0123456789' * 8);
      expect(testLogger.statusText, equals(('0123456789' * 4 + '\n') * 2));
    }, overrides: <Type, Generator>{
      OutputPreferences: () => OutputPreferences(wrapText: true, wrapColumn: 40),
    });

    testUsingContext('can turn off wrapping', () async {
      final String testString = '0123456789' * 20;
      printStatus(testString);
      expect(testLogger.statusText, equals('$testString\n'));
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform()..stdoutSupportsAnsi = true,
      OutputPreferences: () => OutputPreferences(wrapText: false),
    });
  });
  group('character input prompt', () {
    AnsiTerminal terminalUnderTest;

    setUp(() {
      terminalUnderTest = TestTerminal();
    });

    testUsingContext('character prompt', () async {
      mockStdInStream = Stream<String>.fromFutures(<Future<String>>[
        Future<String>.value('d'), // Not in accepted list.
        Future<String>.value('\n'), // Not in accepted list
        Future<String>.value('b'),
      ]).asBroadcastStream();
      final String choice = await terminalUnderTest.promptForCharInput(
        <String>['a', 'b', 'c'],
        prompt: 'Please choose something',
      );
      expect(choice, 'b');
      expect(
          testLogger.statusText,
          'Please choose something [a|b|c]: d\n'
          'Please choose something [a|b|c]: \n'
          '\n'
          'Please choose something [a|b|c]: b\n');
    });

    testUsingContext('default character choice without displayAcceptedCharacters', () async {
      mockStdInStream = Stream<String>.fromFutures(<Future<String>>[
        Future<String>.value('\n'), // Not in accepted list
      ]).asBroadcastStream();
      final String choice = await terminalUnderTest.promptForCharInput(
        <String>['a', 'b', 'c'],
        prompt: 'Please choose something',
        displayAcceptedCharacters: false,
        defaultChoiceIndex: 1, // which is b.
      );
      expect(choice, 'b');
      expect(
          testLogger.statusText,
          'Please choose something: \n'
          '\n');
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
