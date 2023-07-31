// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.hit_types_test;

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';

import 'src/common.dart';

void main() => defineTests();

void defineTests() {
  group('screenView', () {
    test('simple', () async {
      var mock = createMock();
      await mock.sendScreenView('main');
      expect(mock.mockProperties['clientId'], isNotNull);
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
    });
    test('with parameters', () async {
      var mock = createMock();
      await mock.sendScreenView('withParams', parameters: {'cd1': 'foo'});
      expect(mock.mockProperties['clientId'], isNotNull);
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
      has(mock.last, 'cd1');
    });
  });

  group('event', () {
    test('simple', () async {
      var mock = createMock();
      await mock.sendEvent('files', 'save');
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
      was(mock.last, 'event');
      has(mock.last, 'ec');
      has(mock.last, 'ea');
    });

    test('with parameters', () async {
      var mock = createMock();
      await mock.sendEvent('withParams', 'save', parameters: {'cd1': 'foo'});
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
      was(mock.last, 'event');
      has(mock.last, 'ec');
      has(mock.last, 'ea');
      has(mock.last, 'cd1');
    });

    test('optional args', () async {
      var mock = createMock();
      await mock.sendEvent('files', 'save', label: 'File Save', value: 23);
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
      was(mock.last, 'event');
      has(mock.last, 'ec');
      has(mock.last, 'ea');
      has(mock.last, 'el');
      has(mock.last, 'ev');
    });
  });

  group('social', () {
    test('simple', () async {
      var mock = createMock();
      await mock.sendSocial('g+', 'plus', 'userid');
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
      was(mock.last, 'social');
      has(mock.last, 'sn');
      has(mock.last, 'st');
      has(mock.last, 'sa');
    });
  });

  group('timing', () {
    test('simple', () async {
      var mock = createMock();
      await mock.sendTiming('compile', 123);
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
      was(mock.last, 'timing');
      has(mock.last, 'utv');
      has(mock.last, 'utt');
    });

    test('optional args', () async {
      var mock = createMock();
      await mock.sendTiming(
        'compile',
        123,
        category: 'Build',
        label: 'Compile',
      );
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
      was(mock.last, 'timing');
      has(mock.last, 'utv');
      has(mock.last, 'utt');
      has(mock.last, 'utc');
      has(mock.last, 'utl');
    });

    test('timer', () async {
      var mock = createMock();
      var timer =
          mock.startTimer('compile', category: 'Build', label: 'Compile');

      await Future.delayed(Duration(milliseconds: 20));

      await timer.finish();
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
      was(mock.last, 'timing');
      has(mock.last, 'utv');
      has(mock.last, 'utt');
      has(mock.last, 'utc');
      has(mock.last, 'utl');
      var time = timer.currentElapsedMillis;
      expect(time, greaterThan(10));

      await Future.delayed(Duration(milliseconds: 10));
      expect(timer.currentElapsedMillis, time);
    });
  });

  group('exception', () {
    test('simple', () async {
      var mock = createMock();
      await mock.sendException('FooException');
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
      was(mock.last, 'exception');
      has(mock.last, 'exd');
    });

    test('optional args', () async {
      var mock = createMock();
      await mock.sendException('FooException', fatal: true);
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
      was(mock.last, 'exception');
      has(mock.last, 'exd');
      has(mock.last, 'exf');
    });

    test('exception file paths', () async {
      var mock = createMock();
      await mock
          .sendException('foo bar (file:///Users/foobar/tmp/error.dart:3:13)');
      expect(jsonDecode(mock.last)['exd'], 'foo bar (');
    });
  });
}
