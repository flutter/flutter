// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'aggregate_sample.dart';
import 'from_handlers.dart';
import 'rate_limit.dart';

/// Alternatives to [asyncMap].
///
/// The built in [asyncMap] will not overlap execution of the passed callback,
/// and every event will be sent to the callback individually.
///
/// - [asyncMapBuffer] prevents the callback from overlapping execution and
///   collects events while it is executing to process in batches.
/// - [asyncMapSample] prevents overlapping execution and discards events while
///   it is executing.
/// - [concurrentAsyncMap] allows overlap and removes ordering guarantees.
extension AsyncMap<T> on Stream<T> {
  /// Like [asyncMap] but events are buffered until previous events have been
  /// processed by [convert].
  ///
  /// If this stream is a broadcast stream the result will be as well.
  /// When used with a broadcast stream behavior also differs from [asyncMap] in
  /// that the [convert] function is only called once per event, rather than
  /// once per listener per event.
  ///
  /// The first event from this stream is always passed to [convert] as a
  /// list with a single element.
  /// After that, events are buffered until the previous Future returned from
  /// [convert] has completed.
  ///
  /// Errors from this stream are forwarded directly to the result stream.
  /// Errors during the conversion are also forwarded to the result stream and
  /// are considered completing work so the next values are let through.
  ///
  /// The result stream will not close until this stream closes and all pending
  /// conversions have finished.
  Stream<S> asyncMapBuffer<S>(Future<S> Function(List<T>) convert) {
    var workFinished = StreamController<void>()
      // Let the first event through.
      ..add(null);
    return buffer(workFinished.stream)._asyncMapThen(convert, workFinished.add);
  }

  /// Like [asyncMap] but events are discarded while work is happening in
  /// [convert].
  ///
  /// If this stream is a broadcast stream the result will be as well.
  /// When used with a broadcast stream behavior also differs from [asyncMap] in
  /// that the [convert] function is only called once per event, rather than
  /// once per listener per event.
  ///
  /// If no work is happening when an event is emitted it will be immediately
  /// passed to [convert]. If there is ongoing work when an event is emitted it
  /// will be held until the work is finished. New events emitted will replace a
  /// pending event.
  ///
  /// Errors from this stream are forwarded directly to the result stream.
  /// Errors during the conversion are also forwarded to the result stream and are
  /// considered completing work so the next values are let through.
  ///
  /// The result stream will not close until this stream closes and all pending
  /// conversions have finished.
  Stream<S> asyncMapSample<S>(Future<S> Function(T) convert) {
    var workFinished = StreamController<void>()
      // Let the first event through.
      ..add(null);
    return aggregateSample(
            trigger: workFinished.stream,
            aggregate: _dropPrevious,
            longPoll: true,
            onEmpty: _ignore)
        ._asyncMapThen(convert, workFinished.add);
  }

  /// Like [asyncMap] but the [convert] callback may be called for an element
  /// before processing for the previous element is finished.
  ///
  /// Events on the result stream will be emitted in the order that [convert]
  /// completed which may not match the order of this stream.
  ///
  /// If this stream is a broadcast stream the result will be as well.
  /// When used with a broadcast stream behavior also differs from [asyncMap] in
  /// that the [convert] function is only called once per event, rather than
  /// once per listener per event. The [convert] callback won't be called for
  /// events while a broadcast stream has no listener.
  ///
  /// Errors from [convert] or this stream are forwarded directly to the
  /// result stream.
  ///
  /// The result stream will not close until this stream closes and all pending
  /// conversions have finished.
  Stream<S> concurrentAsyncMap<S>(FutureOr<S> Function(T) convert) {
    var valuesWaiting = 0;
    var sourceDone = false;
    return transformByHandlers(onData: (element, sink) {
      valuesWaiting++;
      () async {
        try {
          sink.add(await convert(element));
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

  /// Like [Stream.asyncMap] but the [convert] is only called once per event,
  /// rather than once per listener, and [then] is called after completing the
  /// work.
  Stream<S> _asyncMapThen<S>(
      Future<S> Function(T) convert, void Function(void) then) {
    Future<void>? pendingEvent;
    return transformByHandlers(onData: (event, sink) {
      pendingEvent =
          convert(event).then(sink.add).catchError(sink.addError).then(then);
    }, onDone: (sink) {
      if (pendingEvent != null) {
        pendingEvent!.then((_) => sink.close());
      } else {
        sink.close();
      }
    });
  }
}

T _dropPrevious<T>(T event, _) => event;
void _ignore<T>(Sink<T> sink) {}
