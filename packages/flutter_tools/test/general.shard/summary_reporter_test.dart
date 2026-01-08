// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/test/summary_reporter.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('SummaryReporter', () {
    late BufferLogger logger;
    late _FakeStdout fakeStdout;

    setUp(() {
      logger = BufferLogger.test();
      fakeStdout = _FakeStdout();
    });

    testUsingContext('tracks failed tests from JSON output', () async {
      final reporter = SummaryReporter(supportsColor: false, stdout: fakeStdout);

      // Simulate JSON reporter output
      reporter.handleLine(
        '{"protocolVersion":"0.1.1","runnerVersion":"1.24.9","type":"start","time":0}',
      );
      reporter.handleLine(
        '{"suite":{"id":0,"path":"test/example_test.dart"},"type":"suite","time":5}',
      );
      reporter.handleLine(
        '{"test":{"id":1,"name":"passing test","suiteID":0,"groupIDs":[]},"type":"testStart","time":10}',
      );
      reporter.handleLine(
        '{"testID":1,"result":"success","hidden":false,"skipped":false,"type":"testDone","time":20}',
      );
      reporter.handleLine(
        '{"test":{"id":2,"name":"failing test A","suiteID":0,"groupIDs":[]},"type":"testStart","time":30}',
      );
      reporter.handleLine(
        '{"testID":2,"result":"failure","hidden":false,"skipped":false,"type":"testDone","time":40}',
      );
      reporter.handleLine(
        '{"test":{"id":3,"name":"failing test B","suiteID":0,"groupIDs":[]},"type":"testStart","time":50}',
      );
      reporter.handleLine(
        '{"testID":3,"result":"error","hidden":false,"skipped":false,"type":"testDone","time":60}',
      );
      reporter.handleLine('{"success":false,"type":"done","time":70}');

      expect(logger.statusText, contains('Failing tests:'));
      expect(logger.statusText, contains('failing test A'));
      expect(logger.statusText, contains('failing test B'));
    }, overrides: <Type, Generator>{Logger: () => logger});

    testUsingContext('does not print summary when all tests pass', () async {
      final reporter = SummaryReporter(supportsColor: false, stdout: fakeStdout);

      reporter.handleLine('{"type":"start","time":0}');
      reporter.handleLine(
        '{"test":{"id":1,"name":"passing test","suiteID":0,"groupIDs":[]},"type":"testStart","time":10}',
      );
      reporter.handleLine(
        '{"testID":1,"result":"success","hidden":false,"skipped":false,"type":"testDone","time":20}',
      );
      reporter.handleLine('{"success":true,"type":"done","time":30}');

      expect(logger.statusText, contains('All tests passed!'));
      expect(logger.statusText, isNot(contains('Failing tests:')));
    }, overrides: <Type, Generator>{Logger: () => logger});

    testUsingContext('handles malformed JSON gracefully', () async {
      final reporter = SummaryReporter(supportsColor: false, stdout: fakeStdout);

      // This should not throw
      reporter.handleLine('not valid json');
      reporter.handleLine('{"also": "not a test event"');
      reporter.handleLine('');

      // No crash means success
    }, overrides: <Type, Generator>{Logger: () => logger});

    testUsingContext('ignores hidden tests', () async {
      final reporter = SummaryReporter(supportsColor: false, stdout: fakeStdout);

      reporter.handleLine('{"type":"start","time":0}');
      reporter.handleLine(
        '{"test":{"id":1,"name":"(setUpAll)","suiteID":0,"groupIDs":[]},"type":"testStart","time":10}',
      );
      reporter.handleLine(
        '{"testID":1,"result":"failure","hidden":true,"skipped":false,"type":"testDone","time":20}',
      );
      reporter.handleLine('{"success":false,"type":"done","time":30}');

      // Hidden tests should not appear in summary
      expect(logger.statusText, isNot(contains('(setUpAll)')));
    }, overrides: <Type, Generator>{Logger: () => logger});

    testUsingContext('includes suite path in failure summary', () async {
      final reporter = SummaryReporter(supportsColor: false, stdout: fakeStdout);

      reporter.handleLine('{"type":"start","time":0}');
      reporter.handleLine(
        '{"suite":{"id":0,"path":"test/widget_test.dart"},"type":"suite","time":5}',
      );
      reporter.handleLine(
        '{"test":{"id":1,"name":"my failing test","suiteID":0,"groupIDs":[]},"type":"testStart","time":10}',
      );
      reporter.handleLine(
        '{"testID":1,"result":"failure","hidden":false,"skipped":false,"type":"testDone","time":20}',
      );
      reporter.handleLine('{"success":false,"type":"done","time":30}');

      expect(logger.statusText, contains('test/widget_test.dart: my failing test'));
    }, overrides: <Type, Generator>{Logger: () => logger});

    testUsingContext('handles skipped tests', () async {
      final reporter = SummaryReporter(supportsColor: false, stdout: fakeStdout);

      reporter.handleLine('{"type":"start","time":0}');
      reporter.handleLine(
        '{"test":{"id":1,"name":"skipped test","suiteID":0,"groupIDs":[]},"type":"testStart","time":10}',
      );
      reporter.handleLine(
        '{"testID":1,"result":"success","hidden":false,"skipped":true,"type":"testDone","time":20}',
      );
      reporter.handleLine('{"success":true,"type":"done","time":30}');

      // Skipped tests should not be in failed list
      expect(logger.statusText, isNot(contains('Failing tests:')));
    }, overrides: <Type, Generator>{Logger: () => logger});

    testUsingContext('outputs error messages', () async {
      final reporter = SummaryReporter(supportsColor: false, stdout: fakeStdout);

      reporter.handleLine('{"type":"start","time":0}');
      reporter.handleLine(
        '{"test":{"id":1,"name":"test with error","suiteID":0,"groupIDs":[]},"type":"testStart","time":10}',
      );
      reporter.handleLine(
        r'{"testID":1,"error":"Expected: 2\n  Actual: 1","type":"error","time":15}',
      );
      reporter.handleLine(
        '{"testID":1,"result":"failure","hidden":false,"skipped":false,"type":"testDone","time":20}',
      );
      reporter.handleLine('{"success":false,"type":"done","time":30}');

      expect(logger.statusText, contains('Expected: 2'));
      expect(logger.statusText, contains('Actual: 1'));
    }, overrides: <Type, Generator>{Logger: () => logger});

    testUsingContext('outputs print messages', () async {
      final reporter = SummaryReporter(supportsColor: false, stdout: fakeStdout);

      reporter.handleLine('{"type":"start","time":0}');
      reporter.handleLine(
        '{"test":{"id":1,"name":"test with print","suiteID":0,"groupIDs":[]},"type":"testStart","time":10}',
      );
      reporter.handleLine('{"testID":1,"message":"Hello from test!","type":"print","time":15}');
      reporter.handleLine(
        '{"testID":1,"result":"success","hidden":false,"skipped":false,"type":"testDone","time":20}',
      );
      reporter.handleLine('{"success":true,"type":"done","time":30}');

      expect(logger.statusText, contains('Hello from test!'));
    }, overrides: <Type, Generator>{Logger: () => logger});
  });
}

/// A fake stdout implementation for testing that doesn't write to the real stdout.
class _FakeStdout implements io.Stdout {
  final StringBuffer _buffer = StringBuffer();

  String get output => _buffer.toString();

  @override
  void write(Object? object) {
    _buffer.write(object);
  }

  @override
  void writeln([Object? object = '']) {
    _buffer.writeln(object);
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String sep = '']) {
    _buffer.writeAll(objects, sep);
  }

  @override
  void writeCharCode(int charCode) {
    _buffer.writeCharCode(charCode);
  }

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding encoding) {}

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> get done => Future<void>.value();

  @override
  Future<void> flush() async {}

  @override
  bool get hasTerminal => false;

  @override
  io.IOSink get nonBlocking => throw UnimplementedError();

  @override
  bool get supportsAnsiEscapes => false;

  @override
  int get terminalColumns => 80;

  @override
  int get terminalLines => 24;

  @override
  String get lineTerminator => '\n';

  @override
  set lineTerminator(String value) {}
}
