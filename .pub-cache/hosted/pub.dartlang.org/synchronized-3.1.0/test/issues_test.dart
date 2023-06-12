// Copyright (c) 2016, Alexandre Roux Tekartik. All rights reserved. Use of this source code

// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:synchronized/src/utils.dart';
import 'package:synchronized/synchronized.dart';
import 'package:test/test.dart';

void main() {
  group('issues', () {
    // https://github.com/tekartik/synchronized.dart/issues/22
    test('issue_22_1', () async {
      var lock = Lock();

      // Create a long synchronized function but don't wait for it
      unawaited(lock.synchronized(() async {
        await Future<void>.delayed(const Duration(hours: 1));
      }));

      // Try to grab the lock, this should fail with a time out exception
      try {
        await lock.synchronized(() async {
          // We should never get there
          fail('should timeout');
        }, timeout: const Duration(milliseconds: 100));
      } on TimeoutException catch (_) {}
    });

    test('issue_22_timeout', () async {
      var lock = Lock();

      try {
        // Create a long synchronized function that times out
        await lock.synchronized(() async {
          Future<void> longAction() async {
            // Do you action here...
            await Future<void>.delayed(const Duration(hours: 1));
          }

          // Release the lock before the end
          await longAction().timeout(const Duration(milliseconds: 100));
        });
      } on TimeoutException catch (_) {}
    });
    // https://github.com/tekartik/synchronized.dart/issues/1
    test('issue_1', () async {
      var value = '';
      var lock = Lock(reentrant: true);

      final outer1 = lock.synchronized(() async {
        expect(value, equals(''));
        value = 'outer1';

        await sleep(20);

        await lock.synchronized(() async {
          await sleep(30);
          expect(value, equals('outer1'));
          value = 'inner1';
        });
      });

      final outer2 = lock.synchronized(() async {
        await sleep(30);
        expect(value, equals('inner1'));
        value = 'outer2';
      });

      final outer3 = sleep(30).whenComplete(() {
        return lock.synchronized(() async {
          expect(value, equals('outer2'));
          value = 'outer3';
        });
      });

      await Future.wait([outer1, outer2, outer3]);

      expect(value, equals('outer3'));
    });
  });
}
