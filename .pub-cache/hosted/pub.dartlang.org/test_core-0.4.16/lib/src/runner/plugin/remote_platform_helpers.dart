// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:stream_channel/stream_channel.dart';
// ignore: deprecated_member_use
import 'package:test_api/backend.dart'
    show RemoteListener, StackTraceFormatter, StackTraceMapper;

/// Returns a channel that will emit a serialized representation of the tests
/// defined in [getMain].
///
/// This channel is used to control the tests. Platform plugins should forward
/// it `deserializeSuite`. It's guaranteed to communicate using only
/// JSON-serializable values.
///
/// Any errors thrown within [getMain], synchronously or not, will be forwarded
/// to the load test for this suite. Prints will similarly be forwarded to that
/// test's print stream.
///
/// If [hidePrints] is `true` (the default), calls to `print()` within this
/// suite will not be forwarded to the parent zone's print handler. However, the
/// caller may want them to be forwarded in (for example) a browser context
/// where they'll be visible in the development console.
///
/// If [beforeLoad] is passed, it's called before the tests have been declared
/// for this worker.
StreamChannel<Object?> serializeSuite(Function Function() getMain,
        {bool hidePrints = true,
        Future Function(
                StreamChannel<Object?> Function(String name) suiteChannel)?
            beforeLoad}) =>
    RemoteListener.start(
      getMain,
      hidePrints: hidePrints,
      beforeLoad: beforeLoad,
    );

/// Sets the stack trace mapper for the current test suite.
///
/// This is used to convert JavaScript stack traces into their Dart equivalents
/// using source maps. It should be set before any tests run, usually in the
/// `onLoad()` callback to [serializeSuite].
void setStackTraceMapper(StackTraceMapper mapper) {
  var formatter = StackTraceFormatter.current;
  if (formatter == null) {
    throw StateError(
        'setStackTraceMapper() may only be called within a test worker.');
  }

  formatter.configure(mapper: mapper);
}
