// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:async/async.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  late AsyncCache<String> cache;

  setUp(() {
    // Create a cache that is fresh for an hour.
    cache = AsyncCache(const Duration(hours: 1));
  });

  test('should fetch via a callback when no cache exists', () async {
    expect(await cache.fetch(() async => 'Expensive'), 'Expensive');
  });

  test('should not fetch via callback when a cache exists', () async {
    await cache.fetch(() async => 'Expensive');
    expect(await cache.fetch(expectAsync0(() async => 'fake', count: 0)),
        'Expensive');
  });

  group('ephemeral cache', () {
    test('should not fetch via callback when a future is in-flight', () async {
      // No actual caching is done, just avoid duplicate requests.
      cache = AsyncCache.ephemeral();

      var completer = Completer<String>();
      expect(cache.fetch(() => completer.future), completion('Expensive'));
      expect(cache.fetch(expectAsync0(() async => 'fake', count: 0)),
          completion('Expensive'));
      completer.complete('Expensive');
    });

    test('should fetch via callback when the in-flight future completes',
        () async {
      // No actual caching is done, just avoid duplicate requests.
      cache = AsyncCache.ephemeral();

      var fetched = cache.fetch(() async => 'first');
      expect(fetched, completion('first'));
      expect(
          cache.fetch(expectAsync0(() async => fail('not called'), count: 0)),
          completion('first'));
      await fetched;
      expect(cache.fetch(() async => 'second'), completion('second'));
    });

    test('should invalidate even if the future throws an exception', () async {
      cache = AsyncCache.ephemeral();

      Future<String> throwingCall() async => throw Exception();
      await expectLater(cache.fetch(throwingCall), throwsA(isException));
      // To let the timer invalidate the cache
      await Future.delayed(Duration(milliseconds: 5));

      Future<String> call() async => 'Completed';
      expect(await cache.fetch(call), 'Completed', reason: 'Cache invalidates');
    });
  });

  test('should fetch via a callback again when cache expires', () {
    FakeAsync().run((fakeAsync) async {
      var timesCalled = 0;
      Future<String> call() async => 'Called ${++timesCalled}';
      expect(await cache.fetch(call), 'Called 1');
      expect(await cache.fetch(call), 'Called 1', reason: 'Cache still fresh');

      fakeAsync.elapse(const Duration(hours: 1) - const Duration(seconds: 1));
      expect(await cache.fetch(call), 'Called 1', reason: 'Cache still fresh');

      fakeAsync.elapse(const Duration(seconds: 1));
      expect(await cache.fetch(call), 'Called 2');
      expect(await cache.fetch(call), 'Called 2', reason: 'Cache fresh again');

      fakeAsync.elapse(const Duration(hours: 1));
      expect(await cache.fetch(call), 'Called 3');
    });
  });

  test('should fetch via a callback when manually invalidated', () async {
    var timesCalled = 0;
    Future<String> call() async => 'Called ${++timesCalled}';
    expect(await cache.fetch(call), 'Called 1');
    cache.invalidate();
    expect(await cache.fetch(call), 'Called 2');
    cache.invalidate();
    expect(await cache.fetch(call), 'Called 3');
  });

  test('should fetch a stream via a callback', () async {
    expect(
        await cache.fetchStream(expectAsync0(() {
          return Stream.fromIterable(['1', '2', '3']);
        })).toList(),
        ['1', '2', '3']);
  });

  test('should not fetch stream via callback when a cache exists', () async {
    await cache.fetchStream(() async* {
      yield '1';
      yield '2';
      yield '3';
    }).toList();
    expect(
        await cache.fetchStream(expectAsync0(Stream.empty, count: 0)).toList(),
        ['1', '2', '3']);
  });

  test('should not fetch stream via callback when request in flight', () async {
    // Unlike the above test, we want to verify that we don't make multiple
    // calls if a cache is being filled currently, and instead wait for that
    // cache to be completed.
    var controller = StreamController<String>();
    Stream<String> call() => controller.stream;
    expect(cache.fetchStream(call).toList(), completion(['1', '2', '3']));
    controller.add('1');
    controller.add('2');
    await Future.value();
    expect(cache.fetchStream(call).toList(), completion(['1', '2', '3']));
    controller.add('3');
    await controller.close();
  });

  test('should fetch stream via a callback again when cache expires', () {
    FakeAsync().run((fakeAsync) async {
      var timesCalled = 0;
      Stream<String> call() {
        return Stream.fromIterable(['Called ${++timesCalled}']);
      }

      expect(await cache.fetchStream(call).toList(), ['Called 1']);
      expect(await cache.fetchStream(call).toList(), ['Called 1'],
          reason: 'Cache still fresh');

      fakeAsync.elapse(const Duration(hours: 1) - const Duration(seconds: 1));
      expect(await cache.fetchStream(call).toList(), ['Called 1'],
          reason: 'Cache still fresh');

      fakeAsync.elapse(const Duration(seconds: 1));
      expect(await cache.fetchStream(call).toList(), ['Called 2']);
      expect(await cache.fetchStream(call).toList(), ['Called 2'],
          reason: 'Cache fresh again');

      fakeAsync.elapse(const Duration(hours: 1));
      expect(await cache.fetchStream(call).toList(), ['Called 3']);
    });
  });

  test('should fetch via a callback when manually invalidated', () async {
    var timesCalled = 0;
    Stream<String> call() {
      return Stream.fromIterable(['Called ${++timesCalled}']);
    }

    expect(await cache.fetchStream(call).toList(), ['Called 1']);
    cache.invalidate();
    expect(await cache.fetchStream(call).toList(), ['Called 2']);
    cache.invalidate();
    expect(await cache.fetchStream(call).toList(), ['Called 3']);
  });

  test('should cancel a cached stream without affecting others', () async {
    Stream<String> call() => Stream.fromIterable(['1', '2', '3']);

    expect(cache.fetchStream(call).toList(), completion(['1', '2', '3']));

    // Listens to the stream for the initial value, then cancels subscription.
    expect(await cache.fetchStream(call).first, '1');
  });

  test('should pause a cached stream without affecting others', () async {
    Stream<String> call() => Stream.fromIterable(['1', '2', '3']);

    late StreamSubscription sub;
    sub = cache.fetchStream(call).listen(expectAsync1((event) {
      if (event == '1') sub.pause();
    }));
    expect(cache.fetchStream(call).toList(), completion(['1', '2', '3']));
  });
}
