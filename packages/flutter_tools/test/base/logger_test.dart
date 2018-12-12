// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

final Generator _kNoAnsiPlatform = () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false;

void main() {
  final String red = RegExp.escape(AnsiTerminal.red);
  final String bold = RegExp.escape(AnsiTerminal.bold);
  final String resetBold = RegExp.escape(AnsiTerminal.resetBold);
  final String resetColor = RegExp.escape(AnsiTerminal.resetColor);

  group('AppContext', () {
    testUsingContext('error', () async {
      final BufferLogger mockLogger = BufferLogger();
      final VerboseLogger verboseLogger = VerboseLogger(mockLogger);

      verboseLogger.printStatus('Hey Hey Hey Hey');
      verboseLogger.printTrace('Oooh, I do I do I do');
      verboseLogger.printError('Helpless!');

      expect(mockLogger.statusText, matches(r'^\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] Hey Hey Hey Hey\n'
                                             r'\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] Oooh, I do I do I do\n$'));
      expect(mockLogger.traceText, '');
      expect(mockLogger.errorText, matches( r'^\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] Helpless!\n$'));
    }, overrides: <Type, Generator> {
      OutputPreferences: () => OutputPreferences(showColor: false),
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('ANSI colored errors', () async {
      final BufferLogger mockLogger = BufferLogger();
      final VerboseLogger verboseLogger = VerboseLogger(mockLogger);

      verboseLogger.printStatus('Hey Hey Hey Hey');
      verboseLogger.printTrace('Oooh, I do I do I do');
      verboseLogger.printError('Helpless!');

      expect(
          mockLogger.statusText,
          matches(r'^\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] ' '${bold}Hey Hey Hey Hey$resetBold'
                  r'\n\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] Oooh, I do I do I do\n$'));
      expect(mockLogger.traceText, '');
      expect(
          mockLogger.errorText,
          matches('^$red' r'\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] ' '${bold}Helpless!$resetBold$resetColor' r'\n$'));
    }, overrides: <Type, Generator> {
      OutputPreferences: () => OutputPreferences(showColor: true),
      Platform: () => FakePlatform()..stdoutSupportsAnsi = true,
    });
  });

  group('Spinners', () {
    MockStdio mockStdio;
    AnsiSpinner ansiSpinner;
    AnsiStatus ansiStatus;
    int called;
    const List<String> testPlatforms = <String>['linux', 'macos', 'windows', 'fuchsia'];
    final RegExp secondDigits = RegExp(r'[^\b]\b\b\b\b\b[0-9]+[.][0-9]+(?:s|ms)');

    setUp(() {
      mockStdio = MockStdio();
      ansiSpinner = AnsiSpinner();
      called = 0;
      ansiStatus = AnsiStatus(
        message: 'Hello world',
        expectSlowOperation: true,
        padding: 20,
        onFinish: () => called++,
      );
    });

    List<String> outputStdout() => mockStdio.writtenToStdout.join('').split('\n');
    List<String> outputStderr() => mockStdio.writtenToStderr.join('').split('\n');

    Future<void> doWhileAsync(bool doThis()) async {
      return Future.doWhile(() {
        // We want to let other tasks run at the same time, so we schedule these
        // using a timer rather than a microtask.
        return Future<bool>.delayed(Duration.zero, doThis);
      });
    }

    for (String testOs in testPlatforms) {
      testUsingContext('AnsiSpinner works for $testOs', () async {
        ansiSpinner.start();
        await doWhileAsync(() => ansiSpinner.ticks < 10);
        List<String> lines = outputStdout();
        expect(lines[0], startsWith(platform.isWindows
            ? ' \b-\b\\\b|\b/\b-\b\\\b|\b/'
            : ' \b⣾\b⣽\b⣻\b⢿\b⡿\b⣟\b⣯\b⣷\b⣾\b⣽'));
        expect(lines[0].endsWith('\n'), isFalse);
        expect(lines.length, equals(1));
        ansiSpinner.stop();
        lines = outputStdout();
        expect(lines[0], endsWith('\b \b'));
        expect(lines.length, equals(1));

        // Verify that stopping or canceling multiple times throws.
        expect(() {
          ansiSpinner.stop();
        }, throwsA(isInstanceOf<AssertionError>()));
        expect(() {
          ansiSpinner.cancel();
        }, throwsA(isInstanceOf<AssertionError>()));
      }, overrides: <Type, Generator>{
        Platform: () => FakePlatform(operatingSystem: testOs),
        Stdio: () => mockStdio,
      });

      testUsingContext('Stdout startProgress handle null inputs on colored terminal for $testOs', () async {
        context[Logger].startProgress(
          null,
          progressId: null,
          expectSlowOperation: null,
          progressIndicatorPadding: null,
        );
        final List<String> lines = outputStdout();
        expect(outputStderr().length, equals(1));
        expect(outputStderr().first, isEmpty);
        expect(lines[0], matches(platform.isWindows ? r'[ ]{64} [\b]-' : r'[ ]{64} [\b]⣾'));
      }, overrides: <Type, Generator>{
        Logger: () => StdoutLogger(),
        OutputPreferences: () => OutputPreferences(showColor: true),
        Platform: () => FakePlatform(operatingSystem: testOs)..stdoutSupportsAnsi = true,
        Stdio: () => mockStdio,
      });

      testUsingContext('AnsiStatus works when cancelled for $testOs', () async {
        ansiStatus.start();
        await doWhileAsync(() => ansiStatus.ticks < 10);
        List<String> lines = outputStdout();
        expect(lines[0], startsWith(platform.isWindows
            ? 'Hello world               \b-\b\\\b|\b/\b-\b\\\b|\b/'
            : 'Hello world               \b⣾\b⣽\b⣻\b⢿\b⡿\b⣟\b⣯\b⣷\b⣾\b⣽'));
        expect(lines.length, equals(1));
        expect(lines[0].endsWith('\n'), isFalse);

        // Verify a cancel does _not_ print the time and prints a newline.
        ansiStatus.cancel();
        lines = outputStdout();
        final List<Match> matches = secondDigits.allMatches(lines[0]).toList();
        expect(matches, isEmpty);
        expect(lines[0], endsWith('\b \b'));
        expect(called, equals(1));
        expect(lines.length, equals(2));
        expect(lines[1], equals(''));

        // Verify that stopping or canceling multiple times throws.
        expect(() { ansiStatus.cancel(); }, throwsA(isInstanceOf<AssertionError>()));
        expect(() { ansiStatus.stop(); }, throwsA(isInstanceOf<AssertionError>()));
      }, overrides: <Type, Generator>{
        Platform: () => FakePlatform(operatingSystem: testOs),
        Stdio: () => mockStdio,
      });

      testUsingContext('AnsiStatus works when stopped for $testOs', () async {
        ansiStatus.start();
        await doWhileAsync(() => ansiStatus.ticks < 10);
        List<String> lines = outputStdout();
        expect(lines[0], startsWith(platform.isWindows
            ? 'Hello world               \b-\b\\\b|\b/\b-\b\\\b|\b/'
            : 'Hello world               \b⣾\b⣽\b⣻\b⢿\b⡿\b⣟\b⣯\b⣷\b⣾\b⣽'));
        expect(lines.length, equals(1));

        // Verify a stop prints the time.
        ansiStatus.stop();
        lines = outputStdout();
        final List<Match> matches = secondDigits.allMatches(lines[0]).toList();
        expect(matches, isNotNull);
        expect(matches, hasLength(1));
        final Match match = matches.first;
        expect(lines[0], endsWith(match.group(0)));
        expect(called, equals(1));
        expect(lines.length, equals(2));
        expect(lines[1], equals(''));

        // Verify that stopping or canceling multiple times throws.
        expect(() { ansiStatus.stop(); }, throwsA(isInstanceOf<AssertionError>()));
        expect(() { ansiStatus.cancel(); }, throwsA(isInstanceOf<AssertionError>()));
      }, overrides: <Type, Generator>{
        Platform: () => FakePlatform(operatingSystem: testOs),
        Stdio: () => mockStdio,
      });
    }
  });
  group('Output format', () {
    MockStdio mockStdio;
    SummaryStatus summaryStatus;
    int called;
    final RegExp secondDigits = RegExp(r'[^\b]\b\b\b\b\b[0-9]+[.][0-9]+(?:s|ms)');

    setUp(() {
      mockStdio = MockStdio();
      called = 0;
      summaryStatus = SummaryStatus(
        message: 'Hello world',
        expectSlowOperation: true,
        padding: 20,
        onFinish: () => called++,
      );
    });

    List<String> outputStdout() => mockStdio.writtenToStdout.join('').split('\n');
    List<String> outputStderr() => mockStdio.writtenToStderr.join('').split('\n');

    testUsingContext('Error logs are wrapped', () async {
      context[Logger].printError('0123456789' * 15);
      final List<String> lines = outputStderr();
      expect(outputStdout().length, equals(1));
      expect(outputStdout().first, isEmpty);
      expect(lines[0], equals('0123456789' * 4));
      expect(lines[1], equals('0123456789' * 4));
      expect(lines[2], equals('0123456789' * 4));
      expect(lines[3], equals('0123456789' * 3));
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(wrapText: true, wrapColumn: 40, showColor: false),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('Error logs are wrapped and can be indented.', () async {
      context[Logger].printError('0123456789' * 15, indent: 5);
      final List<String> lines = outputStderr();
      expect(outputStdout().length, equals(1));
      expect(outputStdout().first, isEmpty);
      expect(lines.length, equals(6));
      expect(lines[0], equals('     01234567890123456789012345678901234'));
      expect(lines[1], equals('     56789012345678901234567890123456789'));
      expect(lines[2], equals('     01234567890123456789012345678901234'));
      expect(lines[3], equals('     56789012345678901234567890123456789'));
      expect(lines[4], equals('     0123456789'));
      expect(lines[5], isEmpty);
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(wrapText: true, wrapColumn: 40, showColor: false),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('Error logs are wrapped and can have hanging indent.', () async {
      context[Logger].printError('0123456789' * 15, hangingIndent: 5);
      final List<String> lines = outputStderr();
      expect(outputStdout().length, equals(1));
      expect(outputStdout().first, isEmpty);
      expect(lines.length, equals(6));
      expect(lines[0], equals('0123456789012345678901234567890123456789'));
      expect(lines[1], equals('     01234567890123456789012345678901234'));
      expect(lines[2], equals('     56789012345678901234567890123456789'));
      expect(lines[3], equals('     01234567890123456789012345678901234'));
      expect(lines[4], equals('     56789'));
      expect(lines[5], isEmpty);
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(wrapText: true, wrapColumn: 40, showColor: false),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('Error logs are wrapped, indented, and can have hanging indent.', () async {
      context[Logger].printError('0123456789' * 15, indent: 4, hangingIndent: 5);
      final List<String> lines = outputStderr();
      expect(outputStdout().length, equals(1));
      expect(outputStdout().first, isEmpty);
      expect(lines.length, equals(6));
      expect(lines[0], equals('    012345678901234567890123456789012345'));
      expect(lines[1], equals('         6789012345678901234567890123456'));
      expect(lines[2], equals('         7890123456789012345678901234567'));
      expect(lines[3], equals('         8901234567890123456789012345678'));
      expect(lines[4], equals('         901234567890123456789'));
      expect(lines[5], isEmpty);
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(wrapText: true, wrapColumn: 40, showColor: false),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('Stdout logs are wrapped', () async {
      context[Logger].printStatus('0123456789' * 15);
      final List<String> lines = outputStdout();
      expect(outputStderr().length, equals(1));
      expect(outputStderr().first, isEmpty);
      expect(lines[0], equals('0123456789' * 4));
      expect(lines[1], equals('0123456789' * 4));
      expect(lines[2], equals('0123456789' * 4));
      expect(lines[3], equals('0123456789' * 3));
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(wrapText: true, wrapColumn: 40, showColor: false),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('Stdout logs are wrapped and can be indented.', () async {
      context[Logger].printStatus('0123456789' * 15, indent: 5);
      final List<String> lines = outputStdout();
      expect(outputStderr().length, equals(1));
      expect(outputStderr().first, isEmpty);
      expect(lines.length, equals(6));
      expect(lines[0], equals('     01234567890123456789012345678901234'));
      expect(lines[1], equals('     56789012345678901234567890123456789'));
      expect(lines[2], equals('     01234567890123456789012345678901234'));
      expect(lines[3], equals('     56789012345678901234567890123456789'));
      expect(lines[4], equals('     0123456789'));
      expect(lines[5], isEmpty);
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(wrapText: true, wrapColumn: 40, showColor: false),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('Stdout logs are wrapped and can have hanging indent.', () async {
      context[Logger].printStatus('0123456789' * 15, hangingIndent: 5);
      final List<String> lines = outputStdout();
      expect(outputStderr().length, equals(1));
      expect(outputStderr().first, isEmpty);
      expect(lines.length, equals(6));
      expect(lines[0], equals('0123456789012345678901234567890123456789'));
      expect(lines[1], equals('     01234567890123456789012345678901234'));
      expect(lines[2], equals('     56789012345678901234567890123456789'));
      expect(lines[3], equals('     01234567890123456789012345678901234'));
      expect(lines[4], equals('     56789'));
      expect(lines[5], isEmpty);
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(wrapText: true, wrapColumn: 40, showColor: false),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('Stdout logs are wrapped, indented, and can have hanging indent.', () async {
      context[Logger].printStatus('0123456789' * 15, indent: 4, hangingIndent: 5);
      final List<String> lines = outputStdout();
      expect(outputStderr().length, equals(1));
      expect(outputStderr().first, isEmpty);
      expect(lines.length, equals(6));
      expect(lines[0], equals('    012345678901234567890123456789012345'));
      expect(lines[1], equals('         6789012345678901234567890123456'));
      expect(lines[2], equals('         7890123456789012345678901234567'));
      expect(lines[3], equals('         8901234567890123456789012345678'));
      expect(lines[4], equals('         901234567890123456789'));
      expect(lines[5], isEmpty);
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(wrapText: true, wrapColumn: 40, showColor: false),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('Error logs are red', () async {
      context[Logger].printError('Pants on fire!');
      final List<String> lines = outputStderr();
      expect(outputStdout().length, equals(1));
      expect(outputStdout().first, isEmpty);
      expect(lines[0], equals('${AnsiTerminal.red}Pants on fire!${AnsiTerminal.resetColor}'));
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(showColor: true),
      Platform: () => FakePlatform()..stdoutSupportsAnsi = true,
      Stdio: () => mockStdio,
    });

    testUsingContext('Stdout logs are not colored', () async {
      context[Logger].printStatus('All good.');
      final List<String> lines = outputStdout();
      expect(outputStderr().length, equals(1));
      expect(outputStderr().first, isEmpty);
      expect(lines[0], equals('All good.'));
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(showColor: true),
      Stdio: () => mockStdio,
    });

    testUsingContext('Stdout printStatus handle null inputs on colored terminal', () async {
      context[Logger].printStatus(null, emphasis: null, color: null, newline: null, indent: null);
      final List<String> lines = outputStdout();
      expect(outputStderr().length, equals(1));
      expect(outputStderr().first, isEmpty);
      expect(lines[0], equals(''));
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(showColor: true),
      Stdio: () => mockStdio,
    });

    testUsingContext('Stdout printStatus handle null inputs on regular terminal', () async {
      context[Logger].printStatus(null, emphasis: null, color: null, newline: null, indent: null);
      final List<String> lines = outputStdout();
      expect(outputStderr().length, equals(1));
      expect(outputStderr().first, isEmpty);
      expect(lines[0], equals(''));
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(showColor: false),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('Stdout startProgress handle null inputs on regular terminal', () async {
      context[Logger].startProgress(
        null,
        progressId: null,
        expectSlowOperation: null,
        progressIndicatorPadding: null,
      );
      final List<String> lines = outputStdout();
      expect(outputStderr().length, equals(1));
      expect(outputStderr().first, isEmpty);
      expect(lines[0], matches('[ ]{64}'));
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(showColor: false),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('SummaryStatus works when cancelled', () async {
      summaryStatus.start();
      List<String> lines = outputStdout();
      expect(lines[0], startsWith('Hello world              '));
      expect(lines.length, equals(1));
      expect(lines[0].endsWith('\n'), isFalse);

      // Verify a cancel does _not_ print the time and prints a newline.
      summaryStatus.cancel();
      lines = outputStdout();
      final List<Match> matches = secondDigits.allMatches(lines[0]).toList();
      expect(matches, isEmpty);
      expect(lines[0], endsWith(' '));
      expect(called, equals(1));
      expect(lines.length, equals(2));
      expect(lines[1], equals(''));

      // Verify that stopping or canceling multiple times throws.
      expect(() { summaryStatus.cancel(); }, throwsA(isInstanceOf<AssertionError>()));
      expect(() { summaryStatus.stop(); }, throwsA(isInstanceOf<AssertionError>()));
    }, overrides: <Type, Generator>{Stdio: () => mockStdio, Platform: _kNoAnsiPlatform});

    testUsingContext('SummaryStatus works when stopped', () async {
      summaryStatus.start();
      List<String> lines = outputStdout();
      expect(lines[0], startsWith('Hello world              '));
      expect(lines.length, equals(1));

      // Verify a stop prints the time.
      summaryStatus.stop();
      lines = outputStdout();
      final List<Match> matches = secondDigits.allMatches(lines[0]).toList();
      expect(matches, isNotNull);
      expect(matches, hasLength(1));
      final Match match = matches.first;
      expect(lines[0], endsWith(match.group(0)));
      expect(called, equals(1));
      expect(lines.length, equals(2));
      expect(lines[1], equals(''));

      // Verify that stopping or canceling multiple times throws.
      expect(() { summaryStatus.stop(); }, throwsA(isInstanceOf<AssertionError>()));
      expect(() { summaryStatus.cancel(); }, throwsA(isInstanceOf<AssertionError>()));
    }, overrides: <Type, Generator>{Stdio: () => mockStdio, Platform: _kNoAnsiPlatform});

    testUsingContext('sequential startProgress calls with StdoutLogger', () async {
      context[Logger].startProgress('AAA')..stop();
      context[Logger].startProgress('BBB')..stop();
      expect(outputStdout().length, equals(3));
      expect(outputStdout()[0], matches(RegExp(r'AAA[ ]{60}[\d ]{3}[\d]ms')));
      expect(outputStdout()[1], matches(RegExp(r'BBB[ ]{60}[\d ]{3}[\d]ms')));
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(showColor: false),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('sequential startProgress calls with VerboseLogger and StdoutLogger', () async {
      context[Logger].startProgress('AAA')..stop();
      context[Logger].startProgress('BBB')..stop();
      expect(outputStdout(), <Matcher>[
        matches(r'^\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] AAA$'),
        matches(r'^\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] AAA \(completed\)$'),
        matches(r'^\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] BBB$'),
        matches(r'^\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] BBB \(completed\)$'),
        matches(r'^$'),
      ]);
    }, overrides: <Type, Generator>{
      Logger: () => VerboseLogger(StdoutLogger()),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('sequential startProgress calls with BufferLogger', () async {
      context[Logger].startProgress('AAA')..stop();
      context[Logger].startProgress('BBB')..stop();
      final BufferLogger logger = context[Logger];
      expect(logger.statusText, 'AAA\nBBB\n');
    }, overrides: <Type, Generator>{
      Logger: () => BufferLogger(),
      Platform: _kNoAnsiPlatform,
    });
  });
}
