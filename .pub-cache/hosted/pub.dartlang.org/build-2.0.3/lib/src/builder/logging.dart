// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

const Symbol logKey = #buildLog;

final _default = Logger('build.fallback');

/// The log instance for the currently running BuildStep.
///
/// Will be `null` when not running within a build.
Logger get log => Zone.current[logKey] as Logger? ?? _default;

/// Runs [fn] in an error handling [Zone].
///
/// Any calls to [print] will be logged with `log.warning`, and any errors will
/// be logged with `log.severe`.
///
/// Completes with the first error or result of `fn`, whichever comes first.
Future<T> scopeLogAsync<T>(Future<T> Function() fn, Logger log) {
  var done = Completer<T>();
  runZonedGuarded(fn, (e, st) {
    log.severe('', e, st);
    if (done.isCompleted) return;
    done.completeError(e, st);
  }, zoneSpecification: ZoneSpecification(print: (self, parent, zone, message) {
    log.warning(message);
  }), zoneValues: {logKey: log})?.then((result) {
    if (done.isCompleted) return;
    done.complete(result);
  });
  return done.future;
}
