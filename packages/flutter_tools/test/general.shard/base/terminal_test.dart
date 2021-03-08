// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main() {
  group('output preferences', () {
    testWithoutContext('can wrap output', () async {
      final BufferLogger bufferLogger = BufferLogger(
        outputPreferences: OutputPreferences.test(wrapText: true, wrapColumn: 40),
        terminal: TestTerminal(platform: FakePlatform()..stdoutSupportsAnsi = true),
      );
      bufferLogger.printStatus('0123456789' * 8);

      expect(bufferLogger.statusText, equals(('0123456789' * 4 + '\n') * 2));
    });

    testWithoutContext('can turn off wrapping', () async {
      final BufferLogger bufferLogger = BufferLogger(
        outputPreferences: OutputPreferences.test(wrapText: false),
        terminal: TestTerminal(platform: FakePlatform()..stdoutSupportsAnsi = true),
      );
      final String testString = '0123456789' * 20;
      bufferLogger.printStatus(testString);

      expect(bufferLogger.statusText, equals('$testString\n'));
    });
  });

  group('ANSI coloring and bold', () {
    AnsiTerminal terminal;

    setUp(() {
      terminal = AnsiTerminal(
        stdio: Stdio(), // Danger, using real stdio.
        platform: FakePlatform()..stdoutSupportsAnsi = true,
      );
    });

    testWithoutContext('adding colors works', () {
      for (final TerminalColor color in TerminalColor.values) {
        expect(
          terminal.color('output', color),
          equals('${AnsiTerminal.colorCode(color)}output${AnsiTerminal.resetColor}'),
        );
      }
    });

    testWithoutContext('adding bold works', () {
      expect(
        terminal.bolden('output'),
        equals('${AnsiTerminal.bold}output${AnsiTerminal.resetBold}'),
      );
    });

    testWithoutContext('nesting bold within color works', () {
      expect(
        terminal.color(terminal.bolden('output'), TerminalColor.blue),
        equals('${AnsiTerminal.blue}${AnsiTerminal.bold}output${AnsiTerminal.resetBold}${AnsiTerminal.resetColor}'),
      );
      expect(
        terminal.color('non-bold ${terminal.bolden('output')} also non-bold', TerminalColor.blue),
        equals('${AnsiTerminal.blue}non-bold ${AnsiTerminal.bold}output${AnsiTerminal.resetBold} also non-bold${AnsiTerminal.resetColor}'),
      );
    });

    testWithoutContext('nesting color within bold works', () {
      expect(
        terminal.bolden(terminal.color('output', TerminalColor.blue)),
        equals('${AnsiTerminal.bold}${AnsiTerminal.blue}output${AnsiTerminal.resetColor}${AnsiTerminal.resetBold}'),
      );
      expect(
        terminal.bolden('non-color ${terminal.color('output', TerminalColor.blue)} also non-color'),
        equals('${AnsiTerminal.bold}non-color ${AnsiTerminal.blue}output${AnsiTerminal.resetColor} also non-color${AnsiTerminal.resetBold}'),
      );
    });

    testWithoutContext('nesting color within color works', () {
      expect(
        terminal.color(terminal.color('output', TerminalColor.blue), TerminalColor.magenta),
        equals('${AnsiTerminal.magenta}${AnsiTerminal.blue}output${AnsiTerminal.resetColor}${AnsiTerminal.magenta}${AnsiTerminal.resetColor}'),
      );
      expect(
        terminal.color('magenta ${terminal.color('output', TerminalColor.blue)} also magenta', TerminalColor.magenta),
        equals('${AnsiTerminal.magenta}magenta ${AnsiTerminal.blue}output${AnsiTerminal.resetColor}${AnsiTerminal.magenta} also magenta${AnsiTerminal.resetColor}'),
      );
    });

    testWithoutContext('nesting bold within bold works', () {
      expect(
        terminal.bolden(terminal.bolden('output')),
        equals('${AnsiTerminal.bold}output${AnsiTerminal.resetBold}'),
      );
      expect(
        terminal.bolden('bold ${terminal.bolden('output')} still bold'),
        equals('${AnsiTerminal.bold}bold output still bold${AnsiTerminal.resetBold}'),
      );
    });
  });

  group('character input prompt', () {
    AnsiTerminal terminalUnderTest;

    setUp(() {
      terminalUnderTest = TestTerminal(stdio: FakeStdio());
    });

    testWithoutContext('character prompt throws if usesTerminalUi is false', () async {
      expect(terminalUnderTest.promptForCharInput(
        <String>['a', 'b', 'c'],
        prompt: 'Please choose something',
        logger: null,
      ), throwsStateError);
    });

    testWithoutContext('character prompt', () async {
      final BufferLogger bufferLogger = BufferLogger(
        terminal: terminalUnderTest,
        outputPreferences: OutputPreferences.test(),
      );
      terminalUnderTest.usesTerminalUi = true;
      mockStdInStream = Stream<String>.fromFutures(<Future<String>>[
        Future<String>.value('d'), // Not in accepted list.
        Future<String>.value('\n'), // Not in accepted list
        Future<String>.value('b'),
      ]).asBroadcastStream();
      final String choice = await terminalUnderTest.promptForCharInput(
        <String>['a', 'b', 'c'],
        prompt: 'Please choose something',
        logger: bufferLogger,
      );
      expect(choice, 'b');
      expect(
          bufferLogger.statusText,
          'Please choose something [a|b|c]: d\n'
          'Please choose something [a|b|c]: \n'
          'Please choose something [a|b|c]: b\n');
    });

    testWithoutContext('default character choice without displayAcceptedCharacters', () async {
      final BufferLogger bufferLogger = BufferLogger(
        terminal: terminalUnderTest,
        outputPreferences: OutputPreferences.test(),
      );
      terminalUnderTest.usesTerminalUi = true;
      mockStdInStream = Stream<String>.fromFutures(<Future<String>>[
        Future<String>.value('\n'), // Not in accepted list
      ]).asBroadcastStream();
      final String choice = await terminalUnderTest.promptForCharInput(
        <String>['a', 'b', 'c'],
        prompt: 'Please choose something',
        displayAcceptedCharacters: false,
        defaultChoiceIndex: 1, // which is b.
        logger: bufferLogger,
      );

      expect(choice, 'b');
      expect(
        bufferLogger.statusText,
        'Please choose something: \n'
      );
    });

    testWithoutContext('Does not set single char mode when a terminal is not attached', () {
      final Stdio stdio = FakeStdio()
        ..stdinHasTerminal = false;
      final AnsiTerminal ansiTerminal = AnsiTerminal(
        stdio: stdio,
        platform: const LocalPlatform()
      );

      expect(() => ansiTerminal.singleCharMode = true, returnsNormally);
    });
  });
}

Stream<String> mockStdInStream;

class TestTerminal extends AnsiTerminal {
  TestTerminal({
    Stdio stdio,
    Platform platform = const LocalPlatform(),
  }) : super(stdio: stdio, platform: platform);

  @override
  Stream<String> get keystrokes {
    return mockStdInStream;
  }

  bool singleCharMode = false;
}

class FakeStdio extends Fake implements Stdio {
  @override
  bool stdinHasTerminal = false;
}
