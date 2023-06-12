import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _StartWithErrorStreamSink<S> extends ForwardingSink<S, S> {
  final Object _e;
  final StackTrace? _st;

  _StartWithErrorStreamSink(this._e, this._st);

  @override
  void onData(S data) => sink.add(data);

  @override
  void onError(Object e, StackTrace st) => sink.addError(e, st);

  @override
  void onDone() => sink.close();

  @override
  FutureOr onCancel() {}

  @override
  void onListen() {
    sink.addError(_e, _st);
  }

  @override
  void onPause() {}

  @override
  void onResume() {}
}

/// Prepends an error to the source [Stream].
///
/// ### Example
///
///     Stream.fromIterable([2])
///       .transform(StartWithErrorStreamTransformer('error'))
///       .listen(null, onError: (e) => print(e)); // prints 'error'
class StartWithErrorStreamTransformer<S> extends StreamTransformerBase<S, S> {
  /// The starting error of this [Stream]
  final Object error;

  /// The starting stackTrace of this [Stream]
  final StackTrace? stackTrace;

  /// Constructs a [StreamTransformer] which starts with the provided [error]
  /// and then outputs all events from the source [Stream].
  StartWithErrorStreamTransformer(this.error, [this.stackTrace]);

  @override
  Stream<S> bind(Stream<S> stream) =>
      forwardStream(stream, () => _StartWithErrorStreamSink(error, stackTrace));
}
