// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonEncode;

import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:quiver/testing/async.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

final Generator _kNoAnsiPlatform = () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false;

void main() {
  final String red = RegExp.escape(AnsiTerminal.red);
  final String bold = RegExp.escape(AnsiTerminal.bold);
  final String resetBold = RegExp.escape(AnsiTerminal.resetBold);
  final String resetColor = RegExp.escape(AnsiTerminal.resetColor);

  group('AppContext', () {
    FakeStopwatch fakeStopWatch;

    setUp(() {
      fakeStopWatch = FakeStopwatch();
    });
    testUsingContext('error', () async {
      final BufferLogger mockLogger = BufferLogger();
      final VerboseLogger verboseLogger = VerboseLogger(mockLogger);

      verboseLogger.printStatus('Hey Hey Hey Hey');
      verboseLogger.printTrace('Oooh, I do I do I do');
      verboseLogger.printError('Helpless!');

      expect(mockLogger.statusText, matches(r'^\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] Hey Hey Hey Hey\n'
                                             r'\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] Oooh, I do I do I do\n$'));
      expect(mockLogger.traceText, '');
      expect(mockLogger.errorText, matches( r'^\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] Helpless!\n$'));
    }, overrides: <Type, Generator>{
      OutputPreferences: () => OutputPreferences(showColor: false),
      Platform: _kNoAnsiPlatform,
      Stopwatch: () => fakeStopWatch,
    });

    testUsingContext('ANSI colored errors', () async {
      final BufferLogger mockLogger = BufferLogger();
      final VerboseLogger verboseLogger = VerboseLogger(mockLogger);

      verboseLogger.printStatus('Hey Hey Hey Hey');
      verboseLogger.printTrace('Oooh, I do I do I do');
      verboseLogger.printError('Helpless!');

      expect(
          mockLogger.statusText,
          matches(r'^\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] ' '${bold}Hey Hey Hey Hey$resetBold'
                  r'\n\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] Oooh, I do I do I do\n$'));
      expect(mockLogger.traceText, '');
      expect(
          mockLogger.errorText,
          matches('^$red' r'\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] ' '${bold}Helpless!$resetBold$resetColor' r'\n$'));
    }, overrides: <Type, Generator>{
      OutputPreferences: () => OutputPreferences(showColor: true),
      Platform: () => FakePlatform()..stdoutSupportsAnsi = true,
      Stopwatch: () => fakeStopWatch,
    });
  });

  group('Spinners', () {
    MockStdio mockStdio;
    FakeStopwatch mockStopwatch;
    int called;
    const List<String> testPlatforms = <String>['linux', 'macos', 'windows', 'fuchsia'];
    final RegExp secondDigits = RegExp(r'[0-9,.]*[0-9]m?s');

    AnsiStatus _createAnsiStatus() {
      mockStopwatch = FakeStopwatch();
      return AnsiStatus(
        message: 'Hello world',
        timeout: const Duration(seconds: 2),
        padding: 20,
        onFinish: () => called += 1,
      );
    }

    setUp(() {
      mockStdio = MockStdio();
      called = 0;
    });

    List<String> outputStdout() => mockStdio.writtenToStdout.join('').split('\n');
    List<String> outputStderr() => mockStdio.writtenToStderr.join('').split('\n');

    void doWhileAsync(FakeAsync time, bool doThis()) {
      do {
        mockStopwatch.elapsed += const Duration(milliseconds: 1);
        time.elapse(const Duration(milliseconds: 1));
      } while (doThis());
    }

    for (String testOs in testPlatforms) {
      testUsingContext('AnsiSpinner works for $testOs (1)', () async {
        bool done = false;
        mockStopwatch = FakeStopwatch();
        FakeAsync().run((FakeAsync time) {
          final AnsiSpinner ansiSpinner = AnsiSpinner(
            timeout: const Duration(hours: 10),
          )..start();
          doWhileAsync(time, () => ansiSpinner.ticks < 10);
          List<String> lines = outputStdout();
          expect(lines[0], startsWith(
            platform.isWindows
              ? ' \b\\\b|\b/\b-\b\\\b|\b/\b-'
              : ' \b⣽\b⣻\b⢿\b⡿\b⣟\b⣯\b⣷\b⣾\b⣽\b⣻'
            ),
          );
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
          done = true;
        });
        expect(done, isTrue);
      }, overrides: <Type, Generator>{
        Platform: () => FakePlatform(operatingSystem: testOs),
        Stdio: () => mockStdio,
        Stopwatch: () => mockStopwatch,
      });

      testUsingContext('AnsiSpinner works for $testOs (2)', () async {
        bool done = false;
        mockStopwatch = FakeStopwatch();
        FakeAsync().run((FakeAsync time) {
          final AnsiSpinner ansiSpinner = AnsiSpinner(
            timeout: const Duration(seconds: 2),
          )..start();
          mockStopwatch.elapsed = const Duration(seconds: 1);
          doWhileAsync(time, () => ansiSpinner.ticks < 10); // one second
          expect(ansiSpinner.seemsSlow, isFalse);
          expect(outputStdout().join('\n'), isNot(contains('This is taking an unexpectedly long time.')));
          mockStopwatch.elapsed = const Duration(seconds: 3);
          doWhileAsync(time, () => ansiSpinner.ticks < 30); // three seconds
          expect(ansiSpinner.seemsSlow, isTrue);
          // Check the 2nd line to verify there's a newline before the warning
          expect(outputStdout()[1], contains('This is taking an unexpectedly long time.'));
          ansiSpinner.stop();
          expect(outputStdout().join('\n'), isNot(contains('(!)')));
          done = true;
        });
        expect(done, isTrue);
      }, overrides: <Type, Generator>{
        Platform: () => FakePlatform(operatingSystem: testOs),
        Stdio: () => mockStdio,
        Stopwatch: () => mockStopwatch,
      });

      testUsingContext('Stdout startProgress on colored terminal for $testOs', () async {
        bool done = false;
        FakeAsync().run((FakeAsync time) {
          final Logger logger = context.get<Logger>();
          final Status status = logger.startProgress(
            'Hello',
            progressId: null,
            timeout: timeoutConfiguration.slowOperation,
            progressIndicatorPadding: 20, // this minus the "Hello" equals the 15 below.
          );
          expect(outputStderr().length, equals(1));
          expect(outputStderr().first, isEmpty);
          // the 5 below is the margin that is always included between the message and the time.
          expect(outputStdout().join('\n'), matches(platform.isWindows ? r'^Hello {15} {5} {8}[\b]{8} {7}\\$' :
                                                                         r'^Hello {15} {5} {8}[\b]{8} {7}⣽$'));
          status.stop();
          expect(outputStdout().join('\n'), matches(platform.isWindows ? r'^Hello {15} {5} {8}[\b]{8} {7}\\[\b]{8} {8}[\b]{8}[\d, ]{4}[\d]\.[\d]s[\n]$' :
                                                                         r'^Hello {15} {5} {8}[\b]{8} {7}⣽[\b]{8} {8}[\b]{8}[\d, ]{4}[\d]\.[\d]s[\n]$'));
          done = true;
        });
        expect(done, isTrue);
      }, overrides: <Type, Generator>{
        Logger: () => StdoutLogger(),
        OutputPreferences: () => OutputPreferences(showColor: true),
        Platform: () => FakePlatform(operatingSystem: testOs)..stdoutSupportsAnsi = true,
        Stdio: () => mockStdio,
      });

      testUsingContext('Stdout startProgress on colored terminal pauses on $testOs', () async {
        bool done = false;
        FakeAsync().run((FakeAsync time) {
          final Logger logger = context.get<Logger>();
          final Status status = logger.startProgress(
            'Knock Knock, Who\'s There',
            timeout: const Duration(days: 10),
            progressIndicatorPadding: 10,
          );
          logger.printStatus('Rude Interrupting Cow');
          status.stop();
          final String a = platform.isWindows ? '\\' : '⣽';
          final String b = platform.isWindows ? '|' : '⣻';
          expect(
            outputStdout().join('\n'),
            'Knock Knock, Who\'s There     ' // initial message
            '        ' // placeholder so that spinner can backspace on its first tick
            '\b\b\b\b\b\b\b\b       $a' // first tick
            '\b\b\b\b\b\b\b\b        ' // clearing the spinner
            '\b\b\b\b\b\b\b\b' // clearing the clearing of the spinner
            '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b                             ' // clearing the message
            '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b' // clearing the clearing of the message
            'Rude Interrupting Cow\n' // message
            'Knock Knock, Who\'s There     ' // message restoration
            '        ' // placeholder so that spinner can backspace on its second tick
            '\b\b\b\b\b\b\b\b       $b' // second tick
            '\b\b\b\b\b\b\b\b        ' // clearing the spinner to put the time
            '\b\b\b\b\b\b\b\b' // clearing the clearing of the spinner
            '    0.0s\n', // replacing it with the time
          );
          done = true;
        });
        expect(done, isTrue);
      }, overrides: <Type, Generator>{
        Logger: () => StdoutLogger(),
        OutputPreferences: () => OutputPreferences(showColor: true),
        Platform: () => FakePlatform(operatingSystem: testOs)..stdoutSupportsAnsi = true,
        Stdio: () => mockStdio,
      });

      testUsingContext('AnsiStatus works for $testOs', () {
        final AnsiStatus ansiStatus = _createAnsiStatus();
        bool done = false;
        FakeAsync().run((FakeAsync time) {
          ansiStatus.start();
          mockStopwatch.elapsed = const Duration(seconds: 1);
          doWhileAsync(time, () => ansiStatus.ticks < 10); // one second
          expect(ansiStatus.seemsSlow, isFalse);
          expect(outputStdout().join('\n'), isNot(contains('This is taking an unexpectedly long time.')));
          expect(outputStdout().join('\n'), isNot(contains('(!)')));
          mockStopwatch.elapsed = const Duration(seconds: 3);
          doWhileAsync(time, () => ansiStatus.ticks < 30); // three seconds
          expect(ansiStatus.seemsSlow, isTrue);
          expect(outputStdout().join('\n'), contains('This is taking an unexpectedly long time.'));

          // Test that the number of '\b' is correct.
          for (String line in outputStdout()) {
            int currLength = 0;
            for (int i = 0; i < line.length; i += 1) {
              currLength += line[i] == '\b' ? -1 : 1;
              expect(currLength, isNonNegative, reason: 'The following line has overflow backtraces:\n' + jsonEncode(line));
            }
          }

          ansiStatus.stop();
          expect(outputStdout().join('\n'), contains('(!)'));
          done = true;
        });
        expect(done, isTrue);
      }, overrides: <Type, Generator>{
        Platform: () => FakePlatform(operatingSystem: testOs),
        Stdio: () => mockStdio,
        Stopwatch: () => mockStopwatch,
      });

      testUsingContext('AnsiStatus works when canceled for $testOs', () async {
        final AnsiStatus ansiStatus = _createAnsiStatus();
        bool done = false;
        FakeAsync().run((FakeAsync time) {
          ansiStatus.start();
          mockStopwatch.elapsed = const Duration(seconds: 1);
          doWhileAsync(time, () => ansiStatus.ticks < 10);
          List<String> lines = outputStdout();
          expect(lines[0], startsWith(platform.isWindows
              ? 'Hello world                      \b\b\b\b\b\b\b\b       \\\b\b\b\b\b\b\b\b       |\b\b\b\b\b\b\b\b       /\b\b\b\b\b\b\b\b       -\b\b\b\b\b\b\b\b       \\\b\b\b\b\b\b\b\b       |\b\b\b\b\b\b\b\b       /\b\b\b\b\b\b\b\b       -\b\b\b\b\b\b\b\b       \\\b\b\b\b\b\b\b\b       |'
              : 'Hello world                      \b\b\b\b\b\b\b\b       ⣽\b\b\b\b\b\b\b\b       ⣻\b\b\b\b\b\b\b\b       ⢿\b\b\b\b\b\b\b\b       ⡿\b\b\b\b\b\b\b\b       ⣟\b\b\b\b\b\b\b\b       ⣯\b\b\b\b\b\b\b\b       ⣷\b\b\b\b\b\b\b\b       ⣾\b\b\b\b\b\b\b\b       ⣽\b\b\b\b\b\b\b\b       ⣻'));
          expect(lines.length, equals(1));
          expect(lines[0].endsWith('\n'), isFalse);

          // Verify a cancel does _not_ print the time and prints a newline.
          ansiStatus.cancel();
          lines = outputStdout();
          final List<Match> matches = secondDigits.allMatches(lines[0]).toList();
          expect(matches, isEmpty);
          final String x = platform.isWindows ? '|' : '⣻';
          expect(lines[0], endsWith('$x\b\b\b\b\b\b\b\b        \b\b\b\b\b\b\b\b'));
          expect(called, equals(1));
          expect(lines.length, equals(2));
          expect(lines[1], equals(''));

          // Verify that stopping or canceling multiple times throws.
          expect(() { ansiStatus.cancel(); }, throwsA(isInstanceOf<AssertionError>()));
          expect(() { ansiStatus.stop(); }, throwsA(isInstanceOf<AssertionError>()));
          done = true;
        });
        expect(done, isTrue);
      }, overrides: <Type, Generator>{
        Platform: () => FakePlatform(operatingSystem: testOs),
        Stdio: () => mockStdio,
        Stopwatch: () => mockStopwatch,
      });

      testUsingContext('AnsiStatus works when stopped for $testOs', () async {
        final AnsiStatus ansiStatus = _createAnsiStatus();
        bool done = false;
        FakeAsync().run((FakeAsync time) {
          ansiStatus.start();
          mockStopwatch.elapsed = const Duration(seconds: 1);
          doWhileAsync(time, () => ansiStatus.ticks < 10);
          List<String> lines = outputStdout();
          expect(lines, hasLength(1));
          expect(lines[0],
            platform.isWindows
              ? 'Hello world                      \b\b\b\b\b\b\b\b       \\\b\b\b\b\b\b\b\b       |\b\b\b\b\b\b\b\b       /\b\b\b\b\b\b\b\b       -\b\b\b\b\b\b\b\b       \\\b\b\b\b\b\b\b\b       |\b\b\b\b\b\b\b\b       /\b\b\b\b\b\b\b\b       -\b\b\b\b\b\b\b\b       \\\b\b\b\b\b\b\b\b       |'
              : 'Hello world                      \b\b\b\b\b\b\b\b       ⣽\b\b\b\b\b\b\b\b       ⣻\b\b\b\b\b\b\b\b       ⢿\b\b\b\b\b\b\b\b       ⡿\b\b\b\b\b\b\b\b       ⣟\b\b\b\b\b\b\b\b       ⣯\b\b\b\b\b\b\b\b       ⣷\b\b\b\b\b\b\b\b       ⣾\b\b\b\b\b\b\b\b       ⣽\b\b\b\b\b\b\b\b       ⣻',
          );

          // Verify a stop prints the time.
          ansiStatus.stop();
          lines = outputStdout();
          expect(lines, hasLength(2));
          expect(lines[0], matches(
            platform.isWindows
              ? r'Hello world               {8}[\b]{8} {7}\\[\b]{8} {7}|[\b]{8} {7}/[\b]{8} {7}-[\b]{8} {7}\\[\b]{8} {7}|[\b]{8} {7}/[\b]{8} {7}-[\b]{8} {7}\\[\b]{8} {7}|[\b]{8} {7} [\b]{8}[\d., ]{6}[\d]ms$'
              : r'Hello world               {8}[\b]{8} {7}⣽[\b]{8} {7}⣻[\b]{8} {7}⢿[\b]{8} {7}⡿[\b]{8} {7}⣟[\b]{8} {7}⣯[\b]{8} {7}⣷[\b]{8} {7}⣾[\b]{8} {7}⣽[\b]{8} {7}⣻[\b]{8} {7} [\b]{8}[\d., ]{5}[\d]ms$'
          ));
          expect(lines[1], isEmpty);
          final List<Match> times = secondDigits.allMatches(lines[0]).toList();
          expect(times, isNotNull);
          expect(times, hasLength(1));
          final Match match = times.single;
          expect(lines[0], endsWith(match.group(0)));
          expect(called, equals(1));
          expect(lines.length, equals(2));
          expect(lines[1], equals(''));

          // Verify that stopping or canceling multiple times throws.
          expect(() { ansiStatus.stop(); }, throwsA(isInstanceOf<AssertionError>()));
          expect(() { ansiStatus.cancel(); }, throwsA(isInstanceOf<AssertionError>()));
          done = true;
        });
        expect(done, isTrue);
      }, overrides: <Type, Generator>{
        Platform: () => FakePlatform(operatingSystem: testOs),
        Stdio: () => mockStdio,
        Stopwatch: () => mockStopwatch,
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
        timeout: timeoutConfiguration.slowOperation,
        padding: 20,
        onFinish: () => called++,
      );
    });

    List<String> outputStdout() => mockStdio.writtenToStdout.join('').split('\n');
    List<String> outputStderr() => mockStdio.writtenToStderr.join('').split('\n');

    testUsingContext('Error logs are wrapped', () async {
      final Logger logger = context.get<Logger>();
      logger.printError('0123456789' * 15);
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
      final Logger logger = context.get<Logger>();
      logger.printError('0123456789' * 15, indent: 5);
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
      final Logger logger = context.get<Logger>();
      logger.printError('0123456789' * 15, hangingIndent: 5);
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
      final Logger logger = context.get<Logger>();
      logger.printError('0123456789' * 15, indent: 4, hangingIndent: 5);
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
      final Logger logger = context.get<Logger>();
      logger.printStatus('0123456789' * 15);
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
      final Logger logger = context.get<Logger>();
      logger.printStatus('0123456789' * 15, indent: 5);
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
      final Logger logger = context.get<Logger>();
      logger.printStatus('0123456789' * 15, hangingIndent: 5);
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
      final Logger logger = context.get<Logger>();
      logger.printStatus('0123456789' * 15, indent: 4, hangingIndent: 5);
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
      final Logger logger = context.get<Logger>();
      logger.printError('Pants on fire!');
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
      final Logger logger = context.get<Logger>();
      logger.printStatus('All good.');
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
      final Logger logger = context.get<Logger>();
      logger.printStatus(
        null,
        emphasis: null,
        color: null,
        newline: null,
        indent: null,
      );
      final List<String> lines = outputStdout();
      expect(outputStderr().length, equals(1));
      expect(outputStderr().first, isEmpty);
      expect(lines[0], equals(''));
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(showColor: true),
      Stdio: () => mockStdio,
    });

    testUsingContext('Stdout printStatus handle null inputs on non-color terminal', () async {
      final Logger logger = context.get<Logger>();
      logger.printStatus(
        null,
        emphasis: null,
        color: null,
        newline: null,
        indent: null,
      );
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

    testUsingContext('Stdout startProgress on non-color terminal', () async {
      bool done = false;
      FakeAsync().run((FakeAsync time) {
        final Logger logger = context.get<Logger>();
        final Status status = logger.startProgress(
          'Hello',
          progressId: null,
          timeout: timeoutConfiguration.slowOperation,
          progressIndicatorPadding: 20, // this minus the "Hello" equals the 15 below.
        );
        expect(outputStderr().length, equals(1));
        expect(outputStderr().first, isEmpty);
        // the 5 below is the margin that is always included between the message and the time.
        expect(outputStdout().join('\n'), matches(platform.isWindows ? r'^Hello {15} {5}$' :
                                                                       r'^Hello {15} {5}$'));
        status.stop();
        expect(outputStdout().join('\n'), matches(platform.isWindows ? r'^Hello {15} {5}[\d, ]{4}[\d]\.[\d]s[\n]$' :
                                                                       r'^Hello {15} {5}[\d, ]{4}[\d]\.[\d]s[\n]$'));
        done = true;
      });
      expect(done, isTrue);
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(showColor: false),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('SummaryStatus works when canceled', () async {
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
      final Logger logger = context.get<Logger>();
      logger.startProgress('AAA', timeout: timeoutConfiguration.fastOperation)..stop();
      logger.startProgress('BBB', timeout: timeoutConfiguration.fastOperation)..stop();
      final List<String> output = outputStdout();
      expect(output.length, equals(3));
      // There's 61 spaces at the start: 59 (padding default) - 3 (length of AAA) + 5 (margin).
      // Then there's a left-padded "0ms" 8 characters wide, so 5 spaces then "0ms"
      // (except sometimes it's randomly slow so we handle up to "99,999ms").
      expect(output[0], matches(RegExp(r'AAA[ ]{61}[\d, ]{5}[\d]ms')));
      expect(output[1], matches(RegExp(r'BBB[ ]{61}[\d, ]{5}[\d]ms')));
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
      OutputPreferences: () => OutputPreferences(showColor: false),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('sequential startProgress calls with VerboseLogger and StdoutLogger', () async {
      final Logger logger = context.get<Logger>();
      logger.startProgress('AAA', timeout: timeoutConfiguration.fastOperation)..stop();
      logger.startProgress('BBB', timeout: timeoutConfiguration.fastOperation)..stop();
      expect(outputStdout(), <Matcher>[
        matches(r'^\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] AAA$'),
        matches(r'^\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] AAA \(completed.*\)$'),
        matches(r'^\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] BBB$'),
        matches(r'^\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] BBB \(completed.*\)$'),
        matches(r'^$'),
      ]);
    }, overrides: <Type, Generator>{
      Logger: () => VerboseLogger(StdoutLogger()),
      Stdio: () => mockStdio,
      Platform: _kNoAnsiPlatform,
    });

    testUsingContext('sequential startProgress calls with BufferLogger', () async {
      final BufferLogger logger = context.get<Logger>();
      logger.startProgress('AAA', timeout: timeoutConfiguration.fastOperation)..stop();
      logger.startProgress('BBB', timeout: timeoutConfiguration.fastOperation)..stop();
      expect(logger.statusText, 'AAA\nBBB\n');
    }, overrides: <Type, Generator>{
      Logger: () => BufferLogger(),
      Platform: _kNoAnsiPlatform,
    });
  });
}

class FakeStopwatch implements Stopwatch {
  @override
  bool get isRunning => _isRunning;
  bool _isRunning = false;

  @override
  void start() => _isRunning = true;

  @override
  void stop() => _isRunning = false;

  @override
  Duration elapsed = Duration.zero;

  @override
  int get elapsedMicroseconds => elapsed.inMicroseconds;

  @override
  int get elapsedMilliseconds => elapsed.inMilliseconds;

  @override
  int get elapsedTicks => elapsed.inMilliseconds;

  @override
  int get frequency => 1000;

  @override
  void reset() {
    _isRunning = false;
    elapsed = Duration.zero;
  }

  @override
  String toString() => '$runtimeType $elapsed $isRunning';
}
