import 'dart:async';

/// A [Sink] that supports event hooks.
///
/// This makes it suitable for certain rx transformers that need to
/// take action after onListen, onPause, onResume or onCancel.
///
/// The [ForwardingSink] has been designed to handle asynchronous events from
/// [Stream]s. See, for example, [Stream.eventTransformed] which uses
/// `EventSink`s to transform events.
abstract class ForwardingSink<T, R> {
  EventSink<R>? _sink;

  /// The output sink.
  EventSink<R> get sink =>
      _sink ?? (throw StateError('Must call setSink(sink) before accessing!'));

  /// Set the output sink.
  void setSink(EventSink<R> sink) => _sink = sink;

  /// Handle data event
  void onData(T data);

  /// Handle error event
  void onError(Object error, StackTrace st);

  /// Handle close event
  void onDone();

  /// Fires when a listener subscribes on the underlying [Stream].
  /// Returns a [Future] to delay listening to source [Stream].
  FutureOr<void> onListen();

  /// Fires when a subscriber pauses.
  void onPause();

  /// Fires when a subscriber resumes after a pause.
  void onResume();

  /// Fires when a subscriber cancels.
  FutureOr<void> onCancel();
}
