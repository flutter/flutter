// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/zone_check.dart';

import '../../src/common.dart';

void main() {
  test('sync Completer.completeError does not throw error into zone runZoneChecked and try/catch', () async {
    bool caughtByZone = false;
    bool caughtByHandler = false;
    final Zone zone = Zone.current.fork(specification: ZoneSpecification(
      handleUncaughtError: (
          Zone self,
          ZoneDelegate parent,
          Zone zone,
          Object error,
          StackTrace stackTrace,
          ) {
        caughtByZone = true;
      },
    ));

    await zone.run(() async {
      try {
        await runZoneChecked(() async {
          final Completer<void> completer = Completer<void>.sync();
          completer.completeError(Exception());
          return completer.future;
        });
      } on Exception {
        caughtByHandler = true;
      }
    });
    expect(caughtByZone, false);
    expect(caughtByHandler, true);
  });


  test('async method does not throw error into zone with runZoneChecked and try/catch', () async {
    bool caughtByZone = false;
    bool caughtByHandler = false;
    final Zone zone = Zone.current.fork(specification: ZoneSpecification(
      handleUncaughtError: (
          Zone self,
          ZoneDelegate parent,
          Zone zone,
          Object error,
          StackTrace stackTrace,
          ) {
        caughtByZone = true;
      },
    ));

    await zone.run(() async {
      try {
        await runZoneChecked(() async {
          throw Exception();
        });
      } on Exception {
        caughtByHandler = true;
      }
    });
    expect(caughtByZone, false);
    expect(caughtByHandler, true);
  });

  test('async method does not throw error into zone with runZoneChecked and catchError', () async {
    bool caughtByZone = false;
    bool caughtByHandler = false;
    final Zone zone = Zone.current.fork(specification: ZoneSpecification(
      handleUncaughtError: (
          Zone self,
          ZoneDelegate parent,
          Zone zone,
          Object error,
          StackTrace stackTrace,
          ) {
        caughtByZone = true;
      },
    ));

    await zone.run(() async {
      return runZoneChecked(() async {
        throw Exception();
      }).catchError((Object error) {
        caughtByHandler = true;
      });
    });
    expect(caughtByZone, false);
    expect(caughtByHandler, true);
  });
}
