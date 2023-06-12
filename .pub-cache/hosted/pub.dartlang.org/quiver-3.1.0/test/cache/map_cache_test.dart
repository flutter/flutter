// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library quiver.cache.map_cache_test;

import 'dart:async';

import 'package:quiver/src/cache/map_cache.dart';
import 'package:test/test.dart';

void main() {
  group('MapCache', () {
    late MapCache<String, String> cache;

    setUp(() {
      cache = MapCache<String, String>();
    });

    test('should return null for a non-existent key', () {
      return cache.get('foo').then((value) {
        expect(value, isNull);
      });
    });

    test('should return a previously set key/value pair', () {
      return cache
          .set('foo', 'bar')
          .then((_) => cache.get('foo'))
          .then((value) {
        expect(value, 'bar');
      });
    });

    test('should invalidate a key', () {
      return cache
          .set('foo', 'bar')
          .then((_) => cache.invalidate('foo'))
          .then((_) => cache.get('foo'))
          .then((value) {
        expect(value, null);
      });
    });

    test('should return null if no value and no ifAbsent handler', () {
      return cache.get('foo').then((value) {
        expect(value, isNull);
      });
    });

    test('should load a value given a synchronous loader', () {
      return cache.get('foo', ifAbsent: (k) => k + k).then((value) {
        expect(value, 'foofoo');
      });
    });

    test('should load a value given an asynchronous loader', () {
      return cache
          .get('foo', ifAbsent: (k) => Future.value(k + k))
          .then((value) {
        expect(value, 'foofoo');
      });
    });

    test('should not make multiple requests for the same key', () async {
      final completer = Completer<String>();
      int count = 0;

      Future<String> loader(String key) {
        count += 1;
        return completer.future;
      }

      final futures = Future.wait([
        cache.get('test', ifAbsent: loader),
        cache.get('test', ifAbsent: loader),
      ]);

      completer.complete('bar');
      expect(count, equals(1));
      expect(await futures, equals(['bar', 'bar']));
    });

    test('should not cache a failed request', () async {
      int count = 0;

      Future<String> failLoader(String key) async {
        count += 1;
        throw StateError('Request failed');
      }

      await expectLater(
          () => cache.get('test', ifAbsent: failLoader), throwsStateError);
      await expectLater(
          () => cache.get('test', ifAbsent: failLoader), throwsStateError);

      expect(count, equals(2));
      expect(await cache.get('test'), isNull);

      // Make sure it doesn't block a later successful load.
      await expectLater(
          await cache.get('test', ifAbsent: (key) => 'bar'), 'bar');
    });
  });
}
