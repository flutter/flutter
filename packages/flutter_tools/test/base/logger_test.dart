// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:test/test.dart';

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
      expect(mockLogger.errorText, matches(r'^\[ (?: {0,2}\+[0-9]{1,3} ms|       )\] Helpless!\n$'));
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
      ansiStatus = new AnsiStatus('Hello world', true, () => called++, 20);
    });

    List<String> outputLines() => mockStdio.writtenToStdout.join('').split('\n');

    Future<void> doWhile(bool doThis()) async {
      return Future.doWhile(() async {
        // Future.doWhile() isn't enough by itself, because the VM never gets
        // around to scheduling the other tasks for some reason.
        await new Future<void>.delayed(const Duration(milliseconds: 0));
        return doThis();
      });
    }

    testUsingContext('AnsiSpinner works', () async {
      ansiSpinner.start();
      await doWhile(() => ansiSpinner.ticks < 10);
      List<String> lines = outputLines();
      expect(lines[0], startsWith(' \b-\b\\\b|\b/\b-\b\\\b|\b/'));
      expect(lines[0].endsWith('\n'), isFalse);
      expect(lines.length, equals(1));
      ansiSpinner.stop();
      lines = outputLines();
      expect(lines[0], endsWith('\b \b'));
      expect(lines.length, equals(1));

      // Verify that stopping multiple times doesn't clear multiple times.
      ansiSpinner.stop();
      lines = outputLines();
      expect(lines[0].endsWith('\b \b '), isFalse);
      expect(lines.length, equals(1));
      ansiSpinner.cancel();
      lines = outputLines();
      expect(lines[0].endsWith('\b \b '), isFalse);
      expect(lines.length, equals(1));
    }, overrides: <Type, Generator>{Stdio: () => mockStdio});

    testUsingContext('AnsiStatus works when cancelled', () async {
      ansiStatus.start();
      await doWhile(() => ansiStatus.ticks < 10);
      List<String> lines = outputLines();
      expect(lines[0], startsWith('Hello world               \b-\b\\\b|\b/\b-\b\\\b|\b/\b-'));
      expect(lines[0].endsWith('\n'), isFalse);
      expect(lines.length, equals(1));
      ansiStatus.cancel();
      lines = outputLines();
      expect(lines[0], endsWith('\b \b'));
      expect(lines.length, equals(2));
      expect(called, equals(1));
      ansiStatus.cancel();
      lines = outputLines();
      expect(lines[0].endsWith('\b \b\b \b'), isFalse);
      expect(lines.length, equals(2));
      expect(called, equals(1));
      ansiStatus.stop();
      lines = outputLines();
      expect(lines[0].endsWith('\b \b\b \b'), isFalse);
      expect(lines.length, equals(2));
      expect(called, equals(1));
    }, overrides: <Type, Generator>{Stdio: () => mockStdio});

    testUsingContext('AnsiStatus works when stopped', () async {
      ansiStatus.start();
      await doWhile(() => ansiStatus.ticks < 10);
      List<String> lines = outputLines();
      expect(lines[0], startsWith('Hello world               \b-\b\\\b|\b/\b-\b\\\b|\b/\b-'));
      expect(lines.length, equals(1));

      // Verify a stop prints the time.
      ansiStatus.stop();
      lines = outputLines();
      List<Match> matches = secondDigits.allMatches(lines[0]).toList();
      expect(matches, isNotNull);
      expect(matches, hasLength(1));
      Match  match = matches.first;
      expect(lines[0], endsWith(match.group(0)));
      final String initialTime = match.group(0);
      expect(called, equals(1));
      expect(lines.length, equals(2));
      expect(lines[1], equals(''));

      // Verify stopping more than once generates no additional output.
      ansiStatus.stop();
      lines = outputLines();
      matches = secondDigits.allMatches(lines[0]).toList();
      expect(matches, hasLength(1));
      match = matches.first;
      expect(lines[0], endsWith(initialTime));
      expect(called, equals(1));
      expect(lines.length, equals(2));
      expect(lines[1], equals(''));
    }, overrides: <Type, Generator>{Stdio: () => mockStdio});

    testUsingContext('AnsiStatus works when cancelled', () async {
      ansiStatus.start();
      await doWhile(() => ansiStatus.ticks < 10);
      List<String> lines = outputLines();
      expect(lines[0], startsWith('Hello world               \b-\b\\\b|\b/\b-\b\\\b|\b/\b-'));
      expect(lines.length, equals(1));

      // Verify a cancel does _not_ print the time and prints a newline.
      ansiStatus.cancel();
      lines = outputLines();
      List<Match> matches = secondDigits.allMatches(lines[0]).toList();
      expect(matches, isEmpty);
      expect(lines[0], endsWith('\b \b'));
      expect(called, equals(1));
      // TODO(jcollins-g): Consider having status objects print the newline
      // when canceled, or never printing a newline at all.
      expect(lines.length, equals(2));

      // Verifying calling stop after cancel doesn't print anything weird.
      ansiStatus.stop();
      lines = outputLines();
      matches = secondDigits.allMatches(lines[0]).toList();
      expect(matches, isEmpty);
      expect(lines[0], endsWith('\b \b'));
      expect(called, equals(1));
      expect(lines[0], isNot(endsWith('\b \b\b \b')));
      expect(lines.length, equals(2));
    }, overrides: <Type, Generator>{Stdio: () => mockStdio});
  });
}
