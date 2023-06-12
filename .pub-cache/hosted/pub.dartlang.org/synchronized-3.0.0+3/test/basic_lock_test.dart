// Copyright (c) 2016, Alexandre Roux Tekartik. All rights reserved. Use of this source code

// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:synchronized/synchronized.dart';
import 'package:test/test.dart';

import 'common_lock_test_.dart' as lock_test;
import 'lock_factory.dart';

void main() {
  final lockFactory = BasicLockFactory();
  group('BasicLock', () {
    // Common tests
    lock_test.lockMain(lockFactory);

    test('non-reentrant', () async {
      final lock = Lock();
      Object? exception;
      await lock.synchronized(() async {
        try {
          await lock.synchronized(() {}, timeout: const Duration(seconds: 1));
        } catch (e) {
          exception = e;
        }
      });
      expect(exception, const TypeMatcher<TimeoutException>());
    });
  });
}
