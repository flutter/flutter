// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/mutex.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MutexTest);
  });
}

@reflectiveTest
class MutexTest {
  test_acquire() async {
    var values = <int>[];
    var mutex = Mutex();
    await Future.wait([
      Future(() async {
        await mutex.acquire();
        try {
          await Future<void>.delayed(Duration(milliseconds: 10));
          values.add(1);
        } finally {
          mutex.release();
        }
      }),
      Future(() async {
        await mutex.acquire();
        try {
          values.add(2);
        } finally {
          mutex.release();
        }
      }),
    ]);
    // The first Future is schedule first, and it acquires the mutex first.
    // But then it sleeps before adding (1), so if Mutex locking does not work,
    // the second Future might add (2) first.
    expect(values, [1, 2]);
  }

  test_guard() async {
    var values = <int>[];
    var mutex = Mutex();
    await Future.wait([
      Future(() async {
        await mutex.guard(() async {
          await Future<void>.delayed(Duration(milliseconds: 10));
          values.add(1);
        });
      }),
      Future(() async {
        await mutex.guard(() async {
          values.add(2);
        });
      }),
    ]);
    // The first Future is schedule first, and it acquires the mutex first.
    // But then it sleeps before adding (1), so if Mutex locking does not work,
    // the second Future might add (2) first.
    expect(values, [1, 2]);
  }

  test_release_noLock() {
    var mutex = Mutex();
    expect(() {
      mutex.release();
    }, throwsStateError);
  }

  test_release_noLock_alreadyReleased() async {
    var mutex = Mutex();
    await mutex.acquire();
    mutex.release();
    expect(() {
      mutex.release();
    }, throwsStateError);
  }
}
