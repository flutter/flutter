// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.impl_test;

import 'package:test/test.dart';
import 'package:usage/src/usage_impl.dart';

import 'src/common.dart';

void main() => defineTests();

void defineTests() {
  group('ThrottlingBucket', () {
    test('can send', () {
      var bucket = ThrottlingBucket(20);
      expect(bucket.removeDrop(), true);
    });

    test('doesn\'t send too many', () {
      var bucket = ThrottlingBucket(20);
      for (var i = 0; i < 20; i++) {
        expect(bucket.removeDrop(), true);
      }
      expect(bucket.removeDrop(), false);
    });

    test('does re-send after throttling', () async {
      var bucket = ThrottlingBucket(20);
      for (var i = 0; i < 20; i++) {
        expect(bucket.removeDrop(), true);
      }
      expect(bucket.removeDrop(), false);

      // TODO: Re-write to use package:fake_async.
      await Future.delayed(Duration(milliseconds: 1500));
      expect(bucket.removeDrop(), true);
    });
  });

  group('AnalyticsImpl', () {
    test('trackingId', () {
      var mock = createMock();
      expect(mock.trackingId, isNotNull);
    });

    test('applicationName', () {
      var mock = createMock();
      expect(mock.applicationName, isNotNull);
    });

    test('applicationVersion', () {
      var mock = createMock();
      expect(mock.applicationVersion, isNotNull);
    });

    test('respects disabled', () {
      var mock = createMock();
      mock.enabled = false;
      mock.sendException('FooBar exception');
      expect(mock.enabled, false);
      expect(mock.mockPostHandler.sentValues, isEmpty);
    });

    test('firstRun', () {
      var mock = createMock();
      expect(mock.firstRun, true);
      mock = createMock(props: {'firstRun': false});
      expect(mock.firstRun, false);
    });

    test('setSessionValue', () async {
      var mock = createMock();
      await mock.sendScreenView('foo');
      hasnt(mock.last, 'val');
      mock.setSessionValue('val', 'ue');
      await mock.sendScreenView('bar');
      has(mock.last, 'val');
      mock.setSessionValue('val', null);
      await mock.sendScreenView('baz');
      hasnt(mock.last, 'val');
    });

    test('waitForLastPing', () {
      var mock = createMock();
      mock.sendScreenView('foo');
      mock.sendScreenView('bar');
      mock.sendScreenView('baz');
      return mock.waitForLastPing(timeout: Duration(milliseconds: 100));
    });

    test('waitForLastPing times out', () async {
      var mock = StallingAnalyticsImplMock('blahID');
      // ignore: unawaited_futures
      mock.sendScreenView('foo');
      await mock.waitForLastPing(timeout: Duration(milliseconds: 100));
    });

    group('clientId', () {
      test('is available immediately', () {
        var mock = createMock();
        expect(mock.clientId, isNotEmpty);
      });

      test('is memoized', () {
        var mock = createMock();
        final value1 = mock.clientId;
        final value2 = mock.clientId;
        expect(value1, isNotEmpty);
        expect(value1, value2);
      });

      test('is stored in properties', () {
        var mock = createMock();
        expect(mock.properties['clientId'], isNull);
        final value = mock.clientId;
        expect(mock.properties['clientId'], value);
      });
    });
  });

  group('postEncode', () {
    test('simple', () {
      var map = <String, dynamic>{'foo': 'bar', 'baz': 'qux norf'};
      expect(postEncode(map), 'foo=bar&baz=qux%20norf');
    });
  });
}
