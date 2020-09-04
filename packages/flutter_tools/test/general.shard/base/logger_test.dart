// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show jsonEncode;

import 'package:flutter_tools/executable.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/commands/daemon.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_async/fake_async.dart';

import '../../src/common.dart';
import '../../src/mocks.dart' as mocks;

final Platform _kNoAnsiPlatform = FakePlatform(stdoutSupportsAnsi: false);
final String red = RegExp.escape(AnsiTerminal.red);
final String bold = RegExp.escape(AnsiTerminal.bold);
final String resetBold = RegExp.escape(AnsiTerminal.resetBold);
final String resetColor = RegExp.escape(AnsiTerminal.resetColor);

class MockStdout extends Mock implements Stdout {}

void main() {
  testWithoutContext('correct logger instance is created', () {
    final LoggerFactory loggerFactory = LoggerFactory(
      terminal: Terminal.test(),
      stdio: mocks.MockStdio(),
      outputPreferences: OutputPreferences.test(),
      timeoutConfiguration: const TimeoutConfiguration(),
    );

    expect(loggerFactory.createLogger(
      verbose: false,
      machine: false,
      daemon: false,
      windows: false,
    ), isA<StdoutLogger>());
    expect(loggerFactory.createLogger(
      verbose: false,
      machine: false,
      daemon: false,
      windows: true,
    ), isA<WindowsStdoutLogger>());
    expect(loggerFactory.createLogger(
      verbose: true,
      machine: false,
      daemon: false,
      windows: true,
    ), isA<VerboseLogger>());
    expect(loggerFactory.createLogger(
      verbose: true,
      machine: false,
      daemon: false,
      windows: false,
    ), isA<VerboseLogger>());
    expect(loggerFactory.createLogger(
      verbose: false,
      machine: false,
      daemon: true,
      windows: false,
    ), isA<NotifyingLogger>());
    expect(loggerFactory.createLogger(
      verbose: false,
      machine: true,
      daemon: false,
      windows: false,
    ), isA<AppRunLogger>());
  });

  group('AppContext', () {
    FakeStopwatch fakeStopWatch;

    setUp(() {
      fakeStopWatch = FakeStopwatch();
    });

    testWithoutContext('error', () async {
      final BufferLogger mockLogger = BufferLogger.test(
        outputPreferences: OutputPreferences.test(showColor: false),
      );
      final VerboseLogger verboseLogger = VerboseLogger(
        mockLogger,
        stopwatchFactory: FakeStopwatchFactory(fakeStopWatch),
      );

      verboseLogger.printStatus('Hey Hey Hey Hey');
      verboseLogger.printTrace('Oooh, I do I do I do');
      verboseLogger.printError('Helpless!');

      expect(mockLogger.statusText, matches(r'^\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] Hey Hey Hey Hey\n'
                                             r'\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] Oooh, I do I do I do\n$'));
      expect(mockLogger.traceText, '');
      expect(mockLogger.errorText, matches( r'^\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] Helpless!\n$'));
    });

    testWithoutContext('ANSI colored errors', () async {
      final BufferLogger mockLogger = BufferLogger(
        terminal: AnsiTerminal(
          stdio:  mocks.MockStdio(),
          platform: FakePlatform(stdoutSupportsAnsi: true),
        ),
        outputPreferences: OutputPreferences.test(showColor: true),
      );
      final VerboseLogger verboseLogger = VerboseLogger(
        mockLogger, stopwatchFactory: FakeStopwatchFactory(fakeStopWatch),
      );

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
    });
  });

  testWithoutContext('Logger does not throw when stdio write throws synchronously', () async {
    final MockStdout stdout = MockStdout();
    final MockStdout stderr = MockStdout();
    final Stdio stdio = Stdio.test(stdout: stdout, stderr: stderr);
    bool stdoutThrew = false;
    bool stderrThrew = false;
    final Completer<void> stdoutError = Completer<void>();
    final Completer<void> stderrError = Completer<void>();
    when(stdout.write(any)).thenAnswer((_) {
      stdoutThrew = true;
      throw 'Error';
    });
    when(stderr.write(any)).thenAnswer((_) {
      stderrThrew = true;
      throw 'Error';
    });
    when(stdout.done).thenAnswer((_) => stdoutError.future);
    when(stderr.done).thenAnswer((_) => stderrError.future);
    final Logger logger = StdoutLogger(
      terminal: AnsiTerminal(
        stdio: stdio,
        platform: _kNoAnsiPlatform,
      ),
      stdio: stdio,
      outputPreferences: OutputPreferences.test(),
      timeoutConfiguration: const TimeoutConfiguration(),
    );
    logger.printStatus('message');
    logger.printError('error message');
    expect(stdoutThrew, true);
    expect(stderrThrew, true);
  });

  testWithoutContext('Logger does not throw when stdio write throws asynchronously', () async {
    final MockStdout stdout = MockStdout();
    final MockStdout stderr = MockStdout();
    final Stdio stdio = Stdio.test(stdout: stdout, stderr: stderr);
    final Completer<void> stdoutError = Completer<void>();
    final Completer<void> stderrError = Completer<void>();
    bool stdoutThrew = false;
    bool stderrThrew = false;
    final Completer<void> stdoutCompleter = Completer<void>();
    final Completer<void> stderrCompleter = Completer<void>();
    when(stdout.write(any)).thenAnswer((_) {
      Zone.current.runUnaryGuarded<void>((_) {
        stdoutThrew = true;
        stdoutCompleter.complete();
        throw 'Error';
      }, null);
    });
    when(stderr.write(any)).thenAnswer((_) {
      Zone.current.runUnaryGuarded<void>((_) {
        stderrThrew = true;
        stderrCompleter.complete();
        throw 'Error';
      }, null);
    });
    when(stdout.done).thenAnswer((_) => stdoutError.future);
    when(stderr.done).thenAnswer((_) => stderrError.future);
    final Logger logger = StdoutLogger(
      terminal: AnsiTerminal(
        stdio: stdio,
        platform: _kNoAnsiPlatform,
      ),
      stdio: stdio,
      outputPreferences: OutputPreferences.test(),
      timeoutConfiguration: const TimeoutConfiguration(),
    );
    logger.printStatus('message');
    logger.printError('error message');
    await stdoutCompleter.future;
    await stderrCompleter.future;
    expect(stdoutThrew, true);
    expect(stderrThrew, true);
  });

  testWithoutContext('Logger does not throw when stdio completes done with an error', () async {
    final MockStdout stdout = MockStdout();
    final MockStdout stderr = MockStdout();
    final Stdio stdio = Stdio.test(stdout: stdout, stderr: stderr);
    final Completer<void> stdoutError = Completer<void>();
    final Completer<void> stderrError = Completer<void>();
    final Completer<void> stdoutCompleter = Completer<void>();
    final Completer<void> stderrCompleter = Completer<void>();
    when(stdout.write(any)).thenAnswer((_) {
      Zone.current.runUnaryGuarded<void>((_) {
        stdoutError.completeError(Exception('Some pipe error'));
        stdoutCompleter.complete();
      }, null);
    });
    when(stderr.write(any)).thenAnswer((_) {
      Zone.current.runUnaryGuarded<void>((_) {
        stderrError.completeError(Exception('Some pipe error'));
        stderrCompleter.complete();
      }, null);
    });
    when(stdout.done).thenAnswer((_) => stdoutError.future);
    when(stderr.done).thenAnswer((_) => stderrError.future);
    final Logger logger = StdoutLogger(
      terminal: AnsiTerminal(
        stdio: stdio,
        platform: _kNoAnsiPlatform,
      ),
      stdio: stdio,
      outputPreferences: OutputPreferences.test(),
      timeoutConfiguration: const TimeoutConfiguration(),
    );
    logger.printStatus('message');
    logger.printError('error message');
    await stdoutCompleter.future;
    await stderrCompleter.future;
  });

  group('Spinners', () {
    mocks.MockStdio mockStdio;
    FakeStopwatch mockStopwatch;
    FakeStopwatchFactory stopwatchFactory;
    int called;
    final List<Platform> testPlatforms = <Platform>[
      FakePlatform(
        operatingSystem: 'linux',
        environment: <String, String>{},
        executableArguments: <String>[],
      ),
      FakePlatform(
        operatingSystem: 'macos',
        environment: <String, String>{},
        executableArguments: <String>[],
      ),
      FakePlatform(
        operatingSystem: 'windows',
        environment: <String, String>{},
        executableArguments: <String>[],
      ),
      FakePlatform(
        operatingSystem: 'windows',
        environment: <String, String>{'WT_SESSION': ''},
        executableArguments: <String>[],
      ),
      FakePlatform(
        operatingSystem: 'fuchsia',
        environment: <String, String>{},
        executableArguments: <String>[],
      ),
    ];
    final RegExp secondDigits = RegExp(r'[0-9,.]*[0-9]m?s');

    setUp(() {
      mockStopwatch = FakeStopwatch();
      mockStdio = mocks.MockStdio();
      called = 0;
      stopwatchFactory = FakeStopwatchFactory(mockStopwatch);
    });

    List<String> outputStdout() => mockStdio.writtenToStdout.join('').split('\n');
    List<String> outputStderr() => mockStdio.writtenToStderr.join('').split('\n');

    void doWhileAsync(FakeAsync time, bool doThis()) {
      do {
        mockStopwatch.elapsed += const Duration(milliseconds: 1);
        time.elapse(const Duration(milliseconds: 1));
      } while (doThis());
    }

    for (final Platform testPlatform in testPlatforms) {
      group('(${testPlatform.operatingSystem})', () {
        Platform platform;
        Platform ansiPlatform;
        AnsiTerminal terminal;
        AnsiTerminal coloredTerminal;
        AnsiStatus ansiStatus;

        setUp(() {
          platform = FakePlatform(stdoutSupportsAnsi: false);
          ansiPlatform = FakePlatform(stdoutSupportsAnsi: true);

          terminal = AnsiTerminal(
            stdio: mockStdio,
            platform: platform,
          );
          coloredTerminal = AnsiTerminal(
            stdio: mockStdio,
            platform: ansiPlatform,
          );

          ansiStatus = AnsiStatus(
            message: 'Hello world',
            timeout: const Duration(seconds: 2),
            padding: 20,
            onFinish: () => called += 1,
            stdio: mockStdio,
            timeoutConfiguration: const TimeoutConfiguration(),
            stopwatch: stopwatchFactory.createStopwatch(),
            terminal: terminal,
          );
        });

        testWithoutContext('AnsiSpinner works (1)', () async {
          bool done = false;
          mockStopwatch = FakeStopwatch();
          FakeAsync().run((FakeAsync time) {
            final AnsiSpinner ansiSpinner = AnsiSpinner(
              timeout: const Duration(hours: 10),
              stdio: mockStdio,
              timeoutConfiguration: const TimeoutConfiguration(),
              stopwatch: stopwatchFactory.createStopwatch(),
              terminal: terminal,
            )..start();
            doWhileAsync(time, () => ansiSpinner.ticks < 10);
            List<String> lines = outputStdout();
            expect(lines[0], startsWith(
              terminal.supportsEmoji
                ? ' \b⣽\b⣻\b⢿\b⡿\b⣟\b⣯\b⣷\b⣾\b⣽\b⣻'
                : ' \b\\\b|\b/\b-\b\\\b|\b/\b-'
              ),
            );
            expect(lines[0].endsWith('\n'), isFalse);
            expect(lines.length, equals(1));

            ansiSpinner.stop();
            lines = outputStdout();

            expect(lines[0], endsWith('\b \b'));
            expect(lines.length, equals(1));

            // Verify that stopping or canceling multiple times throws.
            expect(ansiSpinner.stop, throwsAssertionError);
            expect(ansiSpinner.cancel, throwsAssertionError);
            done = true;
          });
          expect(done, isTrue);
        });

        testWithoutContext('AnsiSpinner works (2)', () async {
          bool done = false;
          mockStopwatch = FakeStopwatch();
          FakeAsync().run((FakeAsync time) {
            final AnsiSpinner ansiSpinner = AnsiSpinner(
              timeout: const Duration(seconds: 2),
              stdio: mockStdio,
              timeoutConfiguration: const TimeoutConfiguration(),
              stopwatch: mockStopwatch,
              terminal: terminal,
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
        });

        testWithoutContext('Stdout startProgress on colored terminal', () async {
          bool done = false;
          FakeAsync().run((FakeAsync time) {
            final Logger logger = StdoutLogger(
              terminal: coloredTerminal,
              stdio: mockStdio,
              outputPreferences: OutputPreferences.test(showColor: true),
              timeoutConfiguration: const TimeoutConfiguration(),
              stopwatchFactory: stopwatchFactory,
            );
            final Status status = logger.startProgress(
              'Hello',
              progressId: null,
              timeout: const TimeoutConfiguration().slowOperation,
              progressIndicatorPadding: 20, // this minus the "Hello" equals the 15 below.
            );
            expect(outputStderr().length, equals(1));
            expect(outputStderr().first, isEmpty);
            // the 5 below is the margin that is always included between the message and the time.
            expect(
              outputStdout().join('\n'),
              matches(terminal.supportsEmoji
                ? r'^Hello {15} {5} {8}[\b]{8} {7}⣽$'
                : r'^Hello {15} {5} {8}[\b]{8} {7}\\$'),
            );
            status.stop();
            expect(
              outputStdout().join('\n'),
              matches(
                terminal.supportsEmoji
                ? r'^Hello {15} {5} {8}[\b]{8} {7}⣽[\b]{8} {8}[\b]{8}[\d, ]{4}[\d]\.[\d]s[\n]$'
                : r'^Hello {15} {5} {8}[\b]{8} {7}\\[\b]{8} {8}[\b]{8}[\d, ]{4}[\d]\.[\d]s[\n]$',
              ),
            );
            done = true;
          });
          expect(done, isTrue);
        });

        testWithoutContext('Stdout startProgress on colored terminal pauses', () async {
          bool done = false;
          FakeAsync().run((FakeAsync time) {
            mockStopwatch.elapsed = const Duration(seconds: 5);
            final Logger logger = StdoutLogger(
              terminal: coloredTerminal,
              stdio: mockStdio,
              outputPreferences: OutputPreferences.test(showColor: true),
              timeoutConfiguration: const TimeoutConfiguration(),
              stopwatchFactory: stopwatchFactory,
            );
            final Status status = logger.startProgress(
              "Knock Knock, Who's There",
              timeout: const Duration(days: 10),
              progressIndicatorPadding: 10,
            );
            logger.printStatus('Rude Interrupting Cow');
            status.stop();
            final String a = terminal.supportsEmoji ? '⣽' : r'\';
            final String b = terminal.supportsEmoji ? '⣻' : '|';

            expect(
              outputStdout().join('\n'),
              "Knock Knock, Who's There     " // initial message
              '        ' // placeholder so that spinner can backspace on its first tick
              '\b\b\b\b\b\b\b\b       $a' // first tick
              '\b\b\b\b\b\b\b\b        ' // clearing the spinner
              '\b\b\b\b\b\b\b\b' // clearing the clearing of the spinner
              '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b                             ' // clearing the message
              '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b' // clearing the clearing of the message
              'Rude Interrupting Cow\n' // message
              "Knock Knock, Who's There     " // message restoration
              '        ' // placeholder so that spinner can backspace on its second tick
              '\b\b\b\b\b\b\b\b       $b' // second tick
              '\b\b\b\b\b\b\b\b        ' // clearing the spinner to put the time
              '\b\b\b\b\b\b\b\b' // clearing the clearing of the spinner
              '    5.0s\n', // replacing it with the time
            );
            done = true;
          });
          expect(done, isTrue);
        });

        testWithoutContext('AnsiStatus works', () {
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
            for (final String line in outputStdout()) {
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
        });

        testWithoutContext('AnsiStatus works when canceled', () async {
          bool done = false;
          FakeAsync().run((FakeAsync time) {
            ansiStatus.start();
            mockStopwatch.elapsed = const Duration(seconds: 1);
            doWhileAsync(time, () => ansiStatus.ticks < 10);
            List<String> lines = outputStdout();

            expect(lines[0], startsWith(
              terminal.supportsEmoji
              ? 'Hello world                      \b\b\b\b\b\b\b\b       ⣽\b\b\b\b\b\b\b\b       ⣻\b\b\b\b\b\b\b\b       ⢿\b\b\b\b\b\b\b\b       ⡿\b\b\b\b\b\b\b\b       ⣟\b\b\b\b\b\b\b\b       ⣯\b\b\b\b\b\b\b\b       ⣷\b\b\b\b\b\b\b\b       ⣾\b\b\b\b\b\b\b\b       ⣽\b\b\b\b\b\b\b\b       ⣻'
              : 'Hello world                      \b\b\b\b\b\b\b\b       \\\b\b\b\b\b\b\b\b       |\b\b\b\b\b\b\b\b       /\b\b\b\b\b\b\b\b       -\b\b\b\b\b\b\b\b       \\\b\b\b\b\b\b\b\b       |\b\b\b\b\b\b\b\b       /\b\b\b\b\b\b\b\b       -\b\b\b\b\b\b\b\b       \\\b\b\b\b\b\b\b\b       |',
            ));
            expect(lines.length, equals(1));
            expect(lines[0].endsWith('\n'), isFalse);

            // Verify a cancel does _not_ print the time and prints a newline.
            ansiStatus.cancel();
            lines = outputStdout();
            final List<Match> matches = secondDigits.allMatches(lines[0]).toList();
            expect(matches, isEmpty);
            final String leading = terminal.supportsEmoji ? '⣻' : '|';

            expect(lines[0], endsWith('$leading\b\b\b\b\b\b\b\b        \b\b\b\b\b\b\b\b'));
            expect(called, equals(1));
            expect(lines.length, equals(2));
            expect(lines[1], equals(''));

            // Verify that stopping or canceling multiple times throws.
            expect(ansiStatus.cancel, throwsAssertionError);
            expect(ansiStatus.stop, throwsAssertionError);
            done = true;
          });
          expect(done, isTrue);
        });

        testWithoutContext('AnsiStatus works when stopped', () async {
          bool done = false;
          FakeAsync().run((FakeAsync time) {
            ansiStatus.start();
            mockStopwatch.elapsed = const Duration(seconds: 1);
            doWhileAsync(time, () => ansiStatus.ticks < 10);
            List<String> lines = outputStdout();

            expect(lines, hasLength(1));
            expect(
              lines[0],
              terminal.supportsEmoji
                ? 'Hello world                      \b\b\b\b\b\b\b\b       ⣽\b\b\b\b\b\b\b\b       ⣻\b\b\b\b\b\b\b\b       ⢿\b\b\b\b\b\b\b\b       ⡿\b\b\b\b\b\b\b\b       ⣟\b\b\b\b\b\b\b\b       ⣯\b\b\b\b\b\b\b\b       ⣷\b\b\b\b\b\b\b\b       ⣾\b\b\b\b\b\b\b\b       ⣽\b\b\b\b\b\b\b\b       ⣻'
                : 'Hello world                      \b\b\b\b\b\b\b\b       \\\b\b\b\b\b\b\b\b       |\b\b\b\b\b\b\b\b       /\b\b\b\b\b\b\b\b       -\b\b\b\b\b\b\b\b       \\\b\b\b\b\b\b\b\b       |\b\b\b\b\b\b\b\b       /\b\b\b\b\b\b\b\b       -\b\b\b\b\b\b\b\b       \\\b\b\b\b\b\b\b\b       |',
            );

            // Verify a stop prints the time.
            ansiStatus.stop();
            lines = outputStdout();
            expect(lines, hasLength(2));
            expect(lines[0], matches(
              terminal.supportsEmoji
                ? r'Hello world               {8}[\b]{8} {7}⣽[\b]{8} {7}⣻[\b]{8} {7}⢿[\b]{8} {7}⡿[\b]{8} {7}⣟[\b]{8} {7}⣯[\b]{8} {7}⣷[\b]{8} {7}⣾[\b]{8} {7}⣽[\b]{8} {7}⣻[\b]{8} {7} [\b]{8}[\d., ]{5}[\d]ms$'
                : r'Hello world               {8}[\b]{8} {7}\\[\b]{8} {7}|[\b]{8} {7}/[\b]{8} {7}-[\b]{8} {7}\\[\b]{8} {7}|[\b]{8} {7}/[\b]{8} {7}-[\b]{8} {7}\\[\b]{8} {7}|[\b]{8} {7} [\b]{8}[\d., ]{6}[\d]ms$',
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
            expect(ansiStatus.stop, throwsAssertionError);
            expect(ansiStatus.cancel, throwsAssertionError);
            done = true;
          });
          expect(done, isTrue);
        });
      });
    }
  });

  group('Output format', () {
    mocks.MockStdio mockStdio;
    SummaryStatus summaryStatus;
    int called;
    final RegExp secondDigits = RegExp(r'[^\b]\b\b\b\b\b[0-9]+[.][0-9]+(?:s|ms)');

    setUp(() {
      mockStdio = mocks.MockStdio();
      called = 0;
      summaryStatus = SummaryStatus(
        message: 'Hello world',
        timeout: const TimeoutConfiguration().slowOperation,
        padding: 20,
        onFinish: () => called++,
        stdio: mockStdio,
        timeoutConfiguration: const TimeoutConfiguration(),
        stopwatch: FakeStopwatch(),
      );
    });

    List<String> outputStdout() => mockStdio.writtenToStdout.join('').split('\n');
    List<String> outputStderr() => mockStdio.writtenToStderr.join('').split('\n');

    testWithoutContext('Error logs are wrapped', () async {
      final Logger logger = StdoutLogger(
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: _kNoAnsiPlatform,
        ),
        stdio: mockStdio,
        outputPreferences: OutputPreferences.test(wrapText: true, wrapColumn: 40, showColor: false),
        timeoutConfiguration: const TimeoutConfiguration(),
      );
      logger.printError('0123456789' * 15);
      final List<String> lines = outputStderr();

      expect(outputStdout().length, equals(1));
      expect(outputStdout().first, isEmpty);
      expect(lines[0], equals('0123456789' * 4));
      expect(lines[1], equals('0123456789' * 4));
      expect(lines[2], equals('0123456789' * 4));
      expect(lines[3], equals('0123456789' * 3));
    });

    testWithoutContext('Error logs are wrapped and can be indented.', () async {
      final Logger logger = StdoutLogger(
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: _kNoAnsiPlatform,
        ),
        stdio: mockStdio,
        outputPreferences: OutputPreferences.test(wrapText: true, wrapColumn: 40, showColor: false),
        timeoutConfiguration: const TimeoutConfiguration(),
      );
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
    });

    testWithoutContext('Error logs are wrapped and can have hanging indent.', () async {
      final Logger logger = StdoutLogger(
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: _kNoAnsiPlatform,
        ),
        stdio: mockStdio,
        outputPreferences: OutputPreferences.test(wrapText: true, wrapColumn: 40, showColor: false),
        timeoutConfiguration: const TimeoutConfiguration(),
      );
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
    });

    testWithoutContext('Error logs are wrapped, indented, and can have hanging indent.', () async {
      final Logger logger = StdoutLogger(
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: _kNoAnsiPlatform,
        ),
        stdio: mockStdio,
        outputPreferences: OutputPreferences.test(wrapText: true, wrapColumn: 40, showColor: false),
        timeoutConfiguration: const TimeoutConfiguration(),
      );
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
    });

    testWithoutContext('Stdout logs are wrapped', () async {
      final Logger logger = StdoutLogger(
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: _kNoAnsiPlatform,
        ),
        stdio: mockStdio,
        outputPreferences: OutputPreferences.test(wrapText: true, wrapColumn: 40, showColor: false),
        timeoutConfiguration: const TimeoutConfiguration(),
      );
      logger.printStatus('0123456789' * 15);
      final List<String> lines = outputStdout();

      expect(outputStderr().length, equals(1));
      expect(outputStderr().first, isEmpty);
      expect(lines[0], equals('0123456789' * 4));
      expect(lines[1], equals('0123456789' * 4));
      expect(lines[2], equals('0123456789' * 4));
      expect(lines[3], equals('0123456789' * 3));
    });

    testWithoutContext('Stdout logs are wrapped and can be indented.', () async {
      final Logger logger = StdoutLogger(
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: _kNoAnsiPlatform,
        ),
        stdio: mockStdio,
        outputPreferences: OutputPreferences.test(wrapText: true, wrapColumn: 40, showColor: false),
        timeoutConfiguration: const TimeoutConfiguration(),
      );
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
    });

    testWithoutContext('Stdout logs are wrapped and can have hanging indent.', () async {
      final Logger logger = StdoutLogger(
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: _kNoAnsiPlatform,
        ),
        stdio: mockStdio,
        outputPreferences: OutputPreferences.test(wrapText: true, wrapColumn: 40, showColor: false),
        timeoutConfiguration: const TimeoutConfiguration(),
      );
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
    });

    testWithoutContext('Stdout logs are wrapped, indented, and can have hanging indent.', () async {
      final Logger logger = StdoutLogger(
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: _kNoAnsiPlatform,
        ),
        stdio: mockStdio,
        outputPreferences: OutputPreferences.test(wrapText: true, wrapColumn: 40, showColor: false),
        timeoutConfiguration: const TimeoutConfiguration(),
      );
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
    });

    testWithoutContext('Error logs are red', () async {
      final Logger logger = StdoutLogger(
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: FakePlatform(stdoutSupportsAnsi: true),
        ),
        stdio: mockStdio,
        outputPreferences: OutputPreferences.test(showColor: true),
        timeoutConfiguration: const TimeoutConfiguration(),
      );
      logger.printError('Pants on fire!');
      final List<String> lines = outputStderr();

      expect(outputStdout().length, equals(1));
      expect(outputStdout().first, isEmpty);
      expect(lines[0], equals('${AnsiTerminal.red}Pants on fire!${AnsiTerminal.resetColor}'));
    });

    testWithoutContext('Stdout logs are not colored', () async {
      final Logger logger = StdoutLogger(
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: FakePlatform(),
        ),
        stdio: mockStdio,
        outputPreferences:  OutputPreferences.test(showColor: true),
        timeoutConfiguration: const TimeoutConfiguration(),
      );
      logger.printStatus('All good.');

      final List<String> lines = outputStdout();
      expect(outputStderr().length, equals(1));
      expect(outputStderr().first, isEmpty);
      expect(lines[0], equals('All good.'));
    });

    testWithoutContext('Stdout printStatus handle null inputs on colored terminal', () async {
      final Logger logger = StdoutLogger(
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: FakePlatform(),
        ),
        stdio: mockStdio,
        outputPreferences: OutputPreferences.test(showColor: true),
        timeoutConfiguration: const TimeoutConfiguration(),
      );
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
    });

    testWithoutContext('Stdout printStatus handle null inputs on non-color terminal', () async {
      final Logger logger = StdoutLogger(
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: _kNoAnsiPlatform,
        ),
        stdio: mockStdio,
        outputPreferences: OutputPreferences.test(showColor: false),
        timeoutConfiguration: const TimeoutConfiguration(),
      );
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
    });

    testWithoutContext('Stdout startProgress on non-color terminal', () async {
      bool done = false;
      FakeAsync().run((FakeAsync time) {
        final Logger logger = StdoutLogger(
          terminal: AnsiTerminal(
            stdio: mockStdio,
            platform: _kNoAnsiPlatform,
          ),
          stdio: mockStdio,
          outputPreferences: OutputPreferences.test(showColor: false),
          timeoutConfiguration: const TimeoutConfiguration(),
        );
        final Status status = logger.startProgress(
          'Hello',
          progressId: null,
          timeout: const TimeoutConfiguration().slowOperation,
          progressIndicatorPadding: 20, // this minus the "Hello" equals the 15 below.
        );
        expect(outputStderr().length, equals(1));
        expect(outputStderr().first, isEmpty);
        // the 5 below is the margin that is always included between the message and the time.
        expect(outputStdout().join('\n'), matches(r'^Hello {15} {5}$'));
        status.stop();
        expect(outputStdout().join('\n'), matches(r'^Hello {15} {5}[\d, ]{4}[\d]\.[\d]s[\n]$'));
        done = true;
      });
      expect(done, isTrue);
    });

    testWithoutContext('SummaryStatus works when canceled', () async {
      final SummaryStatus summaryStatus = SummaryStatus(
        message: 'Hello world',
        timeout: const TimeoutConfiguration().slowOperation,
        padding: 20,
        onFinish: () => called++,
        stdio: mockStdio,
        timeoutConfiguration: const TimeoutConfiguration(),
        stopwatch: FakeStopwatch(),
      );
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
      expect(summaryStatus.cancel, throwsAssertionError);
      expect(summaryStatus.stop, throwsAssertionError);
    });

    testWithoutContext('SummaryStatus works when stopped', () async {
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
      expect(summaryStatus.stop, throwsAssertionError);
      expect(summaryStatus.cancel, throwsAssertionError);
    });

    testWithoutContext('sequential startProgress calls with StdoutLogger', () async {
      final Logger logger = StdoutLogger(
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: _kNoAnsiPlatform,
        ),
        stdio: mockStdio,
        outputPreferences: OutputPreferences.test(showColor: false),
        timeoutConfiguration: const TimeoutConfiguration(),
      );
      logger.startProgress('AAA', timeout: const TimeoutConfiguration().fastOperation).stop();
      logger.startProgress('BBB', timeout: const TimeoutConfiguration().fastOperation).stop();
      final List<String> output = outputStdout();

      expect(output.length, equals(3));

      // There's 61 spaces at the start: 59 (padding default) - 3 (length of AAA) + 5 (margin).
      // Then there's a left-padded "0ms" 8 characters wide, so 5 spaces then "0ms"
      // (except sometimes it's randomly slow so we handle up to "99,999ms").
      expect(output[0], matches(RegExp(r'AAA[ ]{61}[\d, ]{5}[\d]ms')));
      expect(output[1], matches(RegExp(r'BBB[ ]{61}[\d, ]{5}[\d]ms')));
    });

    testWithoutContext('sequential startProgress calls with VerboseLogger and StdoutLogger', () async {
      final Logger logger = VerboseLogger(
        StdoutLogger(
          terminal: AnsiTerminal(
            stdio: mockStdio,
            platform: _kNoAnsiPlatform,
          ),
          stdio: mockStdio,
          outputPreferences: OutputPreferences.test(),
          timeoutConfiguration: const TimeoutConfiguration(),
        ),
        stopwatchFactory: FakeStopwatchFactory(),
      );
      logger.startProgress('AAA', timeout: const TimeoutConfiguration().fastOperation).stop();
      logger.startProgress('BBB', timeout: const TimeoutConfiguration().fastOperation).stop();

      expect(outputStdout(), <Matcher>[
        matches(r'^\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] AAA$'),
        matches(r'^\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] AAA \(completed.*\)$'),
        matches(r'^\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] BBB$'),
        matches(r'^\[ (?: {0,2}\+[0-9]{1,4} ms|       )\] BBB \(completed.*\)$'),
        matches(r'^$'),
      ]);
    });

    testWithoutContext('sequential startProgress calls with BufferLogger', () async {
      final BufferLogger logger = BufferLogger(
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: _kNoAnsiPlatform,
        ),
        outputPreferences: OutputPreferences.test(),
      );
      logger.startProgress('AAA', timeout: const TimeoutConfiguration().fastOperation).stop();
      logger.startProgress('BBB', timeout: const TimeoutConfiguration().fastOperation).stop();

      expect(logger.statusText, 'AAA\nBBB\n');
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

class FakeStopwatchFactory implements StopwatchFactory {
  FakeStopwatchFactory([this.stopwatch]);

  Stopwatch stopwatch;

  @override
  Stopwatch createStopwatch() {
    return stopwatch ?? FakeStopwatch();
  }
}
