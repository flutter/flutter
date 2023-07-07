// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.usage_test;

import 'package:test/test.dart';
import 'package:usage/usage.dart';

void main() => defineTests();

void defineTests() {
  group('AnalyticsMock', () {
    test('simple', () {
      var mock = AnalyticsMock();
      mock.sendScreenView('main');
      mock.sendScreenView('withParameters', parameters: {'cd1': 'custom'});
      mock.sendEvent('files', 'save');
      mock.sendEvent('eventWithParameters', 'save',
          parameters: {'cd1': 'custom'});
      mock.sendSocial('g+', 'plus', 'userid');
      mock.sendTiming('compile', 123);
      mock.startTimer('compile').finish();
      mock.sendException('FooException');
      mock.setSessionValue('val', 'ue');
      return mock.waitForLastPing();
    });
  });

  group('sanitizeStacktrace', () {
    test('replace file', () {
      expect(
          sanitizeStacktrace('(file:///Users/foo/tmp/error.dart:3:13)',
              shorten: false),
          '(error.dart:3:13)');
    });

    test('replace files', () {
      expect(
          sanitizeStacktrace(
              'foo (file:///Users/foo/tmp/error.dart:3:13)\n'
              'bar (file:///Users/foo/tmp/error.dart:3:13)',
              shorten: false),
          'foo (error.dart:3:13)\nbar (error.dart:3:13)');
    });

    test('shorten 1', () {
      expect(sanitizeStacktrace('(file:///Users/foo/tmp/error.dart:3:13)'),
          '(error.dart:3:13)');
    });

    test('shorten 2', () {
      expect(
          sanitizeStacktrace('foo (file:///Users/foo/tmp/error.dart:3:13)\n'
              'bar (file:///Users/foo/tmp/error.dart:3:13)'),
          'foo (error.dart:3:13)\nbar (error.dart:3:13)');
    });

    test('shorten 3', () {
      expect(
          sanitizeStacktrace('foo (package:foo/foo.dart:3:13)\n'
              'bar (dart:async/schedule_microtask.dart:41)'),
          'foo (package:foo/foo.dart:3:13)\nbar (dart:async/schedule_microtask.dart:41)');
    });
  });
}
