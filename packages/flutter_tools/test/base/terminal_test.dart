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

  group('ANSI coloring and bold', () {
    AnsiTerminal terminal;

    setUp(() {
      terminal = AnsiTerminal();
    });

    testUsingContext('adding colors works', () {
      for (TerminalColor color in TerminalColor.values) {
        expect(
          terminal.color('output', color),
          equals('${AnsiTerminal.colorCode(color)}output${AnsiTerminal.resetColor}'),
        );
      }
    }, overrides: <Type, Generator> {
      OutputPreferences: () => OutputPreferences(showColor: true),
      Platform: () => FakePlatform()..stdoutSupportsAnsi = true,
    });

    testUsingContext('adding bold works', () {
      expect(
        terminal.bolden('output'),
        equals('${AnsiTerminal.bold}output${AnsiTerminal.resetBold}'),
      );
    }, overrides: <Type, Generator> {
      OutputPreferences: () => OutputPreferences(showColor: true),
      Platform: () => FakePlatform()..stdoutSupportsAnsi = true,
    });

    testUsingContext('nesting bold within color works', () {
      expect(
        terminal.color(terminal.bolden('output'), TerminalColor.blue),
        equals('${AnsiTerminal.blue}${AnsiTerminal.bold}output${AnsiTerminal.resetBold}${AnsiTerminal.resetColor}'),
      );
      expect(
        terminal.color('non-bold ${terminal.bolden('output')} also non-bold', TerminalColor.blue),
        equals('${AnsiTerminal.blue}non-bold ${AnsiTerminal.bold}output${AnsiTerminal.resetBold} also non-bold${AnsiTerminal.resetColor}'),
      );
    }, overrides: <Type, Generator> {
      OutputPreferences: () => OutputPreferences(showColor: true),
      Platform: () => FakePlatform()..stdoutSupportsAnsi = true,
    });

    testUsingContext('nesting color within bold works', () {
      expect(
        terminal.bolden(terminal.color('output', TerminalColor.blue)),
        equals('${AnsiTerminal.bold}${AnsiTerminal.blue}output${AnsiTerminal.resetColor}${AnsiTerminal.resetBold}'),
      );
      expect(
        terminal.bolden('non-color ${terminal.color('output', TerminalColor.blue)} also non-color'),
        equals('${AnsiTerminal.bold}non-color ${AnsiTerminal.blue}output${AnsiTerminal.resetColor} also non-color${AnsiTerminal.resetBold}'),
      );
    }, overrides: <Type, Generator> {
      OutputPreferences: () => OutputPreferences(showColor: true),
      Platform: () => FakePlatform()..stdoutSupportsAnsi = true,
    });

    testUsingContext('nesting color within color works', () {
      expect(
        terminal.color(terminal.color('output', TerminalColor.blue), TerminalColor.magenta),
        equals('${AnsiTerminal.magenta}${AnsiTerminal.blue}output${AnsiTerminal.resetColor}${AnsiTerminal.magenta}${AnsiTerminal.resetColor}'),
      );
      expect(
        terminal.color('magenta ${terminal.color('output', TerminalColor.blue)} also magenta', TerminalColor.magenta),
        equals('${AnsiTerminal.magenta}magenta ${AnsiTerminal.blue}output${AnsiTerminal.resetColor}${AnsiTerminal.magenta} also magenta${AnsiTerminal.resetColor}'),
      );
    }, overrides: <Type, Generator> {
      OutputPreferences: () => OutputPreferences(showColor: true),
      Platform: () => FakePlatform()..stdoutSupportsAnsi = true,
    });

    testUsingContext('nesting bold within bold works', () {
      expect(
        terminal.bolden(terminal.bolden('output')),
        equals('${AnsiTerminal.bold}output${AnsiTerminal.resetBold}'),
      );
      expect(
        terminal.bolden('bold ${terminal.bolden('output')} still bold'),
        equals('${AnsiTerminal.bold}bold output still bold${AnsiTerminal.resetBold}'),
      );
    }, overrides: <Type, Generator> {
      OutputPreferences: () => OutputPreferences(showColor: true),
      Platform: () => FakePlatform()..stdoutSupportsAnsi = true,
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
