// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

void main() async {
  test('sync', () async {
    List<int> freed = [];
    void freeInt(int i) {
      freed.add(i);
    }

    using((Arena arena) {
      arena.using(1234, freeInt);
      expect(freed.isEmpty, true);
    });
    expect(freed, [1234]);
  });

  test('async', () async {
    /// Calling [using] waits with releasing its resources until after
    /// [Future]s complete.
    List<int> freed = [];
    void freeInt(int i) {
      freed.add(i);
    }

    Future<int> myFutureInt = using((Arena arena) {
      return Future.microtask(() {
        arena.using(1234, freeInt);
        return 1;
      });
    });

    expect(freed.isEmpty, true);
    await myFutureInt;
    expect(freed, [1234]);
  });

  test('throw', () {
    /// [using] waits with releasing its resources until after [Future]s
    /// complete.
    List<int> freed = [];
    void freeInt(int i) {
      freed.add(i);
    }

    // Resources are freed also when abnormal control flow occurs.
    var didThrow = false;
    try {
      using((Arena arena) {
        arena.using(1234, freeInt);
        expect(freed.isEmpty, true);
        throw Exception('Exception 1');
      });
    } on Exception {
      expect(freed.single, 1234);
      didThrow = true;
    }
    expect(didThrow, true);
  });

  test(
    'allocate',
    () {
      final countingAllocator = CountingAllocator();
      // To ensure resources are freed, wrap them in a [using] call.
      using((Arena arena) {
        final p = arena<Int64>(2);
        p[1] = p[0];
      }, countingAllocator);
      expect(countingAllocator.freeCount, 1);
    },
  );

  test('allocate throw', () {
    // Resources are freed also when abnormal control flow occurs.
    bool didThrow = false;
    final countingAllocator = CountingAllocator();
    try {
      using((Arena arena) {
        final p = arena<Int64>(2);
        p[0] = 25;
        throw Exception('Exception 2');
      }, countingAllocator);
    } on Exception {
      expect(countingAllocator.freeCount, 1);
      didThrow = true;
    }
    expect(didThrow, true);
  });

  test('toNativeUtf8', () {
    final countingAllocator = CountingAllocator();
    using((Arena arena) {
      final p = 'Hello world!'.toNativeUtf8(allocator: arena);
      expect(p.toDartString(), 'Hello world!');
    }, countingAllocator);
    expect(countingAllocator.freeCount, 1);
  });

  test('zone', () async {
    List<int> freed = [];
    void freeInt(int i) {
      freed.add(i);
    }

    withZoneArena(() {
      zoneArena.using(1234, freeInt);
      expect(freed.isEmpty, true);
    });
    expect(freed.length, 1);
    expect(freed.single, 1234);
  });

  test('zone async', () async {
    /// [using] waits with releasing its resources until after [Future]s
    /// complete.
    List<int> freed = [];
    void freeInt(int i) {
      freed.add(i);
    }

    Future<int> myFutureInt = withZoneArena(() {
      return Future.microtask(() {
        zoneArena.using(1234, freeInt);
        return 1;
      });
    });

    expect(freed.isEmpty, true);
    await myFutureInt;
    expect(freed.length, 1);
    expect(freed.single, 1234);
  });

  test('zone throw', () {
    /// [using] waits with releasing its resources until after [Future]s
    /// complete.
    List<int> freed = [];
    void freeInt(int i) {
      freed.add(i);
    }

    // Resources are freed also when abnormal control flow occurs.
    bool didThrow = false;
    try {
      withZoneArena(() {
        zoneArena.using(1234, freeInt);
        expect(freed.isEmpty, true);
        throw Exception('Exception 3');
      });
    } on Exception {
      expect(freed.single, 1234);
      didThrow = true;
    }
    expect(didThrow, true);
    expect(freed.single, 1234);
  });

  test('zone future error', () async {
    bool caughtError = false;
    bool uncaughtError = false;

    Future<int> asyncFunction() async {
      throw Exception('Exception 4');
    }

    final future = runZonedGuarded(() {
      return withZoneArena(asyncFunction).catchError((error) {
        caughtError = true;
        return 5;
      });
    }, (error, stackTrace) {
      uncaughtError = true;
    });

    final result = (await Future.wait([future!])).single;

    expect(result, 5);
    expect(caughtError, true);
    expect(uncaughtError, false);
  });

  test('allocate during releaseAll', () {
    final countingAllocator = CountingAllocator();
    final arena = Arena(countingAllocator);

    arena.using(arena<Uint8>(), (Pointer discard) {
      arena<Uint8>();
    });

    expect(countingAllocator.allocationCount, 1);
    expect(countingAllocator.freeCount, 0);

    arena.releaseAll(reuse: true);

    expect(countingAllocator.allocationCount, 2);
    expect(countingAllocator.freeCount, 2);
  });
}

/// Keeps track of the number of allocates and frees for testing purposes.
class CountingAllocator implements Allocator {
  final Allocator wrappedAllocator;

  int allocationCount = 0;
  int freeCount = 0;

  CountingAllocator([this.wrappedAllocator = calloc]);

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    allocationCount++;
    return wrappedAllocator.allocate(byteCount, alignment: alignment);
  }

  @override
  void free(Pointer<NativeType> pointer) {
    freeCount++;
    return wrappedAllocator.free(pointer);
  }
}
