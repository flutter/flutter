// Copyright (c) 2016, Alexandre Roux Tekartik. All rights reserved. Use of this source code

// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:synchronized/src/basic_lock.dart';
import 'package:synchronized/src/reentrant_lock.dart';
import 'package:synchronized/src/utils.dart';
import 'package:synchronized/synchronized.dart' as common;
import 'package:test/test.dart';

void main() {
  group('synchronized_impl', () {
    group('BasicLock', () {
      test('type', () {
        var lock = common.Lock();
        expect(lock, const TypeMatcher<BasicLock>());
      });
      test('toString', () {
        var lock = common.Lock();
        expect('$lock', startsWith('Lock['));
        expect('$lock', endsWith(']'));
      });
    });

    group('ReentrantLock', () {
      test('type', () {
        var lock = common.Lock(reentrant: true);
        expect(lock, const TypeMatcher<ReentrantLock>());
      });

      test('toString', () {
        var lock = common.Lock(reentrant: true);
        expect('$lock', startsWith('ReentrantLock['));
        expect('$lock', endsWith(']'));
      });

      group('locked', () {
        test('inner', () async {
          final lock = ReentrantLock();
          final completer = Completer();
          final innerCompleter = Completer();
          final future = lock.synchronized(() async {
            await lock.synchronized(() async {
              await sleep(1);
              await innerCompleter.future;
            });
            await completer.future;
          });
          expect(lock.locked, isTrue);
          completer.complete();
          try {
            await lock.synchronized(() {},
                timeout: const Duration(milliseconds: 100));
            fail('should fail');
          } on TimeoutException catch (_) {}
          expect(lock.locked, isTrue);
          innerCompleter.complete();
          await future;
          expect(lock.locked, isFalse);
        });
      });

      group('inLock', () {
        test('two_locks', () async {
          final lock1 = ReentrantLock();
          final lock2 = ReentrantLock();
          final completer = Completer();
          final future = lock1.synchronized(() async {
            expect(lock1.inLock, isTrue);
            expect(lock2.inLock, isFalse);
            await completer.future;
          });
          expect(lock1.inLock, isFalse);
          completer.complete();
          await future;
        });

        test('inner', () async {
          final lock = ReentrantLock();
          expect(lock.innerLocks.length, 1);
          final future = lock.synchronized(() async {
            expect(lock.inLock, isTrue);

            expect(lock.innerLocks.length, 2);

            await lock.synchronized(() async {
              expect(lock.innerLocks.length, 3);
              expect(lock.inLock, isTrue);
              await sleep(10);
              expect(lock.inLock, isTrue);
              expect(lock.innerLocks.length, 3);
            });
            expect(lock.innerLocks.length, 2);
          });
          // yes we are right away at level 3!
          expect(lock.innerLocks.length, 3);
          expect(lock.inLock, isFalse);
          await future;
          expect(lock.innerLocks.length, 1);
          expect(lock.inLock, isFalse);
        });

        test('inner_vs_outer', () async {
          final list = <int>[];
          final lock = ReentrantLock();
          final future = lock.synchronized(() async {
            await sleep(10);
            await lock.synchronized(() async {
              await sleep(20);
              list.add(1);
            });
          });
          expect(lock.inLock, isFalse);
          final future2 = lock.synchronized(() async {
            await sleep(10);
            list.add(2);
          });
          final future3 = sleep(20).whenComplete(() async {
            await lock.synchronized(() async {
              list.add(3);
            });
          });
          await Future.wait([future, future2, future3]);
          expect(list, [1, 2, 3]);
        });
      });
    });
  });
}
