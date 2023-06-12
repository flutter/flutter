import 'dart:async';

import 'package:rxdart/src/streams/zip.dart';
import 'package:rxdart/src/transformers/materialize.dart';
import 'package:rxdart/src/utils/error_and_stacktrace.dart';
import 'package:rxdart/src/utils/notification.dart';

/// Determine whether two Streams emit the same sequence of items.
/// You can provide an optional equals handler to determine equality.
///
/// [Interactive marble diagram](https://rxmarbles.com/#sequenceEqual)
///
/// ### Example
///
///     SequenceEqualsStream([
///       Stream.fromIterable([1, 2, 3, 4, 5]),
///       Stream.fromIterable([1, 2, 3, 4, 5])
///     ])
///     .listen(print); // prints true
class SequenceEqualStream<S, T> extends Stream<bool> {
  final StreamController<bool> _controller;

  /// Creates a [Stream] that emits true or false, depending on the
  /// equality between the provided [Stream]s.
  /// This single value is emitted when both provided [Stream]s are complete.
  /// After this event, the [Stream] closes.
  SequenceEqualStream(
    Stream<S> stream,
    Stream<T> other, {
    bool Function(S s, T t)? dataEquals,
    bool Function(ErrorAndStackTrace, ErrorAndStackTrace)? errorEquals,
  }) : _controller = _buildController(stream, other, dataEquals, errorEquals);

  @override
  StreamSubscription<bool> listen(void Function(bool event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _controller.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  static StreamController<bool> _buildController<S, T>(
    Stream<S> stream,
    Stream<T> other,
    bool Function(S s, T t)? dataEquals,
    bool Function(ErrorAndStackTrace, ErrorAndStackTrace)? errorEquals,
  ) {
    dataEquals = dataEquals ?? (s, t) => s == t;
    errorEquals = errorEquals ?? (e1, e2) => e1 == e2;

    late StreamController<bool> controller;
    late StreamSubscription<bool> subscription;

    controller = StreamController<bool>(
        sync: true,
        onListen: () {
          void emitAndClose([bool value = true]) => controller
            ..add(value)
            ..close();

          bool compare(Notification<S> s, Notification<T> t) {
            if (s.kind != t.kind) {
              return false;
            }
            switch (s.kind) {
              case Kind.onData:
                return dataEquals!(
                  s.requireData,
                  t.requireData,
                );
              case Kind.onDone:
                return true;
              case Kind.onError:
                return errorEquals!(
                  s.errorAndStackTrace!,
                  t.errorAndStackTrace!,
                );
            }
          }

          subscription =
              ZipStream.zip2(stream.materialize(), other.materialize(), compare)
                  .where((isEqual) => !isEqual)
                  .listen(
                    emitAndClose,
                    onError: controller.addError,
                    onDone: emitAndClose,
                  );
        },
        onPause: () => subscription.pause(),
        onResume: () => subscription.resume(),
        onCancel: () => subscription.cancel());

    return controller;
  }
}
