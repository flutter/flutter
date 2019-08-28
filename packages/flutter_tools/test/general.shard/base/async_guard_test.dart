// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/async_guard.dart';

import '../../src/common.dart';

Future<void> asyncError() {
  final Completer<void> completer = Completer<void>();
  final Completer<void> errorCompleter = Completer<void>();
  errorCompleter.completeError('Async Doom', StackTrace.current);
  return completer.future;
}

Future<void> syncError() {
  throw 'Sync Doom';
}

Future<void> syncAndAsyncError() {
  final Completer<void> errorCompleter = Completer<void>();
  errorCompleter.completeError('Async Doom', StackTrace.current);
  throw 'Sync Doom';
}

void main() {
  Completer<void> caughtInZone;
  bool caughtByZone = false;
  bool caughtByHandler = false;
  Zone zone;

  setUp(() {
    caughtInZone = Completer<void>();
    caughtByZone = false;
    caughtByHandler = false;
    zone = Zone.current.fork(specification: ZoneSpecification(
      handleUncaughtError: (
          Zone self,
          ZoneDelegate parent,
          Zone zone,
          Object error,
          StackTrace stackTrace,
          ) {
        caughtByZone = true;
        if (!caughtInZone.isCompleted) {
          caughtInZone.complete();
        }
      },
    ));
  });

  test('asyncError percolates through zone', () async {
    await zone.run(() async {
      try {
        // Completer is required or else we timeout.
        await Future.any(<Future<void>>[asyncError(), caughtInZone.future]);
      } on String {
        caughtByHandler = true;
      }
    });

    expect(caughtByZone, true);
    expect(caughtByHandler, false);
  });

  test('syncAndAsyncError percolates through zone', () async {
    await zone.run(() async {
      try {
        // Completer is required or else we timeout.
        await Future.any(<Future<void>>[syncAndAsyncError(), caughtInZone.future]);
      } on String {
        caughtByHandler = true;
      }
    });

    expect(caughtByZone, true);
    expect(caughtByHandler, true);
  });

  test('syncError percolates through zone', () async {
    await zone.run(() async {
      try {
        await syncError();
      } on String {
        caughtByHandler = true;
      }
    });

    expect(caughtByZone, false);
    expect(caughtByHandler, true);
  });

  test('syncError is caught by asyncGuard', () async {
    await zone.run(() async {
      try {
        await asyncGuard(syncError);
      } on String {
        caughtByHandler = true;
      }
    });

    expect(caughtByZone, false);
    expect(caughtByHandler, true);
  });


  test('asyncError is caught by asyncGuard', () async {
    await zone.run(() async {
      try {
        await asyncGuard(asyncError);
      } on String {
        caughtByHandler = true;
      }
    });

    expect(caughtByZone, false);
    expect(caughtByHandler, true);
  });

  test('asyncAndSyncError is caught by asyncGuard', () async {
    await zone.run(() async {
      try {
        await asyncGuard(syncAndAsyncError);
      } on String {
        caughtByHandler = true;
      }
    });

    expect(caughtByZone, false);
    expect(caughtByHandler, true);
  });
}
