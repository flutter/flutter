// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../stream_sink_transformer.dart';
import 'capture_sink.dart';
import 'capture_transformer.dart';
import 'error.dart';
import 'release_sink.dart';
import 'release_transformer.dart';
import 'value.dart';

/// The result of a computation.
///
/// Capturing a result (either a returned value or a thrown error) means
/// converting it into a [Result] - either a [ValueResult] or an [ErrorResult].
///
/// This value can release itself by writing itself either to a [EventSink] or a
/// [Completer], or by becoming a [Future].
///
/// A [Future] represents a potential result, one that might not have been
/// computed yet, and a [Result] is always a completed and available result.
abstract class Result<T> {
  /// A stream transformer that captures a stream of events into [Result]s.
  ///
  /// The result of the transformation is a stream of [Result] values and no
  /// error events. This is the transformer used by [captureStream].
  static const StreamTransformer<Object, Result<Object>>
      captureStreamTransformer = CaptureStreamTransformer<Object>();

  /// A stream transformer that releases a stream of result events.
  ///
  /// The result of the transformation is a stream of values and error events.
  /// This is the transformer used by [releaseStream].
  static const StreamTransformer<Result<Object>, Object>
      releaseStreamTransformer = ReleaseStreamTransformer<Object>();

  /// A sink transformer that captures events into [Result]s.
  ///
  /// The result of the transformation is a sink that only forwards [Result]
  /// values and no error events.
  static const StreamSinkTransformer<Object, Result<Object>>
      captureSinkTransformer =
      StreamSinkTransformer<Object, Result<Object>>.fromStreamTransformer(
          CaptureStreamTransformer<Object>());

  /// A sink transformer that releases result events.
  ///
  /// The result of the transformation is a sink that forwards of values and
  /// error events.
  static const StreamSinkTransformer<Result<Object>, Object>
      releaseSinkTransformer =
      StreamSinkTransformer<Result<Object>, Object>.fromStreamTransformer(
          ReleaseStreamTransformer<Object>());

  /// Creates a `Result` with the result of calling [computation].
  ///
  /// This generates either a [ValueResult] with the value returned by
  /// calling `computation`, or an [ErrorResult] with an error thrown by
  /// the call.
  factory Result(T Function() computation) {
    try {
      return ValueResult<T>(computation());
    } on Object catch (e, s) {
      return ErrorResult(e, s);
    }
  }

  /// Creates a `Result` holding a value.
  ///
  /// Alias for [ValueResult.new].
  factory Result.value(T value) = ValueResult<T>;

  /// Creates a `Result` holding an error.
  ///
  /// Alias for [ErrorResult.new].
  factory Result.error(Object error, [StackTrace? stackTrace]) =>
      ErrorResult(error, stackTrace);

  /// Captures the result of a future into a `Result` future.
  ///
  /// The resulting future will never have an error.
  /// Errors have been converted to an [ErrorResult] value.
  static Future<Result<T>> capture<T>(Future<T> future) {
    return future.then(ValueResult.new, onError: ErrorResult.new);
  }

  /// Captures each future in [elements],
  ///
  /// Returns a (future of) a list of results for each element in [elements],
  /// in iteration order.
  /// Each future in [elements] is [capture]d and each non-future is
  /// wrapped as a [Result.value].
  /// The returned future will never have an error.
  static Future<List<Result<T>>> captureAll<T>(Iterable<FutureOr<T>> elements) {
    var results = <Result<T>?>[];
    var pending = 0;
    late Completer<List<Result<T>>> completer;
    for (var element in elements) {
      if (element is Future<T>) {
        var i = results.length;
        results.add(null);
        pending++;
        Result.capture<T>(element).then((result) {
          results[i] = result;
          if (--pending == 0) {
            completer.complete(List.from(results));
          }
        });
      } else {
        results.add(Result<T>.value(element));
      }
    }
    if (pending == 0) {
      return Future.value(List.from(results));
    }
    completer = Completer<List<Result<T>>>();
    return completer.future;
  }

  /// Releases the result of a captured future.
  ///
  /// Converts the [Result] value of the given [future] to a value or error
  /// completion of the returned future.
  ///
  /// If [future] completes with an error, the returned future completes with
  /// the same error.
  static Future<T> release<T>(Future<Result<T>> future) =>
      future.then<T>((result) => result.asFuture);

  /// Captures the results of a stream into a stream of [Result] values.
  ///
  /// The returned stream will not have any error events.
  /// Errors from the source stream have been converted to [ErrorResult]s.
  static Stream<Result<T>> captureStream<T>(Stream<T> source) =>
      source.transform(CaptureStreamTransformer<T>());

  /// Releases a stream of [source] values into a stream of the results.
  ///
  /// `Result` values of the source stream become value or error events in
  /// the returned stream as appropriate.
  /// Errors from the source stream become errors in the returned stream.
  static Stream<T> releaseStream<T>(Stream<Result<T>> source) =>
      source.transform(ReleaseStreamTransformer<T>());

  /// Releases results added to the returned sink as data and errors on [sink].
  ///
  /// A [Result] added to the returned sink is added as a data or error event
  /// on [sink]. Errors added to the returned sink are forwarded directly to
  /// [sink] and so is the [EventSink.close] calls.
  static EventSink<Result<T>> releaseSink<T>(EventSink<T> sink) =>
      ReleaseSink<T>(sink);

  /// Captures the events of the returned sink into results on [sink].
  ///
  /// Data and error events added to the returned sink are captured into
  /// [Result] values and added as data events on the provided [sink].
  /// No error events are ever added to [sink].
  ///
  /// When the returned sink is closed, so is [sink].
  static EventSink<T> captureSink<T>(EventSink<Result<T>> sink) =>
      CaptureSink<T>(sink);

  /// Converts a result of a result to a single result.
  ///
  /// If the result is an error, or it is a `Result` value
  /// which is then an error, then a result with that error is returned.
  /// Otherwise both levels of results are value results, and a single
  /// result with the value is returned.
  static Result<T> flatten<T>(Result<Result<T>> result) {
    if (result.isValue) return result.asValue!.value;
    return result.asError!;
  }

  /// Converts a sequence of results to a result of a list.
  ///
  /// Returns either a list of values if [results] doesn't contain any errors,
  /// or the first error result in [results].
  static Result<List<T>> flattenAll<T>(Iterable<Result<T>> results) {
    var values = <T>[];
    for (var result in results) {
      if (result.isValue) {
        values.add(result.asValue!.value);
      } else {
        return result.asError!;
      }
    }
    return Result<List<T>>.value(values);
  }

  /// Whether this result is a value result.
  ///
  /// Always the opposite of [isError].
  bool get isValue;

  /// Whether this result is an error result.
  ///
  /// Always the opposite of [isValue].
  bool get isError;

  /// If this is a value result, returns itself.
  ///
  /// Otherwise returns `null`.
  ValueResult<T>? get asValue;

  /// If this is an error result, returns itself.
  ///
  /// Otherwise returns `null`.
  ErrorResult? get asError;

  /// Completes a completer with this result.
  void complete(Completer<T> completer);

  /// Adds this result to an [EventSink].
  ///
  /// Calls the sink's `add` or `addError` method as appropriate.
  void addTo(EventSink<T> sink);

  /// A future that has been completed with this result as a value or an error.
  Future<T> get asFuture;
}
