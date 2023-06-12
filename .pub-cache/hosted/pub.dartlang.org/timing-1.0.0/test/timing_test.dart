// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: only_throw_errors

import 'dart:async';

import 'package:test/test.dart';
import 'package:timing/src/clock.dart';
import 'package:timing/src/timing.dart';

void _noop() {}

void main() {
  late DateTime time;
  final startTime = DateTime(2017);
  DateTime fakeClock() => time;

  late TimeTracker tracker;
  late TimeTracker nestedTracker;

  T scopedTrack<T>(T Function() f) =>
      scopeClock(fakeClock, () => tracker.track(f));

  setUp(() {
    time = startTime;
  });

  void canHandleSync([void Function() additionalExpects = _noop]) {
    test('Can track sync code', () {
      expect(tracker.isStarted, false);
      expect(tracker.isTracking, false);
      expect(tracker.isFinished, false);
      scopedTrack(() {
        expect(tracker.isStarted, true);
        expect(tracker.isTracking, true);
        expect(tracker.isFinished, false);
        time = time.add(const Duration(seconds: 5));
      });
      expect(tracker.isStarted, true);
      expect(tracker.isTracking, false);
      expect(tracker.isFinished, true);
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 5));
      additionalExpects();
    });

    test('Can track handled sync exceptions', () async {
      scopedTrack(() {
        try {
          time = time.add(const Duration(seconds: 4));
          throw 'error';
        } on String {
          time = time.add(const Duration(seconds: 1));
        }
      });
      expect(tracker.isFinished, true);
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 5));
      additionalExpects();
    });

    test('Can track in case of unhandled sync exceptions', () async {
      expect(
          () => scopedTrack(() {
                time = time.add(const Duration(seconds: 5));
                throw 'error';
              }),
          throwsA(const TypeMatcher<String>()));
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 5));
      additionalExpects();
    });

    test('Can be nested sync', () {
      scopedTrack(() {
        time = time.add(const Duration(seconds: 1));
        nestedTracker.track(() {
          time = time.add(const Duration(seconds: 2));
        });
        time = time.add(const Duration(seconds: 4));
      });
      expect(tracker.isFinished, true);
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 7));
      expect(nestedTracker.startTime.isAfter(startTime), true);
      expect(nestedTracker.stopTime.isBefore(time), true);
      expect(nestedTracker.duration, const Duration(seconds: 2));
      additionalExpects();
    });
  }

  void canHandleAsync([void Function() additionalExpects = _noop]) {
    test('Can track async code', () async {
      expect(tracker.isStarted, false);
      expect(tracker.isTracking, false);
      expect(tracker.isFinished, false);
      await scopedTrack(() => Future(() {
            expect(tracker.isStarted, true);
            expect(tracker.isTracking, true);
            expect(tracker.isFinished, false);
            time = time.add(const Duration(seconds: 5));
          }));
      expect(tracker.isStarted, true);
      expect(tracker.isTracking, false);
      expect(tracker.isFinished, true);
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 5));
      additionalExpects();
    });

    test('Can track handled async exceptions', () async {
      await scopedTrack(() {
        time = time.add(const Duration(seconds: 1));
        return Future(() {
          time = time.add(const Duration(seconds: 2));
          throw 'error';
        }).then((_) {
          time = time.add(const Duration(seconds: 4));
        }).catchError((error, stack) {
          time = time.add(const Duration(seconds: 8));
        });
      });
      expect(tracker.isFinished, true);
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 11));
      additionalExpects();
    });

    test('Can track in case of unhandled async exceptions', () async {
      final future = scopedTrack(() {
        time = time.add(const Duration(seconds: 1));
        return Future(() {
          time = time.add(const Duration(seconds: 2));
          throw 'error';
        }).then((_) {
          time = time.add(const Duration(seconds: 4));
        });
      });
      await expectLater(future, throwsA(const TypeMatcher<String>()));
      expect(tracker.isFinished, true);
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 3));
      additionalExpects();
    });

    test('Can be nested async', () async {
      await scopedTrack(() async {
        time = time.add(const Duration(milliseconds: 1));
        await Future.value();
        time = time.add(const Duration(milliseconds: 2));
        await nestedTracker.track(() async {
          time = time.add(const Duration(milliseconds: 4));
          await Future.value();
          time = time.add(const Duration(milliseconds: 8));
          await Future.value();
          time = time.add(const Duration(milliseconds: 16));
        });
        time = time.add(const Duration(milliseconds: 32));
        await Future.value();
        time = time.add(const Duration(milliseconds: 64));
      });
      expect(tracker.isFinished, true);
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(milliseconds: 127));
      expect(nestedTracker.startTime.isAfter(startTime), true);
      expect(nestedTracker.stopTime.isBefore(time), true);
      expect(nestedTracker.duration, const Duration(milliseconds: 28));
      additionalExpects();
    });
  }

  group('SyncTimeTracker', () {
    setUp(() {
      tracker = SyncTimeTracker();
      nestedTracker = SyncTimeTracker();
    });

    canHandleSync();

    test('Can not track async code', () async {
      await scopedTrack(() => Future(() {
            time = time.add(const Duration(seconds: 5));
          }));
      expect(tracker.isFinished, true);
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, startTime);
      expect(tracker.duration, const Duration(seconds: 0));
    });
  });

  group('AsyncTimeTracker.simple', () {
    setUp(() {
      tracker = SimpleAsyncTimeTracker();
      nestedTracker = SimpleAsyncTimeTracker();
    });

    canHandleSync();

    canHandleAsync();

    test('Can not distinguish own async code', () async {
      final future = scopedTrack(() => Future(() {
            time = time.add(const Duration(seconds: 5));
          }));
      time = time.add(const Duration(seconds: 10));
      await future;
      expect(tracker.isFinished, true);
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 15));
    });
  });

  group('AsyncTimeTracker', () {
    late AsyncTimeTracker asyncTracker;
    late AsyncTimeTracker nestedAsyncTracker;
    setUp(() {
      tracker = asyncTracker = AsyncTimeTracker();
      nestedTracker = nestedAsyncTracker = AsyncTimeTracker();
    });

    canHandleSync(() {
      expect(asyncTracker.innerDuration, asyncTracker.duration);
      expect(asyncTracker.slices.length, 1);
    });

    canHandleAsync(() {
      expect(asyncTracker.innerDuration, asyncTracker.duration);
      expect(asyncTracker.slices.length, greaterThan(1));
    });

    test('Can track complex async innerDuration', () async {
      final completer = Completer();
      final future = scopedTrack(() async {
        time = time.add(const Duration(seconds: 1)); // Tracked sync
        await Future.value();
        time = time.add(const Duration(seconds: 2)); // Tracked async
        await completer.future;
        time = time.add(const Duration(seconds: 4)); // Tracked async, delayed
      }).then((_) {
        time = time.add(const Duration(seconds: 8)); // Async, after tracking
      });
      time = time.add(const Duration(seconds: 16)); // Sync, between slices

      await Future(() {
        // Async, between slices
        time = time.add(const Duration(seconds: 32));
        completer.complete();
      });
      await future;
      expect(asyncTracker.isFinished, true);
      expect(asyncTracker.startTime, startTime);
      expect(asyncTracker.stopTime.isBefore(time), true);
      expect(asyncTracker.duration, const Duration(seconds: 55));
      expect(asyncTracker.innerDuration, const Duration(seconds: 7));
      expect(asyncTracker.slices.length, greaterThan(1));
    });

    test('Can exclude nested sync', () {
      tracker = asyncTracker = AsyncTimeTracker(trackNested: false);
      scopedTrack(() {
        time = time.add(const Duration(seconds: 1));
        nestedAsyncTracker.track(() {
          time = time.add(const Duration(seconds: 2));
        });
        time = time.add(const Duration(seconds: 4));
      });
      expect(asyncTracker.isFinished, true);
      expect(asyncTracker.startTime, startTime);
      expect(asyncTracker.stopTime, time);
      expect(asyncTracker.duration, const Duration(seconds: 7));
      expect(asyncTracker.innerDuration, const Duration(seconds: 5));
      expect(asyncTracker.slices.length, greaterThan(1));
      expect(nestedAsyncTracker.startTime.isAfter(startTime), true);
      expect(nestedAsyncTracker.stopTime.isBefore(time), true);
      expect(nestedAsyncTracker.duration, const Duration(seconds: 2));
      expect(nestedAsyncTracker.innerDuration, const Duration(seconds: 2));
      expect(nestedAsyncTracker.slices.length, 1);
    });

    test('Can exclude complex nested sync', () {
      tracker = asyncTracker = AsyncTimeTracker(trackNested: false);
      nestedAsyncTracker = AsyncTimeTracker(trackNested: false);
      final nestedAsyncTracker2 = AsyncTimeTracker(trackNested: false);
      scopedTrack(() {
        time = time.add(const Duration(seconds: 1));
        nestedAsyncTracker.track(() {
          time = time.add(const Duration(seconds: 2));
          nestedAsyncTracker2.track(() {
            time = time.add(const Duration(seconds: 4));
          });
          time = time.add(const Duration(seconds: 8));
        });
        time = time.add(const Duration(seconds: 16));
      });
      expect(asyncTracker.isFinished, true);
      expect(asyncTracker.startTime, startTime);
      expect(asyncTracker.stopTime, time);
      expect(asyncTracker.duration, const Duration(seconds: 31));
      expect(asyncTracker.innerDuration, const Duration(seconds: 17));
      expect(asyncTracker.slices.length, greaterThan(1));
      expect(nestedAsyncTracker.startTime.isAfter(startTime), true);
      expect(nestedAsyncTracker.stopTime.isBefore(time), true);
      expect(nestedAsyncTracker.duration, const Duration(seconds: 14));
      expect(nestedAsyncTracker.innerDuration, const Duration(seconds: 10));
      expect(nestedAsyncTracker.slices.length, greaterThan(1));
      expect(nestedAsyncTracker2.startTime.isAfter(startTime), true);
      expect(nestedAsyncTracker2.stopTime.isBefore(time), true);
      expect(nestedAsyncTracker2.duration, const Duration(seconds: 4));
      expect(nestedAsyncTracker2.innerDuration, const Duration(seconds: 4));
      expect(nestedAsyncTracker2.slices.length, 1);
    });

    test(
        'Can track all on grand-parent level and '
        'exclude grand-childrens from parent', () {
      tracker = asyncTracker = AsyncTimeTracker(trackNested: true);
      nestedAsyncTracker = AsyncTimeTracker(trackNested: false);
      final nestedAsyncTracker2 = AsyncTimeTracker();
      scopedTrack(() {
        time = time.add(const Duration(seconds: 1));
        nestedAsyncTracker.track(() {
          time = time.add(const Duration(seconds: 2));
          nestedAsyncTracker2.track(() {
            time = time.add(const Duration(seconds: 4));
          });
          time = time.add(const Duration(seconds: 8));
        });
        time = time.add(const Duration(seconds: 16));
      });
      expect(asyncTracker.isFinished, true);
      expect(asyncTracker.startTime, startTime);
      expect(asyncTracker.stopTime, time);
      expect(asyncTracker.duration, const Duration(seconds: 31));
      expect(asyncTracker.innerDuration, const Duration(seconds: 31));
      expect(asyncTracker.slices.length, 1);
      expect(nestedAsyncTracker.startTime.isAfter(startTime), true);
      expect(nestedAsyncTracker.stopTime.isBefore(time), true);
      expect(nestedAsyncTracker.duration, const Duration(seconds: 14));
      expect(nestedAsyncTracker.innerDuration, const Duration(seconds: 10));
      expect(nestedAsyncTracker.slices.length, greaterThan(1));
      expect(nestedAsyncTracker2.startTime.isAfter(startTime), true);
      expect(nestedAsyncTracker2.stopTime.isBefore(time), true);
      expect(nestedAsyncTracker2.duration, const Duration(seconds: 4));
      expect(nestedAsyncTracker2.innerDuration, const Duration(seconds: 4));
      expect(nestedAsyncTracker2.slices.length, 1);
    });

    test('Can exclude nested async', () async {
      tracker = asyncTracker = AsyncTimeTracker(trackNested: false);
      await scopedTrack(() async {
        time = time.add(const Duration(seconds: 1));
        await nestedAsyncTracker.track(() async {
          time = time.add(const Duration(seconds: 2));
          await Future.value();
          time = time.add(const Duration(seconds: 4));
          await Future.value();
          time = time.add(const Duration(seconds: 8));
        });
        time = time.add(const Duration(seconds: 16));
      });
      expect(asyncTracker.isFinished, true);
      expect(asyncTracker.startTime, startTime);
      expect(asyncTracker.stopTime, time);
      expect(asyncTracker.duration, const Duration(seconds: 31));
      expect(asyncTracker.innerDuration, const Duration(seconds: 17));
      expect(asyncTracker.slices.length, greaterThan(1));
      expect(nestedAsyncTracker.startTime.isAfter(startTime), true);
      expect(nestedAsyncTracker.stopTime.isBefore(time), true);
      expect(nestedAsyncTracker.duration, const Duration(seconds: 14));
      expect(nestedAsyncTracker.innerDuration, const Duration(seconds: 14));
      expect(nestedAsyncTracker.slices.length, greaterThan(1));
    });

    test('Can handle callbacks in excluded nested async', () async {
      tracker = asyncTracker = AsyncTimeTracker(trackNested: false);
      await scopedTrack(() async {
        time = time.add(const Duration(seconds: 1));
        final completer = Completer();
        final future = completer.future.then((_) {
          time = time.add(const Duration(seconds: 2));
        });
        await nestedAsyncTracker.track(() async {
          time = time.add(const Duration(seconds: 4));
          await Future.value();
          time = time.add(const Duration(seconds: 8));
          completer.complete();
          await future;
          time = time.add(const Duration(seconds: 16));
        });
        time = time.add(const Duration(seconds: 32));
      });
      expect(asyncTracker.isFinished, true);
      expect(asyncTracker.startTime, startTime);
      expect(asyncTracker.stopTime, time);
      expect(asyncTracker.duration, const Duration(seconds: 63));
      expect(asyncTracker.innerDuration, const Duration(seconds: 35));
      expect(asyncTracker.slices.length, greaterThan(1));
      expect(nestedAsyncTracker.startTime.isAfter(startTime), true);
      expect(nestedAsyncTracker.stopTime.isBefore(time), true);
      expect(nestedAsyncTracker.duration, const Duration(seconds: 30));
      expect(nestedAsyncTracker.innerDuration, const Duration(seconds: 28));
      expect(nestedAsyncTracker.slices.length, greaterThan(1));
    });
  });
}
