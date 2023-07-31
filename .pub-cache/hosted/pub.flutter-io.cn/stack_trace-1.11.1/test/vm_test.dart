// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file tests stack_trace's ability to parse live stack traces. It's a
/// dual of dartium_test.dart, since method names can differ somewhat from
/// platform to platform. No similar file exists for dart2js since the specific
/// method names there are implementation details.
@TestOn('vm')

import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

// The name of this (trivial) function is verified as part of the test
String getStackTraceString() => StackTrace.current.toString();

// The name of this (trivial) function is verified as part of the test
StackTrace getStackTraceObject() => StackTrace.current;

Frame getCaller([int? level]) {
  if (level == null) return Frame.caller();
  return Frame.caller(level);
}

Frame nestedGetCaller(int level) => getCaller(level);

Trace getCurrentTrace([int level = 0]) => Trace.current(level);

Trace nestedGetCurrentTrace(int level) => getCurrentTrace(level);

void main() {
  group('Trace', () {
    test('.parse parses a real stack trace correctly', () {
      var string = getStackTraceString();
      var trace = Trace.parse(string);
      expect(path.url.basename(trace.frames.first.uri.path),
          equals('vm_test.dart'));
      expect(trace.frames.first.member, equals('getStackTraceString'));
    });

    test('converts from a native stack trace correctly', () {
      var trace = Trace.from(getStackTraceObject());
      expect(path.url.basename(trace.frames.first.uri.path),
          equals('vm_test.dart'));
      expect(trace.frames.first.member, equals('getStackTraceObject'));
    });

    test('.from handles a stack overflow trace correctly', () {
      void overflow() => overflow();

      late Trace? trace;
      try {
        overflow();
      } catch (_, stackTrace) {
        trace = Trace.from(stackTrace);
      }

      expect(trace!.frames.first.member, equals('main.<fn>.<fn>.overflow'));
    });

    group('.current()', () {
      test('with no argument returns a trace starting at the current frame',
          () {
        var trace = Trace.current();
        expect(trace.frames.first.member, equals('main.<fn>.<fn>.<fn>'));
      });

      test('at level 0 returns a trace starting at the current frame', () {
        var trace = Trace.current();
        expect(trace.frames.first.member, equals('main.<fn>.<fn>.<fn>'));
      });

      test('at level 1 returns a trace starting at the parent frame', () {
        var trace = getCurrentTrace(1);
        expect(trace.frames.first.member, equals('main.<fn>.<fn>.<fn>'));
      });

      test('at level 2 returns a trace starting at the grandparent frame', () {
        var trace = nestedGetCurrentTrace(2);
        expect(trace.frames.first.member, equals('main.<fn>.<fn>.<fn>'));
      });

      test('throws an ArgumentError for negative levels', () {
        expect(() => Trace.current(-1), throwsArgumentError);
      });
    });
  });

  group('Frame.caller()', () {
    test('with no argument returns the parent frame', () {
      expect(getCaller().member, equals('main.<fn>.<fn>'));
    });

    test('at level 0 returns the current frame', () {
      expect(getCaller(0).member, equals('getCaller'));
    });

    test('at level 1 returns the current frame', () {
      expect(getCaller(1).member, equals('main.<fn>.<fn>'));
    });

    test('at level 2 returns the grandparent frame', () {
      expect(nestedGetCaller(2).member, equals('main.<fn>.<fn>'));
    });

    test('throws an ArgumentError for negative levels', () {
      expect(() => Frame.caller(-1), throwsArgumentError);
    });
  });
}
