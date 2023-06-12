import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _SwitchIfEmptyStreamSink<S> extends ForwardingSink<S, S> {
  final Stream<S> _fallbackStream;

  var _isEmpty = true;
  StreamSubscription<S>? _fallbackSubscription;

  _SwitchIfEmptyStreamSink(this._fallbackStream);

  @override
  void onData(S data) {
    _isEmpty = false;
    sink.add(data);
  }

  @override
  void onError(Object error, StackTrace st) {
    sink.addError(error, st);
  }

  @override
  void onDone() {
    if (_isEmpty) {
      _fallbackSubscription = _fallbackStream.listen(
        sink.add,
        onError: sink.addError,
        onDone: sink.close,
      );
    } else {
      sink.close();
    }
  }

  @override
  FutureOr<void> onCancel() => _fallbackSubscription?.cancel();

  @override
  void onListen() {}

  @override
  void onPause() => _fallbackSubscription?.pause();

  @override
  void onResume() => _fallbackSubscription?.resume();
}

/// When the original stream emits no items, this operator subscribes to
/// the given fallback stream and emits items from that stream instead.
///
/// This can be particularly useful when consuming data from multiple sources.
/// For example, when using the Repository Pattern. Assuming you have some
/// data you need to load, you might want to start with the fastest access
/// point and keep falling back to the slowest point. For example, first query
/// an in-memory database, then a database on the file system, then a network
/// call if the data isn't on the local machine.
///
/// This can be achieved quite simply with switchIfEmpty!
///
/// ### Example
///
///     // Let's pretend we have some Data sources that complete without emitting
///     // any items if they don't contain the data we're looking for
///     Stream<Data> memory;
///     Stream<Data> disk;
///     Stream<Data> network;
///
///     // Start with memory, fallback to disk, then fallback to network.
///     // Simple as that!
///     Stream<Data> getThatData =
///         memory.switchIfEmpty(disk).switchIfEmpty(network);
class SwitchIfEmptyStreamTransformer<S> extends StreamTransformerBase<S, S> {
  /// The [Stream] which will be used as fallback, if the source [Stream] is empty.
  final Stream<S> fallbackStream;

  /// Constructs a [StreamTransformer] which, when the source [Stream] emits
  /// no events, switches over to [fallbackStream].
  SwitchIfEmptyStreamTransformer(this.fallbackStream);

  @override
  Stream<S> bind(Stream<S> stream) {
    return forwardStream(
        stream, () => _SwitchIfEmptyStreamSink(fallbackStream));
  }
}

/// Extend the Stream class with the ability to return an alternative Stream
/// if the initial Stream completes with no items.
extension SwitchIfEmptyExtension<T> on Stream<T> {
  /// When the original Stream emits no items, this operator subscribes to the
  /// given fallback stream and emits items from that Stream instead.
  ///
  /// This can be particularly useful when consuming data from multiple sources.
  /// For example, when using the Repository Pattern. Assuming you have some
  /// data you need to load, you might want to start with the fastest access
  /// point and keep falling back to the slowest point. For example, first query
  /// an in-memory database, then a database on the file system, then a network
  /// call if the data isn't on the local machine.
  ///
  /// This can be achieved quite simply with switchIfEmpty!
  ///
  /// ### Example
  ///
  ///     // Let's pretend we have some Data sources that complete without
  ///     // emitting any items if they don't contain the data we're looking for
  ///     Stream<Data> memory;
  ///     Stream<Data> disk;
  ///     Stream<Data> network;
  ///
  ///     // Start with memory, fallback to disk, then fallback to network.
  ///     // Simple as that!
  ///     Stream<Data> getThatData =
  ///         memory.switchIfEmpty(disk).switchIfEmpty(network);
  Stream<T> switchIfEmpty(Stream<T> fallbackStream) =>
      SwitchIfEmptyStreamTransformer<T>(fallbackStream).bind(this);
}
