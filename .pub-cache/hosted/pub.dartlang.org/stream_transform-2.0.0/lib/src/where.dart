// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'from_handlers.dart';

/// Utilities to filter events.
extension Where<T> on Stream<T> {
  /// Returns a stream which emits only the events which have type [S].
  ///
  /// If the source stream is a broadcast stream the result will be as well.
  ///
  /// Errors from the source stream are forwarded directly to the result stream.
  ///
  /// [S] should be a subtype of the stream's generic type, otherwise nothing of
  /// type [S] could possibly be emitted, however there is no static or runtime
  /// checking that this is the case.
  Stream<S> whereType<S>() => transformByHandlers(onData: (event, sink) {
        if (event is S) sink.add(event);
      });

  /// Like [where] but allows the [test] to return a [Future].
  ///
  /// Events on the result stream will be emitted in the order that [test]
  /// completes which may not match the order of the original stream.
  ///
  /// If the source stream is a broadcast stream the result will be as well. When
  /// used with a broadcast stream behavior also differs from [Stream.where] in
  /// that the [test] function is only called once per event, rather than once
  /// per listener per event.
  ///
  /// Errors from the source stream are forwarded directly to the result stream.
  /// Errors from [test] are also forwarded to the result stream.
  ///
  /// The result stream will not close until the source stream closes and all
  /// pending [test] calls have finished.
  Stream<T> asyncWhere(FutureOr<bool> Function(T) test) {
    var valuesWaiting = 0;
    var sourceDone = false;
    return transformByHandlers(onData: (element, sink) {
      valuesWaiting++;
      () async {
        try {
          if (await test(element)) sink.add(element);
        } catch (e, st) {
          sink.addError(e, st);
        }
        valuesWaiting--;
        if (valuesWaiting <= 0 && sourceDone) sink.close();
      }();
    }, onDone: (sink) {
      sourceDone = true;
      if (valuesWaiting <= 0) sink.close();
    });
  }
}
