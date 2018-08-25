// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  group('AppContext', () {
    test('error', () async {
      final BufferLogger mockLogger = new BufferLogger();
      final VerboseLogger verboseLogger = new VerboseLogger(mockLogger);
      verboseLogger.supportsColor = false;

      verboseLogger.printStatus('Hey Hey Hey Hey');
      verboseLogger.printTrace('Oooh, I do I do I do');
      verboseLogger.printError('Helpless!');

      expect(mockLogger.statusText, matches(r'^\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] Hey Hey Hey Hey\n'
                                             r'\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] Oooh, I do I do I do\n$'));
      expect(mockLogger.traceText, '');
      expect(mockLogger.errorText, matches( r'^\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] Helpless!\n$'));
    });
  });

  group('Spinners', () {
    MockStdio mockStdio;
    AnsiSpinner ansiSpinner;
    AnsiStatus ansiStatus;
    int called;
    final RegExp secondDigits = new RegExp(r'[^\b]\b\b\b\b\b[0-9]+[.][0-9]+(?:s|ms)');

    setUp(() {
      mockStdio = new MockStdio();
      ansiSpinner = new AnsiSpinner();
      called = 0;
      ansiStatus = new AnsiStatus(
        message: 'Hello world',
        expectSlowOperation: true,
        padding: 20,
        onFinish: () => called++,
      );
    });

    List<String> outputLines() => mockStdio.writtenToStdout.join('').split('\n');

    Future<void> doWhileAsync(bool doThis()) async {
      return Future.doWhile(() {
        // We want to let other tasks run at the same time, so we schedule these
        // using a timer rather than a microtask.
        return Future<bool>.delayed(Duration.zero, doThis);
      });
    }

    testUsingContext('AnsiSpinner works', () async {
      ansiSpinner.start();
      await doWhileAsync(() => ansiSpinner.ticks < 10);
      List<String> lines = outputLines();
      expect(lines[0], startsWith(' \b-\b\\\b|\b/\b-\b\\\b|\b/'));
      expect(lines[0].endsWith('\n'), isFalse);
      expect(lines.length, equals(1));
      ansiSpinner.stop();
      lines = outputLines();
      expect(lines[0], endsWith('\b \b'));
      expect(lines.length, equals(1));

      // Verify that stopping or canceling multiple times throws.
      expect(() { ansiSpinner.stop(); }, throwsA(isInstanceOf<AssertionError>()));
      expect(() { ansiSpinner.cancel(); }, throwsA(isInstanceOf<AssertionError>()));
    }, overrides: <Type, Generator>{Stdio: () => mockStdio});

    testUsingContext('AnsiStatus works when cancelled', () async {
      ansiStatus.start();
      await doWhileAsync(() => ansiStatus.ticks < 10);
      List<String> lines = outputLines();
      expect(lines[0], startsWith('Hello world               \b-\b\\\b|\b/\b-\b\\\b|\b/\b-'));
      expect(lines.length, equals(1));
      expect(lines[0].endsWith('\n'), isFalse);

      // Verify a cancel does _not_ print the time and prints a newline.
      ansiStatus.cancel();
      lines = outputLines();
      final List<Match> matches = secondDigits.allMatches(lines[0]).toList();
      expect(matches, isEmpty);
      expect(lines[0], endsWith('\b \b'));
      expect(called, equals(1));
      expect(lines.length, equals(2));
      expect(lines[1], equals(''));

      // Verify that stopping or canceling multiple times throws.
      expect(() { ansiStatus.cancel(); }, throwsA(isInstanceOf<AssertionError>()));
      expect(() { ansiStatus.stop(); }, throwsA(isInstanceOf<AssertionError>()));
    }, overrides: <Type, Generator>{Stdio: () => mockStdio});

    testUsingContext('AnsiStatus works when stopped', () async {
      ansiStatus.start();
      await doWhileAsync(() => ansiStatus.ticks < 10);
      List<String> lines = outputLines();
      expect(lines[0], startsWith('Hello world               \b-\b\\\b|\b/\b-\b\\\b|\b/\b-'));
      expect(lines.length, equals(1));

      // Verify a stop prints the time.
      ansiStatus.stop();
      lines = outputLines();
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
    }, overrides: <Type, Generator>{Stdio: () => mockStdio});

    testUsingContext('sequential startProgress calls with StdoutLogger', () async {
      context[Logger].startProgress('AAA')..stop();
      context[Logger].startProgress('BBB')..stop();
      expect(outputLines(), <String>[
        'AAA',
        'BBB',
        '',
      ]);
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      Logger: () => new StdoutLogger(),
    });

    testUsingContext('sequential startProgress calls with VerboseLogger and StdoutLogger', () async {
      context[Logger].startProgress('AAA')..stop();
      context[Logger].startProgress('BBB')..stop();
      expect(outputLines(), <Matcher>[
        matches(r'^\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] AAA$'),
        matches(r'^\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] AAA \(completed\)$'),
        matches(r'^\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] BBB$'),
        matches(r'^\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] BBB \(completed\)$'),
        matches(r'^$'),
      ]);
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      Logger: () => new VerboseLogger(new StdoutLogger()),
    });

    testUsingContext('sequential startProgress calls with BufferLogger', () async {
      context[Logger].startProgress('AAA')..stop();
      context[Logger].startProgress('BBB')..stop();
      final BufferLogger logger = context[Logger];
      expect(logger.statusText, 'AAA\nBBB\n');
    }, overrides: <Type, Generator>{
      Logger: () => new BufferLogger(),
    });
  });
}
