// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

/// Force uncaught zone exceptions through normal exception control flow.
///
/// When an exception is caught either via try/catch or the zone, trap it
/// and use the finally block to reestablish normal control flow. Then rethrow
/// the error so it can be handled via normal control flow.
Future<void> runZoneChecked(FutureOr<void> Function() cb) async{
  final Completer<void> completer = Completer<void>();
  final Zone zone = Zone.current.fork(
      specification: ZoneSpecification(
    handleUncaughtError: (
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      Object error,
      StackTrace stackTrace,
    ) {
      // Do nothing so regular control flow is reestablished.
    },
  ));
  Object error;

  zone.runGuarded(() async {
    try {
      await cb();
    } catch (err) {
      error = err;
    } finally {
      completer.complete();
    }
  });
  await completer.future;

  if (error != null) {
    throw error;
  }
}
