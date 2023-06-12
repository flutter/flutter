import 'dart:async';

import 'package:rxdart/src/streams/timer.dart';
import 'package:rxdart/src/transformers/backpressure/backpressure.dart';

/// Transforms a [Stream] so that will only emit items from the source sequence
/// if a window has completed, without the source sequence emitting
/// another item.
///
/// This window is created after the last debounced event was emitted.
/// You can use the value of the last debounced event to determine
/// the length of the next window.
///
/// A window is open until the first window event emits.
///
/// The debounce [StreamTransformer] filters out items emitted by the source
/// Stream that are rapidly followed by another emitted item.
///
/// [Interactive marble diagram](http://rxmarbles.com/#debounce)
///
/// ### Example
///
///     Stream.fromIterable([1, 2, 3, 4])
///       .debounceTime(Duration(seconds: 1))
///       .listen(print); // prints 4
class DebounceStreamTransformer<T> extends BackpressureStreamTransformer<T, T> {
  /// Constructs a [StreamTransformer] which buffers events into a [List] and
  /// emits this [List] whenever the current [window] fires.
  ///
  /// The [window] is reset whenever the [Stream] that is being transformed
  /// emits an event.
  DebounceStreamTransformer(Stream Function(T event) window)
      : assert(window != null, 'window stream factory cannot be null'),
        super(
          WindowStrategy.everyEvent,
          window,
          onWindowEnd: (Iterable<T> queue) => queue.last,
          maxLengthQueue: 1,
        );
}

/// Extends the Stream class with the ability to debounce events in various ways
extension DebounceExtensions<T> on Stream<T> {
  /// Transforms a [Stream] so that will only emit items from the source sequence
  /// if a [window] has completed, without the source sequence emitting
  /// another item.
  ///
  /// This [window] is created after the last debounced event was emitted.
  /// You can use the value of the last debounced event to determine
  /// the length of the next [window].
  ///
  /// A [window] is open until the first [window] event emits.
  ///
  /// debounce filters out items emitted by the source [Stream]
  /// that are rapidly followed by another emitted item.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#debounce)
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3, 4])
  ///       .debounce((_) => TimerStream(true, Duration(seconds: 1)))
  ///       .listen(print); // prints 4
  Stream<T> debounce(Stream Function(T event) window) =>
      transform(DebounceStreamTransformer<T>(window));

  /// Transforms a [Stream] so that will only emit items from the source
  /// sequence whenever the time span defined by [duration] passes, without the
  /// source sequence emitting another item.
  ///
  /// This time span start after the last debounced event was emitted.
  ///
  /// debounceTime filters out items emitted by the source [Stream] that are
  /// rapidly followed by another emitted item.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#debounceTime)
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3, 4])
  ///       .debounceTime(Duration(seconds: 1))
  ///       .listen(print); // prints 4
  Stream<T> debounceTime(Duration duration) => transform(
      DebounceStreamTransformer<T>((_) => TimerStream<void>(null, duration)));
}
